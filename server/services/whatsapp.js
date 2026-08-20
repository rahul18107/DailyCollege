const { default: makeWASocket, useMultiFileAuthState, DisconnectReason } = require('@whiskeysockets/baileys')
const qrcode = require('qrcode-terminal')
const pino = require('pino')
const fs = require('fs')
const path = require('path')

const AUTH_DIR = path.join(__dirname, '..', 'baileys_auth')

const CACHE_MAX_AGE_DAYS = 30

let sock = null
let clientReady = false
let pendingPhoneNumber = null
let currentPairingCode = null
let pairingAttempts = 0
const MAX_PAIRING_ATTEMPTS = 3

// jid → Message[]
const messageCache = new Map()

// ── Cache persistence ──────────────────────────


function getCacheFile() {
  if (!sock?.user?.id) return path.join(__dirname, '..', 'message_cache_default.json')
  const phone = sock.user.id.split(':')[0]
  return path.join(__dirname, '..', `message_cache_${phone}.json`)
}

function loadCacheFromDisk() {
  try {
    if (!fs.existsSync(getCacheFile())) return
    const raw = fs.readFileSync(getCacheFile(), 'utf-8')
    const obj = JSON.parse(raw)
    for (const [jid, messages] of Object.entries(obj)) {
      messageCache.set(jid, messages)
    }
    console.log(`📂 Cache loaded from disk — ${messageCache.size} chats`)
  } catch (e) {
    console.error('Cache load error:', e.message)
  }
}

function saveCacheToDisk() {
  try {
    const obj = {}
    for (const [jid, messages] of messageCache.entries()) {
      obj[jid] = messages
    }
    fs.writeFileSync(getCacheFile(), JSON.stringify(obj))
  } catch (e) {
    console.error('Cache save error:', e.message)
  }
}

function cleanOldMessages() {
  const cutoff = Date.now() / 1000 - CACHE_MAX_AGE_DAYS * 86400
  let cleaned = 0
  for (const [jid, messages] of messageCache.entries()) {
    const filtered = messages.filter(m => (m.messageTimestamp || 0) > cutoff)
    cleaned += messages.length - filtered.length
    messageCache.set(jid, filtered)
  }
  if (cleaned > 0) {
    console.log(`🧹 Cleaned ${cleaned} messages older than ${CACHE_MAX_AGE_DAYS} days`)
    saveCacheToDisk()
  }
}

// ── Message caching ────────────────────────────

function cacheMessages(messages) {
  for (const msg of messages) {
    const jid = msg.key?.remoteJid
    if (!jid) continue
    if (!messageCache.has(jid)) messageCache.set(jid, [])
    const list = messageCache.get(jid)
    const exists = list.find(m => m.key?.id === msg.key?.id)
    if (!exists) list.push(msg)
    // keep max 1000 per chat
    if (list.length > 1000) list.splice(0, list.length - 1000)
  }
}

function loadMessages(jid, count = 200) {
  const list = messageCache.get(jid) || []
  console.log(`📦 Cache has ${list.length} messages for this group`)
  return list.slice(-count)
}

// ── WhatsApp connection ────────────────────────

let isConnecting = false
loadCacheFromDisk()

async function connectToWhatsApp() {
  if (isConnecting) return
  isConnecting = true

  const { state, saveCreds } = await useMultiFileAuthState(AUTH_DIR)

  sock = makeWASocket({
      auth: state,
      printQRInTerminal: false,
      logger: pino({ level: 'silent' }),
      syncFullHistory: false,
      connectTimeoutMs: 60000,
    })

    // Request pairing code if not already authenticated
    if (!state.creds.registered && pendingPhoneNumber && pairingAttempts < MAX_PAIRING_ATTEMPTS) {
      pairingAttempts++
      // Wait for socket to be ready
      setTimeout(async () => {
        try {
          const code = await sock.requestPairingCode(pendingPhoneNumber)
          console.log(`🔑 Pairing code for ${pendingPhoneNumber}: ${code}`)
          currentPairingCode = code
        } catch (e) {
          console.error('Pairing code error:', e.message)
          currentPairingCode = null
        }
      }, 2000)
    }

  sock.ev.on('messages.upsert', ({ messages, type }) => {
    if (type === 'notify' || type === 'append') {
      console.log(`📥 Received ${messages.length} message(s), type: ${type}`)
      messages.forEach(msg => {
        const content = msg.message
        if (content?.documentMessage?.mimetype === 'application/pdf') {
          console.log(`📄 PDF detected: ${content.documentMessage.fileName}`)
        } else if (content?.imageMessage) {
          console.log(`🖼️ Image detected`)
        } else if (content?.conversation || content?.extendedTextMessage) {
          console.log(`💬 Text message detected`)
        }
      })
      cacheMessages(messages)
      saveCacheToDisk()
    }
  })

  sock.ev.on('connection.update', async (update) => {
    const { connection, lastDisconnect, qr } = update

    if (qr && !pendingPhoneNumber) {
      // Only show QR if not in pairing mode
      console.log('\n📱 Scan this QR code with your WhatsApp:\n')
      qrcode.generate(qr, { small: true })
    }

    if (connection === 'open') {
      isConnecting = false
      clientReady = true
      pendingPhoneNumber = null
      currentPairingCode = null
      pairingAttempts = 0
      console.log('✅ WhatsApp session ready')
    }

    if (connection === 'close') {
      clientReady = false
      const statusCode = lastDisconnect?.error?.output?.statusCode

      if (statusCode === DisconnectReason.loggedOut) {
        console.log('❌ Logged out — clearing session')
        if (fs.existsSync(AUTH_DIR)) {
          fs.readdirSync(AUTH_DIR).forEach(f => fs.rmSync(path.join(AUTH_DIR, f)))
        }
        // Don't auto-reconnect in pairing mode
        if (!pendingPhoneNumber) {
          isConnecting = false
          setTimeout(() => connectToWhatsApp(), 3000)
        } else {
          isConnecting = false
          pairingAttempts = 0
          console.log('⚠️ Pairing failed - try again with a different number or use QR code')
        }
      } else if (statusCode === DisconnectReason.connectionReplaced) {
        console.log('⚠️ Connection replaced — waiting 15s...')
        isConnecting = false
        setTimeout(() => connectToWhatsApp(), 15000)
      } else {
        // Don't reconnect repeatedly during pairing
        if (pendingPhoneNumber && pairingAttempts >= MAX_PAIRING_ATTEMPTS) {
          console.log('⚠️ Pairing connection unstable - stopping reconnection')
          isConnecting = false
        } else {
          console.log('🔄 Reconnecting in 5s...')
          isConnecting = false
          setTimeout(() => connectToWhatsApp(), 5000)
        }
      }
    }
  })

  sock.ev.on('creds.update', saveCreds)

  setInterval(saveCacheToDisk, 5 * 60 * 1000)
  setInterval(cleanOldMessages, 24 * 60 * 60 * 1000)
}

function getClient() {
  return sock
}

function isReady() {
  return clientReady
}

async function requestCode(phoneNumber) {
  // Clean and validate phone number - must start with country code
  let cleanPhone = phoneNumber.replace(/[^0-9]/g, '')

  // Ensure it doesn't start with + or 00
  if (cleanPhone.startsWith('00')) {
    cleanPhone = cleanPhone.substring(2)
  }

  console.log(`📞 Requesting pairing code for: ${cleanPhone}`)

  // If already ready, user needs to logout first
  if (clientReady) {
    throw new Error('Already authenticated. Logout first.')
  }

  // Set pending phone number for pairing mode
  pendingPhoneNumber = cleanPhone
  currentPairingCode = null
  pairingAttempts = 0

  // Clear any existing auth to force pairing
  if (fs.existsSync(AUTH_DIR)) {
    const files = fs.readdirSync(AUTH_DIR)
    files.forEach(f => fs.rmSync(path.join(AUTH_DIR, f)))
    console.log(`🧹 Cleared ${files.length} auth files`)
  }

  // Reconnect with pairing
  isConnecting = false
  connectToWhatsApp()

  // Wait up to 30s for code
  for (let i = 0; i < 30; i++) {
    if (currentPairingCode) {
      console.log(`✅ Code generated: ${currentPairingCode}`)
      return currentPairingCode
    }
    await new Promise(r => setTimeout(r, 1000))
  }

  // Reset pairing mode on timeout
  pendingPhoneNumber = null
  pairingAttempts = 0
  console.error('❌ Pairing code timeout')
  throw new Error('Pairing code timeout - try again')
}

function getCurrentPairingCode() {
  return currentPairingCode
}

function getStatus() {
  if (clientReady) return 'ready'
  if (currentPairingCode) return 'waiting_for_code'
  return 'not_ready'
}

function getConnectedUser() {
  return sock?.user || null
}

async function logout() {
  try {
    await sock?.logout()
  } catch (_) {}
  clientReady = false
  if (fs.existsSync(AUTH_DIR)) {
    fs.readdirSync(AUTH_DIR).forEach(f => fs.rmSync(path.join(AUTH_DIR, f)))
  }
  messageCache.clear()
}



module.exports = { connectToWhatsApp, getClient, loadMessages, isReady, loadCacheFromDisk, requestCode, getStatus, getCurrentPairingCode ,getConnectedUser,logout  }
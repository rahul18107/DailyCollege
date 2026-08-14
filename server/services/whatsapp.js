const { default: makeWASocket, useMultiFileAuthState, DisconnectReason } = require('@whiskeysockets/baileys')
const qrcode = require('qrcode-terminal')
const pino = require('pino')
const fs = require('fs')
const path = require('path')

const AUTH_DIR = path.join(__dirname, '..', 'baileys_auth')
const CACHE_FILE = path.join(__dirname, '..', 'message_cache.json')
const CACHE_MAX_AGE_DAYS = 30

let sock = null
let clientReady = false

// jid → Message[]
const messageCache = new Map()

// ── Cache persistence ──────────────────────────

function loadCacheFromDisk() {
  try {
    if (!fs.existsSync(CACHE_FILE)) return
    const raw = fs.readFileSync(CACHE_FILE, 'utf-8')
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
    fs.writeFileSync(CACHE_FILE, JSON.stringify(obj))
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
  })

  sock.ev.on('messages.upsert', ({ messages, type }) => {
    if (type === 'notify' || type === 'append') {
      cacheMessages(messages)
      saveCacheToDisk()
    }
  })

  sock.ev.on('connection.update', async (update) => {
    const { connection, lastDisconnect, qr } = update

    if (qr) {
      console.log('\n📱 Scan this QR code with your WhatsApp:\n')
      qrcode.generate(qr, { small: true })
    }

    if (connection === 'open') {
      isConnecting = false
      clientReady = true
      console.log('✅ WhatsApp session ready')
    }

    if (connection === 'close') {
      clientReady = false
      isConnecting = false
      const statusCode = lastDisconnect?.error?.output?.statusCode

      if (statusCode === DisconnectReason.loggedOut) {
        console.log('❌ Logged out — clearing session')
        if (fs.existsSync(AUTH_DIR)) {
          fs.readdirSync(AUTH_DIR).forEach(f => fs.rmSync(path.join(AUTH_DIR, f)))
        }
        setTimeout(() => connectToWhatsApp(), 3000)
      } else if (statusCode === DisconnectReason.connectionReplaced) {
        console.log('⚠️ Connection replaced — waiting 15s...')
        setTimeout(() => connectToWhatsApp(), 15000)
      } else {
        console.log('🔄 Reconnecting in 5s...')
        setTimeout(() => connectToWhatsApp(), 5000)
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

module.exports = { connectToWhatsApp, getClient, loadMessages, isReady, loadCacheFromDisk }
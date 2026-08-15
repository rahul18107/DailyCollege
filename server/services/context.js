const { PDFParse } = require('pdf-parse')
const { downloadMediaMessage } = require('@whiskeysockets/baileys')
const { loadMessages } = require('./whatsapp')
const { getLastProcessedTime } = require('./db')


async function buildContext(sock, groupId) {
  console.log('📦 Building context for group:', groupId)

  const allmessages = loadMessages(groupId, 200)
  const lastTime = await getLastProcessedTime(groupId)
  const messages = lastTime
    ? allmessages.filter(m => m.messageTimestamp > lastTime)
    : allmessages
  console.log(`📨 Total cached: ${allmessages.length}, New messages: ${messages.length}, Last processed: ${lastTime}`)

  const textMessages = []
  const pdfs = []
  const images = []

  // contacts map — populated by Baileys as messages arrive
  const contacts = sock.store?.contacts || {}

  function getDisplayName(jid) {
    if (!jid) return 'Unknown'
    const contact = contacts[jid]
    // notify = their WhatsApp name, name = saved contact name
    return contact?.notify || contact?.name || jid.split('@')[0]
  }

  for (let i = 0; i < messages.length; i++) {
    const msg = messages[i]
    const content = msg.message
    if (!content) continue

    const timestamp = msg.messageTimestamp
    const authorJid = msg.key?.participant || msg.key?.remoteJid || 'unknown'
    const authorName = msg.pushName || authorJid.split('@')[0]

    if (content.conversation || content.extendedTextMessage) {
      const body = content.conversation || content.extendedTextMessage?.text || ''
      let quotedContent = null
      if (content.extendedTextMessage?.contextInfo?.quotedMessage) {
        const quoted = content.extendedTextMessage.contextInfo.quotedMessage
        quotedContent = quoted.conversation || quoted.extendedTextMessage?.text || '[media]'
      }
      if (body.trim()) {
        textMessages.push({
          index: i,
          timestamp,
          author: authorJid,
          authorName,
          body,
          quotedContent
        })
      }
    } else if (content.documentMessage?.mimetype === 'application/pdf') {
      try {
        const buffer = await downloadMediaMessage(msg, 'buffer', {}, { logger: { warn: () => {}, debug: () => {}, info: () => {}, error: console.error } })
        const parser = new PDFParse({ data: buffer })
        const result = await parser.getText()
        const pdfText = result.pages.map(pg => pg.text).join('\n')
        const surrounding = textMessages.filter(m => Math.abs(m.index - i) <= 100)
        pdfs.push({
          index: i,
          timestamp,
          author: authorJid,
          authorName,
          filename: content.documentMessage.fileName || 'document.pdf',
          text: pdfText,
          surrounding
        })
        console.log(`📄 PDF parsed: ${content.documentMessage.fileName}`)
      } catch (e) {
        console.error('PDF download/parse error:', content.documentMessage.fileName, '—', e.message)
      }
    } else if (content.imageMessage) {
      try {
        const buffer = await downloadMediaMessage(msg, 'buffer', {}, { logger: { warn: () => {}, debug: () => {}, info: () => {}, error: console.error } })
        const base64 = buffer.toString('base64')
        images.push({
          index: i,
          timestamp,
          author: authorJid,
          authorName,
          base64,
          mimetype: content.imageMessage.mimetype || 'image/jpeg',
          caption: content.imageMessage.caption || ''
        })
        console.log('🖼️ Image captured')
      } catch (e) {
        console.error('Image error:', e.message)
      }
    }
  }

  let pinnedMsg = null
  try {
    const groupMeta = await sock.groupMetadata(groupId)
    if (groupMeta.pinnedMsg) pinnedMsg = groupMeta.pinnedMsg
  } catch (_) {}

  console.log(`✅ Context built — ${textMessages.length} texts, ${pdfs.length} PDFs, ${images.length} images`)

  // Return the latest message timestamp
  const latestTimestamp = messages.length > 0
    ? Math.max(...messages.map(m => m.messageTimestamp || 0))
    : null

  return { pinnedMsg, textMessages, pdfs, images, latestTimestamp }
}

module.exports = { buildContext }
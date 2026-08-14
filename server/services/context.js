const pdfParse = require('pdf-parse')
const { loadMessages } = require('./whatsapp')

async function buildContext(sock, groupId) {
  console.log('📦 Building context for group:', groupId)

  const messages = loadMessages(groupId, 200)
  console.log(`📨 Fetched ${messages.length} messages`)

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
    const authorName = getDisplayName(authorJid)

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
        const buffer = await sock.downloadMediaMessage(msg)
        const parsed = await pdfParse(buffer)
        const surrounding = textMessages.filter(m => Math.abs(m.index - i) <= 100)
        pdfs.push({
          index: i,
          timestamp,
          author: authorJid,
          authorName,
          filename: content.documentMessage.fileName || 'document.pdf',
          text: parsed.text,
          surrounding
        })
        console.log(`📄 PDF parsed: ${content.documentMessage.fileName}`)
      } catch (e) {
        console.error('PDF error:', e.message)
      }
    } else if (content.imageMessage) {
      try {
        const buffer = await sock.downloadMediaMessage(msg)
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
  return { pinnedMsg, textMessages, pdfs, images }
}

module.exports = { buildContext }
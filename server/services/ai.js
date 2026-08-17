const MODELS = {
  text: '@cf/meta/llama-3.3-70b-instruct-fp8-fast',
  vision: '@cf/meta/llama-4-scout-17b-16e-instruct'
}

async function callTextModel(prompt) {
  const response = await fetch(
    `https://api.cloudflare.com/client/v4/accounts/${process.env.CLOUDFLARE_ACCOUNT_ID}/ai/run/${MODELS.text}`,
    {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${process.env.CLOUDFLARE_API_TOKEN}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        messages: [
          {
            role: 'system',
            content: getSystemPrompt()
          },
          {
            role: 'user',
            content: prompt
          }
        ]
      })
    }
  )

  const data = await response.json()
  const raw = data.result?.response ?? data.result ?? ''
  return parseJSON(raw)
}

async function callVisionModel(base64Image, mimetype, caption) {
  const response = await fetch(
    `https://api.cloudflare.com/client/v4/accounts/${process.env.CLOUDFLARE_ACCOUNT_ID}/ai/run/${MODELS.vision}`,
    {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${process.env.CLOUDFLARE_API_TOKEN}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        messages: [
          {
            role: 'system',
            content: getSystemPrompt()
          },
          {
            role: 'user',
            content: [
              {
                type: 'image',
                source: {
                  type: 'base64',
                  media_type: mimetype,
                  data: base64Image
                }
              },
              {
                type: 'text',
                text: caption
                  ? `This image was sent with caption: "${caption}". Extract any academic events.`
                  : 'Extract any academic events from this timetable or notice image.'
              }
            ]
          }
        ]
      })
    }
  )

  const data = await response.json()
  const raw = data.result?.response ?? data.result ?? []
  return parseJSON(raw)
}

function getSystemPrompt() {
  return `You are an AI assistant that extracts academic events from college WhatsApp group messages.
You must respond with ONLY a valid JSON array. No explanation, no markdown, no extra text.
Each object in the array must have these exact fields:
{
  "type": "cancellation" | "reschedule" | "holiday" | "exam" | "cir",
  "subject": "subject name or null",
  "date": "YYYY-MM-DD or null",
  "description": "one line summary",
  "is_tentative": true or false,
  "new_time": "new time if rescheduled or null",
  "syllabus": "units/topics if exam or null",
  "source_msg": "the original message that triggered this",
  "sent_by": "WhatsApp display name of who sent the source message",
  "quoted_msg": "the quoted/referenced message if this is a reply, or null",
  "confidence": "high" | "medium" | "low"
}

IMPORTANT: You are only processing NEW messages that haven't been analyzed before.
Extract ONLY events from these new messages. Do not re-extract or duplicate events you may have seen previously.
If there are no relevant academic events in these NEW messages, return an empty array: []
Only extract events that are clearly academic — ignore personal conversations, memes, and unrelated messages.`
}

function parseJSON(text) {
  try {
    // if Cloudflare already returned parsed JSON, use it directly
    if (typeof text === 'object') return text
    const clean = text.replace(/```json|```/g, '').trim()
    return JSON.parse(clean)
  } catch (e) {
    console.error('JSON parse error:', e.message)
    console.error('Raw response:', text)
    return []
  }
}

async function parseWithAI(context) {
  const allEvents = []

  // ── Process text messages ──
  if (context.textMessages.length > 0) {
    console.log('🤖 Processing text messages...')
    try {
      const prompt = buildTextPrompt(context.textMessages, context.pinnedMsg)
      const events = await callTextModel(prompt)
      console.log(`✅ Text done — ${events.length} events found`)
      allEvents.push(...events)
    } catch (e) {
      console.error('Text processing error:', e.message)
    }
  }

  // ── Process PDFs ──
  for (const pdf of context.pdfs) {
    console.log(`🤖 Processing PDF: ${pdf.filename}`)
    try {
      const prompt = buildPdfPrompt(pdf, context.pinnedMsg)
      const events = await callTextModel(prompt)
      console.log(`✅ PDF done — ${events.length} events found`)
      allEvents.push(...events)
    } catch (e) {
      console.error('PDF processing error:', e.message)
    }
  }

  // ── Process images ──
  for (const image of context.images) {
    console.log('🤖 Processing image...')
    try {
      const events = await callVisionModel(image.base64, image.mimetype, image.caption)
      console.log(`✅ Image done — ${events.length} events found`)
      allEvents.push(...events)
    } catch (e) {
      console.error('Image processing error:', e.message)
    }
  }

  return allEvents
}

function buildTextPrompt(textMessages, pinnedMsg) {
  let prompt = ''

  if (pinnedMsg) {
    prompt += `PINNED MESSAGE (important reference):\n${pinnedMsg}\n\n`
  }

  prompt += `WHATSAPP GROUP MESSAGES (NEW MESSAGES ONLY):\n`
  prompt += textMessages.map(m =>
    `[${new Date(m.timestamp * 1000).toLocaleString()}] ${m.authorName}: ${m.body}` +
    (m.quotedContent ? `\n  (replying to: "${m.quotedContent}")` : '')
  ).join('\n')

  console.log('PROMPT PREVIEW:\n', prompt.slice(0, 500))
  console.log(`📊 Processing ${textMessages.length} new messages`)

  prompt += `\n\nExtract all academic events from these NEW messages only. For sent_by use the name before the colon in each message line.`

  return prompt
}

function buildPdfPrompt(pdf, pinnedMsg) {
  let prompt = ''

  if (pinnedMsg) {
    prompt += `PINNED MESSAGE (important reference):\n${pinnedMsg}\n\n`
  }

  prompt += `PDF DOCUMENT (NEW): ${pdf.filename}\n`
  prompt += `Sent by: ${pdf.authorName}\n`
  prompt += `PDF CONTENT:\n${pdf.text}\n\n`

  if (pdf.surrounding.length > 0) {
    prompt += `SURROUNDING MESSAGES (sent around the same time as this PDF):\n`
    prompt += pdf.surrounding.map(m =>
      `[${new Date(m.timestamp * 1000).toLocaleString()}] ${m.authorName}: ${m.body}` +
      (m.quotedContent ? `\n  (replying to: "${m.quotedContent}")` : '')
    ).join('\n')
    prompt += `\n\nUse surrounding messages to determine if any PDF events are tentative or have been updated.`
  }

  prompt += `\n\nExtract all academic events from this NEW PDF only — exam dates, holidays, CIR dates, syllabus. For sent_by use "${pdf.authorName}".`

  return prompt
}


module.exports = { parseWithAI }
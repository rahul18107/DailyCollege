const express = require('express')
const router = express.Router()
const { getClient, isReady } = require('../services/whatsapp')
const { buildContext } = require('../services/context')
const { parseWithAI } = require('../services/ai')
const { saveCards, getCards } = require('../services/db')

router.post('/', async (req, res) => {
  if (!isReady()) {
    return res.status(503).json({ error: 'WhatsApp not ready yet' })
  }

  const { groupId } = req.body
  if (!groupId) {
    return res.status(400).json({ error: 'groupId is required' })
  }

  try {
    console.log('\n🚀 Process started for group:', groupId)

    console.log('Step 1: Building context...')
    const sock = getClient()
    const context = await buildContext(sock, groupId)

    console.log('Step 2: Sending to AI...')
    const events = await parseWithAI(context)
    console.log(`Step 2 done: ${events.length} total events extracted`)

    console.log('Step 3: Saving to Supabase...')
    await saveCards(events, groupId)

    console.log('Step 4: Fetching all cards...')
    const allCards = await getCards(groupId)

    console.log('✅ Process complete\n')
    res.json({
      success: true,
      newEvents: events.length,
      totalCards: allCards.length,
      cards: allCards
    })

  } catch (err) {
    console.error('❌ Process error:', err.message)
    res.status(500).json({ error: err.message })
  }
})

module.exports = router
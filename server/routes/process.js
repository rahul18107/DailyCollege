const express = require('express')
const router = express.Router()
const { getClient, isReady ,getConnectedUser} = require('../services/whatsapp')
const { buildContext } = require('../services/context')
const { parseWithAI } = require('../services/ai')
const { saveCards, getCards, updateLastProcessedTime } = require('../services/db')

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

    const user = getConnectedUser()
    const userPhone = user?.id?.split(':')[0] || 'default'

    console.log('Step 1: Building context...')
    const sock = getClient()
    const context = await buildContext(sock, groupId)

    if (context.textMessages.length === 0 && context.pdfs.length === 0 && context.images.length === 0) {
      console.log('⚠️ No new messages to process')
      const allCards = await getCards(groupId)
      return res.json({
        success: true,
        newEvents: 0,
        totalCards: allCards.length,
        cards: allCards,
        message: 'No new messages since last processing'
      })


    }

    console.log('Step 2: Sending to AI...')
    const events = await parseWithAI(context)
    console.log(`Step 2 done: ${events.length} total events extracted`)

    console.log('Step 3: Saving to Supabase...')
    await saveCards(events, groupId, userPhone)

    // Update the last processed timestamp
    if (context.latestTimestamp) {
      console.log(`Step 4: Updating last processed time to ${context.latestTimestamp}`)
      await updateLastProcessedTime(groupId, context.latestTimestamp,userPhone)
    }

    console.log('Step 5: Fetching all cards...')
    const allCards = await getCards(groupId,userPhone)

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
const express = require('express')
const router = express.Router()
const { getClient, isReady } = require('../services/whatsapp')

router.get('/', async (req, res) => {
  if (!isReady()) {
    return res.status(503).json({ error: 'WhatsApp not ready yet' })
  }

  try {
    const sock = getClient()
    const result = await sock.groupFetchAllParticipating()
    const groups = Object.values(result).map(g => ({
      id: g.id,
      name: g.subject,
      participantCount: g.participants?.length || 0
    }))

    res.json(groups)
  } catch (err) {
    res.status(500).json({ error: err.message })
  }
})

module.exports = router
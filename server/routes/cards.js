const express = require('express')
const router = express.Router()
const { getCards } = require('../services/db')
const { getConnectedUser } = require('../services/whatsapp')

router.get('/:groupId', async (req, res) => {
  try {
    const user = getConnectedUser()
    const userPhone = user?.id?.split(':')[0] || 'default'
    const cards = await getCards(req.params.groupId, userPhone)
    res.json(cards)
  } catch (err) {
    res.status(500).json({ error: err.message })
  }
})

module.exports = router
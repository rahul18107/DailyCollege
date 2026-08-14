const express = require('express')
const router = express.Router()
const { getCards } = require('../services/db')

router.get('/:groupId', async (req, res) => {
  try {
    const cards = await getCards(req.params.groupId)
    res.json(cards)
  } catch (err) {
    res.status(500).json({ error: err.message })
  }
})

module.exports = router
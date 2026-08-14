require('dotenv').config()
const express = require('express')
const { connectToWhatsApp, loadCacheFromDisk } = require('./services/whatsapp')
const groupsRoute = require('./routes/groups')
const processRoute = require('./routes/process')
const cardsRoute = require('./routes/cards')

const app = express()
app.use(express.json())

app.use('/groups', groupsRoute)
app.use('/process', processRoute)
app.use('/cards', cardsRoute)

app.get('/status', (req, res) => {
  const { isReady } = require('./services/whatsapp')
  res.json({
    whatsapp: isReady() ? 'ready' : 'not_ready',
    server: 'online'
  })
})
// load cache once on startup
loadCacheFromDisk()

// Start WhatsApp
connectToWhatsApp()

const PORT = process.env.PORT || 3000
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`)
  console.log(`Waiting for WhatsApp session...`)
})
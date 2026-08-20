require('dotenv').config()
const express = require('express')
const { connectToWhatsApp, loadCacheFromDisk, requestCode, getCurrentPairingCode,getConnectedUser,logout } = require('./services/whatsapp')
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
    server: 'online',
    user: getConnectedUser()
  })
})

app.post('/request-code', async (req, res) => {
  const { phoneNumber } = req.body
  if (!phoneNumber) {
    return res.status(400).json({ error: 'phoneNumber is required' })
  }
  try {
    const code = await requestCode(phoneNumber)
    res.json({ success: true, code })
  } catch (e) {
    res.status(500).json({ error: e.message })
  }
})

app.get('/current-code', (req, res) => {
  const code = getCurrentPairingCode()
  if (code) {
    res.json({ code })
  } else {
    res.status(404).json({ error: 'No active pairing code' })
  }
})

// load cache once on startup
loadCacheFromDisk()

// Start WhatsApp
connectToWhatsApp()

// Logout
app.post('/logout', async (req, res) => {
  await logout()
  res.json({ success: true })
})

const PORT = process.env.PORT || 3000
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`)
  console.log(`Waiting for WhatsApp session...`)
})



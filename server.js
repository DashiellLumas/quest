const express = require('express')
const timeago = require('time-ago')
const app = express()
const survivors = require('./survivors.json')

app.use((req, res) => {
  const list = survivors.map((survivor) => {
    const ago = timeago.ago(new Date(survivor.wasHere))
    return `<li>${survivor.name} was here ${ago}</li>`
  }).join()
  res.send(`<h1>Survivors of DevOps Quest Mark I</h1><ul>${list}</ul>`)
})

app.listen(80)

console.log('Quest Server Listening...')

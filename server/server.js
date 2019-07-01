const chatkit = require('./chatkit')
const Express = require('express')

const app = new Express()

app.listen(3000, () => {
    console.log("Token providing endpoint listening at: http://localhost:3000/auth")
})

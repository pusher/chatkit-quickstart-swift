const Chatkit = require("@pusher/chatkit-server")

const chatkit = new Chatkit.default({
  instanceLocator: "YOUR_INSTANCE_LOCATOR",
  key:
    "YOUR_SECRET_KEY"
})

module.exports = chatkit
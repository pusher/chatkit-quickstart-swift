const Chatkit = require('@pusher/chatkit-server')

const chatkit = new Chatkit.default({
  instanceLocator: "v1:us1:871fd2a0-e790-473a-8c23-a03cc08a94be",
  key:
    "e5fcf01f-b329-4543-856c-81663fd19600:b/4LmgbMj4JoD1uL4eKhEJRy1KKsntn1iQM2uOjCqs0="
})

chatkit
  .createUser({
    id: "zan@pusher.com",
    name: "Zan Markan",
    avatarURL:
      "https://s.gravatar.com/avatar/b32e3c9770267e272b466bf5af9e6ffd?s=80"
  })
  .then((user) => {
    
    console.log(`User ${user.id} created successfully`)
    return chatkit.createUser({
        id: "luka@pusher.com",
        name: "Luka Bratos",
        avatarURL: "https://s.gravatar.com/avatar/04b30108eb4ee189f92e6c647c730605?s=80"
    })
  })
  .then( (user) => {

    console.log(`User ${user.id} created successfully`)
    return chatkit.createRoom({
        creatorId: "zan@pusher.com",
        isPrivate: true,
        name: "zan@pusher.com|luka@pusher.com",
        userIds: [ "zan@pusher.com", "luka@pusher.com"]
    })
  })
  .then( (room) => {
    console.log(`Room ${room.id} created successfully`)
  })
  .catch(err => {
    console.log(err)
  })





  
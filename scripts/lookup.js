const Chatkit = require("@pusher/chatkit-server")

const chatkit = new Chatkit.default({
  instanceLocator: "v1:us1:871fd2a0-e790-473a-8c23-a03cc08a94be",
  key:
    "e5fcf01f-b329-4543-856c-81663fd19600:b/4LmgbMj4JoD1uL4eKhEJRy1KKsntn1iQM2uOjCqs0="
})

async function lookup() {

    let users = await chatkit.getUsers()
    users.forEach(user => {
        console.log(user)
        
    });

    let rooms = await chatkit.getRooms({includePrivate: true})
    rooms.forEach(room => {
        console.log(room)
    })

    let status = await chatkit.getDeleteStatus({ jobId: "463" })
    console.log(status)
}



lookup()
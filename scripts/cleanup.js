const Chatkit = require("@pusher/chatkit-server")

const chatkit = new Chatkit.default({
  instanceLocator: "v1:us1:871fd2a0-e790-473a-8c23-a03cc08a94be",
  key:
    "e5fcf01f-b329-4543-856c-81663fd19600:b/4LmgbMj4JoD1uL4eKhEJRy1KKsntn1iQM2uOjCqs0="
})

function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms))
}

async function cleanUp() {

    let rooms = await chatkit.getRooms({ includePrivate: true })
    
    for (let i = 0; i < rooms.length; i++) {
        let deletion = await chatkit.asyncDeleteRoom({ roomId: rooms[i].id})
        console.log(`Deleting room job:`)
        console.log(deletion)
    }


    let users = await chatkit.getUsers()
    for(let i = 0; i < users.length; i++){

        let deletion = await chatkit.asyncDeleteUser({userId: users[i].id})
        console.log(`Deleting user job:`)
        console.log(deletion)
    }      
}

cleanUp();


// chatkit.getRooms({includePrivate: true})
//     .then(rooms => {



//         rooms.forEach(room => {
//             chatkit.asyncDeleteRoom(room.id)
//             console.log(`Deleted room: ${room.id}`)
//         });
//     })
//     .then(() => {
//         return chatkit.getUsers()
        
//     })
//     .then(users => {
//         users.forEach(user => {
//             chatkit.asyncDeleteUser({userId: user.id})
//             console.log(`Deleted user ${user.id}`)
//         })

//     }).catch( error => {
//         console.log(error)
//     })
    
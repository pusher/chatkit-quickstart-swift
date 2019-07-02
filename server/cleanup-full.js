const chatkit = require('./chatkit')

async function cleanUp() {

     let rooms = await chatkit.getRooms({ includePrivate: true })
     for (let i = 0; i < rooms.length; i++) {
       console.log(`Deleting room with id: ${rooms[i].id}`)
       await chatkit.deleteRoom({
         roomId: rooms[i].id
       })
     }

    let users = await chatkit.getUsers()
    for(let i = 0; i < users.length; i++){
        await chatkit.deleteUser({userId: users[i].id})
        console.log(`Deleted user ${users[i].id}`)
    }      
}

cleanUp();

    
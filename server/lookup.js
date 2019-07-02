const chatkit = require('./chatkit')

async function lookup() {

    console.log("Users:")

    let users = await chatkit.getUsers()
    users.forEach(user => {
        console.log(user.id)
    });

    console.log("Rooms:")

    let rooms = await chatkit.getRooms({includePrivate: true})
    rooms.forEach(room => {
        console.log(`Room Name: ${room.name} ID: ${room.id}`)
    })
}



lookup()
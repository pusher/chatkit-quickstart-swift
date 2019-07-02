const chatkit = require("./chatkit")

async function cleanUp() {
  let users = await chatkit.getUsers()

  for (let i = 0; i < users.length; i++) {
    console.log(`Deleting user: ${users[i].id}`)
    let deletion = await chatkit.asyncDeleteUser({ userId: users[i].id })
    console.log(`Deletion: ${deletion.id}`)

    while (true) {
      let status = await chatkit.getDeleteStatus({ jobId: deletion.id })
      console.log(status.status)
      if (status.status !== "in_progress") break
    }
  }

  let rooms = await chatkit.getRooms({ includePrivate: true })

  for (let i = 0; i < rooms.length; i++) {
    console.log(`Deleting room with id: ${rooms[i].id}`)
    let deletion = await chatkit.asyncDeleteRoom({ roomId: rooms[i].id })
    console.log(`Deletion: ${deletion.id}`)

    while (true) {
      let status = await chatkit.getDeleteStatus({
        jobId: deletion.id
      })
      console.log(status.status)
      if (status.status !== "in_progress") break
    }
  }
}

cleanUp()

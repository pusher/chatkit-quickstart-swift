const chatkit = require('./chatkit')

async function create() {
    //Creating users

    const usersToCreate = [
        {
            id: "alice",
            name: "Alice A"
        },
        {
            id: "bob",
            name: "Bob B"
        }
    ]
    let users = await chatkit.createUsers({
        users: usersToCreate
    })
    console.log("Created users:")
    users.forEach(user => {
        console.log(user.id)
    })

    //Creating a room with 2 members
    let room = await chatkit.createRoom({
        id: 'alice;bob',
        creatorId: 'alice',
        isPrivate: true,
        name: 'Alice A, Bob B',
        userIds: ['alice', 'bob']
    })

    console.log(`Created room: ${room.id}`)

    //Seeding a conversation...
    await chatkit.sendSimpleMessage({
        roomId: room.id,
        userId: 'bob',
        text: 'How much wood could a woodchuck chuck if a woodchuck could chuck wood?',
    })

    await chatkit.sendSimpleMessage({
      roomId: room.id,
      userId: "alice",
      text:
        "A woodchuck would chuck no amount of wood since a woodchuck can’t chuck wood."
    })

    await chatkit.sendSimpleMessage({
      roomId: room.id,
      userId: "bob",
      text:
        "But if a woodchuck could chuck and would chuck some amount of wood, what amount of wood would a woodchuck chuck?"
    })

    await chatkit.sendSimpleMessage({
      roomId: room.id,
      userId: "alice",
      text:
        "Even if a woodchuck could chuck wood and even if a woodchuck would chuck wood, should a woodchuck chuck wood?"
    })

    await chatkit.sendSimpleMessage({
      roomId: room.id,
      userId: "bob",
      text:
        "A woodchuck should chuck if a woodchuck could chuck wood, as long as a woodchuck would chuck wood."
    })

    await chatkit.sendSimpleMessage({
      roomId: room.id,
      userId: "alice",
      text: "Oh shut up."
    })

    console.log("Seeded the room with messages")
}

create()


  
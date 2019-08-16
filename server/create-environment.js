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
    /**
      Conversation sourced from Monty Python
      http://montypython.50webs.com/scripts/Holy_Grail/Scene22.htm
    **/
    await chatkit.sendSimpleMessage({
        roomId: room.id,
        userId: 'bob',
        text: 'What is your quest?',
    })

    await chatkit.sendSimpleMessage({
      roomId: room.id,
      userId: "alice",
      text:
        "To seek the Holy Grail!"
    })

    await chatkit.sendSimpleMessage({
      roomId: room.id,
      userId: "bob",
      text:
        "What... is the air-speed velocity of an unladen swallow?"
    })

    await chatkit.sendSimpleMessage({
      roomId: room.id,
      userId: "alice",
      text:
        "What do you mean? An African or European swallow?"
    })

    await chatkit.sendSimpleMessage({
      roomId: room.id,
      userId: "bob",
      text:
        "Huh? I-- I don't know that. Auuuuuuuugh!"
    })

    await chatkit.sendSimpleMessage({
      roomId: room.id,
      userId: "bob",
      text:
        "How do know so much about swallows?"
    })

    await chatkit.sendSimpleMessage({
      roomId: room.id,
      userId: "alice",
      text: "Well, you have to know these things when you're a king, you know!"
    })

    console.log("Seeded the room with messages")
}

create()

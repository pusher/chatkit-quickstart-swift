const chatkit = require("./chatkit")
const uuidv4 = require("uuid/v4")


let userId = uuidv4()
console.log(userId)

async function runScript(userId){

    let user = await chatkit.createUser({
        id: userId,
        name: 'test_user'
    })

    console.log("User Created:")
    console.log(user)

    let deletionRequest = await chatkit.asyncDeleteUser({
        userId: userId
    })

    console.log("Deleting user")
    console.log(deletionRequest)

    while(true){

        try { 

       
        let deletionStatus = await chatkit.getDeleteStatus("asd" )
        console.log("deletion status")
        console.log(deletionStatus)
        
        if(deletionStatus.status !== 'in_progress' ) {
            console.log("Deleted.")
            break
        }

         } catch(e) {
             console.log(e)
         }
    }

    let users = await chatkit.getUsers()
    users.forEach(user => {
        console.log(user)
    });
}

runScript('foo@ilikepopcorn.com')

import UIKit

// Import the Chatkit SDK
import PusherChatkit

// For this example, you are adding all the Chatkit code to this View Controller.
// In practice you might split the Chatkit logic across different files.
class ChatroomViewController: UIViewController {
    
    @IBOutlet weak var messagesTableView: UITableView!
    @IBOutlet weak var textEntry: UITextField!
    
    // Internal delegate class that listens to Chatkit connection-level events. Passed when initializing Chatkit.
    // Implement it's methods to listen to different events
    // https://pusher.com/docs/chatkit/reference/swift#pcchatmanagerdelegate
    class MyChatManagerDelegate: PCChatManagerDelegate {
        func onError(error: Error) {
            print("Error in Chat manager delegate! \(error.localizedDescription)")
        }
    }
    
    // Chatkit properties
    public var chatManager: ChatManager?
    public var currentUser: PCCurrentUser?
    var messages = [PCMultipartMessage]()
    
    
    // All initialization happens in this method
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Read the Chatkit instance details from Chatkit.plist
        guard let chatkitInfo = plistValues(bundle: Bundle.main) else { return }
        
        messagesTableView.delegate = self
        messagesTableView.dataSource = self
        
        // Instantiate Chatkit with instance ID, token provider endpoint, and ID of the user you're connecting as.
        // Initialization: https://pusher.com/docs/chatkit/reference/swift#initialization
        // Authenticating users and and providing tokens: https://pusher.com/docs/chatkit/reference/swift#pctokenprovider
        self.chatManager = ChatManager(
            instanceLocator: chatkitInfo.instanceLocator, //Your Chatkit Instance ID
            tokenProvider: PCTokenProvider(url: chatkitInfo.tokenProviderEndpoint), //Token provider endpoint
            userID: chatkitInfo.userId
        )
        
        // Connect to Chatkit by passing in the ChatManagerDelegate you defined at the top of this class.
        // https://pusher.com/docs/chatkit/reference/swift#connecting
        chatManager!.connect(delegate: MyChatManagerDelegate()) { (currentUser, error) in
            guard(error == nil) else {
                print("Error connecting: \(error!.localizedDescription)")
                return
            }
            
            // PCCurrentUser is the main entity you interact with in the Chatkit Swfit SDK
            // You get it in a callback when successfully connected to Chatkit
            // https://pusher.com/docs/chatkit/reference/swift#pccurrentuser
            
            self.currentUser = currentUser
            
            // Subscribe to the first room for the current user
            // RoomDelegate with event listeners is implemented below as an extension to this class
            // https://pusher.com/docs/chatkit/reference/swift#subscribing-to-a-room
            
            let firstRoom = currentUser!.rooms.first!
            currentUser!.subscribeToRoomMultipart(room: firstRoom, roomDelegate: self, completionHandler: { (error) in
                guard error == nil else {
                    print("Error subscribing to room: \(error!.localizedDescription)")
                    return
                }
                print("Successfully subscribed to the room! 👋")
            })
        }
    }
    
    @IBAction func onSendClicked(_ sender: Any) {
        let messageToSend = textEntry.text!
        if !messageToSend.isEmpty {
            sendMessage(messageToSend)
        }
    }
    
    //Send a message to Chatkit
    func sendMessage(_ message: String) {
        
        // SendSimpleMessage assumes a message with a single inline text part
        // Send it to the first room of this user
        // https://pusher.com/docs/chatkit/reference/swift#sending-a-message
        currentUser!.sendSimpleMessage(
            roomID: currentUser!.rooms.first!.id,
            text: message,
            completionHandler: { (messageID, error) in
                guard error == nil else {
                    print("Error sending message: \(error!.localizedDescription)")
                    return
                }
                DispatchQueue.main.async {
                    self.textEntry.text = ""
                }
        }
        )
    }
}


// Extension to handle incoming message - PCRoomDelegate
// https://pusher.com/docs/chatkit/reference/swift#receiving-new-messages
extension ChatroomViewController: PCRoomDelegate {
    func onMultipartMessage(_ message: PCMultipartMessage) {
        print("Message received!")
        
        // Messages are received on a background thread, so you need to use the main thread to display them
        DispatchQueue.main.async {
            self.messages.append(message)
            self.messagesTableView.reloadData()
            // scroll to last message
            self.messagesTableView.scrollToRow(at: IndexPath(row: (self.messages.count - 1), section: 0), at: .bottom, animated: true)
        }
    }
}


extension ChatroomViewController: UITableViewDelegate {}

// Render messages in the UITableView
extension ChatroomViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        // UITableView has as many rows as there are messages in the messages array
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Get a message and fill its details into a cell
        let message = messages[indexPath.row]
        let sender = message.sender
        
        // Handle a simple message payload that is inline-only
        var messageText = ""
        switch message.parts.first!.payload {
        case .inline(let payload):
            messageText = payload.content
        default:
            print("Message doesn't have the right payload!")
        }
        
        if (sender.id != currentUser!.id) {
            // display message is from the other person
            let cell = tableView.dequeueReusableCell(withIdentifier: "OthersMessageTableViewCell", for: indexPath) as! OthersMessageTableViewCell
            cell.lblName.text = sender.displayName
            cell.lblMessage.text = messageText
            
            if(sender.avatarURL != nil){
                cell.setImage(ImageURL: sender.avatarURL!)
            }
            
            return cell
        } else {
            // display message is from the other me
            let cell = tableView.dequeueReusableCell(withIdentifier: "SenderMessageTableViewCell", for: indexPath) as! SenderMessageTableViewCell
            cell.lblName.text = sender.displayName
            cell.lblMessage.text = messageText
            
            if(sender.avatarURL != nil){
                cell.setImage(ImageURL: sender.avatarURL!)
            }
            
            return cell
        }
        
        
    }
}

//Chatkit.plist values parser
//Taken from Auth0's excellent samples - https://github.com/auth0-samples/auth0-ios-swift-sample/blob/master/00-Login/Auth0Sample/HomeViewController.swift#L75
func plistValues(bundle: Bundle) -> (
    instanceLocator: String,
    tokenProviderEndpoint: String,
    userId: String,
    roomId: String)? {
        guard
            let path = bundle.path(forResource: "Chatkit", ofType: "plist"),
            let values = NSDictionary(contentsOfFile: path) as? [String: Any]
            else {
                print("Missing Chatkit.plist file with 'ChatkitInstanceLocator', 'ChatkitTokenProviderEndpoint', 'ChatkitUserId', and 'ChatkitRoomId' entries in main bundle!")
                return nil
        }
        
        guard
            let instanceLocator = values["ChatkitInstanceLocator"] as? String,
            let tokenProviderEndpoint = values["ChatkitTokenProviderEndpoint"] as? String,
            let userId = values["ChatkitUserId"] as? String,
            let roomId = values["ChatkitRoomId"] as? String
            else {
                print("Chatkit.plist file at \(path) is missing 'ChatkitInstanceLocator', 'ChatkitTokenProviderEndpoint', 'ChatkitUserId', and/or 'ChatkitRoomId' entries!")
                print("File currently has the following entries: \(values)")
                return nil
        }
        return (instanceLocator: instanceLocator, tokenProviderEndpoint: tokenProviderEndpoint, userId: userId, roomId: roomId)
}

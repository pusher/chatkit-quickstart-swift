import UIKit
// Import Chatkit dependency
import PusherChatkit

class ChatroomViewController: UIViewController {
    
    @IBOutlet weak var messagesTableView: UITableView!
    @IBOutlet weak var textEntry: UITextField!
    
    // Class params and inner classes
    class MyChatManagerDelegate: PCChatManagerDelegate {
        func onError(error: Error) {
            print("Error in Chat manager delegate! \(error.localizedDescription)")
        }
    }
    
    public var chatManager: ChatManager?
    public var currentUser: PCCurrentUser?
    var messages = [PCMultipartMessage]()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let chatkitInfo = plistValues(bundle: Bundle.main) else { return }
        
        messagesTableView.delegate = self
        messagesTableView.dataSource = self
        
        // Init Chatkit
        self.chatManager = ChatManager(
            instanceLocator: chatkitInfo.instanceLocator,
            tokenProvider: PCTokenProvider(url: chatkitInfo.tokenProviderEndpoint),
            userID: chatkitInfo.userId
        )
        
        // Connect to Chatkit
        chatManager!.connect(delegate: MyChatManagerDelegate()) { (currentUser, error) in
            guard(error == nil) else {
                print("Error connecting: \(error!.localizedDescription)")
                return
            }
            self.currentUser = currentUser
            
            // Subscribe to the first room
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
    
    //Send a message
    func sendMessage(_ message: String) {
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


//Handle incoming message
extension ChatroomViewController: PCRoomDelegate {
    func onMultipartMessage(_ message: PCMultipartMessage) {
        print("Message received!")
        DispatchQueue.main.async {
            self.messages.append(message)
            self.messagesTableView.reloadData()
            
            // scroll to last message
            self.messagesTableView.scrollToRow(at: IndexPath(row: (self.messages.count - 1), section: 0), at: .bottom, animated: true)
        }
    }
}


extension ChatroomViewController: UITableViewDelegate {}

// Render messages
extension ChatroomViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let message = messages[indexPath.row]
        let sender = message.sender
        
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

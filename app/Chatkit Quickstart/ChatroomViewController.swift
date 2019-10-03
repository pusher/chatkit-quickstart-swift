import UIKit
//TODO - import PusherChatkit
import PusherChatkit

class ChatroomViewController: UIViewController {
    
    
    @IBOutlet weak var messagesTableView: UITableView!
    @IBOutlet weak var textEntry: UITextField!
    @IBAction func onSendClicked(_ sender: Any) {
        let messageToSend = textEntry.text!
        if !messageToSend.isEmpty {
          sendMessage(messageToSend)
        }
    }
    
    class MyChatManagerDelegate: PCChatManagerDelegate {
        func onError(error: Error) {
            print("Error in Chat manager delegate! \(error.localizedDescription)")
        }
    }
    
    var userId: String = "alice"
    var roomId: String = "alice&bob"
    public var chatManager: ChatManager?
    public var currentUser: PCCurrentUser?
    
    //TODO create messages array
    var messages = [PCMultipartMessage]()

    func initChatkit(_ userId: String, _ callback: @escaping (_ currentUser: PCCurrentUser) -> Void){
        self.chatManager = ChatManager(
            instanceLocator: "v1:us1:d38e1721-2363-44f7-b9d3-743fcff90930",
            tokenProvider: PCTokenProvider(url: "https://us1.pusherplatform.io/services/chatkit_token_provider/v1/d38e1721-2363-44f7-b9d3-743fcff90930/token"),
            userID: userId
        )
        chatManager!.connect(delegate: MyChatManagerDelegate()) { (currentUser, error) in
            guard(error == nil) else {
                print("Error connecting: \(error!.localizedDescription)")
                return
            }
            self.currentUser = currentUser
            callback(currentUser!)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        messagesTableView.delegate = self
        messagesTableView.dataSource = self
        //TODO: Initiate Chatkit with your user ID
        initChatkit(self.userId) { (currentUser) in
            let firstRoom = currentUser.rooms.first!
            // Subscribe to the first room
            currentUser.subscribeToRoomMultipart(room: firstRoom, roomDelegate: self, completionHandler: { (error) in
                guard error == nil else {
                    print("Error subscribing to room: \(error!.localizedDescription)")
                    return
                }
                print("Successfully subscribed to the room!")
            })
            
        }
    }
    
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

//TODO create PCRoomDelegate extension
extension ChatroomViewController: PCRoomDelegate {
    func onMultipartMessage(_ message: PCMultipartMessage) {
        print("Message received!")
        DispatchQueue.main.async {
            self.messages.append(message)
            self.messagesTableView.reloadData()
        }
    }
}


extension ChatroomViewController: UITableViewDelegate {}

extension ChatroomViewController: UITableViewDataSource {
    //TODO: empty implementation - replace with your own
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MessageCell", for: indexPath)
        let message = messages[indexPath.row]
        let senderDisplayName = message.sender.displayName
        var messageText = ""
        
        switch message.parts.first!.payload {
        case .inline(let payload):
            messageText = payload.content
        default:
            print("Message doesn't have the right payload!")
        }
        
        cell.textLabel?.text = "\(senderDisplayName): \(messageText)"
        return cell
    }
}

func plistValues(bundle: Bundle) -> (clientId: String, domain: String)? {
    guard
        let path = bundle.path(forResource: "Chatkit", ofType: "plist"),
        let values = NSDictionary(contentsOfFile: path) as? [String: Any]
        else {
            print("Missing Chatkit.plist file with 'ClientId' and 'Domain' entries in main bundle! TODO reword")
            return nil
    }
    
    guard
        let clientId = values["ClientId"] as? String,
        let domain = values["Domain"] as? String
        else {
            print("Auth0.plist file at \(path) is missing 'ClientId' and/or 'Domain' entries!")
            print("File currently has the following entries: \(values)")
            return nil
    }
    return (clientId: clientId, domain: domain)
}

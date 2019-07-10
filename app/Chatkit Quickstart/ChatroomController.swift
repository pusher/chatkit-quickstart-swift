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
    
    var appDelegate: AppDelegate!

    var userId: String?
    
    //TODO create messages array
    var messages = [PCMultipartMessage]()


    override func viewDidLoad() {
        super.viewDidLoad()

        appDelegate = (UIApplication.shared.delegate as! AppDelegate)
        messagesTableView.delegate = self
        messagesTableView.dataSource = self
        //TODO: Initiate Chatkit with your user ID
        appDelegate.initChatkit(self.userId!) { (currentUser) in
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
        appDelegate.currentUser!.sendSimpleMessage(
            roomID: appDelegate.currentUser!.rooms.first!.id,
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


import UIKit
import PusherChatkit

// In this single-screen app example, all Chatkit initialization is done in this ViewController.
// In a more complex application, the SDK might be initialized elsewhere and passed to different
// ViewControllers as the user navigates between screens.
class ChatroomViewController: UIViewController {
    
    // The table in which messages are rendered
    @IBOutlet weak var messagesTableView: UITableView!
    
    // The field in which users can compose messages
    @IBOutlet weak var textEntry: UITextField!
    
    // The button used to submit a message
    @IBOutlet weak var sendButton: UIButton!
    // A spinner, shown in place of the send button while a message is being sent
    @IBOutlet weak var sendingIndicator: UIActivityIndicatorView!
    
    // The constraint from which the bottom of all components are measured,
    // so that we can adjust as the keyboard appears and disappears
    @IBOutlet weak var bottomOfView: NSLayoutConstraint!
    
    // Chatkit properties
    private var chatManager: ChatManager?
    private var currentUser: PCCurrentUser?
    
    private var dataModel: MessagesDataModel?
    private var viewModel: MessagesViewModel?

    // Internal delegate class that listens to Chatkit connection-level events. Passed when initializing Chatkit.
    // Implement more methods from the protocol to listen to more types of event.
    // https://pusher.com/docs/chatkit/reference/swift#pcchatmanagerdelegate
    class MyChatManagerDelegate: PCChatManagerDelegate {
        func onError(error: Error) {
            print("Error in Chat manager delegate! \(error.localizedDescription)")
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Load Chatkit instance details from the plist file
        guard let chatkitInfo = plistValues(bundle: Bundle.main) else {
            return
        }
        
        // We want to adjust out layout when the keyboard shows or hides
        registerForKeyboardNotifications()
        
        // We want to trigger a send message action when the user hits "return"
        textEntry.delegate = self
        
        viewModel = MessagesViewModel()
        viewModel?.delegate = self
        
        messagesTableView.delegate = self
        messagesTableView.dataSource = viewModel
        messagesTableView.allowsSelection = true
        
        // Instantiate Chatkit with instance ID, token provider endpoint, and ID of the user you will connect as.
        // Initialization: https://pusher.com/docs/chatkit/reference/swift#initialization
        // Authenticating users and and providing tokens: https://pusher.com/docs/chatkit/reference/swift#pctokenprovider
        chatManager = ChatManager(
            instanceLocator: chatkitInfo.instanceLocator,
            tokenProvider: PCTokenProvider(url: chatkitInfo.tokenProviderEndpoint),
            userID: chatkitInfo.userId
        )
        
        // Connect to Chatkit by passing in the ChatManagerDelegate defined at the top of this class.
        // https://pusher.com/docs/chatkit/reference/swift#connecting
        chatManager!.connect(delegate: MyChatManagerDelegate()) { (currentUser, error) in
            guard(error == nil) else {
                print("Error connecting: \(error!.localizedDescription)")
                return
            }
            
            DispatchQueue.main.async {
                // PCCurrentUser is the main entity you interact with from the Chatkit SDK
                // You get it in a callback when successfully connected to Chatkit
                // https://pusher.com/docs/chatkit/reference/swift#pccurrentuser
                self.currentUser = currentUser

                // We know our user to be in exactly one room, so get it
                let firstRoom = currentUser!.rooms.first!

                self.dataModel = MessagesDataModel(currentUserId: currentUser!.id,
                                                   currentUserName: currentUser!.name,
                                                   currentUserAvatarUrl: currentUser?.avatarURL)
                self.dataModel?.delegate = self.viewModel

                // Subscribe to the first room for the current user.
                // A RoomDelegate is passed to be notified of events occurring in the room.
                // This controller is a RoomDelegate, the implementation is in an extension below.
                // https://pusher.com/docs/chatkit/reference/swift#subscribing-to-a-room
                currentUser!.subscribeToRoomMultipart(room: firstRoom, 
                                                      roomDelegate: self, 
                                                      completionHandler: { (error) in
                    guard error == nil else {
                        print("Error subscribing to room: \(error!.localizedDescription)")
                        return
                    }
                    print("Successfully subscribed to the room! 👋")
                })
            }
        }
    }
    
    @IBAction func onSendClicked(_ sender: Any) {
        sendFromTextEntry()
    }
    
    func sendFromTextEntry() {
        guard let text = textEntry.text else {
            return
        }
        if (text.isEmpty) {
            return
        }
        
        let message = MessageMapper().textToMessage(text)
        self.textEntry.text = nil
        
        sendMessage(message: message)
    }
    
    func sendMessage(message: LocalMessage) {
        dataModel?.addPendingMessage(message)
        
        currentUser!.sendMultipartMessage(
            roomID: currentUser!.rooms.first!.id,
            parts: message.parts,
            completionHandler: { (messageID, error) in
                // The callback comes from another queue, so we must update our UI back on the
                // main queue
                DispatchQueue.main.async {
                    if (error != nil) {
                        print("Error sending message: \(error!.localizedDescription)")
                        self.dataModel?.pendingMessageFailed(message)
                    } else {
                        self.dataModel?.pendingMessageSent(message)
                    }
                }
            }
        )
    }
    
    // MARK: - Handle keyboard show/hide
    
    func registerForKeyboardNotifications() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillShow(_:)),
                                               name: UIResponder.keyboardWillShowNotification,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillHide(_:)),
                                               name: UIResponder.keyboardWillHideNotification,
                                               object: nil)
    }
    
    @objc
    func keyboardWillShow(_ notification: Notification) {
        guard let keyboardHeight =
            (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.height else {
                return
        }
        self.bottomOfView.constant = keyboardHeight + 15
    }

    @objc
    func keyboardWillHide(_ notification: Notification) {
        self.bottomOfView.constant = 30
    }
}

// MARK: - Incoming message handling delegates

// Implementing the PCRoomDelegate protocol allows us to receive notification of events occuring
// in a room we are subscribed to.
// https://pusher.com/docs/chatkit/reference/swift#receiving-new-messages
extension ChatroomViewController: PCRoomDelegate {
    func onMultipartMessage(_ message: PCMultipartMessage) {
        print("Message received!")
        // Events may be received from background queues, so we must dispatch out UI updates
        // to the main queue
        DispatchQueue.main.async {
            self.dataModel?.addMessageFromServer(message)
        }
    }
}

extension MessagesViewModel: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print("Number of rows requested")
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Get a message and fill its details into a cell
        let message = items[indexPath.row]
        let cell: MessageTableViewCell
        switch (message.viewType) {
        case .pending:
            let senderCell = tableView.dequeueReusableCell(withIdentifier: "SenderMessageTableViewCell",
                                                           for: indexPath) as! SenderMessageTableViewCell
            
            senderCell.setBg(color: UIColor.lightGray)
            cell = senderCell
        case .failed:
            let senderCell = tableView.dequeueReusableCell(withIdentifier: "SenderMessageTableViewCell",
                                                           for: indexPath) as! SenderMessageTableViewCell
            
            senderCell.setBg(color: UIColor.systemPink)
            cell = senderCell
        case .fromMe:
            let senderCell = tableView.dequeueReusableCell(withIdentifier: "SenderMessageTableViewCell",
                                                           for: indexPath) as! SenderMessageTableViewCell
            
            senderCell.setBg(color: UIColor(red: 0.19, green: 0.05, blue: 0.31, alpha: 1.0))
            cell = senderCell
        case .fromOther: 
            cell = tableView.dequeueReusableCell(withIdentifier: "OthersMessageTableViewCell",
                                                 for: indexPath) as! OthersMessageTableViewCell
        }
        
        cell.configure(senderName: message.senderName, text: message.text)
        
        if (message.senderAvatarUrl != nil) {
            cell.setImage(ImageURL: message.senderAvatarUrl!)
        }
        
        return cell
    }
}

extension ChatroomViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        print("didSelectRowAt: \(indexPath.row)")
        let item = self.dataModel?.itemAt(index: indexPath.row)
        if case .local(let message, .failed) = item {
            sendMessage(message: message)
        }
        
        // Don't actually select the row
        return nil
    }
}

protocol MessageTableViewCell: UITableViewCell {
    func configure(senderName: String, text: String)
    func setImage(ImageURL: String)
}

// MARK: - TextField delegate (send on enter keypress)

extension ChatroomViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.sendFromTextEntry()
        return false
    }
}

extension MessagesViewModel: MessagesDataModelDelegate {
    func didChange(model: MessagesDataModel.MessagesModel, changeType: ChangeType) {
        print("Data model updated")
        self.update(model: model, change: changeType)
    }
}

extension ChatroomViewController: MessagesViewModelDelegate {
    func didUpdate(model: [MessagesViewModel.MessageView], change: ChangeType) {
        print("View model updated")
        self.messagesTableView.reloadData()
        if case let .itemAdded(index) = change {
            self.messagesTableView.scrollToRow(at: IndexPath(row: index, section: 0), at: .bottom, animated: true)
        }
    }
}

// MARK: - Property list parsing

// Taken from Auth0's excellent samples - https://github.com/auth0-samples/auth0-ios-swift-sample/blob/master/00-Login/Auth0Sample/HomeViewController.swift#L75
func plistValues(bundle: Bundle) -> (
    instanceLocator: String,
    tokenProviderEndpoint: String,
    userId: String,
    roomId: String)?
{
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

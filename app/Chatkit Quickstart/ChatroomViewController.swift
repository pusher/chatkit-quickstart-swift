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
    
    private var store: MessagesStore?
    private var viewModel: MessagesViewModel?

    // Internal delegate class that listens to Chatkit connection-level events. Passed when initializing Chatkit.
    // Implement more methods from the protocol to listen to more types of event.
    // https://pusher.com/docs/chatkit/reference/swift#pcchatmanagerdelegate
    class ChatManagerDelegate: PCChatManagerDelegate {
        func onError(error: Error) {
            print("Error in Chat manager delegate! \(error.localizedDescription)")
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        // We want to adjust out layout when the keyboard shows or hides
        registerForKeyboardNotifications()
        
        // We want to trigger a send message action when the user hits "return"
        textEntry.delegate = self
        
        viewModel = MessagesViewModel()
        viewModel?.delegate = self
        
        messagesTableView.delegate = self
        messagesTableView.dataSource = viewModel
        messagesTableView.allowsSelection = true
        
        // Load Chatkit instance details from the plist file
        let chatkitInfo = plistValues(bundle: Bundle.main)
        
        // Instantiate Chatkit with instance ID, token provider endpoint, and ID of the user you will connect as.
        // Initialization: https://pusher.com/docs/chatkit/reference/swift#initialization
        // Authenticating users and and providing tokens: https://pusher.com/docs/chatkit/reference/swift#pctokenprovider
        let chatManager = ChatManager(
            instanceLocator: chatkitInfo.instanceLocator,
            tokenProvider: PCTokenProvider(url: chatkitInfo.tokenProviderEndpoint),
            userID: chatkitInfo.userId
        )
        self.chatManager = chatManager
        
        // Connect to Chatkit by passing in the ChatManagerDelegate defined at the top of this class.
        // https://pusher.com/docs/chatkit/reference/swift#connecting
        chatManager.connect(delegate: ChatManagerDelegate()) { (currentUser, error) in
            guard error == nil else {
                print("Error connecting: \(error!.localizedDescription)")
                return
            }
            guard let currentUser = currentUser else {
                print("currentUser was nil")
                return
            }

            // We know our user to be in exactly one room, so get it
            guard let firstRoom = currentUser.rooms.first else {
                print("currentUser was not in any rooms")
                return
            }
        
            DispatchQueue.main.async {
                
                // PCCurrentUser is the main entity you interact with from the Chatkit SDK
                // You get it in a callback when successfully connected to Chatkit
                // https://pusher.com/docs/chatkit/reference/swift#pccurrentuser
                self.currentUser = currentUser

            self.store = MessagesStore(currentUserId: currentUser.id,
                                       currentUserName: currentUser.name,
                                       currentUserAvatarUrl: currentUser.avatarURL)
            self.store?.delegate = self.viewModel

                // Subscribe to the first room for the current user.
                // A RoomDelegate is passed to be notified of events occurring in the room.
                // This controller is a RoomDelegate, the implementation is in an extension below.
                // https://pusher.com/docs/chatkit/reference/swift#subscribing-to-a-room
                currentUser.subscribeToRoomMultipart(room: firstRoom, roomDelegate: self) { (error) in
                    guard error == nil else {
                        print("Error subscribing to room: \(error!.localizedDescription)")
                        return
                    }
                    print("Successfully subscribed to the room! 👋")
                }
                
            }
        }
    }
    
    @IBAction private func onSendClicked(_ sender: Any) {
        sendFromTextEntry()
    }
    
    private func sendFromTextEntry() {
        guard let text = textEntry.text, !text.isEmpty else {
            return
        }
        
        self.textEntry.text = nil
        
        let message = LocalMessage(text: text)
        sendMessage(message: message)
    }
    
    private func sendMessage(message: LocalMessage) {
        guard let currentUser = currentUser,
            let firstRoom = currentUser.rooms.first else {
            return
        }
        
        store?.addPendingMessage(message)
        
        currentUser.sendMultipartMessage(roomID: firstRoom.id, parts: message.parts) { (_, error) in
            // The callback comes from another queue, so we must update our UI back on the
            // main queue
            DispatchQueue.main.async {
                if let error = error {
                    print("Error sending message: \(error.localizedDescription)")
                    self.store?.pendingMessageFailed(message)
                } else {
                    self.store?.pendingMessageSent(message)
                }
            }
        }
    }
    
    // MARK: - Handle keyboard show/hide
    
    private func registerForKeyboardNotifications() {
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
    private func keyboardWillShow(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
            let keyboardFrameObject = userInfo[UIResponder.keyboardFrameEndUserInfoKey],
            let keyboardFrame = keyboardFrameObject as? NSValue else {
                return
        }
        let keyboardHeight = keyboardFrame.cgRectValue.height
        self.bottomOfView.constant = keyboardHeight + 15
    }

    @objc
    private func keyboardWillHide(_ notification: Notification) {
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
            self.store?.addMessageFromServer(message)
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
        let messageViewItem = items[indexPath.row]
        
        let cellType: MessageTableViewCell.Type
        let backgroundColor: UIColor
        
        switch (messageViewItem.viewType) {
        case .pending:
            cellType = SenderMessageTableViewCell.self
            backgroundColor = .lightGray
        case .failed:
            cellType = SenderMessageTableViewCell.self
            backgroundColor = .systemPink
        case .fromMe:
            cellType = SenderMessageTableViewCell.self
            backgroundColor = cellType.defaultBackgroundColor
        case .fromOther:
            cellType = OthersMessageTableViewCell.self
            backgroundColor = cellType.defaultBackgroundColor
        }
        
        let cellIdentifier = String(describing: cellType)
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier) as! MessageTableViewCell

        cell.configure(senderName: messageViewItem.senderName,
                       senderAvatarUrl: messageViewItem.senderAvatarUrl,
                       text: messageViewItem.text,
                       backgroundColor: backgroundColor)
        return cell
    }
}

extension ChatroomViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        
        print("didSelectRowAt: \(indexPath.row)")
        
        guard let item = self.store?.item(at: indexPath.row),
            case .local(let message, .failed) = item else {
            return nil // Return nil so the row is not actually selected
        }
        
        sendMessage(message: message)
        
        return nil // Return nil so the row is not actually selected
    }
}

protocol MessageTableViewCell: UITableViewCell {
    
    static var defaultBackgroundColor: UIColor { get }
    
    func configure(senderName: String,
                   senderAvatarUrl: String?,
                   text: String,
                   backgroundColor: UIColor)
}

// MARK: - TextField delegate (send on enter keypress)

extension ChatroomViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.sendFromTextEntry()
        return false
    }
}

extension ChatroomViewController: MessagesViewModelDelegate {
    
    func messagesViewModel(_ messagesViewModel: MessagesViewModel, didUpdateItems: [MessageViewItem], addingMessageAt index: Int) {
        print("View model updated (message added at index: \(index)")
        self.messagesTableView.reloadData()
        self.messagesTableView.scrollToRow(at: IndexPath(row: index, section: 0), at: .bottom, animated: true)
    }
    
    func messagesViewModel(_ messagesViewModel: MessagesViewModel, didUpdateItems: [MessageViewItem], updatingMessageAt index: Int) {
        print("View model updated (message updated at index: \(index))")
        self.messagesTableView.reloadData()
    }

}

// MARK: - Property list parsing

// Taken from Auth0's excellent samples - https://github.com/auth0-samples/auth0-ios-swift-sample/blob/master/00-Login/Auth0Sample/HomeViewController.swift#L75
func plistValues(bundle: Bundle) -> (
    instanceLocator: String,
    tokenProviderEndpoint: String,
    userId: String,
    roomId: String)
{
    guard
        let path = bundle.path(forResource: "Chatkit", ofType: "plist"),
        let values = NSDictionary(contentsOfFile: path) as? [String: Any]
        else {
            preconditionFailure("Missing Chatkit.plist file with 'ChatkitInstanceLocator', 'ChatkitTokenProviderEndpoint', 'ChatkitUserId', and 'ChatkitRoomId' entries in main bundle!")
    }
    
    guard
        let instanceLocator = values["ChatkitInstanceLocator"] as? String,
        let tokenProviderEndpoint = values["ChatkitTokenProviderEndpoint"] as? String,
        let userId = values["ChatkitUserId"] as? String,
        let roomId = values["ChatkitRoomId"] as? String
        else {
            preconditionFailure("""
                Chatkit.plist file at \(path) is missing 'ChatkitInstanceLocator', 'ChatkitTokenProviderEndpoint', 'ChatkitUserId', and/or 'ChatkitRoomId' entries!"
                File currently has the following entries: \(values)
            """)
    }
    
    guard instanceLocator != "YOUR_INSTANCE_LOCATOR" else {
        preconditionFailure("Chatkit.plist file at \(path) needs updating with a valid 'ChatkitInstanceLocator'")
    }
    
    return (instanceLocator: instanceLocator, tokenProviderEndpoint: tokenProviderEndpoint, userId: userId, roomId: roomId)
}

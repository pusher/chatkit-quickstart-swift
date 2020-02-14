import UIKit
import PusherChatkit

// Controller for a message view, which presents a conversation between two users.
class MessagesViewController: UIViewController {
    
    // The table in which messages are rendered
    @IBOutlet weak var messagesTableView: UITableView!
    
    // The field in which users can compose messages
    @IBOutlet weak var textEntry: UITextField!
    
    // The button used to submit a message
    @IBOutlet weak var sendButton: UIButton!

    // The constraint from which the bottom of all components are measured,
    // so that we can adjust as the keyboard appears and disappears
    @IBOutlet weak var bottomOfView: NSLayoutConstraint!
    
    // Chatkit SDK main interaction handle
    internal var currentUser: PCCurrentUser?
    
    // The MessagesStore is responsible for tracking messages in the room.
    private var store: MessagesStore?
    
    // The MessagesViewModel translates the contents of the MessagesStore to the information we
    // want to render. It is the UIDataSource for the UITableView.
    private var viewModel: MessagesViewModel?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.hidesBackButton = true
        
        // The Controller which switched to this view should have prepared us with a reference to
        // the PCCurrentUser
        guard let currentUser = self.currentUser else {
            print("Error, currentUser was not set before view loaded")
            return
        }
        // Our test data puts both users in exactly one room, so we can just grab it.
        guard let firstRoom = currentUser.rooms.first else {
            print("currentUser was not in any rooms")
            return
        }
        
        // We want to adjust out layout when the keyboard shows or hides.
        registerForKeyboardNotifications()
        
        // We want to trigger a send message action when the user hits "return".
        textEntry.delegate = self
        
        // Contruct the store in which we will track messages, both those received from the backend
        // and messages which have not yet reached the backend.
        let store = MessagesStore(currentUserId: currentUser.id,
                                  currentUserName: currentUser.name,
                                  currentUserAvatarUrl: currentUser.avatarURL)
        self.store = store
        
        // Construct the view model which will map the contents of the store in to the fields we
        // wish to render in individual cells of our UITableView.
        let viewModel = MessagesViewModel()
        self.viewModel = viewModel

        // The view model should be notified on any change to the data model.
        store.delegate = self.viewModel

        // As the controller for the UITableView, this class is notified of changes to the view
        // model. On change we can instruct the UITableView to reload the data, and scroll as
        // appropriate to reveal new messages as they arrive.
        viewModel.delegate = self
        
        // The view model is the data source for the UITableView.
        messagesTableView.dataSource = viewModel
        
        // This controller implements UITableViewDelegate in order to be notified when the user
        // taps a row of the table. If the user taps a failed message, we want to retry sending it.
        messagesTableView.delegate = self
        messagesTableView.allowsSelection = true
        
        // With the Store, ViewModel and TableView constructed, we can "subscribe" to the room
        // using the Chatkit SDK. 
        // A RoomDelegate is passed to be notified of events occurring in the room.
        // This controller is a RoomDelegate, and forwards received messages to the data model.
        // https://pusher.com/docs/chatkit/reference/swift#subscribing-to-a-room
        currentUser.subscribeToRoomMultipart(room: firstRoom, roomDelegate: self) { (error) in
            guard error == nil else {
                print("Error subscribing to room: \(error!.localizedDescription)")
                return
            }
            print("Successfully subscribed to the room! 👋")
        }
    }
    
    // MARK: - Sending a message
    
    // IBAction for the send button in the interface
    @IBAction private func onSendClicked(_ sender: Any) {
        sendFromTextEntry()
    }
    
    // Take the text from the interface text entry field and send it as a message
    private func sendFromTextEntry() {
        guard let text = textEntry.text, !text.isEmpty else {
            return
        }
        
        self.textEntry.text = nil
        
        let message = LocalMessage(text: text)
        sendMessage(message: message)
    }
    
    // Given a representation of an unsent (i.e. pending, or failed) message, send it to the room
    // using the Chatkit SDK.
    private func sendMessage(message: LocalMessage) {
        
        guard let currentUser = currentUser,
            let firstRoom = currentUser.rooms.first else {
            return
        }
        
        // Update the store to record that this message is pending.
        store?.addPendingMessage(message)
        
        // Call the Chatkit SDK to have the message sent to the room.
        // https://pusher.com/docs/chatkit/reference/swift#sending-a-message
        currentUser.sendMultipartMessage(roomID: firstRoom.id, parts: message.parts) { (_, error) in
            // The callback comes from another queue, so we must update our UI back on the
            // main queue.
            DispatchQueue.main.async {
                // Update the store based on whether the send was successful or not.
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
extension MessagesViewController: PCRoomDelegate {
    
    func onMultipartMessage(_ message: PCMultipartMessage) {
        // Events may be received from background queues, so we must dispatch out UI updates
        // to the main queue
        DispatchQueue.main.async {
            // Update the store with the message from the server.
            // Messages we send are also received here, so the store knows to update an existing
            // message (might be pending or failed) if it already exists.
            self.store?.addMessageFromServer(message)
        }
    }
}

extension MessagesViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        guard let item = self.store?.item(at: indexPath.row),
            case .local(let message, .failed) = item else {
            return nil // Return nil so the row is not actually selected
        }
        
        sendMessage(message: message)
        
        return nil // Return nil so the row is not actually selected
    }
}

extension MessagesViewController: MessagesViewModelDelegate {
    
    func messagesViewModel(_ messagesViewModel: MessagesViewModel,
                           didUpdateItems: [MessageViewItem],
                           addingMessageAt index: Int) {
        // When the view model notifies us of a new message, notify the table view
        // and scroll to display it
        self.messagesTableView.insertRows(at: [IndexPath(row: index, section: 0)],
                                          with: .bottom)
        self.messagesTableView.scrollToRow(at: IndexPath(row: index, section: 0), 
                                           at: .bottom, 
                                           animated: false)
    }
    
    func messagesViewModel(_ messagesViewModel: MessagesViewModel,
                           didUpdateItems: [MessageViewItem],
                           updatingMessageAt index: Int) {
        // When the view model notifies us that a message has changed (e.g. from pending to sent),
        // notify the table view
        self.messagesTableView.reloadRows(at: [IndexPath(row: index, section: 0)],
                                          with: .fade)
    }

}

// MARK: - TextField delegate (send on enter keypress)

extension MessagesViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        self.sendFromTextEntry()
        return false
    }
}

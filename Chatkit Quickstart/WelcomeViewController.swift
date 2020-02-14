import Foundation
import UIKit
import PusherChatkit

// Controller for the initial page which allows you to choose which of two test users to
// connect as in the messages view.
// This Controller is responsible for initialising and connecting the Chatkit SDK, it passes an
// instance of the PCCurrentUser class to the other chat views which you can access from here.
// We recommend connecting to the SDK once in the lifetime of the app and passing the connected
// PCCurrentUser to views which require it throughout the app, as done here. 
class WelcomeViewController: UIViewController {

    // The configuration information from the Chatkit.plist file
    private let chatkitInfo = plistValues(bundle: Bundle.main)
    
    // The ChatManager is the initial entry point to the SDK. A strong reference should be
    // maintained to this object while the SDK is in use.
    private var chatManager: ChatManager?
    
    // The PCCurrentUser is the main object from the SDK that you use to interact with the service.
    private var currentUser: PCCurrentUser?

    // Internal delegate class that listens to Chatkit connection-level events.
    // Passed when initializing Chatkit.
    // Implement more methods from the protocol to listen to more types of event.
    // https://pusher.com/docs/chatkit/reference/swift#pcchatmanagerdelegate
    class ChatManagerDelegate: PCChatManagerDelegate {
        
        func onError(error: Error) {
            print("Error in Chat manager delegate! \(error.localizedDescription)")
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Instantiate Chatkit with instance ID, token provider endpoint, and ID of the user we
        // will connect as.
        // Initialization: https://pusher.com/docs/chatkit/reference/swift#initialization
        // Authenticating users and and providing tokens: 
        // https://pusher.com/docs/chatkit/reference/swift#pctokenprovider
        // This example uses the (insecure) test token provider, provided by Chatkit, which will
        // sign a token for any user who requests it. It is only suitable for private development
        // purposes.
        let chatManager = ChatManager(
            instanceLocator: chatkitInfo.instanceLocator,
            tokenProvider: PCTokenProvider(url: chatkitInfo.tokenProviderEndpoint),
            userID: chatkitInfo.userId
        )
        self.chatManager = chatManager
        
        // Connect to Chatkit, passing in the ChatManagerDelegate defined at the top of this class.
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

            // The callback comes from an internal queue, so we switch back to the main queue
            // before proceeding.
            DispatchQueue.main.async {
                // Now we are connected, we are ready to move to the messages view
                self.currentUser = currentUser
                self.performSegue(withIdentifier: "ShowMessages", sender: nil)
            }
        }
    }
    
    // We use prepare(for segue) to pass the PCCurrentUser object to the view we are switching to.
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let messagesViewController = segue.destination as? MessagesViewController else {
            return
        }
        
        messagesViewController.currentUser = self.currentUser
    }
}

// MARK: - Property list parsing

func plistValues(bundle: Bundle) -> (
    instanceLocator: String,
    tokenProviderEndpoint: String,
    userId: String,
    roomId: String) {

    guard
        let path = bundle.path(forResource: "Chatkit", ofType: "plist"),
        let values = NSDictionary(contentsOfFile: path) as? [String: Any]
        else {
            preconditionFailure("Missing Chatkit.plist file with 'ChatkitInstanceLocator', 'ChatkitTokenProviderEndpoint', 'ChatkitUserId', and 'ChatkitRoomId' entries in main bundle!")
    }
    
    guard
        let instanceLocator = values["ChatkitInstanceLocator"] as? String,
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
    
    let elements = instanceLocator.split(separator: ":")
    guard elements.count == 3 else {
        preconditionFailure("'ChatkitInstanceLocator' from Chatkit.plist file appears to be invalid")
    }
    
    let cluster = elements[1]
    let instanceId = elements[2]
    let tokenProviderEndpoint = "https://\(cluster).pusherplatform.io/services/chatkit_token_provider/v1/\(instanceId)/token"
    
    return (instanceLocator: instanceLocator, 
            tokenProviderEndpoint: tokenProviderEndpoint,
            userId: userId,
            roomId: roomId)
}

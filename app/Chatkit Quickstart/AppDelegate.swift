import UIKit
import PusherChatkit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    public var chatManager: ChatManager?
    public var currentUser: PCCurrentUser?
    
    //TODO: add initChatkit function!
    func initChatkit(_ userId: String, _ callback: @escaping (_ currentUser: PCCurrentUser) -> Void){
        self.chatManager = ChatManager(
            instanceLocator: "YOUR_INSTANCE_LOCATOR",
            tokenProvider: PCTokenProvider(url: "YOUR_TOKEN_PROVIDER_ENDPOINT"),
            userID: userId
        )
        chatManager!.connect(delegate: self) { (currentUser, error) in
            guard(error == nil) else {
                print("Error connecting: \(error!.localizedDescription)")
                return
            }
            self.currentUser = currentUser
            callback(currentUser!)
        }
    }
}

//TODO: add ChatManagerDelegate extension
extension AppDelegate: PCChatManagerDelegate {}




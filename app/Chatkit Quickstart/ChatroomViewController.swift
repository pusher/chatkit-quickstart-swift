import UIKit
//TODO - Import Chatkit dependency

class ChatroomViewController: UIViewController {
    
    @IBOutlet weak var messagesTableView: UITableView!
    @IBOutlet weak var textEntry: UITextField!
    
    //TODO - Class params and inner classes

    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let chatkitInfo = plistValues(bundle: Bundle.main) else { return }
        
        messagesTableView.delegate = self
        messagesTableView.dataSource = self
        
        //TODO - Init Chatkit
     
        //TODO - Connect to Chatkit
        
    }
    
    @IBAction func onSendClicked(_ sender: Any) {
        let messageToSend = textEntry.text!
        if !messageToSend.isEmpty {
            sendMessage(messageToSend)
        }
    }
    
    //TODO - Send a message
    func sendMessage(_ message: String) {
        
    }
    
}

//TODO - Handle incoming message

extension ChatroomViewController: UITableViewDelegate {}

//TODO - Render messages
extension ChatroomViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MessageCell", for: indexPath)
        return cell
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


//Extension for loading an image into an UIImageView from a URL string
//Inspired by tutorialspoint https://www.tutorialspoint.com/lazy-loading-of-images-in-table-view-using-swift
extension UITableViewCell {
    func setImageFromUrl(ImageURL: String, tableview: UITableView) {
        self.forceSize()

        URLSession.shared.dataTask( with: NSURL(string:ImageURL)! as URL, completionHandler: {
            (data, response, error) -> Void in
            DispatchQueue.main.async {
                if let data = data {
                    self.imageView?.image = UIImage(data: data)
                }
            }
        }).resume()
    }
    
    private func forceSize(){
        let itemSize = CGSize.init(width: 50, height: 50)
        UIGraphicsBeginImageContextWithOptions(itemSize, false, UIScreen.main.scale);
        let imageRect = CGRect.init(origin: CGPoint.zero, size: itemSize)
        self.imageView?.image!.draw(in: imageRect)
        self.imageView?.image! = UIGraphicsGetImageFromCurrentImageContext()!;
        UIGraphicsEndImageContext();
    }
}

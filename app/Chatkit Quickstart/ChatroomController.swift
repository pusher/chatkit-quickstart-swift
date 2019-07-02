import UIKit

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

    override func viewDidLoad() {
        super.viewDidLoad()

        appDelegate = (UIApplication.shared.delegate as! AppDelegate)
        messagesTableView.delegate = self
        messagesTableView.dataSource = self
        //TODO:
    }
    
    func sendMessage(_ message: String) {
    }
}

extension ChatroomViewController: UITableViewDelegate {}

extension ChatroomViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MessageCell", for: indexPath)
        return cell
    }
}


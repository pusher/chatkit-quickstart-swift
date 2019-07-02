import UIKit

class LoginViewController: UIViewController {
    
    @IBOutlet var userId: UITextField!
    @IBOutlet var loginButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if (segue.identifier == "loginWithCurrentUser") {
            print("Segue starting")
            
            let vc = segue.destination as! ChatroomViewController
            vc.userId = userId.text!
        }
    }

    
}


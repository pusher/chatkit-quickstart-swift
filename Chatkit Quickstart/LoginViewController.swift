//
//  ViewController.swift
//  Chatkit Quickstart
//
//  Created by Zan Markan on 21/06/2019.
//  Copyright © 2019 Pusher. All rights reserved.
//

import UIKit
import PusherChatkit

class LoginViewController: UIViewController {
    
    @IBOutlet var userId: UITextField!
    @IBOutlet var loginButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        // Do any additional setup after loading the view.
    }

    @IBAction func onLoginPressed(_ sender: Any) {
        
    
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if (segue.identifier == "openChatroomSegue") {
            
            print("SEGUE STARTINGGGGG")
            
            let vc = segue.destination as! ChatroomViewController
            vc.userId = userId.text!
        }
    }

    
}


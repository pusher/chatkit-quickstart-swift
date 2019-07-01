//
//  ChatroomViewController.swift
//  Chatkit Quickstart
//
//  Created by Zan Markan on 25/06/2019.
//  Copyright © 2019 Pusher. All rights reserved.
//

import Foundation
import MessageKit
import PusherChatkit

class ChatroomViewController: MessagesViewController, MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate, PCChatManagerDelegate {
    
    func currentSender() -> Sender {
        return Sender(id: "any_unique_id", displayName: "Steven")
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messages[indexPath.section]

    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messages.count
    }
    
    
    public var userId: String = ""
    let messages: [MessageType] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        
        print("SEGUE")
        print(userId)
    
        var chatManager = ChatManager(
            instanceLocator: "v1:us1:871fd2a0-e790-473a-8c23-a03cc08a94be", tokenProvider: PCTokenProvider(
                url: "https://us1.pusherplatform.io/services/chatkit_token_provider/v1/871fd2a0-e790-473a-8c23-a03cc08a94be/token"
            ), userID: userId
        )
      
        chatManager.connect(delegate: self) { currentUser, error in
            guard error == nil else {
                print("Error connecting: \(error!.localizedDescription)")
                return
            }
            
            let rooms = currentUser!.rooms
            print("Connected! \(currentUser!.name)'s rooms: \(rooms)")
        }
        
        
        
        
    }
    
//    func currentSender() -> Sender {
//        return Sender(id: "any_unique_id", displayName: "Steven")
//    }
//
//    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
//        return messages.count
//    }
//
//    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
//        return messages[indexPath.section]
//    }
    
    
    
    
}

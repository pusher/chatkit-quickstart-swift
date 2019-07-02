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

class ChatroomViewController: MessagesViewController, PCRoomDelegate {
    
    class CMDelegate: PCChatManagerDelegate {}
    class ChatkitMessage: MessageType {
        var messageId: String
        var sentDate: Date
        var kind: MessageKind
        var sender: Sender
        init(messageId: String, sentDate: Date, content: String, senderId: String, senderName: String){
            self.messageId = messageId
            self.sentDate = sentDate
            self.kind = MessageKind.text(content)
            self.sender = Sender(id: senderId, displayName: senderName)
        }
    }
    
    var messages: [MessageType] = []
    var currentUser: PCCurrentUser?
    public var userId: String = ""
    var chatManager: ChatManager!
    

    
    func addMessage(newMessage: PCMultipartMessage){
        switch newMessage.parts[0].payload {
        case .inline(let firstPayload):
            
            let chatkitMessage = ChatkitMessage(
            messageId: String(newMessage.id),
            sentDate: Date(),
            content: firstPayload.content,
            senderId: newMessage.sender.id,
            senderName: newMessage.sender.name!)
            
            messages.append(chatkitMessage)
            print("appended new message")
            print(chatkitMessage)
            
            messagesCollectionView.reloadData()
            
        default:
            print("ignoring this")
        }
    }
    
    func onMultipartMessage(_ message: PCMultipartMessage) {
        print("Message received!")
        print(message)

        addMessage(newMessage: message)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        
        chatManager = ChatManager(
            instanceLocator: "v1:us1:886ed162-c1fc-4bc6-8599-b3e969c85787",
            tokenProvider: PCTokenProvider(url: "https://us1.pusherplatform.io/services/chatkit_token_provider/v1/886ed162-c1fc-4bc6-8599-b3e969c85787/token"),
            userID: userId
        )
      
        chatManager.connect(delegate: CMDelegate()) { currentUser, error in
            guard error == nil else {
                print("Error connecting: \(error!.localizedDescription)")
                return
            }
            
            let rooms = currentUser!.rooms
            print("Connected! \(currentUser!.name)'s rooms: \(rooms)")
            
            let room = rooms.first!
            
            currentUser?.subscribeToRoomMultipart(id: room.id, roomDelegate: self, messageLimit: 20, completionHandler:
                { _ in })
            
        }
    }
    
 
}

extension ChatroomViewController: MessagesDataSource {
    func currentSender() -> Sender {
        return Sender(id: "alice@example.com", displayName: "Alice" )
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messages.count
    }
    
}

extension ChatroomViewController: MessagesLayoutDelegate {}

extension ChatroomViewController: MessagesDisplayDelegate {}

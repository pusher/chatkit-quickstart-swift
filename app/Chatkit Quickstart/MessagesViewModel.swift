//
//  MessagesViewModel.swift
//  Chatkit Quickstart
//
//  Created by Mike Pye on 31/01/2020.
//  Copyright © 2020 Pusher. All rights reserved.
//

import Foundation

protocol MessagesViewModelDelegate {
    func didUpdate(model: [MessagesViewModel.MessageView], change: ChangeType)
}

class MessagesViewModel: NSObject {
    
    enum ViewType {
        case pending
        case failed
        case fromMe
        case fromOther
    }
    
    struct MessageView {
        let senderName: String
        let senderAvatarUrl: String?
        let text: String
        let viewType: ViewType
    }
    
    private(set) var items = [MessageView]()
    
    var delegate: MessagesViewModelDelegate?
    
    func update(model: MessagesDataModel.MessagesModel, change: ChangeType) {
        let newItems = model.items.map { (item: MessagesDataModel.MessageItem) -> MessageView in 
            let senderName: String
            let senderAvatarUrl: String?
            let text: String
            let viewType: ViewType
            
            switch (item) {
            case MessagesDataModel.MessageItem.fromServer(let message):
                senderName = message.sender.name ?? "Anonymous User"
                senderAvatarUrl = message.sender.avatarURL
                text = message.text
                viewType = message.sender.id == model.currentUserId ? .fromMe : .fromOther
            
            case MessagesDataModel.MessageItem.local(let message, let state):
                senderName = model.currentUserName ?? "Anonymous User"
                senderAvatarUrl = model.currentUserAvatarUrl
                text = message.text
                switch (state) {
                case .pending: 
                    viewType = .pending
                case .failed: 
                    viewType = .failed
                case .sent: 
                    viewType = .fromMe
                }
            }
            
            return MessageView(senderName: senderName,
                               senderAvatarUrl: senderAvatarUrl,
                               text: text,
                               viewType: viewType)
        }
        
        self.items = newItems
        delegate?.didUpdate(model: newItems, change: change)
    }
}

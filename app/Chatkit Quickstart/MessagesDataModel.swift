//
//  MessagesDataModel.swift
//  Chatkit Quickstart
//
//  Created by Mike Pye on 30/01/2020.
//  Copyright © 2020 Pusher. All rights reserved.
//

import Foundation
import PusherChatkit

enum ChangeType {
    case itemAdded(index: Int)
    case itemUpdated(index: Int)
}

struct LocalMessage {
    let text: String
    let internalId: String
    
    var parts: [PCPartRequest] {
        get {
            return [
                PCPartRequest(.inline(PCPartInlineRequest(type: MIME_TYPE_TEXT, content: text))),
                PCPartRequest(.inline(PCPartInlineRequest(type: MIME_TYPE_INTERNAL_ID, content: internalId)))            
            ]
        }
    }
}

class MessagesDataModel {
    
    enum LocalMessageState {
        case pending
        case failed
        case sent
    }
    
    enum MessageItem {
        case fromServer(_ message: PCMultipartMessage)
        case local(_ message: LocalMessage, state: LocalMessageState)
        
        var internalId: String? { 
            get {
                switch (self) {
                    case .fromServer(let message):
                        return MessageMapper().messageToInternalId(message)
                    case .local(let message, _):
                        return MessageMapper().messageToInternalId(message)
                }
            }
        }
    }
    
    struct MessagesModel {
        let currentUserId: String
        let currentUserName: String?
        let currentUserAvatarUrl: String?
        let items: [MessageItem]
    }
    
    public var delegate: MessagesDataModelDelegate?
    
    private let currentUserId: String
    private let currentUserName: String?
    private let currentUserAvatarUrl: String?

    private var items: [MessageItem] = []

    public init(currentUserId: String, currentUserName: String?, currentUserAvatarUrl: String?) {
        self.currentUserId = currentUserId
        self.currentUserName = currentUserName
        self.currentUserAvatarUrl = currentUserAvatarUrl
    }
    
    public func itemAt(index: Int) -> MessageItem {
        return items[index]
    }
    
    func addMessageFromServer(_ message: PCMultipartMessage) {
        addOrUpdateItem(MessageItem.fromServer(message))
    }   

    func addPendingMessage(_ message: LocalMessage) {
        addOrUpdateItem(MessageItem.local(message, state: .pending))
    }   

    func pendingMessageSent(_ message: LocalMessage) {
        addOrUpdateItem(MessageItem.local(message, state: .sent))
    }   

    func pendingMessageFailed(_ message: LocalMessage) {
        addOrUpdateItem(MessageItem.local(message, state: .failed))
    }   

    private func addOrUpdateItem(_ item: MessageItem) {
        switch (item) {
        case .fromServer:
            // A message from the server is canonical, and will always replace a local message
            // with the same internalId
            let index = findItemIndexByInternalId(item.internalId)

            if (index == nil) {
                addItem(item)
            } else {                                                                                                                                                                    
                replaceItem(item, index: index!)
            }
        case .local:
            // We may update the state of local messages, but we should never overwrite that of
            // a FromServer message
            let index = findItemIndexByInternalId(item.internalId)

            if (index == nil) {
                addItem(item)
            } else {
                if case MessageItem.local(_, state: _) = items[index!] {
                    replaceItem(item, index: index!)
                }
            }
        }
    }
    
    private func addItem(_ item: MessageItem) {
        items.append(item)
        delegate?.didChange(model: MessagesModel(currentUserId: currentUserId,
                                                currentUserName: currentUserName, 
                                                currentUserAvatarUrl: currentUserAvatarUrl, 
                                                items: items),
                           changeType: ChangeType.itemAdded(index: items.count-1))
    }

    private func replaceItem(_ item: MessageItem, index: Int) {
        items[index] = item
        delegate?.didChange(model: MessagesModel(currentUserId: currentUserId,
                                                currentUserName: currentUserName, 
                                                currentUserAvatarUrl: currentUserAvatarUrl, 
                                                items: items),
                           changeType: ChangeType.itemUpdated(index: index))
    }

    private func findItemIndexByInternalId(_ internalId: String?) -> Int? {
        items.lastIndex { (item) in
            switch (item) {
            case .fromServer:
                return item.internalId != nil && item.internalId == internalId
            case .local:
                return item.internalId != nil && item.internalId == internalId
            }
        }
    }
}

protocol MessagesDataModelDelegate {
    func didChange(model: MessagesDataModel.MessagesModel, changeType: ChangeType)
}

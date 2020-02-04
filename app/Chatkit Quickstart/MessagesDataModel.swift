//
//  MessagesDataModel.swift
//  Chatkit Quickstart
//
//  Created by Mike Pye on 30/01/2020.
//  Copyright © 2020 Pusher. All rights reserved.
//

import Foundation
import PusherChatkit

private let MIME_TYPE_INTERNAL_ID = "com-pusher-gettingstarted/internal-id"
private let MIME_TYPE_TEXT = "text/plain"

enum ChangeType {
    case itemAdded(index: Int)
    case itemUpdated(index: Int)
}

struct LocalMessage {
    let text: String
    let internalId: String
    
    init(text: String) {
        self.text = text
        self.internalId = UUID().uuidString
    }
    
    var parts: [PCPartRequest] {
        return [
            PCPartRequest(.inline(PCPartInlineRequest(type: MIME_TYPE_TEXT, content: text))),
            PCPartRequest(.inline(PCPartInlineRequest(type: MIME_TYPE_INTERNAL_ID, content: internalId)))
        ]
    }
}

extension PCMultipartMessage {
    
    var internalId: String? {
        return part(forType: MIME_TYPE_INTERNAL_ID)
    }
    
    var text: String {
        return part(forType: MIME_TYPE_TEXT) ?? ""
    }
    
    private func part(forType type: String) -> String? {
        for part in parts {
            if case .inline(let payload) = part.payload {
                if payload.type == type {
                    return payload.content
                }
            }
        }
        return nil
    }
}

protocol MessagesDataModelDelegate {
    func didChange(model: MessagesDataModel.MessagesModel, changeType: ChangeType)
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
    }
    
    struct MessagesModel {
        let currentUserId: String
        let currentUserName: String?
        let currentUserAvatarUrl: String?
        let items: [MessageItem]
    }
    
    var delegate: MessagesDataModelDelegate?
    
    private let currentUserId: String
    private let currentUserName: String?
    private let currentUserAvatarUrl: String?

    private var items: [MessageItem] = []

    init(currentUserId: String, currentUserName: String?, currentUserAvatarUrl: String?) {
        self.currentUserId = currentUserId
        self.currentUserName = currentUserName
        self.currentUserAvatarUrl = currentUserAvatarUrl
    }
    
    func item(at index: Int) -> MessageItem? {
        return items.count > index ? items[index] : nil
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
        case let .fromServer(message):
            // A message from the server is canonical, and will always replace a local message
            // with the same internalId
            if let index = findItemIndexByInternalId(message.internalId) {
                replaceItem(item, index: index)
            } else {
                addItem(item)
            }
        case let .local(message, _):
            // We may update the state of local messages, but we should never overwrite that of
            // a FromServer message
            if let index = findItemIndexByInternalId(message.internalId) {
                if case MessageItem.local = items[index] {
                    replaceItem(item, index: index)
                }
            } else {
                addItem(item)
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
            case let .fromServer (message):
                return message.internalId != nil && message.internalId == internalId
            case let .local(message, _):
                return message.internalId == internalId
            }
        }
    }
}

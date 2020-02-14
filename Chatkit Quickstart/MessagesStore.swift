import Foundation
import PusherChatkit

private let MIME_TYPE_INTERNAL_ID = "com-pusher-gettingstarted/internal-id"
private let MIME_TYPE_TEXT = "text/plain"

struct LocalMessage {
    let internalId: String
    let text: String
    
    init(text: String) {
        self.internalId = UUID().uuidString
        self.text = text
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


enum MessageDataItem {
    
    enum LocalMessageState {
        case pending
        case failed
        case sent
    }
    
    case fromServer(_ message: PCMultipartMessage)
    case local(_ message: LocalMessage, state: LocalMessageState)
}

struct MessagesDataModel {
    let currentUserId: String
    let currentUserName: String?
    let currentUserAvatarUrl: String?
    let items: [MessageDataItem]
}

protocol MessagesStoreDelegate: NSObject {
    func messagesStore(_ messagesStore: MessagesStore, didUpdateDataModel messagesDataModel: MessagesDataModel, addingMessageAt index: Int)
    func messagesStore(_ messagesStore: MessagesStore, didUpdateDataModel messagesDataModel: MessagesDataModel, updatingMessageAt index: Int)
}

class MessagesStore {
    
    weak var delegate: MessagesStoreDelegate?
    
    private let currentUserId: String
    private let currentUserName: String?
    private let currentUserAvatarUrl: String?

    private var items: [MessageDataItem] = []

    init(currentUserId: String, currentUserName: String?, currentUserAvatarUrl: String?) {
        self.currentUserId = currentUserId
        self.currentUserName = currentUserName
        self.currentUserAvatarUrl = currentUserAvatarUrl
    }
    
    func item(at index: Int) -> MessageDataItem? {
        return items.count > index ? items[index] : nil
    }
    
    func addMessageFromServer(_ message: PCMultipartMessage) {
        addOrUpdateItem(.fromServer(message))
    }   

    func addPendingMessage(_ message: LocalMessage) {
        addOrUpdateItem(.local(message, state: .pending))
    }   

    func pendingMessageSent(_ message: LocalMessage) {
        addOrUpdateItem(.local(message, state: .sent))
    }   

    func pendingMessageFailed(_ message: LocalMessage) {
        addOrUpdateItem(.local(message, state: .failed))
    }   

    private func addOrUpdateItem(_ item: MessageDataItem) {
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
                if case MessageDataItem.local = items[index] {
                    replaceItem(item, index: index)
                }
            } else {
                addItem(item)
            }
        }
    }
    
    private func addItem(_ item: MessageDataItem) {
        items.append(item)
        
        let messagesDataModel = MessagesDataModel(currentUserId: currentUserId,
                                                  currentUserName: currentUserName,
                                                  currentUserAvatarUrl: currentUserAvatarUrl,
                                                  items: items)
        
        delegate?.messagesStore(self,
                                didUpdateDataModel: messagesDataModel,
                                addingMessageAt: items.count - 1)
    }

    private func replaceItem(_ item: MessageDataItem, index: Int) {
        items[index] = item
        
        let messagesDataModel = MessagesDataModel(currentUserId: currentUserId,
                                                  currentUserName: currentUserName,
                                                  currentUserAvatarUrl: currentUserAvatarUrl,
                                                  items: items)
        
        delegate?.messagesStore(self,
                                didUpdateDataModel: messagesDataModel,
                                updatingMessageAt: index)
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

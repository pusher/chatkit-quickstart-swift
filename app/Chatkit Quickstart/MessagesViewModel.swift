import Foundation

protocol MessagesViewModelDelegate: AnyObject {
    func messagesViewModel(_ messagesViewModel: MessagesViewModel, didUpdateItems: [MessageViewItem], updatingMessageAt index: Int)
    func messagesViewModel(_ messagesViewModel: MessagesViewModel, didUpdateItems: [MessageViewItem], addingMessageAt index: Int)
}


struct MessageViewItem {

    enum ViewType {
        case pending
        case failed
        case fromMe
        case fromOther
    }
    
    let senderName: String
    let senderAvatarUrl: String?
    let text: String
    let viewType: ViewType
}

class MessagesViewModel: NSObject {

    private(set) var items = [MessageViewItem]()

    weak var delegate: MessagesViewModelDelegate?

    private func updateMessageViewItems(withDataModel dataModel: MessagesDataModel) {

        items = dataModel.items.map { (item: MessageDataItem) -> MessageViewItem in
            let senderName: String
            let senderAvatarUrl: String?
            let text: String
            let viewType: MessageViewItem.ViewType
            
            switch (item) {
            case .fromServer(let message):
                senderName = message.sender.name ?? "Anonymous User"
                senderAvatarUrl = message.sender.avatarURL
                text = message.text
                viewType = message.sender.id == dataModel.currentUserId ? .fromMe : .fromOther
            
            case .local(let message, let state):
                senderName = dataModel.currentUserName ?? "Anonymous User"
                senderAvatarUrl = dataModel.currentUserAvatarUrl
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
            
            return MessageViewItem(senderName: senderName,
                                   senderAvatarUrl: senderAvatarUrl,
                                   text: text,
                                   viewType: viewType)
        }
    }
}

extension MessagesViewModel: MessagesStoreDelegate {
    
    func messagesStore(_ messagesStore: MessagesStore, didUpdateDataModel messagesDataModel: MessagesDataModel, addingMessageAt index: Int) {
        print("Data model updated")
        
        updateMessageViewItems(withDataModel: messagesDataModel)
        
        delegate?.messagesViewModel(self, didUpdateItems: items, addingMessageAt: index)
    }
    
    func messagesStore(_ messagesStore: MessagesStore, didUpdateDataModel messagesDataModel: MessagesDataModel, updatingMessageAt index: Int) {
        print("Data model updated")
        
        updateMessageViewItems(withDataModel: messagesDataModel)
        
        delegate?.messagesViewModel(self, didUpdateItems: items, updatingMessageAt: index)
    }
}

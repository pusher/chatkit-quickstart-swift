import Foundation

protocol MessagesViewModelDelegate {
    func messagesViewModel(_ messagesViewModel: MessagesViewModel, didUpdateModel: [MessagesViewModel.MessageView], updatingMessageAt index: Int)
    func messagesViewModel(_ messagesViewModel: MessagesViewModel, didUpdateModel: [MessagesViewModel.MessageView], addingMessageAt index: Int)
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

    private func updateItems(with model: MessagesDataModel.MessagesModel) {

        self.items = model.items.map { (item: MessagesDataModel.MessageItem) -> MessageView in
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
    }
}

extension MessagesViewModel: MessagesDataModelDelegate {
    
    func messagesDataModel(_ messagesDataModel: MessagesDataModel, didUpdateModel messagesModel: MessagesDataModel.MessagesModel, addingMessageAt index: Int) {
        print("Data model updated")
        
        updateItems(with: messagesModel)
        
        delegate?.messagesViewModel(self, didUpdateModel: items, addingMessageAt: index)
    }
    
    func messagesDataModel(_ messagesDataModel: MessagesDataModel, didUpdateModel messagesModel: MessagesDataModel.MessagesModel, updatingMessageAt index: Int) {
        print("Data model updated")
        
        updateItems(with: messagesModel)
        
        delegate?.messagesViewModel(self, didUpdateModel: items, updatingMessageAt: index)
    }
}

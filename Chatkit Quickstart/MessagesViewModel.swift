import Foundation
import UIKit


// A protocol for observing changes to the ViewModel
protocol MessagesViewModelDelegate: AnyObject {
    
    func messagesViewModel(_ messagesViewModel: MessagesViewModel, didUpdateItems: [MessageViewItem], updatingMessageAt index: Int)
    func messagesViewModel(_ messagesViewModel: MessagesViewModel, didUpdateItems: [MessageViewItem], addingMessageAt index: Int)
}

// The view-oriented model of a message to be rendered
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

    // The collection of items currently available for rendering
    private var items = [MessageViewItem]()

    weak var delegate: MessagesViewModelDelegate?

    // Process each new model of the messages received from the store.
    // This naive implementation simply re-maps all messages in the model to their MessageViewItem
    // form.
    func updateMessageViewItems(withDataModel dataModel: MessagesDataModel) {

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

// The view model implements MessagesStoreDelegate, so that it can update in response to changes
// in the data model.
extension MessagesViewModel: MessagesStoreDelegate {
    
    func messagesStore(_ messagesStore: MessagesStore, didUpdateDataModel messagesDataModel: MessagesDataModel, addingMessageAt index: Int) {
        updateMessageViewItems(withDataModel: messagesDataModel)
        
        delegate?.messagesViewModel(self, didUpdateItems: items, addingMessageAt: index)
    }
    
    func messagesStore(_ messagesStore: MessagesStore, didUpdateDataModel messagesDataModel: MessagesDataModel, updatingMessageAt index: Int) {
        updateMessageViewItems(withDataModel: messagesDataModel)
        
        delegate?.messagesViewModel(self, didUpdateItems: items, updatingMessageAt: index)
    }
}

// MARK: - UITableViewDatasource implementation

struct CellColors {
    
    static let darkBackground = UIColor(red: 0.19, green: 0.05, blue: 0.31, alpha: 1.0)
    static let lightBackground = UIColor(red: 0.96, green: 0.96, blue: 1.00, alpha: 1.0)
    static let greyBackground = UIColor(red: 0.625, green: 0.625, blue: 0.625, alpha: 1.0)
    static let redBackground = UIColor(red: 1, green: 0.625, blue: 0.625, alpha: 1.0)
    
}

// A protocol which allows us to configure the fields of our different ViewCell types using a
// consistent signature, so we don't have to care about the difference in the implementation of
// UITableViewDataSource
protocol MessageTableViewCell: UITableViewCell {
    
    func configure(senderName: String,
                   senderAvatarUrl: String?,
                   text: String,
                   backgroundColor: UIColor)
}

// Extension of the ViewModel to be a the data source for a UITableView
extension MessagesViewModel: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Get a message and fill its details into a cell
        let messageViewItem = items[indexPath.row]
        
        let cellType: MessageTableViewCell.Type
        let backgroundColor: UIColor
        
        switch (messageViewItem.viewType) {
        case .pending:
            cellType = SenderMessageTableViewCell.self
            backgroundColor = CellColors.greyBackground
        case .failed:
            cellType = SenderMessageTableViewCell.self
            backgroundColor = CellColors.redBackground
        case .fromMe:
            cellType = SenderMessageTableViewCell.self
            backgroundColor = CellColors.darkBackground
        case .fromOther:
            cellType = OthersMessageTableViewCell.self
            backgroundColor = CellColors.lightBackground
        }
        
        let cellIdentifier = String(describing: cellType)
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier) as! MessageTableViewCell
        
        cell.configure(senderName: messageViewItem.senderName,
                       senderAvatarUrl: messageViewItem.senderAvatarUrl,
                       text: messageViewItem.text,
                       backgroundColor: backgroundColor)
        return cell
    }
}

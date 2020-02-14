import UIKit

class OthersMessageTableViewCell: UITableViewCell {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var avatarImageView: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        nameLabel.textAlignment = .left
        
        messageLabel.textAlignment = .left
        messageLabel.textColor = UIColor(red: 0.19, green: 0.05, blue: 0.31, alpha: 1.0)
        
        backgroundImageView.backgroundColor = CellColors.lightBackground
        backgroundImageView.layer.cornerRadius = 4.0
        backgroundImageView.clipsToBounds = true
    }
    
}

extension OthersMessageTableViewCell: MessageTableViewCell {
    
    func configure(senderName: String,
                   senderAvatarUrl: String?,
                   text: String,
                   backgroundColor: UIColor) {
        
        nameLabel.text = senderName
        messageLabel.text = text
        backgroundImageView.backgroundColor = backgroundColor
        avatarImageView.image = UIImage(named: "AvatarPlaceholder")
        
        if let senderAvatarUrlString = senderAvatarUrl,
            let senderAvatarUrl = URL(string: senderAvatarUrlString) {
    
            URLSession.shared.dataTask(with: senderAvatarUrl) { (data, _, _) in
                if let data = data {
                    DispatchQueue.main.async {
                        self.avatarImageView.image = UIImage(data: data)
                    }
                }
            }.resume()
        }
    }
}

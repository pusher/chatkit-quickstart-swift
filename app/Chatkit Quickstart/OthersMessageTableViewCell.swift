import UIKit

class OthersMessageTableViewCell: UITableViewCell {

    @IBOutlet weak var lblName: UILabel!
    @IBOutlet weak var imgBackground: UIImageView!
    @IBOutlet weak var lblMessage: UILabel!
    @IBOutlet weak var imgAvatar: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        lblName.textAlignment = .left
        lblMessage.textAlignment = .left
        
        imgBackground.backgroundColor = UIColor(red:0.96, green:0.96, blue:1.00, alpha:1.0)
        imgBackground.layer.cornerRadius = 4.0
        imgBackground.clipsToBounds = true
        
        lblMessage.textColor = UIColor(red:0.19, green:0.05, blue:0.31, alpha:1.0)
    }
    
     func setImage(ImageURL: String) {
        URLSession.shared.dataTask( with: NSURL(string:ImageURL)! as URL, completionHandler: {
            (data, response, error) -> Void in
            DispatchQueue.main.async {
                if let data = data {
                    self.imgAvatar?.image = UIImage(data: data)
                }
            }
        }).resume()
    }
}


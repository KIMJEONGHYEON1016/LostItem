//
//  ChatRoomTableViewCell.swift
//  LostItemApp
//
//  Created by 김정현 on 2023/08/23.
//

import UIKit

class ChatRoomTableViewCell: UITableViewCell {

    
    @IBOutlet var leftImageView: UIImageView!
    @IBOutlet var messageLabel: UILabel!
    @IBOutlet var myMessage: UILabel!
    @IBOutlet var messageBubble: UIView!
    @IBOutlet var MymessageBubble: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

    }

}

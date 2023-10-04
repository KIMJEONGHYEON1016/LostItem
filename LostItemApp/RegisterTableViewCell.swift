//
//  RegisterTableViewCell.swift
//  LostItemApp
//
//  Created by 김정현 on 2023/08/26.
//

import UIKit

class RegisterTableViewCell: UITableViewCell {

    @IBOutlet var previewLabel: UILabel!
    @IBOutlet var previewImage: UIImageView!
    @IBOutlet var previewDate: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

    }

}

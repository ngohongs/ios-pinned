//
//  HeaderTableViewCell.swift
//  Pinned
//
//  Created by Hong Son Ngo on 05/02/2021.
//

import UIKit

class HeaderTableViewCell: UITableViewCell {
    @IBOutlet weak var headerBackground: UIView!
    @IBOutlet weak var contentBackground: UIView!
    
    // MARK: - Setup -
    
    override func awakeFromNib() {
        super.awakeFromNib()
        headerBackground.layer.cornerRadius = 10
        contentBackground.layer.cornerRadius = 8
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    

}

class FooterTableViewCell: UITableViewCell {
    
    @IBOutlet weak var footerBackground: UIView!
    @IBOutlet weak var contenetBackground: UIView!
    
    // MARK: - Setup -
    
    override func awakeFromNib() {
        super.awakeFromNib()
        footerBackground.layer.cornerRadius = 10
        contenetBackground.layer.cornerRadius = 8
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}

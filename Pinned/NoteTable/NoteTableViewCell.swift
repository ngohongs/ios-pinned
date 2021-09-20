//
//  NoteTableViewCell.swift
//  Pinned
//
//  Created by Hong Son Ngo on 05/02/2021.
//

import UIKit

class NoteTableViewCell: UITableViewCell {

    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var noteBackground: UIView!
    @IBOutlet weak var noteHeaderBackground: UIView!
    @IBOutlet weak var noteContentBackground: UIView!
    @IBOutlet weak var textView: UITextView!
    
    // MARK: - Setup -
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        noteBackground.layer.cornerRadius = 8
        noteHeaderBackground.layer.cornerRadius = 5
        noteContentBackground.layer.cornerRadius = 5
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}

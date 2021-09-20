//
//  exNSAttributedString.swift
//  Pinned
//
//  Created by Hong Son Ngo on 08/02/2021.
//

import UIKit

// Html conversion
extension NSAttributedString {
    var attributedStringToHtml: String? {
        do {
            let htmlData = try self.data(from: NSRange(location: 0, length: self.length), documentAttributes:[.documentType: NSAttributedString.DocumentType.html, .characterEncoding:String.Encoding.utf8.rawValue]);
            return String.init(data: htmlData, encoding: String.Encoding.utf8)
        } catch {
            return nil
        }
    }
}

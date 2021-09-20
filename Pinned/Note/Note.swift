//
//  Note.swift
//  Pinned
//
//  Created by Hong Son Ngo on 02/02/2021.
//

import UIKit

struct NoteResponse: Codable {
    let data: [String: Note]
}

struct Note: Codable {
    let id: String
    let createTime: Double
    let expTime: Double?
    let title: String
    let lat: Double?
    let lon: Double?
    let data: [Content]
}

struct Content: Codable {
    let type: String
    let data: String
    let ratio: CGFloat?
}

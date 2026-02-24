//
//  Item.swift
//  MultiClips
//
//  Created by Nitish M on 22/02/26.
//

import Foundation
import SwiftData

enum ClipType: String, Codable{
    case Text
    case Image
    case Files
    case Unknown
}

@Model
final class Item {
    @Attribute(.unique) var id: UUID
    
    var copiedDate: Date
    
    var type: ClipType
    
    var textCopied: String?
    
    var files: URL?
    
    @Attribute(.externalStorage) var rawData: Data?
    
    var displayTitle: String {
        if let text = textCopied {
            return text
        }
        if let url = files {
            return url.lastPathComponent
        }
        if type == .Image {
            return "Image Copied"
        }
        return "Unknown Clip"
    }
    
    init(id: UUID, copiedDate: Date, type: ClipType, textCopied: String? = nil, files: URL? = nil, rawData: Data? = nil) {
        self.id = id
        self.copiedDate = copiedDate
        self.type = type
        self.textCopied = textCopied
        self.files = files
        self.rawData = rawData
    }   
}

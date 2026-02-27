import Foundation
import SwiftData

enum ClipType: String, Codable {
    case Texts
    case Images
    case Medias
    case Documents
    case Files
    case Links
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
        if let text = textCopied, !text.isEmpty { return text }
        if let url = files { return url.lastPathComponent }
        switch type {
        case .Texts: return "Text Copied"
        case .Images: return "Image Copied"
        case .Medias: return "Media Copied"
        case .Documents: return "Document Copied"
        case .Files: return "File Copied"
        case .Links: return "Link Copied"
        case .Unknown: return "Unknown Clip"
        }
    }

    init(id: UUID = UUID(),
         copiedDate: Date = Date(),
         type: ClipType,
         textCopied: String? = nil,
         files: URL? = nil,
         rawData: Data? = nil) {
        self.id = id
        self.copiedDate = copiedDate
        self.type = type
        self.textCopied = textCopied
        self.files = files
        self.rawData = rawData
    }
}

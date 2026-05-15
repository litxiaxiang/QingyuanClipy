import Foundation
import SwiftData
import AppKit

@Model
final class ClipItem {
    var id: UUID
    var itemType: String // "text" 或 "image"
    
    // 如果是文本，存放在这里
    var textContent: String?
    
    // 如果是图片，存放在这里，使用 externalStorage 优化大文件存储
    @Attribute(.externalStorage)
    var imageData: Data?
    
    var timestamp: Date
    
    init(itemType: String, textContent: String? = nil, imageData: Data? = nil, timestamp: Date = .now) {
        self.id = UUID()
        self.itemType = itemType
        self.textContent = textContent
        self.imageData = imageData
        self.timestamp = timestamp
    }
}
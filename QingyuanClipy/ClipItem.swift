import Foundation
import SwiftData

@Model
final class ClipItem {
    var id: UUID
    var content: String
    var timestamp: Date
    
    init(content: String, timestamp: Date = .now) {
        self.id = UUID()
        self.content = content
        self.timestamp = timestamp
    }
}
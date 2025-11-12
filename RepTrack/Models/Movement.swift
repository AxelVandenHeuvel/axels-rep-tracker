import SwiftData
import Foundation

@Model
final class Movement {
    @Attribute(.unique) var id: UUID
    var name: String
    var tags: [String]           // e.g., ["Chest","Barbell"]
    var createdAt: Date

    init(id: UUID = UUID(), name: String, tags: [String] = [], createdAt: Date = .now) {
        self.id = id
        self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        self.tags = tags
        self.createdAt = createdAt
    }
}


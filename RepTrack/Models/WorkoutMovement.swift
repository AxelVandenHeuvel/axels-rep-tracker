import SwiftData
import Foundation

@Model
final class WorkoutMovement {
    @Attribute(.unique) var id: UUID
    var movement: Movement       // reference to library movement
    var notes: String?
    var sets: [SetEntry]

    init(id: UUID = UUID(), movement: Movement, notes: String? = nil, sets: [SetEntry] = []) {
        self.id = id
        self.movement = movement
        self.notes = notes
        self.sets = sets
    }
}


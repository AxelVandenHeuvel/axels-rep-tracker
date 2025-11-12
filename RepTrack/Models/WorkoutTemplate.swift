import SwiftData
import Foundation

@Model
final class WorkoutTemplate {
    @Attribute(.unique) var id: UUID
    var name: String
    var movementIDs: [UUID]      // References to Movement.id
    var movementNotes: [UUID: String]?  // Optional notes per movement ID
    var colorHex: String

    init(
        id: UUID = UUID(),
        name: String,
        movementIDs: [UUID] = [],
        movementNotes: [UUID: String]? = nil,
        colorHex: String = "#4D96FF"
    ) {
        self.id = id
        self.name = name
        self.movementIDs = movementIDs
        self.movementNotes = movementNotes
        self.colorHex = colorHex
    }
}


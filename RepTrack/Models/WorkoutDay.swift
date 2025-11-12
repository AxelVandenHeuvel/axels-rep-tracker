import SwiftData
import Foundation

@Model
final class WorkoutDay {
    @Attribute(.unique) var id: UUID
    var date: Date               // normalized to midnight
    var movements: [WorkoutMovement]
    var appliedTemplateIDs: [UUID]

    init(
        id: UUID = UUID(),
        date: Date,
        movements: [WorkoutMovement] = [],
        appliedTemplateIDs: [UUID] = []
    ) {
        self.id = id
        self.date = date
        self.movements = movements
        self.appliedTemplateIDs = appliedTemplateIDs
    }
}


import SwiftData
import Foundation

@Model
final class SetEntry {
    @Attribute(.unique) var id: UUID
    var weight: Double
    var reps: Int
    var rpe: Double?             // optional; hidden by default in UI
    var timestamp: Date
    var isTopSet: Bool

    init(
        id: UUID = UUID(),
        weight: Double,
        reps: Int,
        rpe: Double? = nil,
        timestamp: Date = .now,
        isTopSet: Bool = false
    ) {
        self.id = id
        self.weight = weight
        self.reps = reps
        self.rpe = rpe
        self.timestamp = timestamp
        self.isTopSet = isTopSet
    }
    
    convenience init(
        id: UUID = UUID(),
        weight: Double,
        reps: Int,
        rpe: Double? = nil,
        timestamp: Date = .now
    ) {
        self.init(
            id: id,
            weight: weight,
            reps: reps,
            rpe: rpe,
            timestamp: timestamp,
            isTopSet: false
        )
    }
}


import Foundation
import SwiftData
import Combine

extension Notification.Name {
    static let workoutDayUpdated = Notification.Name("workoutDayUpdated")
}

@MainActor
class WorkoutDayVM: ObservableObject {
    @Published var workoutDay: WorkoutDay?
    @Published var selectedMovement: Movement?
    
    private var modelContext: ModelContext?
    private let date: Date
    
    init(date: Date, modelContext: ModelContext? = nil) {
        self.date = Date.startOfDay(date)
        self.modelContext = modelContext
        loadWorkoutDay()
    }
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        loadWorkoutDay()
    }
    
    private func loadWorkoutDay() {
        guard let context = modelContext else { return }
        
        let descriptor = FetchDescriptor<WorkoutDay>(
            predicate: #Predicate { $0.date == date }
        )
        
        if let existing = try? context.fetch(descriptor).first {
            workoutDay = existing
        } else {
            let newDay = WorkoutDay(date: date, appliedTemplateIDs: [])
            context.insert(newDay)
            try? context.save()
            workoutDay = newDay
        }
    }
    
    func addMovement(_ movement: Movement) {
        guard let context = modelContext, let day = workoutDay else { return }
        
        // Check if movement already exists in this workout
        if day.movements.contains(where: { $0.movement.id == movement.id }) {
            return // Already added
        }
        
        let workoutMovement = WorkoutMovement(movement: movement)
        context.insert(workoutMovement)
        day.movements.append(workoutMovement)
        try? context.save()
    }
    
    func removeMovement(_ workoutMovement: WorkoutMovement) {
        guard let context = modelContext, let day = workoutDay else { return }
        
        // Delete all sets first
        for set in workoutMovement.sets {
            context.delete(set)
        }
        
        day.movements.removeAll { $0.id == workoutMovement.id }
        context.delete(workoutMovement)
        if day.movements.isEmpty {
            day.appliedTemplateIDs = []
        }
        objectWillChange.send()
        try? context.save()
        NotificationCenter.default.post(name: .workoutDayUpdated, object: day.id)
    }
    
    func addSet(to workoutMovement: WorkoutMovement, weight: Double, reps: Int, rpe: Double? = nil) {
        guard let context = modelContext else { return }
        
        let set = SetEntry(weight: weight, reps: reps, rpe: rpe)
        context.insert(set)
        workoutMovement.sets.append(set)
        try? context.save()
        objectWillChange.send()
        NotificationCenter.default.post(name: .workoutDayUpdated, object: workoutDay?.id)
    }
    
    func deleteSet(_ set: SetEntry, from workoutMovement: WorkoutMovement) {
        guard let context = modelContext else { return }
        
        workoutMovement.sets.removeAll { $0.id == set.id }
        context.delete(set)
        try? context.save()
        objectWillChange.send()
        NotificationCenter.default.post(name: .workoutDayUpdated, object: workoutDay?.id)
    }
    
    func updateSet(_ set: SetEntry, weight: Double, reps: Int, rpe: Double? = nil) {
        set.weight = weight
        set.reps = reps
        set.rpe = rpe
        try? modelContext?.save()
        objectWillChange.send()
        NotificationCenter.default.post(name: .workoutDayUpdated, object: workoutDay?.id)
    }

    func markTemplateApplied(_ template: WorkoutTemplate) {
        guard let day = workoutDay else { return }
        if !day.appliedTemplateIDs.contains(template.id) {
            day.appliedTemplateIDs.append(template.id)
            try? modelContext?.save()
            objectWillChange.send()
            NotificationCenter.default.post(name: .workoutDayUpdated, object: day.id)
        }
    }
    
    func removeAppliedTemplate(_ template: WorkoutTemplate, shouldRemoveMovements: Bool) {
        guard let day = workoutDay else { return }
        day.appliedTemplateIDs.removeAll { $0 == template.id }
        
        if shouldRemoveMovements {
            let templateMovementIDs = Set(template.movementIDs)
            if !templateMovementIDs.isEmpty {
                var movementsToRemove: [WorkoutMovement] = []
                for workoutMovement in day.movements {
                    if templateMovementIDs.contains(workoutMovement.movement.id) {
                        workoutMovement.sets.forEach { modelContext?.delete($0) }
                        movementsToRemove.append(workoutMovement)
                    }
                }
                day.movements.removeAll { movement in
                    if movementsToRemove.contains(where: { $0.id == movement.id }) {
                        modelContext?.delete(movement)
                        return true
                    }
                    return false
                }
            }
        }
        
        try? modelContext?.save()
        objectWillChange.send()
        NotificationCenter.default.post(name: .workoutDayUpdated, object: day.id)
    }
    
    var totalSetsCount: Int {
        workoutDay?.movements.reduce(0) { $0 + $1.sets.count } ?? 0
    }
}


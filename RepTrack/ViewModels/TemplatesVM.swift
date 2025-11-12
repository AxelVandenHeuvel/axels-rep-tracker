import Foundation
import SwiftData
import Combine

@MainActor
class TemplatesVM: ObservableObject {
    private var modelContext: ModelContext?
    
    @Published var allTemplates: [WorkoutTemplate] = []
    @Published var allMovements: [Movement] = []

    static let colorOptions: [String] = [
        "#FF6B6B",
        "#F7B801",
        "#6BCB77",
        "#4D96FF",
        "#9D4EDD",
        "#FF922B",
        "#20A4F3",
        "#EF476F"
    ]
    
    init(modelContext: ModelContext? = nil) {
        self.modelContext = modelContext
    }
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        loadData()
    }
    
    func loadData() {
        guard let context = modelContext else { return }
        
        let templateDescriptor = FetchDescriptor<WorkoutTemplate>(
            sortBy: [SortDescriptor(\.name)]
        )
        allTemplates = (try? context.fetch(templateDescriptor)) ?? []
        
        let movementDescriptor = FetchDescriptor<Movement>(
            sortBy: [SortDescriptor(\.name)]
        )
        allMovements = (try? context.fetch(movementDescriptor)) ?? []
    }
    
    func createTemplate(
        name: String,
        movementIDs: [UUID],
        colorHex: String,
        movementNotes: [UUID: String]? = nil
    ) -> WorkoutTemplate? {
        guard let context = modelContext else { return nil }
        
        let template = WorkoutTemplate(
            name: name,
            movementIDs: movementIDs,
            movementNotes: movementNotes,
            colorHex: colorHex
        )
        context.insert(template)
        try? context.save()
        loadData()
        return template
    }
    
    func updateTemplate(
        _ template: WorkoutTemplate,
        name: String? = nil,
        movementIDs: [UUID]? = nil,
        movementNotes: [UUID: String]? = nil,
        colorHex: String? = nil
    ) {
        if let name = name {
            template.name = name
        }
        if let movementIDs = movementIDs {
            template.movementIDs = movementIDs
        }
        if let movementNotes = movementNotes {
            template.movementNotes = movementNotes
        }
        if let colorHex = colorHex {
            template.colorHex = colorHex
        }
        try? modelContext?.save()
        loadData()
    }
    
    /// Gets Movement entities from template's movement IDs
    func getMovements(for template: WorkoutTemplate) -> [Movement] {
        template.movementIDs.compactMap { id in
            allMovements.first { $0.id == id }
        }
    }
    
    /// Applies template to a workout day - returns movements to add
    func applyTemplate(_ template: WorkoutTemplate, to context: ModelContext) -> [Movement] {
        var movementsToAdd: [Movement] = []
        
        for movementID in template.movementIDs {
            if let movement = allMovements.first(where: { $0.id == movementID }) {
                movementsToAdd.append(movement)
            }
        }
        
        return movementsToAdd
    }
    
    func deleteTemplate(_ template: WorkoutTemplate) {
        deleteTemplateAndDetachMovements(template, removeMovementsFromDays: false)
    }
    
    func deleteTemplateAndDetachMovements(_ template: WorkoutTemplate, removeMovementsFromDays: Bool) {
        guard let context = modelContext else { return }
        
        let dayDescriptor = FetchDescriptor<WorkoutDay>()
        if let workoutDays = try? context.fetch(dayDescriptor) {
            let templateMovementIDs = Set(template.movementIDs)
            for day in workoutDays {
                day.appliedTemplateIDs.removeAll { $0 == template.id }
                if removeMovementsFromDays && !templateMovementIDs.isEmpty {
                    var movementsToRemove: [WorkoutMovement] = []
                    for workoutMovement in day.movements where templateMovementIDs.contains(workoutMovement.movement.id) {
                        workoutMovement.sets.forEach { context.delete($0) }
                        movementsToRemove.append(workoutMovement)
                    }
                    day.movements.removeAll { movement in
                        if movementsToRemove.contains(where: { $0.id == movement.id }) {
                            context.delete(movement)
                            return true
                        }
                        return false
                    }
                }
            }
        }
        
        context.delete(template)
        try? context.save()
        loadData()
    }
    
}


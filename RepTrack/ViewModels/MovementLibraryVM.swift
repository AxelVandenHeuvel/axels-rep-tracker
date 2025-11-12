import Foundation
import SwiftData
import Combine

@MainActor
class MovementLibraryVM: ObservableObject {
    @Published var searchText: String = ""
    @Published var selectedTags: Set<String> = []
    @Published var showingTagFilter = false
    
    private var modelContext: ModelContext?
    
    @Published var allMovements: [Movement] = []
    
    // Preset tags
    static let presetTags = [
        "Chest", "Back", "Shoulders", "Quads", "Hamstrings", "Glutes",
        "Biceps", "Triceps", "Core", "Calves",
        "Barbell", "Dumbbell", "Machine", "Cable", "Bodyweight"
    ]
    
    init(modelContext: ModelContext? = nil) {
        self.modelContext = modelContext
    }
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        loadMovements()
    }
    
    func loadMovements() {
        guard let context = modelContext else { return }
        
        let descriptor = FetchDescriptor<Movement>(
            sortBy: [SortDescriptor(\.createdAt)]
        )
        
        allMovements = (try? context.fetch(descriptor)) ?? []
    }
    
    var filteredMovements: [Movement] {
        var filtered = allMovements
        
        // Filter by search text
        if !searchText.isEmpty {
            filtered = filtered.filter { movement in
                movement.name.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Filter by selected tags (must have ALL selected tags)
        if !selectedTags.isEmpty {
            filtered = filtered.filter { movement in
                selectedTags.isSubset(of: Set(movement.tags))
            }
        }
        
        return filtered
    }
    
    func createMovement(name: String, tags: [String]) -> Movement? {
        guard let context = modelContext else { return nil }
        
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return nil }
        
        // Check for existing movement (case-insensitive)
        let existing = allMovements.first { movement in
            movement.name.localizedCaseInsensitiveCompare(trimmedName) == .orderedSame
        }
        
        if let existing = existing {
            return existing // Return existing movement
        }
        
        let movement = Movement(name: trimmedName, tags: tags)
        context.insert(movement)
        try? context.save()
        loadMovements() // Refresh list
        return movement
    }
    
    func toggleTag(_ tag: String) {
        if selectedTags.contains(tag) {
            selectedTags.remove(tag)
        } else {
            selectedTags.insert(tag)
        }
    }
    
    func clearFilters() {
        searchText = ""
        selectedTags.removeAll()
    }

    func deleteMovement(_ movement: Movement) {
        guard let context = modelContext else { return }

        // Remove references from workout days
        let dayDescriptor = FetchDescriptor<WorkoutDay>()
        let workoutDays = (try? context.fetch(dayDescriptor)) ?? []
        for day in workoutDays {
            let movementsToRemove = day.movements.filter { $0.movement.id == movement.id }
            for workoutMovement in movementsToRemove {
                workoutMovement.sets.forEach { context.delete($0) }
                context.delete(workoutMovement)
            }
            day.movements.removeAll { $0.movement.id == movement.id }
            if day.movements.isEmpty {
                day.appliedTemplateIDs.removeAll()
            }
        }

        // Remove from templates
        let templateDescriptor = FetchDescriptor<WorkoutTemplate>()
        let templates = (try? context.fetch(templateDescriptor)) ?? []
        for template in templates {
            template.movementIDs.removeAll { $0 == movement.id }
            if var notes = template.movementNotes {
                notes.removeValue(forKey: movement.id)
                template.movementNotes = notes.isEmpty ? nil : notes
            }
        }

        context.delete(movement)
        try? context.save()
        loadMovements()
        NotificationCenter.default.post(name: .workoutDayUpdated, object: nil)
    }
}


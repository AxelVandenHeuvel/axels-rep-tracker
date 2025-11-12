import Foundation
import SwiftData

struct SeedDataService {
    /// Seeds initial data only in DEBUG mode on first launch
    static func seedIfNeeded(modelContext: ModelContext) {
        #if DEBUG
        // Check if we've already seeded
        let descriptor = FetchDescriptor<Movement>()
        if let existing = try? modelContext.fetch(descriptor), !existing.isEmpty {
            return // Already seeded
        }
        
        // Create seed movements
        let movements: [(name: String, tags: [String])] = [
            ("Barbell Bench Press", ["Chest", "Barbell"]),
            ("Back Squat", ["Quads", "Barbell"]),
            ("Conventional Deadlift", ["Back", "Barbell"]),
            ("Incline DB Press", ["Chest", "Dumbbell"]),
            ("Triceps Pushdown", ["Triceps", "Cable"]),
            ("Barbell Row", ["Back", "Barbell"]),
            ("Lat Pulldown", ["Back", "Machine"]),
            ("Leg Press", ["Quads", "Machine"]),
            ("Leg Curl", ["Hamstrings", "Machine"])
        ]
        
        var createdMovements: [UUID: Movement] = [:]
        
        for movementData in movements {
            let movement = Movement(name: movementData.name, tags: movementData.tags)
            modelContext.insert(movement)
            createdMovements[movement.id] = movement
        }
        
        // Create seed templates
        let benchPressID = createdMovements.values.first { $0.name == "Barbell Bench Press" }?.id
        let inclineDBID = createdMovements.values.first { $0.name == "Incline DB Press" }?.id
        let tricepsID = createdMovements.values.first { $0.name == "Triceps Pushdown" }?.id
        let deadliftID = createdMovements.values.first { $0.name == "Conventional Deadlift" }?.id
        let rowID = createdMovements.values.first { $0.name == "Barbell Row" }?.id
        let pulldownID = createdMovements.values.first { $0.name == "Lat Pulldown" }?.id
        let squatID = createdMovements.values.first { $0.name == "Back Squat" }?.id
        let legPressID = createdMovements.values.first { $0.name == "Leg Press" }?.id
        let legCurlID = createdMovements.values.first { $0.name == "Leg Curl" }?.id
        
        // Push template
        var templateLookup: [String: WorkoutTemplate] = [:]
        
        if let bench = benchPressID, let incline = inclineDBID, let tri = tricepsID {
            let pushTemplate = WorkoutTemplate(
                name: "Push",
                movementIDs: [bench, incline, tri],
                colorHex: "#FF6B6B"
            )
            modelContext.insert(pushTemplate)
            templateLookup["Push"] = pushTemplate
        }
        
        // Pull template
        if let dead = deadliftID, let row = rowID, let pull = pulldownID {
            let pullTemplate = WorkoutTemplate(
                name: "Pull",
                movementIDs: [dead, row, pull],
                colorHex: "#4D96FF"
            )
            modelContext.insert(pullTemplate)
            templateLookup["Pull"] = pullTemplate
        }
        
        // Legs template
        if let squat = squatID, let press = legPressID, let curl = legCurlID {
            let legsTemplate = WorkoutTemplate(
                name: "Legs",
                movementIDs: [squat, press, curl],
                colorHex: "#6BCB77"
            )
            modelContext.insert(legsTemplate)
            templateLookup["Legs"] = legsTemplate
        }
        
        // Create sample workout days with sets
        let calendar = Calendar.current
        let today = Date()
        
        for dayOffset in [-5, -3, -1] {
            if let workoutDate = calendar.date(byAdding: .day, value: dayOffset, to: today) {
                let normalizedDate = Date.startOfDay(workoutDate)
                let workoutDay = WorkoutDay(date: normalizedDate)
                modelContext.insert(workoutDay)
                
                // Add sample sets for bench press if available
                if let benchMovement = createdMovements.values.first(where: { $0.name == "Barbell Bench Press" }) {
                    let workoutMovement = WorkoutMovement(movement: benchMovement)
                    modelContext.insert(workoutMovement)
                    workoutDay.movements.append(workoutMovement)
                    
                    // Add 2-3 sets
                    let weights = [135.0, 155.0, 175.0]
                    let reps = [12, 10, 8]
                    for i in 0..<3 {
                        let set = SetEntry(
                            weight: weights[i],
                            reps: reps[i],
                            timestamp: workoutDate.addingTimeInterval(Double(i * 60))
                        )
                        modelContext.insert(set)
                        workoutMovement.sets.append(set)
                    }
                }
                
                // Add sample sets for squats if available
                if let squatMovement = createdMovements.values.first(where: { $0.name == "Back Squat" }) {
                    let workoutMovement = WorkoutMovement(movement: squatMovement)
                    modelContext.insert(workoutMovement)
                    workoutDay.movements.append(workoutMovement)
                    
                    let weights = [225.0, 245.0]
                    let reps = [10, 8]
                    for i in 0..<2 {
                        let set = SetEntry(
                            weight: weights[i],
                            reps: reps[i],
                            timestamp: workoutDate.addingTimeInterval(Double(300 + i * 60))
                        )
                        modelContext.insert(set)
                        workoutMovement.sets.append(set)
                    }
                }
                // Tag sample days with templates for calendar coloring
                if dayOffset == -5, let pushTemplate = templateLookup["Push"] {
                    workoutDay.appliedTemplateIDs.append(pushTemplate.id)
                } else if dayOffset == -3, let pullTemplate = templateLookup["Pull"] {
                    workoutDay.appliedTemplateIDs.append(pullTemplate.id)
                } else if dayOffset == -1, let legsTemplate = templateLookup["Legs"] {
                    workoutDay.appliedTemplateIDs.append(legsTemplate.id)
                }
            }
        }
        
        try? modelContext.save()
        #endif
    }
}


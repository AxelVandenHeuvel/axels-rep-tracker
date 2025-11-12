import Foundation
import SwiftData
import Charts
import Combine


@MainActor
class ChartsVM: ObservableObject {
    @Published var selectedMovement: Movement? {
        didSet {
            if oldValue?.id != selectedMovement?.id {
                syncTargetWeightToRecentSet()
                markNeedsRefresh()
            }
        }
    }
    @Published var chartMode: ChartMode = .topSetRepsAtWeight {
        didSet {
            if oldValue != chartMode {
                markNeedsRefresh()
            }
        }
    }
    @Published var targetWeight: Double = 135.0 {
        didSet {
            if abs(oldValue - targetWeight) > 0.0001 {
                markNeedsRefresh()
            }
        }
    }
    @Published private(set) var refreshToken = UUID()
    
    enum ChartMode: String, CaseIterable {
        case topSetRepsAtWeight = "Top Set Reps"
        case averageRepsAtWeight = "Avg Reps @ Weight"
        case volumeAtWeight = "Volume @ Weight"
    }
    
    private var modelContext: ModelContext?
    
    var allMovements: [Movement] = []
    
    init(modelContext: ModelContext? = nil) {
        self.modelContext = modelContext
    }
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        loadMovements()
        markNeedsRefresh()
    }
    
    func loadMovements() {
        guard let context = modelContext else { return }
        
        let descriptor = FetchDescriptor<Movement>(
            sortBy: [SortDescriptor(\.name)]
        )
        allMovements = (try? context.fetch(descriptor)) ?? []
        markNeedsRefresh()
    }
    
    func availableWeights() -> [Double] {
        let sets = getAllSets()
        var seen: Set<Int> = []
        var unique: [Double] = []
        
        for set in sets {
            let normalized = Int((set.weight * 1000).rounded())
            if !seen.contains(normalized) {
                seen.insert(normalized)
                unique.append(set.weight)
            }
        }
        
        return unique.sorted()
    }
    
    func syncTargetWeightToRecentSet() {
        let weights = availableWeights()
        if weights.isEmpty {
            markNeedsRefresh()
            return
        }
        
        if !weights.contains(where: { abs($0 - targetWeight) < 0.001 }) {
            targetWeight = weights.last ?? targetWeight
        } else {
            markNeedsRefresh()
        }
    }
    
    /// Gets all sets for the selected movement, sorted by date
    func getAllSets() -> [SetEntry] {
        guard let movement = selectedMovement, let context = modelContext else { return [] }
        
        let descriptor = FetchDescriptor<WorkoutDay>()
        let workoutDays = (try? context.fetch(descriptor)) ?? []
        
        var allSets: [(set: SetEntry, date: Date)] = []
        
        for workoutDay in workoutDays {
            for workoutMovement in workoutDay.movements where workoutMovement.movement.id == movement.id {
                for set in workoutMovement.sets {
                    allSets.append((set, workoutDay.date))
                }
            }
        }
        
        // Sort by date
        allSets.sort { $0.date < $1.date }
        
        return allSets.map { $0.set }
    }
    
    /// Gets top-set reps over time at a specific weight (±0.5% tolerance)
    func getTopSetRepsAtWeight() -> [(date: Date, value: Double)] {
        guard let movement = selectedMovement, let context = modelContext else { return [] }
        
        let tolerance = targetWeight * 0.005
        let minWeight = targetWeight - tolerance
        let maxWeight = targetWeight + tolerance
        
        let descriptor = FetchDescriptor<WorkoutDay>()
        let workoutDays = (try? context.fetch(descriptor)) ?? []
        
        var results: [(Date, Double)] = []
        
        for workoutDay in workoutDays {
            for workoutMovement in workoutDay.movements where workoutMovement.movement.id == movement.id {
                if let topSet = workoutMovement.sets.first(where: { $0.isTopSet && $0.weight >= minWeight && $0.weight <= maxWeight }) {
                    results.append((workoutDay.date, Double(topSet.reps)))
                }
            }
        }
        
        return results.sorted { $0.0 < $1.0 }
    }
    
    /// Gets average reps over time at a specific weight (±0.5% tolerance)
    func getAverageRepsAtWeight() -> [(date: Date, value: Double)] {
        guard let movement = selectedMovement, let context = modelContext else { return [] }
        
        let tolerance = targetWeight * 0.005
        let minWeight = targetWeight - tolerance
        let maxWeight = targetWeight + tolerance
        
        let descriptor = FetchDescriptor<WorkoutDay>()
        let workoutDays = (try? context.fetch(descriptor)) ?? []
        
        var perDay: [Date: (total: Double, count: Int)] = [:]
        
        for workoutDay in workoutDays {
            for workoutMovement in workoutDay.movements where workoutMovement.movement.id == movement.id {
                for set in workoutMovement.sets where set.weight >= minWeight && set.weight <= maxWeight {
                    let entry = perDay[workoutDay.date] ?? (0, 0)
                    perDay[workoutDay.date] = (entry.total + Double(set.reps), entry.count + 1)
                }
            }
        }
        
        return perDay.compactMap { date, aggregate in
            guard aggregate.count > 0 else { return nil }
            return (date, aggregate.total / Double(aggregate.count))
        }
        .sorted { $0.date < $1.date }
    }
    
    /// Gets total volume over time at a specific weight (±0.5% tolerance)
    func getVolumeAtWeight() -> [(date: Date, value: Double)] {
        guard let movement = selectedMovement, let context = modelContext else { return [] }
        
        let tolerance = targetWeight * 0.005
        let minWeight = targetWeight - tolerance
        let maxWeight = targetWeight + tolerance
        
        let descriptor = FetchDescriptor<WorkoutDay>()
        let workoutDays = (try? context.fetch(descriptor)) ?? []
        
        var perDay: [Date: Double] = [:]
        
        for workoutDay in workoutDays {
            for workoutMovement in workoutDay.movements where workoutMovement.movement.id == movement.id {
                for set in workoutMovement.sets where set.weight >= minWeight && set.weight <= maxWeight {
                    perDay[workoutDay.date, default: 0] += set.weight * Double(set.reps)
                }
            }
        }
        
        return perDay.map { ($0.key, $0.value) }
            .sorted { $0.date < $1.date }
    }
    
    func markNeedsRefresh() {
        refreshToken = UUID()
    }
}


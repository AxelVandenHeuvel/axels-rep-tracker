import SwiftUI
import SwiftData
import Combine

struct MovementRowView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var workoutMovement: WorkoutMovement
    @StateObject private var setEditorVM = SetEditorViewModel()
    
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Movement header
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(workoutMovement.movement.name)
                        .font(.headline)
                        .foregroundColor(AppColors.textPrimary)
                    
                    MovementTagPills(tags: workoutMovement.movement.tags)
                }
                
                Spacer()
                
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Image(systemName: "trash.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(AppColors.accentLight)
                        .accessibilityLabel("Remove movement")
                }
                .buttonStyle(.plain)
            }
            
            // Sets list
            if !workoutMovement.sets.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(workoutMovement.sets.sorted(by: { $0.timestamp < $1.timestamp })) { set in
                        HStack {
                            Text("\(String(format: "%.1f", set.weight)) lbs × \(set.reps)")
                                .font(.body)
                                .foregroundColor(AppColors.textPrimary)
                            
                            if let rpe = set.rpe {
                                Text("(@ \(String(format: "%.1f", rpe)) RPE)")
                                    .font(.caption)
                                    .foregroundColor(AppColors.textSecondary)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                toggleTopSet(set)
                            }) {
                                Image(systemName: set.isTopSet ? "star.fill" : "star")
                                    .font(.body)
                            }
                            .buttonStyle(.plain)
                            .foregroundColor(set.isTopSet ? AppColors.accentLight : AppColors.textSecondary)
                            .accessibilityLabel(set.isTopSet ? "Unmark top set" : "Mark as top set")
                            
                            Button(role: .destructive, action: {
                                deleteSet(set)
                            }) {
                                Image(systemName: "trash")
                                    .font(.body)
                            }
                            .buttonStyle(.plain)
                            .foregroundColor(AppColors.accentLight)
                            .accessibilityLabel("Delete set")
                        }
                        .padding(.vertical, 4)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive, action: {
                                deleteSet(set)
                            }) {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            
            // Quick Add Set Editor
            SetEditorRow(
                weightText: $setEditorVM.weightText,
                repsText: $setEditorVM.repsText,
                rpeText: $setEditorVM.rpeText,
                onAdd: {
                    addSet()
                },
                isValid: setEditorVM.isValid,
                lastWeight: setEditorVM.lastWeight,
                lastReps: setEditorVM.lastReps,
                lastRPE: setEditorVM.lastRPE
            )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(AppColors.surfaceElevated)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(AppColors.border, lineWidth: 1)
        )
        .shadow(color: AppColors.accent.opacity(0.15), radius: 12, x: 0, y: 6)
        .onAppear {
            setEditorVM.loadLastValues(from: workoutMovement.sets)
        }
        .onChange(of: workoutMovement.sets.count) { oldValue, newValue in
            setEditorVM.loadLastValues(from: workoutMovement.sets)
        }
    }
    
    private func addSet() {
        guard let weight = Double(setEditorVM.weightText),
              let reps = Int(setEditorVM.repsText),
              weight > 0, reps > 0 else { return }
        
        let rpe = Double(setEditorVM.rpeText)
        
        let set = SetEntry(weight: weight, reps: reps, rpe: rpe)
        modelContext.insert(set)
        workoutMovement.sets.append(set)
        
        // Update last values for next set
        setEditorVM.lastWeight = weight
        setEditorVM.lastReps = reps
        setEditorVM.lastRPE = rpe
        
        // Prefill for next set
        setEditorVM.weightText = String(format: "%.1f", weight)
        setEditorVM.repsText = "\(reps)"
        if let rpe = rpe {
            setEditorVM.rpeText = String(format: "%.1f", rpe)
        }
        
        try? modelContext.save()
        NotificationCenter.default.post(name: .workoutDayUpdated, object: workoutMovement.id)
    }
    
    private func deleteSet(_ set: SetEntry) {
        workoutMovement.sets.removeAll { $0.id == set.id }
        modelContext.delete(set)
        try? modelContext.save()
        setEditorVM.loadLastValues(from: workoutMovement.sets)
        NotificationCenter.default.post(name: .workoutDayUpdated, object: workoutMovement.id)
    }

    private func toggleTopSet(_ set: SetEntry) {
        let context = modelContext
        
        if set.isTopSet {
            set.isTopSet = false
        } else {
            for other in workoutMovement.sets where other.isTopSet {
                other.isTopSet = false
            }
            set.isTopSet = true
        }
        
        try? context.save()
        NotificationCenter.default.post(name: .workoutDayUpdated, object: workoutMovement.id)
    }
}

// Helper view model for set editor state
@MainActor
class SetEditorViewModel: ObservableObject {
    @Published var weightText: String = ""
    @Published var repsText: String = ""
    @Published var rpeText: String = ""
    
    @Published var lastWeight: Double?
    @Published var lastReps: Int?
    @Published var lastRPE: Double?
    
    var isValid: Bool {
        guard let weight = Double(weightText),
              let reps = Int(repsText),
              weight > 0, reps > 0 else {
            return false
        }
        return true
    }
    
    func loadLastValues(from sets: [SetEntry]) {
        guard let lastSet = sets.sorted(by: { $0.timestamp > $1.timestamp }).first else {
            // No sets yet, clear prefills
            weightText = ""
            repsText = ""
            rpeText = ""
            return
        }
        
        lastWeight = lastSet.weight
        lastReps = lastSet.reps
        lastRPE = lastSet.rpe
        
        // Prefill fields with last values
        weightText = String(format: "%.1f", lastSet.weight)
        repsText = "\(lastSet.reps)"
        if let rpe = lastSet.rpe {
            rpeText = String(format: "%.1f", rpe)
        } else {
            rpeText = ""
        }
    }
}


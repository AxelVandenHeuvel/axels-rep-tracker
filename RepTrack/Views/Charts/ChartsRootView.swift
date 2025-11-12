import SwiftUI
import SwiftData
import Combine

struct ChartsRootView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = ChartsVM()
    @State private var showingMovementPicker = false
    
    var body: some View {
        let palette = themeManager.currentTheme
        
        return NavigationStack {
            VStack(spacing: 16) {
                // Movement selector
                Button(action: {
                    showingMovementPicker = true
                }) {
                    HStack {
                        if let movement = viewModel.selectedMovement {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(movement.name)
                                    .foregroundColor(palette.textPrimary)
                                MovementTagPills(tags: movement.tags)
                            }
                        } else {
                            Text("Select Movement")
                                .foregroundColor(palette.textSecondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(palette.textSecondary)
                    }
                    .padding()
                    .background(palette.surface)
                    .cornerRadius(14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(palette.border, lineWidth: 1)
                    )
                    .shadow(color: palette.accent.opacity(0.12), radius: 10, x: 0, y: 6)
                }
                .padding(.horizontal)
                .padding(.top)
                
                // Chart mode picker
                Picker("Chart Mode", selection: $viewModel.chartMode) {
                    ForEach(ChartsVM.ChartMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .colorMultiply(palette.accent)
                .padding(.horizontal)
                
                if viewModel.selectedMovement != nil {
                    weightSelectionView
                }
                
                // Chart
                if let movement = viewModel.selectedMovement {
                    ScrollView {
                        MovementProgressChart(
                            movement: movement,
                            viewModel: viewModel
                        )
                    }
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "chart.bar")
                            .font(.system(size: 48))
                            .foregroundColor(palette.textSecondary)
                        Text("Select a movement to view progress")
                            .font(.headline)
                            .foregroundColor(palette.textSecondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                }
                
                Spacer()
            }
            .navigationTitle("Charts")
            .background(palette.background)
            .onAppear {
                viewModel.setModelContext(modelContext)
            }
            .onReceive(NotificationCenter.default.publisher(for: .workoutDayUpdated)) { _ in
                viewModel.loadMovements()
            }
            .sheet(isPresented: $showingMovementPicker) {
                MovementLibraryView { movement in
                    viewModel.selectedMovement = movement
                    showingMovementPicker = false
                }
            }
        }
        .background(palette.background.ignoresSafeArea())
        .tint(palette.accent)
    }
}

private extension ChartsRootView {
    var weightSelectionView: some View {
        let palette = themeManager.currentTheme
        
        return VStack(alignment: .leading, spacing: 8) {
            Text("Target Weight (lbs)")
                .font(.caption)
                .foregroundColor(palette.textSecondary)
            
            let weights = viewModel.availableWeights()
            if weights.isEmpty {
                Text("Log sets for this movement to choose a weight.")
                    .font(.footnote)
                    .foregroundColor(palette.textSecondary)
                    .padding(.vertical, 12)
            } else {
                Menu {
                    ForEach(weights, id: \.self) { weight in
                        Button(action: {
                            viewModel.targetWeight = weight
                        }) {
                            HStack {
                                Text("\(String(format: "%.1f", weight)) lbs")
                                    .foregroundColor(palette.textPrimary)
                                if abs(viewModel.targetWeight - weight) < 0.001 {
                                    Spacer()
                                    Image(systemName: "checkmark")
                                        .foregroundColor(palette.accentLight)
                                }
                            }
                        }
                    }
                } label: {
                    HStack {
                        Text("\(String(format: "%.1f", viewModel.targetWeight)) lbs")
                            .foregroundColor(palette.textPrimary)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .foregroundColor(palette.textSecondary)
                    }
                    .padding()
                    .frame(height: 44)
                    .background(palette.surface)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(palette.border, lineWidth: 1)
                    )
                }
            }
        }
        .padding(.horizontal)
    }
}


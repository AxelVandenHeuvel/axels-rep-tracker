import SwiftUI
import SwiftData

struct WorkoutDayView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var viewModel: WorkoutDayVM
    @StateObject private var templatesVM: TemplatesVM
    
    @State private var showingMovementLibrary = false
    @State private var showingTemplatePicker = false
    @State private var showingTemplateRemovalConfirmation = false
    @State private var templatePendingRemoval: WorkoutTemplate?
    
    let date: Date
    private let initialModelContext: ModelContext?
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter
    }
    
    init(date: Date, modelContext: ModelContext? = nil) {
        self.date = date
        self.initialModelContext = modelContext
        _viewModel = StateObject(wrappedValue: WorkoutDayVM(date: date, modelContext: modelContext))
        _templatesVM = StateObject(wrappedValue: TemplatesVM(modelContext: modelContext))
    }
    
    private var appliedTemplates: [WorkoutTemplate]? {
        guard let day = viewModel.workoutDay else { return nil }
        let templates = day.appliedTemplateIDs.compactMap { id in
            templatesVM.allTemplates.first { $0.id == id }
        }
        return templates.isEmpty ? nil : templates
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Header
                    VStack(alignment: .leading, spacing: 4) {
                        Text(dateFormatter.string(from: date))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(AppColors.textPrimary)
                        
                        Text("\(viewModel.totalSetsCount) sets logged")
                            .font(.subheadline)
                            .foregroundColor(AppColors.textSecondary)
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                    if let appliedTemplates = appliedTemplates, !appliedTemplates.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Applied Templates")
                                .font(.caption)
                                .foregroundColor(AppColors.textSecondary)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(appliedTemplates) { template in
                                        HStack(spacing: 6) {
                                            Circle()
                                                .fill(Color(hex: template.colorHex) ?? AppColors.accent)
                                                .frame(width: 8, height: 8)
                                            
                                            Text(template.name)
                                                .font(.subheadline)
                                                .foregroundColor(AppColors.textPrimary)
                                            
                                            Button {
                                                templatePendingRemoval = template
                                                showingTemplateRemovalConfirmation = true
                                            } label: {
                                                Image(systemName: "xmark.circle.fill")
                                                    .font(.system(size: 14))
                                                    .foregroundColor(AppColors.textSecondary)
                                            }
                                            .buttonStyle(.plain)
                                            .accessibilityLabel("Remove \(template.name)")
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background((Color(hex: template.colorHex) ?? AppColors.accent).opacity(0.15))
                                        .cornerRadius(16)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Add Movement button
                    PrimaryButton(title: "Add Movement", action: {
                        showingMovementLibrary = true
                    })
                    .padding(.horizontal)
                    
                    // Movements list
                    if let workoutDay = viewModel.workoutDay, !workoutDay.movements.isEmpty {
                        LazyVStack(spacing: 12) {
                            ForEach(workoutDay.movements) { workoutMovement in
                                MovementRowView(
                                    workoutMovement: workoutMovement,
                                    onDelete: {
                                        viewModel.removeMovement(workoutMovement)
                                    }
                                )
                                .padding(.horizontal)
                            }
                        }
                        .padding(.vertical)
                    } else {
                        // Empty state
                        VStack(spacing: 16) {
                            Text("No movements added yet")
                                .font(.headline)
                                .foregroundColor(AppColors.textPrimary)
                            
                            Text("Tap 'Add Movement' to start logging your workout")
                                .font(.subheadline)
                                .foregroundColor(AppColors.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    }
                }
            }
            .navigationTitle("Workout")
            .navigationBarTitleDisplayMode(.inline)
            .background(AppColors.background)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply Template") {
                        templatesVM.setModelContext(modelContext)
                        templatesVM.loadData()
                        if !templatesVM.allTemplates.isEmpty {
                            showingTemplatePicker = true
                        }
                    }
                    .disabled(templatesVM.allTemplates.isEmpty)
                }
            }
            .onAppear {
                if initialModelContext == nil {
                    viewModel.setModelContext(modelContext)
                    templatesVM.setModelContext(modelContext)
                }
                templatesVM.loadData()
            }
            .sheet(isPresented: $showingMovementLibrary) {
                MovementLibraryView { movement in
                    viewModel.addMovement(movement)
                    templatesVM.loadData()
                    showingMovementLibrary = false
                }
            }
            .sheet(isPresented: $showingTemplatePicker) {
                TemplatePickerView(
                    templates: templatesVM.allTemplates,
                    onSelect: { template in
                        applyTemplate(template)
                        showingTemplatePicker = false
                    }
                )
            }
            .alert("Remove Template?", isPresented: $showingTemplateRemovalConfirmation) {
                Button("Remove Movements & Template", role: .destructive) {
                    if let template = templatePendingRemoval {
                        viewModel.removeAppliedTemplate(template, shouldRemoveMovements: true)
                        templatePendingRemoval = nil
                    }
                }
                Button("Remove Template Only", role: .destructive) {
                    if let template = templatePendingRemoval {
                        viewModel.removeAppliedTemplate(template, shouldRemoveMovements: false)
                        templatePendingRemoval = nil
                    }
                }
                Button("Cancel", role: .cancel) {
                    templatePendingRemoval = nil
                }
            } message: {
                Text("Removing this template will detach it from the day. You can also remove any movements that came from this template.")
            }
        }
        .background(AppColors.background.ignoresSafeArea())
        .tint(AppColors.accent)
        .toolbarBackground(AppColors.background, for: .navigationBar)
        .toolbarColorScheme(AppColors.isDarkMode ? .dark : .light, for: .navigationBar)
    }
    
    private func applyTemplate(_ template: WorkoutTemplate) {
        guard let workoutDay = viewModel.workoutDay else { return }
        
        let movementsToAdd = templatesVM.applyTemplate(template, to: modelContext)
        
        for movement in movementsToAdd {
            // Check if already added
            if !workoutDay.movements.contains(where: { $0.movement.id == movement.id }) {
                viewModel.addMovement(movement)
            }
        }

        viewModel.markTemplateApplied(template)
    }
}

// Template picker sheet
struct TemplatePickerView: View {
    let templates: [WorkoutTemplate]
    let onSelect: (WorkoutTemplate) -> Void
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(templates) { template in
                    Button(action: {
                        onSelect(template)
                    }) {
                        HStack(spacing: 12) {
                            Circle()
                                .fill(Color(hex: template.colorHex) ?? AppColors.accent)
                                .frame(width: 16, height: 16)
                            
                            Text(template.name)
                                .foregroundColor(AppColors.textPrimary)
                        }
                    }
                }
            }
            .navigationTitle("Select Template")
            .navigationBarTitleDisplayMode(.inline)
            .scrollContentBackground(.hidden)
            .background(AppColors.background)
        }
    }
}


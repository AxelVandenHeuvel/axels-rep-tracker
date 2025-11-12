import SwiftUI
import SwiftData

struct TemplateEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var viewModel: TemplatesVM
    @Bindable var template: WorkoutTemplate
    
    @State private var nameText: String
    @State private var showingMovementPicker = false
    @State private var selectedColorHex: String
    
    init(template: WorkoutTemplate, viewModel: TemplatesVM) {
        self.template = template
        _viewModel = StateObject(wrappedValue: viewModel)
        _nameText = State(initialValue: template.name)
        _selectedColorHex = State(initialValue: template.colorHex)
    }
    
    var templateMovements: [Movement] {
        viewModel.getMovements(for: template)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Template Name") {
                    TextField("Template name", text: $nameText)
                        .foregroundColor(AppColors.textPrimary)
                }

                Section("Template Color") {
                    let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 5)
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(TemplatesVM.colorOptions, id: \.self) { hex in
                            Button(action: {
                                selectedColorHex = hex
                            }) {
                                Circle()
                                    .fill(Color(hex: hex) ?? AppColors.accent)
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Circle()
                                            .stroke(
                                                selectedColorHex == hex ? AppColors.textPrimary : Color.clear,
                                                lineWidth: 2
                                            )
                                    )
                                    .overlay(
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(.white)
                                            .opacity(selectedColorHex == hex ? 1 : 0)
                                    )
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(Text("Select color \(hex)"))
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                Section("Movements") {
                    if templateMovements.isEmpty {
                        Text("No movements added")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(templateMovements) { movement in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(movement.name)
                                    MovementTagPills(tags: movement.tags)
                                }
                                Spacer()
                            }
                        }
                        .onDelete { indexSet in
                            deleteMovements(at: indexSet)
                        }
                    }
                    
                    Button(action: {
                        showingMovementPicker = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.blue)
                            Text("Add Movement")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .navigationTitle("Edit Template")
            .navigationBarTitleDisplayMode(.inline)
            .scrollContentBackground(.hidden)
            .background(AppColors.background)
            .tint(AppColors.accent)
            .toolbarBackground(AppColors.background, for: .navigationBar)
            .toolbarColorScheme(AppColors.isDarkMode ? .dark : .light, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        save()
                    }
                }
                
                ToolbarItem(placement: .bottomBar) {
                    Button(role: .destructive, action: {
                        deleteTemplate()
                    }) {
                        Label("Delete Template", systemImage: "trash")
                    }
                }
            }
            .sheet(isPresented: $showingMovementPicker) {
                MovementLibraryView { movement in
                    addMovement(movement)
                    showingMovementPicker = false
                }
                .onDisappear {
                    viewModel.loadData()
                }
            }
        }
    }
    
    private func save() {
        viewModel.updateTemplate(template, name: nameText, colorHex: selectedColorHex)
        dismiss()
    }
    
    private func addMovement(_ movement: Movement) {
        var currentIDs = template.movementIDs
        if !currentIDs.contains(movement.id) {
            currentIDs.append(movement.id)
            viewModel.updateTemplate(template, movementIDs: currentIDs)
        }
    }
    
    private func deleteMovements(at offsets: IndexSet) {
        var currentIDs = template.movementIDs
        let movements = templateMovements
        for index in offsets {
            if index < movements.count {
                let movementID = movements[index].id
                currentIDs.removeAll { $0 == movementID }
            }
        }
        viewModel.updateTemplate(template, movementIDs: currentIDs)
    }
    
    private func deleteTemplate() {
        viewModel.deleteTemplate(template)
        dismiss()
    }
}


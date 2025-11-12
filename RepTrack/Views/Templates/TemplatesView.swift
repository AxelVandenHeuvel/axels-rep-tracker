import SwiftUI
import SwiftData

struct TemplatesView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = TemplatesVM()
    @State private var showingCreateTemplate = false
    @State private var newTemplateName = ""
    @State private var newTemplateColorHex = TemplatesVM.colorOptions.first ?? "#4D96FF"
    @State private var selectedTemplate: WorkoutTemplate?
    @State private var showingDeleteConfirmation = false
    @State private var templatePendingDeletion: WorkoutTemplate?
    
    var body: some View {
        NavigationStack {
            templateList
                .navigationTitle("Templates")
                .scrollContentBackground(.hidden)
                .background(AppColors.background)
                .listStyle(.insetGrouped)
                .listRowSeparator(.hidden)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            showingCreateTemplate = true
                        }) {
                            Image(systemName: "plus")
                        }
                        .accessibilityLabel("Create Template")
                    }
                }
        }
        .background(AppColors.background.ignoresSafeArea())
        .tint(AppColors.accent)
        .toolbarBackground(AppColors.background, for: .navigationBar)
        .toolbarColorScheme(AppColors.isDarkMode ? .dark : .light, for: .navigationBar)
        .onAppear {
            viewModel.setModelContext(modelContext)
        }
        .alert("Delete Template?", isPresented: $showingDeleteConfirmation, presenting: templatePendingDeletion) { template in
                deleteButtons(for: template)
        } message: { template in
            Text("Removing \(template.name) deletes it from the library. You can optionally remove its movements from any workout days.")
        }
        .sheet(isPresented: $showingCreateTemplate) {
            CreateTemplateSheet(
                name: $newTemplateName,
                selectedColorHex: $newTemplateColorHex,
                colorOptions: TemplatesVM.colorOptions,
                onSave: {
                    createTemplate()
                },
                onCancel: {
                    newTemplateName = ""
                    newTemplateColorHex = TemplatesVM.colorOptions.first ?? "#4D96FF"
                    showingCreateTemplate = false
                }
            )
        }
    }
    
    private var templateList: some View {
        List {
            if viewModel.allTemplates.isEmpty {
                emptyTemplatesView
                    .listRowSeparator(.hidden)
            } else {
                templateRows(viewModel.allTemplates)
            }
        }
    }
    
    @ViewBuilder
    private func templateRows(_ templates: [WorkoutTemplate]) -> some View {
        ForEach(templates) { template in
            NavigationLink(destination: TemplateEditorView(template: template, viewModel: viewModel)) {
                templateRowContent(
                    name: template.name,
                    colorHex: template.colorHex,
                    movementCount: viewModel.getMovements(for: template).count
                )
            }
            .listRowBackground(AppColors.surface)
        }
        .onDelete { indexSet in
            handleDeletion(at: indexSet, templates: templates)
        }
    }
    
    private var emptyTemplatesView: some View {
        VStack(spacing: 16) {
            Text("No templates yet")
                .font(.headline)
                .foregroundColor(AppColors.textPrimary)
            
            Text("Create a template to quickly apply a set of movements to your workout")
                .font(.subheadline)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    @ViewBuilder
    private func deleteButtons(for template: WorkoutTemplate) -> some View {
        Button("Remove Movements & Delete", role: .destructive) {
            viewModel.deleteTemplateAndDetachMovements(template, removeMovementsFromDays: true)
            templatePendingDeletion = nil
        }
        Button("Delete Template Only", role: .destructive) {
            viewModel.deleteTemplateAndDetachMovements(template, removeMovementsFromDays: false)
            templatePendingDeletion = nil
        }
        Button("Cancel", role: .cancel) {
            templatePendingDeletion = nil
        }
    }
    
    private func createTemplate() {
        let trimmedName = newTemplateName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        if let template = viewModel.createTemplate(
            name: trimmedName,
            movementIDs: [],
            colorHex: newTemplateColorHex
        ) {
            newTemplateName = ""
            newTemplateColorHex = TemplatesVM.colorOptions.first ?? "#4D96FF"
            showingCreateTemplate = false
            selectedTemplate = template
        }
    }
    
    private func handleDeletion(at offsets: IndexSet, templates: [WorkoutTemplate]) {
        guard let index = offsets.first, index < templates.count else { return }
        templatePendingDeletion = templates[index]
        showingDeleteConfirmation = true
    }
    
    private func templateRowContent(name: String, colorHex: String, movementCount: Int) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color(hex: colorHex) ?? AppColors.accent)
                .frame(width: 16, height: 16)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.headline)
                    .foregroundColor(AppColors.textPrimary)
                
                Text(
                    movementCount == 0
                        ? "No movements"
                        : "\(movementCount) movement\(movementCount == 1 ? "" : "s")"
                )
                .font(.caption)
                .foregroundColor(AppColors.textSecondary)
            }
        }
    }
}

// Create template sheet
struct CreateTemplateSheet: View {
    @Binding var name: String
    @Binding var selectedColorHex: String
    let colorOptions: [String]
    let onSave: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Template Name") {
                    TextField("Template name", text: $name)
                        .foregroundColor(AppColors.textPrimary)
                }

                Section("Template Color") {
                    let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 5)
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(colorOptions, id: \.self) { hex in
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
            }
            .navigationTitle("New Template")
            .navigationBarTitleDisplayMode(.inline)
            .scrollContentBackground(.hidden)
            .background(AppColors.background)
            .tint(AppColors.accent)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        onSave()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}


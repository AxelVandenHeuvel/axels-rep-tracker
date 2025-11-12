import SwiftUI
import SwiftData

struct MovementLibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var viewModel = MovementLibraryVM()
    @State private var showingTagFilter = false
    @State private var showingCreateNew = false
    @State private var newMovementName = ""
    @State private var newMovementTags: Set<String> = []
    @State private var showingDuplicateAlert = false
    @State private var duplicateMovement: Movement?
    @State private var movementPendingDeletion: Movement?
    @State private var showingDeleteConfirmation = false
    
    let onSelect: (Movement) -> Void
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(AppColors.textSecondary)
                    TextField("Search movements", text: $viewModel.searchText)
                        .textFieldStyle(.plain)
                        .foregroundColor(AppColors.textPrimary)
                }
                .padding()
                .background(AppColors.surface)
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.top)
                
                // Tag filter button
                if !viewModel.selectedTags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(Array(viewModel.selectedTags), id: \.self) { tag in
                                HStack {
                                    Text(tag)
                                        .foregroundColor(AppColors.textPrimary)
                                    Button(action: {
                                        viewModel.toggleTag(tag)
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(AppColors.textSecondary)
                                    }
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(AppColors.accent.opacity(0.2))
                                .foregroundColor(AppColors.textPrimary)
                                .cornerRadius(16)
                            }
                            
                            Button("Clear") {
                                viewModel.clearFilters()
                            }
                            .foregroundColor(AppColors.accentLight)
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 8)
                }
                
                // Sections
                List {
                    // Select Existing section
                    Section {
                        if viewModel.filteredMovements.isEmpty {
                            Text("No movements found")
                                .foregroundColor(AppColors.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding()
                                .listRowBackground(AppColors.surface)
                        } else {
                            ForEach(viewModel.filteredMovements) { movement in
                                Button(action: {
                                    onSelect(movement)
                                }) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(movement.name)
                                            .foregroundColor(AppColors.textPrimary)
                                        MovementTagPills(tags: movement.tags)
                                    }
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        movementPendingDeletion = movement
                                        showingDeleteConfirmation = true
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                                .listRowBackground(AppColors.surface)
                            }
                        }
                    } header: {
                        HStack {
                            Text("Select Existing")
                                .foregroundColor(AppColors.textSecondary)
                            Spacer()
                            Button(action: {
                                showingTagFilter = true
                            }) {
                                Text("Filter Tags")
                                    .font(.caption)
                                    .foregroundColor(AppColors.accentLight)
                            }
                        }
                    }
                    
                    // Create New section
                    Section {
                        Button(action: {
                            showingCreateNew = true
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(AppColors.accentLight)
                                Text("Create New Movement")
                                    .foregroundColor(AppColors.accentLight)
                            }
                        }
                        .listRowBackground(AppColors.surface)
                    } header: {
                        Text("Create New")
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
                .scrollContentBackground(.hidden)
                .background(AppColors.background)
                .listStyle(.plain)
            }
            .navigationTitle("Movement Library")
            .navigationBarTitleDisplayMode(.inline)
            .background(AppColors.background)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                viewModel.setModelContext(modelContext)
            }
            .sheet(isPresented: $showingTagFilter) {
                TagFilterSheet(
                    selectedTags: $viewModel.selectedTags,
                    onApply: {
                        showingTagFilter = false
                    }
                )
            }
            .sheet(isPresented: $showingCreateNew) {
                CreateMovementSheet(
                    name: $newMovementName,
                    selectedTags: $newMovementTags,
                    onSave: {
                        saveNewMovement()
                    },
                    onCancel: {
                        newMovementName = ""
                        newMovementTags.removeAll()
                        showingCreateNew = false
                    }
                )
            }
            .alert("Movement Already Exists", isPresented: $showingDuplicateAlert) {
                Button("Use Existing") {
                    if let existing = duplicateMovement {
                        onSelect(existing)
                        showingDuplicateAlert = false
                    }
                }
                Button("Save as New", role: .cancel) {
                    // Force create with same name
                    createMovementForce()
                }
            } message: {
                Text("A movement with this name already exists. Would you like to use the existing one or save as a new movement?")
            }
            .alert("Delete Movement?", isPresented: $showingDeleteConfirmation, presenting: movementPendingDeletion) { movement in
                Button("Delete", role: .destructive) {
                    viewModel.deleteMovement(movement)
                    movementPendingDeletion = nil
                }
                Button("Cancel", role: .cancel) {
                    movementPendingDeletion = nil
                }
            } message: { movement in
                Text("This will remove \(movement.name) from all workout days and templates.")
            }
        }
        .background(AppColors.background.ignoresSafeArea())
        .tint(AppColors.accent)
        .toolbarBackground(AppColors.background, for: .navigationBar)
        .toolbarColorScheme(AppColors.isDarkMode ? .dark : .light, for: .navigationBar)
    }
    
    private func saveNewMovement() {
        let trimmedName = newMovementName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        // Check for duplicate
        let existing = viewModel.allMovements.first { movement in
            movement.name.localizedCaseInsensitiveCompare(trimmedName) == .orderedSame
        }
        
        if let existing = existing {
            duplicateMovement = existing
            showingDuplicateAlert = true
            return
        }
        
        createMovementForce()
    }
    
    private func createMovementForce() {
        if let movement = viewModel.createMovement(name: newMovementName, tags: Array(newMovementTags)) {
            onSelect(movement)
            newMovementName = ""
            newMovementTags.removeAll()
            showingCreateNew = false
        }
    }
}

// Tag filter sheet
struct TagFilterSheet: View {
    @Binding var selectedTags: Set<String>
    let onApply: () -> Void
    
    let presetTags = MovementLibraryVM.presetTags
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(presetTags, id: \.self) { tag in
                    Button(action: {
                        if selectedTags.contains(tag) {
                            selectedTags.remove(tag)
                        } else {
                            selectedTags.insert(tag)
                        }
                    }) {
                        HStack {
                            Text(tag)
                                .foregroundColor(AppColors.textPrimary)
                            Spacer()
                            if selectedTags.contains(tag) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(AppColors.accentLight)
                            }
                        }
                    }
                    .listRowBackground(AppColors.surface)
                }
            }
            .navigationTitle("Filter by Tags")
            .navigationBarTitleDisplayMode(.inline)
            .scrollContentBackground(.hidden)
            .background(AppColors.background)
            .tint(AppColors.accent)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        onApply()
                    }
                }
            }
        }
    }
}

// Create movement sheet
struct CreateMovementSheet: View {
    @Binding var name: String
    @Binding var selectedTags: Set<String>
    let onSave: () -> Void
    let onCancel: () -> Void
    
    let presetTags = MovementLibraryVM.presetTags
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Movement name", text: $name)
                        .foregroundColor(AppColors.textPrimary)
                }
                
                Section("Tags") {
                    TagSelectionView(selectedTags: $selectedTags)
                }
            }
            .navigationTitle("New Movement")
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
                    Button("Save") {
                        onSave()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}


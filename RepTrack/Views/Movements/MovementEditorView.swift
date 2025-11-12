import SwiftUI
import SwiftData

struct MovementEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Bindable var movement: Movement
    @State private var nameText: String
    @State private var selectedTags: Set<String>
    
    init(movement: Movement) {
        self.movement = movement
        _nameText = State(initialValue: movement.name)
        _selectedTags = State(initialValue: Set(movement.tags))
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Movement name", text: $nameText)
                        .foregroundColor(AppColors.textPrimary)
                }
                
                Section("Tags") {
                    TagSelectionView(selectedTags: $selectedTags)
                }
            }
            .navigationTitle("Edit Movement")
            .navigationBarTitleDisplayMode(.inline)
            .scrollContentBackground(.hidden)
            .background(AppColors.background)
            .tint(AppColors.accent)
            .toolbarBackground(AppColors.background, for: .navigationBar)
            .toolbarColorScheme(AppColors.isDarkMode ? .dark : .light, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        save()
                    }
                }
            }
        }
    }
    
    private func save() {
        movement.name = nameText.trimmingCharacters(in: .whitespacesAndNewlines)
        movement.tags = Array(selectedTags)
        try? modelContext.save()
        dismiss()
    }
}

// Tag selection helper view
struct TagSelectionView: View {
    @Binding var selectedTags: Set<String>
    
    let presetTags = MovementLibraryVM.presetTags
    
    var body: some View {
        let columns = [
            GridItem(.adaptive(minimum: 90), spacing: 8)
        ]
        
        LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
            ForEach(presetTags, id: \.self) { tag in
                Button(action: {
                    if selectedTags.contains(tag) {
                        selectedTags.remove(tag)
                    } else {
                        selectedTags.insert(tag)
                    }
                }) {
                    Text(tag)
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .background(
                            Capsule()
                                .fill(selectedTags.contains(tag) ? AppColors.accent : AppColors.muted)
                        )
                        .foregroundColor(AppColors.textPrimary)
                        .overlay(
                            Capsule()
                                .stroke(AppColors.accent.opacity(selectedTags.contains(tag) ? 0.8 : 0.3), lineWidth: 1)
                        )
                        .cornerRadius(16)
                }
                .buttonStyle(.plain)
            }
        }
    }
}


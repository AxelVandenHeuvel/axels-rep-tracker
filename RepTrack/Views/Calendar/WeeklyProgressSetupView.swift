import SwiftUI

struct WeeklyProgressSetupView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var calendarVM: CalendarVM
    @StateObject private var templatesVM = TemplatesVM()
    
    @State private var rows: [EditableRow] = []
    @State private var modelContextSet = false
    
    private let minimumTarget = 1
    private let maximumTarget = 10
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Weekly Goals") {
                    if templatesVM.allTemplates.isEmpty {
                        Text("Create templates first to set weekly goals.")
                            .foregroundColor(AppColors.textSecondary)
                    } else {
                        ForEach(rows) { row in
                            WeeklyTargetRow(
                                row: binding(for: row.id),
                                templates: availableTemplates(for: row.id),
                                minimumTarget: minimumTarget,
                                maximumTarget: maximumTarget,
                                onRemove: { removeRow(with: row.id) }
                            )
                        }
                        
                        if rows.count < 4 {
                            Button {
                                addRow()
                            } label: {
                                Label("Add Template Goal", systemImage: "plus.circle.fill")
                            }
                            .disabled(remainingTemplateOptions.isEmpty)
                        }
                    }
                }
                
                Section {
                    Text("Choose up to four templates and set how many times you want to apply each during the current week.")
                        .font(.footnote)
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.leading)
                }
            }
            .navigationTitle("Weekly Goals")
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
                    .disabled(!hasValidConfiguration)
                }
            }
            .onAppear {
                guard !modelContextSet else { return }
                if let context = calendarVM.modelContext {
                    templatesVM.setModelContext(context)
                    modelContextSet = true
                }
                templatesVM.loadData()
                if rows.isEmpty {
                    rows = calendarVM.weeklyTargets.map { EditableRow(target: $0) }
                    if rows.isEmpty {
                        addRow()
                    }
                }
            }
        }
        .background(AppColors.background.ignoresSafeArea())
    }
    
    private var hasValidConfiguration: Bool {
        rows.contains { row in
            row.templateID != nil && row.targetCount >= minimumTarget
        }
    }
    
    private func binding(for id: UUID) -> Binding<EditableRow> {
        Binding<EditableRow>(
            get: {
                rows.first { $0.id == id } ?? EditableRow(templateID: nil, targetCount: minimumTarget)
            },
            set: { newValue in
                if let index = rows.firstIndex(where: { $0.id == id }) {
                    rows[index] = newValue
                }
            }
        )
    }
    
    private func availableTemplates(for rowID: UUID) -> [WorkoutTemplate] {
        let selectedIDs = Set(rows.compactMap { row -> UUID? in
            if row.id == rowID { return nil }
            return row.templateID
        })
        var options = templatesVM.allTemplates
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            .filter { !selectedIDs.contains($0.id) }
        
        if
            let currentTemplateID = rows.first(where: { $0.id == rowID })?.templateID,
            !options.contains(where: { $0.id == currentTemplateID }),
            let currentTemplate = templatesVM.allTemplates.first(where: { $0.id == currentTemplateID })
        {
            options.insert(currentTemplate, at: 0)
        }
        
        return options
    }
    
    private func addRow() {
        guard rows.count < 4, !remainingTemplateOptions.isEmpty else { return }
        rows.append(EditableRow(templateID: nil, targetCount: minimumTarget))
    }
    
    private func removeRow(with id: UUID) {
        rows.removeAll { $0.id == id }
        if rows.isEmpty {
            addRow()
        }
    }
    
    private func save() {
        let validTargets = rows.compactMap { row -> CalendarVM.WeeklyAttendanceTarget? in
            guard let templateID = row.templateID, row.targetCount >= minimumTarget else { return nil }
            return CalendarVM.WeeklyAttendanceTarget(id: row.id, templateID: templateID, targetCount: row.targetCount)
        }
        calendarVM.updateWeeklyTargets(validTargets)
        dismiss()
    }
    
    private var remainingTemplateOptions: [WorkoutTemplate] {
        let selectedIDs = Set(rows.compactMap { $0.templateID })
        return templatesVM.allTemplates.filter { !selectedIDs.contains($0.id) }
    }
    
    struct EditableRow: Identifiable, Equatable {
        var id: UUID
        var templateID: UUID?
        var targetCount: Int
        
        init(id: UUID = UUID(), templateID: UUID?, targetCount: Int) {
            self.id = id
            self.templateID = templateID
            self.targetCount = targetCount
        }
        
        init(target: CalendarVM.WeeklyAttendanceTarget) {
            self.id = target.id
            self.templateID = target.templateID
            self.targetCount = target.targetCount
        }
    }
}

private struct WeeklyTargetRow: View {
    @Binding var row: WeeklyProgressSetupView.EditableRow
    let templates: [WorkoutTemplate]
    let minimumTarget: Int
    let maximumTarget: Int
    let onRemove: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Picker("Template", selection: Binding(get: {
                row.templateID
            }, set: { newValue in
                row.templateID = newValue
            })) {
                Text("Select Template").tag(nil as UUID?)
                ForEach(templates) { template in
                    Text(template.name).tag(Optional(template.id))
                }
            }
            .pickerStyle(.menu)
            
            Stepper(value: $row.targetCount, in: minimumTarget...maximumTarget) {
                Text("Target: \(row.targetCount)")
                    .foregroundColor(AppColors.textPrimary)
            }
            
            if templates.count > 1 || row.templateID != nil {
                Button("Remove", role: .destructive, action: onRemove)
                    .font(.caption)
            }
        }
        .padding(.vertical, 4)
    }
}



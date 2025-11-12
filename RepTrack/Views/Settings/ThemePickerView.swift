import SwiftUI

struct ThemePickerView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(themeManager.availableThemes) { theme in
                        Button(action: {
                            themeManager.select(theme)
                        }) {
                            ThemeRow(theme: theme, isSelected: theme.id == themeManager.selectedThemeID)
                        }
                        .buttonStyle(.plain)
                    }
                } footer: {
                    Text("Changes apply instantly across the app.")
                        .font(.footnote)
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            .navigationTitle("Color Theme")
            .navigationBarTitleDisplayMode(.inline)
            .scrollContentBackground(.hidden)
            .background(AppColors.background.ignoresSafeArea())
            .tint(AppColors.accent)
            .toolbarBackground(AppColors.background, for: .navigationBar)
            .toolbarColorScheme(AppColors.isDarkMode ? .dark : .light, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct ThemeRow: View {
    let theme: AppThemePalette
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            themePreview
            
            VStack(alignment: .leading, spacing: 4) {
                Text(theme.displayName)
                    .font(.headline)
                    .foregroundColor(AppColors.textPrimary)
                Text(theme.description)
                    .font(.subheadline)
                    .foregroundColor(AppColors.textSecondary)
            }
            
            Spacer()
            
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(AppColors.accent)
            }
        }
        .padding(.vertical, 10)
    }
    
    private var themePreview: some View {
        HStack(spacing: 4) {
            previewBlock(color: theme.background)
            previewBlock(color: theme.surface)
            previewBlock(color: theme.accent)
        }
        .frame(width: 54, height: 32)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(AppColors.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(AppColors.border, lineWidth: 1)
        )
    }
    
    private func previewBlock(color: Color) -> some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(color)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(AppColors.border.opacity(0.4), lineWidth: 0.5)
            )
    }
}



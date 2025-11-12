import SwiftUI

struct WeeklyProgressView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @ObservedObject var viewModel: CalendarVM
    let onConfigure: () -> Void
    
    var body: some View {
        let theme = themeManager.currentTheme
        
        VStack(alignment: .leading, spacing: 16) {
            header
            
            if viewModel.isWeeklyProgressConfigured {
                if viewModel.weeklySummaries.isEmpty {
                    Text("No progress tracked yet. Apply templates this week to see updates.")
                        .font(.subheadline)
                        .foregroundColor(theme.textSecondary)
                } else {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(viewModel.weeklySummaries) { summary in
                            WeeklyProgressRow(summary: summary)
                        }
                    }
                }
                
                PrimaryButton(title: "Edit Weekly Goals", action: onConfigure)
                    .padding(.top, 4)
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    Text("No weekly goals yet")
                        .font(.headline)
                        .foregroundColor(theme.textPrimary)
                    Text("Set targets for how many templates you want to complete this week. Track your attendance automatically.")
                        .font(.subheadline)
                        .foregroundColor(theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                PrimaryButton(title: "Set Weekly Goals", action: onConfigure)
                    .padding(.top, 4)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(theme.surfaceElevated)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(theme.border, lineWidth: 1)
        )
        .shadow(color: theme.accent.opacity(0.08), radius: 12, x: 0, y: 6)
    }
    
    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Weekly Progress")
                    .font(.headline)
                    .foregroundColor(themeManager.currentTheme.textPrimary)
                Text("Track template attendance this week")
                    .font(.subheadline)
                    .foregroundColor(themeManager.currentTheme.textSecondary)
            }
            Spacer()
        }
    }
}

private struct WeeklyProgressRow: View {
    @EnvironmentObject private var themeManager: ThemeManager
    let summary: CalendarVM.WeeklyAttendanceSummary
    
    var body: some View {
        let theme = themeManager.currentTheme
        
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color(hex: summary.templateColorHex) ?? theme.accent)
                        .frame(width: 8, height: 8)
                    Text(summary.templateName)
                        .foregroundColor(theme.textPrimary)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                Text("\(summary.completedCount)/\(summary.targetCount)")
                    .foregroundColor(theme.textSecondary)
                    .font(.subheadline)
            }
            
            ProgressView(value: summary.progress)
                .progressViewStyle(.linear)
                .tint(Color(hex: summary.templateColorHex) ?? theme.accent)
            
            HStack {
                if summary.remainingCount > 0 {
                    Text("\(summary.remainingCount) left this week")
                        .font(.caption)
                        .foregroundColor(theme.textSecondary)
                } else {
                    Text("Goal reached! Great work.")
                        .font(.caption)
                        .foregroundColor(theme.accentLight)
                }
                Spacer()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(theme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(theme.border, lineWidth: 1)
        )
    }
}



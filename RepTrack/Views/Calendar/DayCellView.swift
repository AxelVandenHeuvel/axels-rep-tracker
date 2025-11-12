import SwiftUI

struct DayCellView: View {
    let date: Date
    let isToday: Bool
    let hasLoggedSets: Bool
    let templateColor: Color?
    let isCurrentMonth: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.system(size: 16, weight: isToday ? .bold : .medium))
                    .foregroundColor(textColor)
                
                if hasLoggedSets {
                    Circle()
                        .fill(isToday ? AppColors.textPrimary : (templateColor ?? AppColors.accent))
                        .frame(width: 6, height: 6)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .frame(height: 44)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(backgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isToday ? AppColors.accentLight.opacity(0.6) : AppColors.border, lineWidth: isToday ? 1.5 : 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Day \(Calendar.current.component(.day, from: date))")
    }
    
    private var backgroundColor: Color {
        if isToday {
            return AppColors.accent
        }
        if let templateColor {
            return templateColor.opacity(0.28)
        }
        return isCurrentMonth ? AppColors.surface.opacity(0.6) : AppColors.surface.opacity(0.3)
    }
    
    private var textColor: Color {
        if isToday {
            return AppColors.textPrimary
        }
        if !isCurrentMonth {
            return AppColors.textSecondary.opacity(0.4)
        }
        return AppColors.textPrimary
    }
}


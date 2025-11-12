import SwiftUI

struct MonthHeaderView: View {
    let month: Date
    let onPrevious: () -> Void
    let onNext: () -> Void
    
    private var monthFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }
    
    var body: some View {
        HStack {
            Button(action: onPrevious) {
                Image(systemName: "chevron.left")
                    .font(.headline)
                    .foregroundColor(AppColors.textPrimary)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(AppColors.surface)
                            .overlay(
                                Circle()
                                    .stroke(AppColors.border, lineWidth: 1)
                            )
                    )
            }
            .accessibilityLabel("Previous month")
            
            Spacer()
            
            Text(monthFormatter.string(from: month))
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(AppColors.textPrimary)
            
            Spacer()
            
            Button(action: onNext) {
                Image(systemName: "chevron.right")
                    .font(.headline)
                    .foregroundColor(AppColors.textPrimary)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(AppColors.surface)
                            .overlay(
                                Circle()
                                    .stroke(AppColors.border, lineWidth: 1)
                            )
                    )
            }
            .accessibilityLabel("Next month")
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
}


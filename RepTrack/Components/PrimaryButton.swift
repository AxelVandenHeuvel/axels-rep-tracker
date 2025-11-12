import SwiftUI

struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundColor(AppColors.textPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(
                    LinearGradient(
                        colors: [AppColors.accent, AppColors.accentDark],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(AppColors.accentLight.opacity(0.4), lineWidth: 1)
                )
                .cornerRadius(14)
                .shadow(color: AppColors.accent.opacity(0.35), radius: 12, x: 0, y: 8)
        }
        .buttonStyle(.plain)
    }
}


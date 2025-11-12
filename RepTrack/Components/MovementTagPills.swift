import SwiftUI

struct MovementTagPills: View {
    let tags: [String]
    
    var body: some View {
        if !tags.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(tags, id: \.self) { tag in
                        Text(tag)
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(AppColors.accent.opacity(0.18))
                            )
                            .overlay(
                                Capsule()
                                    .stroke(AppColors.accent.opacity(0.4), lineWidth: 1)
                            )
                            .foregroundColor(AppColors.textPrimary)
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }
}


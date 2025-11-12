import SwiftUI

struct SetEditorRow: View {
    @AppStorage("showRPE") private var showRPE = false
    
    @Binding var weightText: String
    @Binding var repsText: String
    @Binding var rpeText: String
    @State private var showRPEField = false
    
    let onAdd: () -> Void
    let isValid: Bool
    let lastWeight: Double?
    let lastReps: Int?
    let lastRPE: Double?
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // Weight field
                VStack(alignment: .leading, spacing: 4) {
                    Text("Weight")
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                    TextField("0", text: $weightText)
                        .keyboardType(.decimalPad)
                        .padding(.horizontal)
                        .frame(height: 44)
                        .background(AppColors.surface)
                        .cornerRadius(10)
                        .foregroundColor(AppColors.textPrimary)
                }
                
                // Reps field
                VStack(alignment: .leading, spacing: 4) {
                    Text("Reps")
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                    TextField("0", text: $repsText)
                        .keyboardType(.numberPad)
                        .padding(.horizontal)
                        .frame(height: 44)
                        .background(AppColors.surface)
                        .cornerRadius(10)
                        .foregroundColor(AppColors.textPrimary)
                        .onSubmit {
                            if isValid {
                                onAdd()
                            }
                        }
                }
            }
            
            // RPE field (if enabled)
            if showRPE && showRPEField {
                VStack(alignment: .leading, spacing: 4) {
                    Text("RPE")
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                    TextField("0", text: $rpeText)
                        .keyboardType(.decimalPad)
                        .padding(.horizontal)
                        .frame(height: 44)
                        .background(AppColors.surface)
                        .cornerRadius(10)
                        .foregroundColor(AppColors.textPrimary)
                }
            }
            
            // RPE toggle button
            if showRPE {
                Button(action: { showRPEField.toggle() }) {
                    HStack {
                        Image(systemName: showRPEField ? "chevron.up" : "chevron.down")
                        Text("RPE")
                    }
                    .font(.caption)
                    .foregroundColor(AppColors.accentLight)
                }
            }
            
            // Add Set button
            PrimaryButton(title: "Add Set", action: onAdd)
                .disabled(!isValid)
                .opacity(isValid ? 1.0 : 0.5)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppColors.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppColors.border, lineWidth: 1)
        )
    }
}


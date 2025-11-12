import SwiftUI
import Charts

struct MovementProgressChart: View {
    @EnvironmentObject private var themeManager: ThemeManager
    let movement: Movement
    @ObservedObject var viewModel: ChartsVM
    
    var body: some View {
        let palette = themeManager.currentTheme
        
        VStack(alignment: .leading, spacing: 16) {
            Text(movement.name)
                .font(.headline)
                .foregroundColor(palette.textPrimary)
            
            MovementTagPills(tags: movement.tags)
            
            Text(chartSubtitle)
                .font(.subheadline)
                .foregroundColor(palette.textSecondary)
            
            switch viewModel.chartMode {
            case .topSetRepsAtWeight:
                repsChart(
                    emptyMessage: "No top sets found at \(formattedWeight) lbs. Mark a set as the top set to track it here.",
                    data: viewModel.getTopSetRepsAtWeight()
                )
            case .averageRepsAtWeight:
                repsChart(
                    emptyMessage: "No sets at \(formattedWeight) lbs yet. Log sets to see an average.",
                    data: viewModel.getAverageRepsAtWeight()
                )
            case .volumeAtWeight:
                volumeChart
            }
        }
        .id(viewModel.refreshToken)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(palette.surfaceElevated)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(palette.border, lineWidth: 1)
        )
        .shadow(color: palette.accent.opacity(0.12), radius: 8, x: 0, y: 6)
    }
    
    @ViewBuilder
    private var volumeChart: some View {
        let data = viewModel.getVolumeAtWeight()
        
        if data.isEmpty {
            emptyChartView(message: "No volume logged at \(formattedWeight) lbs yet.")
        } else {
            Chart(data, id: \.date) { item in
                LineMark(
                    x: .value("Date", item.date, unit: .day),
                    y: .value("Volume", item.value)
                )
                .foregroundStyle(themeManager.currentTheme.accent)
                .interpolationMethod(.catmullRom)
                
                PointMark(
                    x: .value("Date", item.date, unit: .day),
                    y: .value("Volume", item.value)
                )
                .foregroundStyle(themeManager.currentTheme.accentLight)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 7)) { _ in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.month().day())
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let doubleValue = value.as(Double.self) {
                            Text("\(Int(doubleValue))")
                        }
                    }
                }
            }
            .frame(height: 250)
        }
    }
    
    @ViewBuilder
    private func repsChart(emptyMessage: String, data: [(date: Date, value: Double)]) -> some View {
        if data.isEmpty {
            emptyChartView(message: emptyMessage)
        } else {
            Chart(data, id: \.date) { item in
                LineMark(
                    x: .value("Date", item.date, unit: .day),
                    y: .value("Reps", item.value)
                )
                .foregroundStyle(themeManager.currentTheme.accent)
                .interpolationMethod(.catmullRom)
                
                PointMark(
                    x: .value("Date", item.date, unit: .day),
                    y: .value("Reps", item.value)
                )
                .foregroundStyle(themeManager.currentTheme.accentLight)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 7)) { _ in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.month().day())
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine()
                    AxisValueLabel()
                }
            }
            .frame(height: 250)
        }
    }
    
    private func emptyChartView(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 48))
                .foregroundColor(themeManager.currentTheme.textSecondary)
            Text("Not enough data yet")
                .font(.headline)
                .foregroundColor(themeManager.currentTheme.textSecondary)
            Text(message)
                .font(.subheadline)
                .foregroundColor(themeManager.currentTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    private var formattedWeight: String {
        "\(String(format: "%.1f", viewModel.targetWeight))"
    }
    
    private var chartSubtitle: String {
        switch viewModel.chartMode {
        case .topSetRepsAtWeight:
            return "Top set reps at \(formattedWeight) lbs"
        case .averageRepsAtWeight:
            return "Average reps at \(formattedWeight) lbs"
        case .volumeAtWeight:
            return "Total volume at \(formattedWeight) lbs"
        }
    }
}


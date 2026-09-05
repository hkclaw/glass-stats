import Charts
import SwiftUI

struct UsageChart: View {
    var points: [HistoryPoint]
    var keyPath: KeyPath<HistoryPoint, Double>
    var tint: Color

    var body: some View {
        Chart(points) { point in
            AreaMark(
                x: .value("Time", point.date),
                y: .value("Usage", point[keyPath: keyPath])
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [tint.opacity(0.35), tint.opacity(0.02)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .interpolationMethod(.catmullRom)

            LineMark(
                x: .value("Time", point.date),
                y: .value("Usage", point[keyPath: keyPath])
            )
            .foregroundStyle(tint)
            .interpolationMethod(.catmullRom)
            .lineStyle(StrokeStyle(lineWidth: 1.6, lineCap: .round))
        }
        .chartXAxis(.hidden)
        .chartYScale(domain: 0...1)
        .chartYAxis {
            AxisMarks(position: .leading, values: [0, 0.5, 1]) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.4))
                    .foregroundStyle(Color.secondary.opacity(0.25))
                if let fraction = value.as(Double.self) {
                    AxisValueLabel {
                        Text(Formatters.percent(fraction))
                            .font(.system(size: 9, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .frame(height: 72)
        .overlay {
            if points.isEmpty {
                Text("Collecting samples…")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityHidden(points.isEmpty)
    }
}

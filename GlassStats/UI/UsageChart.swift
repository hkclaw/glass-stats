import Charts
import SwiftUI

struct UsageChart: View {
    @Environment(\.colorScheme) private var colorScheme

    var points: [HistoryPoint]
    var keyPath: KeyPath<HistoryPoint, Double>
    var tint: Color

    /// Dark keeps the original wash and hairline. Light needs a stronger fill and stroke on white.
    private var areaTopOpacity: Double { colorScheme == .light ? 0.42 : 0.35 }
    private var areaBottomOpacity: Double { colorScheme == .light ? 0.08 : 0.02 }
    private var lineWidth: CGFloat { colorScheme == .light ? 2 : 1.6 }
    private var gridLineWidth: CGFloat { colorScheme == .light ? 0.8 : 0.4 }
    private var gridColor: Color {
        colorScheme == .light
            ? Color(red: 0.16, green: 0.22, blue: 0.30).opacity(0.55)
            : Color.secondary.opacity(0.25)
    }

    var body: some View {
        Chart(points) { point in
            AreaMark(
                x: .value("Time", point.date),
                y: .value("Usage", point[keyPath: keyPath])
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [tint.opacity(areaTopOpacity), tint.opacity(areaBottomOpacity)],
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
            .lineStyle(StrokeStyle(lineWidth: lineWidth, lineCap: .round))
        }
        .chartXAxis(.hidden)
        .chartYScale(domain: 0...1)
        .chartYAxis {
            AxisMarks(position: .leading, values: [0, 0.5, 1]) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: gridLineWidth))
                    .foregroundStyle(gridColor)
                if let fraction = value.as(Double.self) {
                    AxisValueLabel {
                        axisLabel(Formatters.percent(fraction))
                    }
                }
            }
        }
        .frame(height: 72)
        .overlay {
            if points.isEmpty {
                Text("Collecting samples…")
                    .font(.caption)
                    .glassSecondaryText()
            }
        }
        .accessibilityHidden(points.isEmpty)
    }

    @ViewBuilder
    private func axisLabel(_ title: String) -> some View {
        let label = Text(title).font(.system(size: 9, design: .rounded))
        if colorScheme == .light {
            label.foregroundStyle(Color.primary.opacity(0.62))
        } else {
            label.foregroundStyle(.secondary)
        }
    }
}

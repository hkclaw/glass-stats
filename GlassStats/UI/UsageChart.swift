import Charts
import SwiftUI

struct UsageChart: View {
    @Environment(\.colorScheme) private var colorScheme

    var points: [HistoryPoint]
    var keyPath: KeyPath<HistoryPoint, Double>
    var tint: Color

    /// Dark keeps the original wash and hairline. Light keeps a readable stroke and a
    /// wash that is composited only inside the plot, on the same surface as the card.
    private var areaTopOpacity: Double { colorScheme == .light ? 0.15 : 0.35 }
    private var areaBottomOpacity: Double { colorScheme == .light ? 0.03 : 0.02 }
    private var lineWidth: CGFloat { colorScheme == .light ? 2 : 1.6 }
    private var gridLineWidth: CGFloat { colorScheme == .light ? 0.7 : 0.4 }
    private var gridColor: Color {
        colorScheme == .light
            ? Color.primary.opacity(0.18)
            : Color.secondary.opacity(0.25)
    }

    var body: some View {
        framedChart
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
    private var framedChart: some View {
        if colorScheme == .light {
            // Same surface as the card, so the wash stays in the plot. Do not clip:
            // 100% and 0% are centered on the plot edges and a clip cuts them in half.
            marks
                .chartPlotStyle { plot in
                    plot.background(GlassTheme.lightCardSurface)
                }
                .frame(height: 72)
        } else {
            marks.frame(height: 72)
        }
    }

    private var marks: some View {
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

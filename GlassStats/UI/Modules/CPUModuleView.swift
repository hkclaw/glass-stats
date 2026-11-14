import GlassStatsCore
import SwiftUI

struct CPUModuleView: View {
    @EnvironmentObject private var store: MonitorStore
    @Environment(\.colorScheme) private var colorScheme

    private var tint: Color { GlassTheme.cpuTint(colorScheme) }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Label("CPU", systemImage: "cpu")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text(store.snapshot.cpu.isReady ? TextFormat.percent(store.snapshot.cpu.total) : "—")
                    .font(.system(.title3, design: .rounded).monospacedDigit())
                    .foregroundStyle(tint)
            }

            UsageChart(points: store.history, keyPath: \.cpu, tint: tint)

            if !store.snapshot.cpu.cores.isEmpty {
                HStack(spacing: 3) {
                    ForEach(Array(store.snapshot.cpu.cores.enumerated()), id: \.offset) { _, fraction in
                        Capsule()
                            .fill(tint.opacity(colorScheme == .light ? 0.40 + 0.60 * fraction : 0.25 + 0.75 * fraction))
                            .frame(height: max(3, 14 * fraction))
                            .frame(maxWidth: .infinity, alignment: .bottom)
                    }
                }
                .frame(height: 14)
                .accessibilityLabel("Per-core load")
            }

            if !store.attention.spikes.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(store.attention.spikes.prefix(6)) { event in
                        HStack(spacing: 6) {
                            Text(event.at, format: .dateTime.hour().minute())
                            Text(TextFormat.percent(event.total))
                            if let name = event.processName {
                                Text(name)
                                    .lineLimit(1)
                            }
                            Spacer(minLength: 0)
                        }
                        .font(.caption.monospacedDigit())
                        .glassSecondaryText()
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
    }
}

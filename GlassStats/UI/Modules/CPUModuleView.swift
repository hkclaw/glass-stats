import SwiftUI

struct CPUModuleView: View {
    @EnvironmentObject private var store: MonitorStore
    @Environment(\.colorScheme) private var colorScheme

    private var tint: Color { GlassTheme.cpuTint(colorScheme) }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("CPU", systemImage: "cpu")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text(store.snapshot.cpu.isReady ? Formatters.percent(store.snapshot.cpu.total) : "—")
                    .font(.system(.title3, design: .rounded).monospacedDigit())
                    .foregroundStyle(tint)
            }

            UsageChart(points: store.history, keyPath: \.cpu, tint: tint)

            if !store.snapshot.cpu.cores.isEmpty {
                HStack(spacing: 3) {
                    ForEach(Array(store.snapshot.cpu.cores.enumerated()), id: \.offset) { _, fraction in
                        Capsule()
                            .fill(tint.opacity(colorScheme == .light ? 0.40 + 0.60 * fraction : 0.25 + 0.75 * fraction))
                            .frame(height: max(3, 18 * fraction))
                            .frame(maxWidth: .infinity, alignment: .bottom)
                    }
                }
                .frame(height: 18)
                .accessibilityLabel("Per-core load")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
    }
}

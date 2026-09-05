import SwiftUI

struct CPUModuleView: View {
    @EnvironmentObject private var store: MonitorStore

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("CPU", systemImage: "cpu")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text(store.snapshot.cpu.isReady ? Formatters.percent(store.snapshot.cpu.total) : "—")
                    .font(.system(.title3, design: .rounded).monospacedDigit())
                    .foregroundStyle(GlassTheme.accent)
            }

            UsageChart(points: store.history, keyPath: \.cpu, tint: GlassTheme.accent)

            if !store.snapshot.cpu.cores.isEmpty {
                HStack(spacing: 3) {
                    ForEach(Array(store.snapshot.cpu.cores.enumerated()), id: \.offset) { _, fraction in
                        Capsule()
                            .fill(GlassTheme.accent.opacity(0.25 + 0.75 * fraction))
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

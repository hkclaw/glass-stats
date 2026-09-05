import SwiftUI

struct MemoryModuleView: View {
    @EnvironmentObject private var store: MonitorStore

    var body: some View {
        let memory = store.snapshot.memory
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Memory", systemImage: "memorychip")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text(memory.isReady ? Formatters.percent(memory.usedRatio) : "—")
                    .font(.system(.title3, design: .rounded).monospacedDigit())
                    .foregroundStyle(Color.mint)
            }

            UsageChart(points: store.history, keyPath: \.memory, tint: .mint)

            if memory.isReady {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(Formatters.bytes(memory.usedBytes)) used of \(Formatters.bytes(memory.physicalBytes))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    HStack(spacing: 10) {
                        metric("App", memory.appBytes)
                        metric("Wired", memory.wiredBytes)
                        metric("Compressed", memory.compressedBytes)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
    }

    private func metric(_ title: String, _ bytes: UInt64) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(Formatters.bytes(bytes))
                .font(.caption.monospacedDigit())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

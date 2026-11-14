import GlassStatsCore
import SwiftUI

struct NetworkModuleView: View {
    @EnvironmentObject private var store: MonitorStore

    var body: some View {
        let network = store.snapshot.network
        VStack(alignment: .leading, spacing: 8) {
            Label("Network", systemImage: "arrow.up.arrow.down")
                .font(.subheadline.weight(.semibold))
            HStack {
                labeledRate(title: "Down", systemImage: "arrow.down", value: network.bytesInPerSecond, ready: network.isReady)
                labeledRate(title: "Up", systemImage: "arrow.up", value: network.bytesOutPerSecond, ready: network.isReady)
            }
            if !store.attention.bursts.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(store.attention.bursts.prefix(6)) { event in
                        HStack(spacing: 6) {
                            Text(event.at, format: .dateTime.hour().minute())
                            Text(event.direction.label)
                            Text(TextFormat.bytes(event.bytes))
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

    private func labeledRate(title: String, systemImage: String, value: UInt64, ready: Bool) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Label(title, systemImage: systemImage)
                .font(.caption)
                .glassCaptionText()
            Text(ready ? Formatters.rate(value) : "—")
                .font(.caption.monospacedDigit())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

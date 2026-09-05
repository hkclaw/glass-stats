import SwiftUI

struct TopProcessesView: View {
    @EnvironmentObject private var store: MonitorStore

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Top processes", systemImage: "list.bullet.rectangle")
                .font(.subheadline.weight(.semibold))

            if store.processes.isEmpty {
                Text("Waiting for process samples…")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(store.processes) { process in
                    HStack(spacing: 8) {
                        Text(process.name)
                            .lineLimit(1)
                        Spacer()
                        Text(Formatters.percent(process.cpu))
                            .foregroundStyle(.secondary)
                            .frame(width: 40, alignment: .trailing)
                        Text(Formatters.bytes(process.residentBytes))
                            .foregroundStyle(.secondary)
                            .frame(width: 64, alignment: .trailing)
                    }
                    .font(.system(.caption, design: .rounded).monospacedDigit())
                    .accessibilityElement(children: .combine)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
    }
}

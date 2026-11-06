import SwiftUI

struct TopProcessesView: View {
    @EnvironmentObject private var store: MonitorStore
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Top processes", systemImage: "list.bullet.rectangle")
                .font(.subheadline.weight(.semibold))

            if store.processes.isEmpty {
                Text("Waiting for process samples…")
                    .font(.caption)
                    .glassSecondaryText()
            } else {
                ForEach(store.processes) { process in
                    HStack(spacing: 8) {
                        processName(process.name)
                        Spacer()
                        processPercent(Formatters.percent(process.cpu))
                        processMemory(Formatters.bytes(process.residentBytes))
                    }
                    .font(.system(.caption, design: .rounded).monospacedDigit())
                    .accessibilityElement(children: .combine)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
    }

    /// Dark rows stay primary name + hierarchical secondary figures, inheriting the row font.
    /// Light sets an explicit weight so the parent font cannot flatten the hierarchy.
    @ViewBuilder
    private func processName(_ name: String) -> some View {
        let text = Text(name).lineLimit(1)
        if colorScheme == .light {
            text.font(rowFont(weight: .medium))
        } else {
            text
        }
    }

    @ViewBuilder
    private func processPercent(_ value: String) -> some View {
        let text = Text(value).frame(width: 48, alignment: .trailing)
        if colorScheme == .light {
            text.font(rowFont(weight: .semibold)).foregroundStyle(Color.primary.opacity(0.78))
        } else {
            text.foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private func processMemory(_ value: String) -> some View {
        let text = Text(value).frame(width: 64, alignment: .trailing)
        if colorScheme == .light {
            text.font(rowFont(weight: .regular)).foregroundStyle(Color.primary.opacity(0.62))
        } else {
            text.foregroundStyle(.secondary)
        }
    }

    private func rowFont(weight: Font.Weight) -> Font {
        .system(.caption, design: .rounded, weight: weight).monospacedDigit()
    }
}

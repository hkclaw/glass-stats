import GlassStatsCore
import SwiftUI

struct TopProcessesView: View {
    @EnvironmentObject private var store: MonitorStore
    @Environment(\.colorScheme) private var colorScheme
    @State private var pendingQuit: ProcessAttention?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Top processes", systemImage: "list.bullet.rectangle")
                .font(.subheadline.weight(.semibold))

            if store.attention.rows.isEmpty {
                Text("Waiting for process samples…")
                    .font(.caption)
                    .glassSecondaryText()
            } else {
                ForEach(store.attention.rows) { item in
                    HStack(spacing: 8) {
                        VStack(alignment: .leading, spacing: 1) {
                            processName(item.row.name)
                            if let since = item.sinceOpenLabel {
                                Text(since)
                                    .font(.caption2)
                                    .glassCaptionText()
                            }
                        }
                        Spacer()
                        processPercent(TextFormat.percent(item.row.cpu))
                        processMemory(Formatters.bytes(item.row.residentBytes))
                    }
                    .font(.system(.caption, design: .rounded).monospacedDigit())
                    .accessibilityElement(children: .combine)
                    .contextMenu {
                        if item.decision.allowed {
                            Button("Copy") {
                                ProcessCommands.copy(item.decision.copyText)
                            }
                            Button("Show in Finder") {
                                ProcessCommands.reveal(pid: item.row.pid, name: item.row.name)
                            }
                            Button("Quit…") {
                                pendingQuit = item
                            }
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
        .confirmationDialog(
            pendingQuit?.decision.confirmTitle ?? "",
            isPresented: Binding(
                get: { pendingQuit != nil },
                set: { if !$0 { pendingQuit = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Quit", role: .destructive) {
                if let item = pendingQuit {
                    ProcessCommands.quit(pid: item.row.pid, name: item.row.name, startToken: item.row.startToken)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(pendingQuit?.decision.confirmMessage ?? "")
        }
    }

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

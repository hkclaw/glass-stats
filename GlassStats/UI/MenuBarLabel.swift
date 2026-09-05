import SwiftUI

struct MenuBarLabel: View {
    @EnvironmentObject private var settings: ModuleSettings
    @EnvironmentObject private var store: MonitorStore

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "gauge.medium")
                .symbolRenderingMode(.hierarchical)
            if settings.showCPUInMenuBar {
                Text(cpuText)
            }
            if settings.showCPUInMenuBar, settings.showMemoryInMenuBar {
                Text("·")
                    .foregroundStyle(.secondary)
            }
            if settings.showMemoryInMenuBar {
                Text(memoryText)
            }
            if !settings.showCPUInMenuBar, !settings.showMemoryInMenuBar {
                Text("Glass")
            }
        }
        .font(.system(size: 11, weight: .semibold, design: .rounded))
        .monospacedDigit()
        .accessibilityLabel(accessibility)
    }

    private var cpuText: String {
        guard store.snapshot.cpu.isReady else { return "CPU —" }
        return "CPU \(Formatters.percent(store.snapshot.cpu.total))"
    }

    private var memoryText: String {
        guard store.snapshot.memory.isReady else { return "MEM —" }
        return "MEM \(Formatters.percent(store.snapshot.memory.usedRatio))"
    }

    private var accessibility: String {
        "Glass Stats, \(cpuText), \(memoryText)"
    }
}

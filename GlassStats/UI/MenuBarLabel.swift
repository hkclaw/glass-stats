import SwiftUI

struct MenuBarLabel: View {
    @EnvironmentObject private var settings: ModuleSettings
    @EnvironmentObject private var store: MonitorStore

    var body: some View {
        HStack(spacing: 4) {
            if settings.showCPUInMenuBar {
                Text(cpuShort)
            }
            if settings.showCPUInMenuBar, settings.showMemoryInMenuBar {
                Text("·")
                    .foregroundStyle(.secondary)
            }
            if settings.showMemoryInMenuBar {
                Text(memoryShort)
            }
            if !settings.showCPUInMenuBar, !settings.showMemoryInMenuBar {
                Text("Glass")
            }
        }
        .font(.system(size: 11, weight: .semibold, design: .rounded))
        .monospacedDigit()
        // MenuBarExtra labels can stick on some macOS builds without an identity bump.
        .id(store.snapshot.timestamp)
        .accessibilityLabel(accessibility)
    }

    private var cpuShort: String {
        guard store.snapshot.cpu.isReady else { return "—" }
        return Formatters.percent(store.snapshot.cpu.total)
    }

    private var memoryShort: String {
        guard store.snapshot.memory.isReady else { return "—" }
        return Formatters.percent(store.snapshot.memory.usedRatio)
    }

    private var accessibility: String {
        "Glass Stats, CPU \(cpuShort), memory \(memoryShort)"
    }
}

import AppKit
import SwiftUI

struct PopoverRootView: View {
    @EnvironmentObject private var settings: ModuleSettings
    @EnvironmentObject private var store: MonitorStore

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
                .padding(.bottom, 10)

            GlassStack {
                if settings.cpuEnabled {
                    CPUModuleView()
                }
                if settings.memoryEnabled {
                    MemoryModuleView()
                }
                if settings.processesEnabled {
                    TopProcessesView()
                }
                if settings.diskEnabled {
                    DiskModuleView()
                }
                if settings.networkEnabled {
                    NetworkModuleView()
                }
                if settings.batteryEnabled {
                    BatteryModuleView()
                }
            }
        }
        .padding(14)
        .frame(width: GlassTheme.popoverWidth)
        .glassPopoverChrome()
    }

    private var header: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Glass Stats")
                    .font(.headline)
                Text("Local only · Apple Silicon")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            SettingsLink {
                Image(systemName: "gearshape")
            }
            .help("Settings")
            .glassControlStyle()
            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Image(systemName: "power")
            }
            .help("Quit Glass Stats")
            .glassControlStyle()
        }
    }
}

#Preview {
    let settings = ModuleSettings()
    let store = MonitorStore(settings: settings)
    return PopoverRootView()
        .environmentObject(settings)
        .environmentObject(store)
        .frame(height: 640)
}

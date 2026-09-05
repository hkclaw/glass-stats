import AppKit
import ServiceManagement
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settings: ModuleSettings

    var body: some View {
        TabView {
            modules
                .tabItem { Label("Modules", systemImage: "square.grid.2x2") }
            menuBar
                .tabItem { Label("Menu Bar", systemImage: "menubar.rectangle") }
            about
                .tabItem { Label("About", systemImage: "info.circle") }
        }
        .frame(width: 460, height: 360)
        .onAppear {
            NSApplication.shared.activate()
        }
    }

    private var modules: some View {
        Form {
            Section("Popover") {
                Toggle("CPU", isOn: $settings.cpuEnabled)
                Toggle("Memory", isOn: $settings.memoryEnabled)
                Toggle("Top processes", isOn: $settings.processesEnabled)
                Toggle("Disk (scaffold)", isOn: $settings.diskEnabled)
                Toggle("Network (scaffold)", isOn: $settings.networkEnabled)
                Toggle("Battery (scaffold)", isOn: $settings.batteryEnabled)
            }
            Section("Sampling") {
                Picker("Refresh interval", selection: $settings.refreshInterval) {
                    Text("1 s").tag(1.0)
                    Text("2 s").tag(2.0)
                    Text("5 s").tag(5.0)
                }
                Text("CPU and memory are live Mach samples. Disk, network, and battery are basic V1 readouts.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding(8)
    }

    private var menuBar: some View {
        Form {
            Section("Status item") {
                Toggle("Show CPU", isOn: $settings.showCPUInMenuBar)
                Toggle("Show memory", isOn: $settings.showMemoryInMenuBar)
            }
            Section("Startup") {
                Toggle("Open at login", isOn: $settings.launchAtLogin)
                    .onChange(of: settings.launchAtLogin) { _, enabled in
                        updateLoginItem(enabled)
                    }
                Text("macOS may require Glass Stats to live in /Applications before Open at Login stays registered.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding(8)
        .onAppear {
            if settings.launchAtLogin {
                updateLoginItem(true)
            }
        }
    }

    private var about: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Glass Stats")
                .font(.title2.weight(.semibold))
            Text("A self-developed macOS menu bar system monitor. Local only — no ads, no tracking, no network telemetry.")
                .foregroundStyle(.secondary)
            Text("Not affiliated with, endorsed by, or derived from Stats (exelban / mac-stats.com). No Stats trademarks, assets, or source code are used.")
                .font(.callout)
            Text("GPU, fans, and sensors are planned for V1.1.")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text("MIT License · com.hkclaw.GlassStats · macOS 14+")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func updateLoginItem(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            NSLog("Glass Stats login item failed: \(error.localizedDescription)")
        }
    }
}

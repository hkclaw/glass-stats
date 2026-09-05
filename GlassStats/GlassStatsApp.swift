import SwiftUI

@main
struct GlassStatsApp: App {
    @StateObject private var settings: ModuleSettings
    @StateObject private var store: MonitorStore

    init() {
        let settings = ModuleSettings()
        _settings = StateObject(wrappedValue: settings)
        _store = StateObject(wrappedValue: MonitorStore(settings: settings))
    }

    var body: some Scene {
        MenuBarExtra {
            PopoverRootView()
                .environmentObject(settings)
                .environmentObject(store)
        } label: {
            MenuBarLabel()
                .environmentObject(settings)
                .environmentObject(store)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .environmentObject(settings)
        }
    }
}

import Foundation
import Combine

/// Persisted module and menu-bar toggles. Sampling still runs locally; these
/// flags only control what is shown.
@MainActor
final class ModuleSettings: ObservableObject {
    private enum Key {
        static let cpu = "gs.module.cpu"
        static let memory = "gs.module.memory"
        static let disk = "gs.module.disk"
        static let network = "gs.module.network"
        static let battery = "gs.module.battery"
        static let processes = "gs.module.processes"
        static let menuCPU = "gs.menubar.cpu"
        static let menuMemory = "gs.menubar.memory"
        static let interval = "gs.refresh.interval"
        static let launchAtLogin = "gs.launchAtLogin"
    }

    @Published var cpuEnabled: Bool {
        didSet { UserDefaults.standard.set(cpuEnabled, forKey: Key.cpu) }
    }

    @Published var memoryEnabled: Bool {
        didSet { UserDefaults.standard.set(memoryEnabled, forKey: Key.memory) }
    }

    @Published var diskEnabled: Bool {
        didSet { UserDefaults.standard.set(diskEnabled, forKey: Key.disk) }
    }

    @Published var networkEnabled: Bool {
        didSet { UserDefaults.standard.set(networkEnabled, forKey: Key.network) }
    }

    @Published var batteryEnabled: Bool {
        didSet { UserDefaults.standard.set(batteryEnabled, forKey: Key.battery) }
    }

    @Published var processesEnabled: Bool {
        didSet { UserDefaults.standard.set(processesEnabled, forKey: Key.processes) }
    }

    @Published var showCPUInMenuBar: Bool {
        didSet { UserDefaults.standard.set(showCPUInMenuBar, forKey: Key.menuCPU) }
    }

    @Published var showMemoryInMenuBar: Bool {
        didSet { UserDefaults.standard.set(showMemoryInMenuBar, forKey: Key.menuMemory) }
    }

    /// Seconds between Mach / IOKit samples. Values are clamped to 0.5...5.
    @Published var refreshInterval: Double {
        didSet {
            let clamped = min(5, max(0.5, refreshInterval))
            if clamped != refreshInterval {
                refreshInterval = clamped
                return
            }
            UserDefaults.standard.set(refreshInterval, forKey: Key.interval)
        }
    }

    @Published var launchAtLogin: Bool {
        didSet { UserDefaults.standard.set(launchAtLogin, forKey: Key.launchAtLogin) }
    }

    init() {
        let defaults = UserDefaults.standard
        cpuEnabled = defaults.object(forKey: Key.cpu) as? Bool ?? true
        memoryEnabled = defaults.object(forKey: Key.memory) as? Bool ?? true
        diskEnabled = defaults.object(forKey: Key.disk) as? Bool ?? true
        networkEnabled = defaults.object(forKey: Key.network) as? Bool ?? true
        batteryEnabled = defaults.object(forKey: Key.battery) as? Bool ?? true
        processesEnabled = defaults.object(forKey: Key.processes) as? Bool ?? true
        showCPUInMenuBar = defaults.object(forKey: Key.menuCPU) as? Bool ?? true
        showMemoryInMenuBar = defaults.object(forKey: Key.menuMemory) as? Bool ?? true
        refreshInterval = defaults.object(forKey: Key.interval) as? Double ?? 1.0
        launchAtLogin = defaults.object(forKey: Key.launchAtLogin) as? Bool ?? false
    }
}

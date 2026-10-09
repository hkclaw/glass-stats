import Foundation
import Combine

@MainActor
final class MonitorStore: ObservableObject {
    @Published private(set) var snapshot = SystemSnapshot.empty
    @Published private(set) var history: [HistoryPoint] = []
    @Published private(set) var processes: [ProcessRow] = []
    @Published private(set) var popoverOpen = false

    let settings: ModuleSettings
    private let sampler = SystemSampler()
    private var loop: Task<Void, Never>?

    private let historyLimit = 60

    init(settings: ModuleSettings) {
        self.settings = settings
        start()
    }

    func start() {
        guard loop == nil else { return }
        loop = Task { [weak self] in
            while let self, !Task.isCancelled {
                await self.refresh()
                let nanoseconds = UInt64(self.settings.refreshInterval * 1_000_000_000)
                try? await Task.sleep(nanoseconds: nanoseconds)
            }
        }
    }

    func stop() {
        loop?.cancel()
        loop = nil
    }

    /// Heavy modules (processes, disk, network, battery) sample only while this is true.
    func setPopoverOpen(_ isOpen: Bool) {
        let changed = popoverOpen != isOpen
        popoverOpen = isOpen
        guard changed, isOpen else { return }
        Task { await refresh() }
    }

    private func refresh() async {
        let result = await sampler.sample(currentRequest())
        apply(result)
    }

    /// CPU and memory follow the menu bar. Popover modules are added only while it is open,
    /// and only when that module's toggle is on.
    private func currentRequest() -> SampleRequest {
        SampleRequest(
            cpu: settings.showCPUInMenuBar || (popoverOpen && settings.cpuEnabled),
            memory: settings.showMemoryInMenuBar || (popoverOpen && settings.memoryEnabled),
            disk: popoverOpen && settings.diskEnabled,
            network: popoverOpen && settings.networkEnabled,
            battery: popoverOpen && settings.batteryEnabled,
            processes: popoverOpen && settings.processesEnabled
        )
    }

    private func apply(_ result: SampleResult) {
        snapshot = result.snapshot
        processes = result.processes
        if result.didSampleCPU, !result.snapshot.cpu.isReady {
            return
        }
        let memoryReady = result.didSampleMemory && result.snapshot.memory.isReady
        guard result.didSampleCPU || memoryReady else { return }
        let cpu = result.didSampleCPU
            ? result.snapshot.cpu.total
            : (history.last?.cpu ?? 0)
        let memory = memoryReady
            ? result.snapshot.memory.usedRatio
            : (history.last?.memory ?? 0)
        history.append(
            HistoryPoint(
                date: result.snapshot.timestamp,
                cpu: cpu,
                memory: memory
            )
        )
        if history.count > historyLimit {
            history.removeFirst(history.count - historyLimit)
        }
    }
}

import Combine
import Foundation
import GlassStatsCore

@MainActor
final class MonitorStore: ObservableObject {
    @Published private(set) var snapshot = SystemSnapshot.empty
    @Published private(set) var history: [HistoryPoint] = []
    @Published private(set) var attention: Attention
    @Published private(set) var popoverOpen = false

    let settings: ModuleSettings
    private let sampler = SystemSampler()
    private var board: AttentionBoard
    private let saveArchive: (Data) -> Void
    private var lastSaved: Data
    private var loop: Task<Void, Never>?
    private var folderScan: Task<Void, Never>?
    private var settingsTicket: AnyCancellable?
    private let historyLimit = 60

    init(
        settings: ModuleSettings,
        loadArchive: () -> Data? = { nil },
        saveArchive: @escaping (Data) -> Void = { _ in }
    ) {
        self.settings = settings
        self.saveArchive = saveArchive
        let now = Date()
        board = AttentionBoard(
            restoring: loadArchive(),
            now: now,
            situation: Self.situation(settings: settings, popoverOpen: false)
        )
        attention = board.attention
        lastSaved = board.persistableData()
        settingsTicket = settings.objectWillChange.sink { [weak self] _ in
            Task { @MainActor in
                self?.noteSituation()
            }
        }
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

    func setPopoverOpen(_ isOpen: Bool) {
        let changed = popoverOpen != isOpen
        popoverOpen = isOpen
        if !isOpen {
            folderScan?.cancel()
            folderScan = nil
        }
        guard changed else { return }
        attention = board.ingest(AttentionTick.situation(currentSituation(), at: Date()))
        persistIfNeeded()
        guard isOpen else { return }
        Task { await refresh() }
    }

    private func noteSituation() {
        attention = board.ingest(AttentionTick.situation(currentSituation(), at: Date()))
        persistIfNeeded()
    }

    private func refresh() async {
        let now = Date()
        let situation = currentSituation()
        let plan = board.plan(at: now, situation: situation)
        let result = await sampler.sample(plan.request)
        let pressure = plan.readPressure ? HostPressure.read() : nil
        let sleep = plan.readSleepHold ? HostAssertions.userIdleSleepHolder() : nil
        apply(result: result, plan: plan, situation: situation, at: now, pressure: pressure, sleep: sleep)
        guard plan.scanFolders, folderScan == nil else { return }
        folderScan = Task.detached(priority: .utility) { [weak self] in
            let folders = FolderScan.knownHeavyFolders()
            await self?.deliver(folders)
        }
    }

    private func deliver(_ folders: [FolderCulprit]) {
        guard !Task.isCancelled else { return }
        folderScan = nil
        attention = board.ingest(AttentionTick.folders(folders, at: Date(), situation: currentSituation()))
        persistIfNeeded()
    }

    private func apply(
        result: SampleResult,
        plan: SamplePlan,
        situation: SamplingSituation,
        at: Date,
        pressure: Int?,
        sleep: SleepHold?
    ) {
        snapshot = result.snapshot
        attention = board.ingest(
            AttentionTick.sample(
                result: result,
                plan: plan,
                at: at,
                situation: situation,
                thisAppPid: ProcessInfo.processInfo.processIdentifier,
                logicalCores: ProcessInfo.processInfo.processorCount,
                pressureRaw: pressure,
                sleepHold: sleep
            )
        )
        persistIfNeeded()

        if result.sampled.cpu, !result.snapshot.cpu.isReady {
            return
        }
        let memoryReady = result.sampled.memory && result.snapshot.memory.isReady
        guard result.sampled.cpu || memoryReady else { return }
        let cpu = result.sampled.cpu
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

    private func persistIfNeeded() {
        let data = board.persistableData()
        guard data != lastSaved else { return }
        lastSaved = data
        saveArchive(data)
    }

    private func currentSituation() -> SamplingSituation {
        Self.situation(settings: settings, popoverOpen: popoverOpen)
    }

    private static func situation(settings: ModuleSettings, popoverOpen: Bool) -> SamplingSituation {
        SamplingSituation(
            popoverOpen: popoverOpen,
            showCPUInMenuBar: settings.showCPUInMenuBar,
            showMemoryInMenuBar: settings.showMemoryInMenuBar,
            cpuEnabled: settings.cpuEnabled,
            memoryEnabled: settings.memoryEnabled,
            diskEnabled: settings.diskEnabled,
            networkEnabled: settings.networkEnabled,
            batteryEnabled: settings.batteryEnabled,
            processesEnabled: settings.processesEnabled
        )
    }
}

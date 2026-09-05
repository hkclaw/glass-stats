import Foundation
import Combine

@MainActor
final class MonitorStore: ObservableObject {
    @Published private(set) var snapshot = SystemSnapshot.empty
    @Published private(set) var history: [HistoryPoint] = []
    @Published private(set) var processes: [ProcessRow] = []

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
                let result = await self.sampler.sample()
                self.apply(result)
                let nanoseconds = UInt64(self.settings.refreshInterval * 1_000_000_000)
                try? await Task.sleep(nanoseconds: nanoseconds)
            }
        }
    }

    func stop() {
        loop?.cancel()
        loop = nil
    }

    private func apply(_ result: SampleResult) {
        snapshot = result.snapshot
        processes = result.processes
        guard result.snapshot.cpu.isReady else { return }
        history.append(
            HistoryPoint(
                date: result.snapshot.timestamp,
                cpu: result.snapshot.cpu.total,
                memory: result.snapshot.memory.usedRatio
            )
        )
        if history.count > historyLimit {
            history.removeFirst(history.count - historyLimit)
        }
    }
}

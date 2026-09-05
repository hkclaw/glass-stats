import Foundation

/// Live CPU utilization from Mach `host_processor_info(PROCESSOR_CPU_LOAD_INFO)`
/// plus `host_statistics(HOST_CPU_LOAD_INFO)` as a cross-check for the total.
/// Utilization is the delta of (user+system+nice) / (user+system+nice+idle).
struct HostCPU {
    private var previousCores: [CPUTicks]?
    private var previousTotal: CPUTicks?

    mutating func sample() -> CPUSnapshot {
        let coresBuffer = CoreTickBuffer.read()
        let loadInfo = MachSupport.hostCPULoad().map(CPUTicks.fromLoadInfo)

        guard let coresBuffer else {
            return .empty
        }

        var coreFractions: [Double] = []
        if let previousCores, previousCores.count == coresBuffer.ticks.count {
            coreFractions = zip(coresBuffer.ticks, previousCores).map { current, previous in
                current.utilization(since: previous)
            }
        }

        let total: Double
        if let loadInfo, let previousTotal {
            total = loadInfo.utilization(since: previousTotal)
        } else if !coreFractions.isEmpty {
            total = coreFractions.reduce(0, +) / Double(coreFractions.count)
        } else {
            total = 0
        }

        let isReady = previousCores != nil || previousTotal != nil
        previousCores = coresBuffer.ticks
        if let loadInfo {
            previousTotal = loadInfo
        }

        return CPUSnapshot(total: total, cores: coreFractions, isReady: isReady)
    }
}

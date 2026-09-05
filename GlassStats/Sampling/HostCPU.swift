import Foundation

/// System-wide CPU utilization matching Activity Monitor's overall CPU
/// (user + system + nice) / (user + system + nice + idle), from Mach
/// `HOST_CPU_LOAD_INFO` tick deltas. Per-core bars use `host_processor_info`.
struct HostCPU {
    private var previousTotal: CPUTicks?
    private var previousCores: [CPUTicks]?
    /// EMA so the menu bar tracks Activity Monitor's smoothed feel (not one noisy second).
    private var smoothed: Double?
    private let smoothAlpha: Double = 0.45

    mutating func sample() -> CPUSnapshot {
        let loadInfo = MachSupport.hostCPULoad().map(CPUTicks.fromLoadInfo)
        let coresBuffer = CoreTickBuffer.read()

        var coreFractions: [Double] = []
        if let coresBuffer {
            if let previousCores, previousCores.count == coresBuffer.ticks.count {
                coreFractions = zip(coresBuffer.ticks, previousCores).map { current, previous in
                    current.utilization(since: previous)
                }
            }
            previousCores = coresBuffer.ticks
        }

        var instant: Double?
        var isReady = false

        if let loadInfo {
            if let previousTotal {
                let raw = loadInfo.utilization(since: previousTotal)
                // Ignore pathological tiny windows / counter glitches.
                if loadInfo.total > previousTotal.total {
                    instant = raw
                    isReady = true
                }
            }
            previousTotal = loadInfo
        } else if !coreFractions.isEmpty {
            // Fallback: mean of per-core busy fractions (== aggregate when cores are equal weight).
            instant = coreFractions.reduce(0, +) / Double(coreFractions.count)
            isReady = previousCores != nil
        }

        let total: Double
        if let instant {
            if let smoothed {
                let next = smoothed * (1 - smoothAlpha) + instant * smoothAlpha
                self.smoothed = next
                total = next
            } else {
                self.smoothed = instant
                total = instant
            }
        } else {
            total = smoothed ?? 0
        }

        return CPUSnapshot(total: total, cores: coreFractions, isReady: isReady || smoothed != nil)
    }
}

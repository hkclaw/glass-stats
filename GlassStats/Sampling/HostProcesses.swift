import Darwin
import Foundation

/// Top processes via `proc_listpids` + `proc_pidinfo(PROC_PIDTASKINFO)`.
/// Names are resolved only for the rows that will be shown.
/// CPU is a share of one core: delta(user+system nanoseconds) / elapsed wall time,
/// clamped to the logical CPU count (the most one process can use).
struct HostProcesses {
    private var previousCPUTime: [pid_t: UInt64] = [:]
    private var previousSampleAt: Date?

    private struct Scan {
        var pid: pid_t
        var fraction: Double
        var residentBytes: UInt64
    }

    mutating func sample(limit: Int = 8) -> [ProcessRow] {
        let now = Date()
        let pids = Self.allPIDs()
        let cpuCount = max(1, ProcessInfo.processInfo.processorCount)
        let elapsed = previousSampleAt.map { now.timeIntervalSince($0) } ?? 0
        var nextCPUTime: [pid_t: UInt64] = [:]
        var scans: [Scan] = []
        scans.reserveCapacity(pids.count)

        for pid in pids {
            guard pid > 0, let task = Self.taskInfo(pid) else { continue }
            let cpuNanos = task.pti_total_user &+ task.pti_total_system
            nextCPUTime[pid] = cpuNanos

            var fraction = 0.0
            if elapsed > 0, let previous = previousCPUTime[pid], cpuNanos >= previous {
                let deltaSeconds = Double(cpuNanos - previous) / 1_000_000_000.0
                let oneCore = deltaSeconds / elapsed
                fraction = min(Double(cpuCount), max(0, oneCore))
            }

            scans.append(
                Scan(
                    pid: pid,
                    fraction: fraction,
                    residentBytes: task.pti_resident_size
                )
            )
        }

        previousCPUTime = nextCPUTime
        previousSampleAt = now

        return scans
            .sorted {
                if $0.fraction != $1.fraction { return $0.fraction > $1.fraction }
                return $0.residentBytes > $1.residentBytes
            }
            .prefix(limit)
            .map { scan in
                ProcessRow(
                    pid: scan.pid,
                    name: Self.processName(scan.pid),
                    cpu: scan.fraction,
                    residentBytes: scan.residentBytes
                )
            }
    }

    private static func allPIDs() -> [pid_t] {
        let bytesNeeded = proc_listpids(UInt32(PROC_ALL_PIDS), 0, nil, 0)
        guard bytesNeeded > 0 else { return [] }
        let capacity = Int(bytesNeeded) / MemoryLayout<pid_t>.stride
        var pids = [pid_t](repeating: 0, count: capacity)
        let written = pids.withUnsafeMutableBufferPointer { buffer in
            proc_listpids(
                UInt32(PROC_ALL_PIDS),
                0,
                buffer.baseAddress,
                Int32(buffer.count * MemoryLayout<pid_t>.stride)
            )
        }
        guard written > 0 else { return [] }
        let count = Int(written) / MemoryLayout<pid_t>.stride
        return Array(pids.prefix(count)).filter { $0 != 0 }
    }

    private static func taskInfo(_ pid: pid_t) -> proc_taskinfo? {
        var info = proc_taskinfo()
        let size = MemoryLayout<proc_taskinfo>.stride
        let result = withUnsafeMutablePointer(to: &info) { pointer in
            proc_pidinfo(pid, PROC_PIDTASKINFO, 0, pointer, Int32(size))
        }
        guard result == Int32(size) else { return nil }
        return info
    }

    private static func processName(_ pid: pid_t) -> String {
        var buffer = [CChar](repeating: 0, count: Int(MAXPATHLEN))
        let length = proc_name(pid, &buffer, UInt32(buffer.count))
        if length > 0 {
            return String(cString: buffer)
        }
        var path = [CChar](repeating: 0, count: Int(MAXPATHLEN))
        if proc_pidpath(pid, &path, UInt32(path.count)) > 0 {
            return URL(fileURLWithPath: String(cString: path)).lastPathComponent
        }
        return "pid \(pid)"
    }
}

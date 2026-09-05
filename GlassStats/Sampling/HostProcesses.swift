import Darwin
import Foundation

/// Top processes via `proc_listpids` + `proc_pidinfo(PROC_PIDTASKINFO)`.
/// CPU percent needs two samples of `pti_total_user` + `pti_total_system`
/// (nanoseconds) divided by elapsed wall time and logical CPU count.
struct HostProcesses {
    private var previousCPUTime: [pid_t: UInt64] = [:]
    private var previousSampleAt: Date?

    mutating func sample(limit: Int = 8) -> [ProcessRow] {
        let now = Date()
        let pids = Self.allPIDs()
        let cpuCount = max(1, ProcessInfo.processInfo.processorCount)
        let elapsed = previousSampleAt.map { now.timeIntervalSince($0) } ?? 0
        var nextCPUTime: [pid_t: UInt64] = [:]
        var rows: [ProcessRow] = []
        rows.reserveCapacity(min(limit * 4, pids.count))

        for pid in pids {
            guard pid > 0, let task = Self.taskInfo(pid) else { continue }
            let cpuNanos = task.pti_total_user &+ task.pti_total_system
            nextCPUTime[pid] = cpuNanos

            var fraction = 0.0
            if elapsed > 0, let previous = previousCPUTime[pid], cpuNanos >= previous {
                let deltaSeconds = Double(cpuNanos - previous) / 1_000_000_000.0
                fraction = max(0, deltaSeconds / (elapsed * Double(cpuCount)))
            }

            rows.append(
                ProcessRow(
                    pid: pid,
                    name: Self.processName(pid),
                    cpu: fraction,
                    residentBytes: task.pti_resident_size
                )
            )
        }

        previousCPUTime = nextCPUTime
        previousSampleAt = now

        return rows
            .sorted {
                if $0.cpu != $1.cpu { return $0.cpu > $1.cpu }
                return $0.residentBytes > $1.residentBytes
            }
            .prefix(limit)
            .map { $0 }
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

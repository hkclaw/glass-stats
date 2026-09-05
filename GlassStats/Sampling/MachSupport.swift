import Darwin
import Foundation

enum MachSupport {
    static func hostCPULoad() -> host_cpu_load_info? {
        var info = host_cpu_load_info()
        var count = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info>.stride / MemoryLayout<integer_t>.stride)
        let status = withUnsafeMutablePointer(to: &info) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { rebound in
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, rebound, &count)
            }
        }
        return status == KERN_SUCCESS ? info : nil
    }

    static func hostVMInfo64() -> vm_statistics64? {
        var info = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.stride / MemoryLayout<integer_t>.stride)
        let status = withUnsafeMutablePointer(to: &info) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { rebound in
                host_statistics64(mach_host_self(), HOST_VM_INFO64, rebound, &count)
            }
        }
        return status == KERN_SUCCESS ? info : nil
    }

    static func pageSize() -> UInt64? {
        var size: vm_size_t = 0
        guard host_page_size(mach_host_self(), &size) == KERN_SUCCESS else { return nil }
        return UInt64(size)
    }
}

struct CPUTicks: Equatable {
    var user: UInt64
    var system: UInt64
    var idle: UInt64
    var nice: UInt64

    var busy: UInt64 { user &+ system &+ nice }
    var total: UInt64 { busy &+ idle }

    /// Busy fraction since `previous`. Tick counters are monotonic and may wrap.
    func utilization(since previous: CPUTicks) -> Double {
        let deltaBusy = Double(busy &- previous.busy)
        let deltaTotal = Double(total &- previous.total)
        guard deltaTotal > 0 else { return 0 }
        return min(1, max(0, deltaBusy / deltaTotal))
    }

    static func fromLoadInfo(_ info: host_cpu_load_info) -> CPUTicks {
        withUnsafeBytes(of: info.cpu_ticks) { raw in
            let ticks = raw.bindMemory(to: natural_t.self)
            return CPUTicks(
                user: UInt64(ticks[0]),
                system: UInt64(ticks[1]),
                idle: UInt64(ticks[2]),
                nice: UInt64(ticks[3])
            )
        }
    }
}

struct CoreTickBuffer {
    var ticks: [CPUTicks]

    static func read() -> CoreTickBuffer? {
        var processorCount: natural_t = 0
        var infoArray: processor_info_array_t?
        var infoCount: mach_msg_type_number_t = 0
        let status = host_processor_info(
            mach_host_self(),
            PROCESSOR_CPU_LOAD_INFO,
            &processorCount,
            &infoArray,
            &infoCount
        )
        guard status == KERN_SUCCESS, let infoArray else { return nil }
        defer {
            let bytes = vm_size_t(MemoryLayout<integer_t>.stride * Int(infoCount))
            vm_deallocate(mach_task_self_, vm_address_t(UInt(bitPattern: infoArray)), bytes)
        }

        let states = Int(CPU_STATE_MAX)
        var ticks: [CPUTicks] = []
        ticks.reserveCapacity(Int(processorCount))
        for core in 0..<Int(processorCount) {
            let base = core * states
            ticks.append(
                CPUTicks(
                    user: UInt64(infoArray[base + Int(CPU_STATE_USER)]),
                    system: UInt64(infoArray[base + Int(CPU_STATE_SYSTEM)]),
                    idle: UInt64(infoArray[base + Int(CPU_STATE_IDLE)]),
                    nice: UInt64(infoArray[base + Int(CPU_STATE_NICE)])
                )
            )
        }
        return CoreTickBuffer(ticks: ticks)
    }
}

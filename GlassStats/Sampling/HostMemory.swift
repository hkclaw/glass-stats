import Foundation

/// Physical RAM accounting from `host_statistics64(HOST_VM_INFO64)` and
/// `ProcessInfo.physicalMemory` (`hw.memsize`).
///
/// Used memory follows Activity Monitor's "Memory Used" idea: app (internal
/// minus purgeable) + wired + compressor. The file cache is excluded so a
/// healthy Mac does not read as ~100% full.
enum HostMemory {
    static func sample() -> MemorySnapshot {
        guard let info = MachSupport.hostVMInfo64(), let pageSize = MachSupport.pageSize() else {
            return .empty
        }

        let physical = ProcessInfo.processInfo.physicalMemory
        let internalPages = UInt64(info.internal_page_count)
        let purgeablePages = UInt64(info.purgeable_count)
        let appPages = internalPages > purgeablePages ? internalPages - purgeablePages : 0

        return MemorySnapshot(
            physicalBytes: physical,
            appBytes: appPages * pageSize,
            wiredBytes: UInt64(info.wire_count) * pageSize,
            compressedBytes: UInt64(info.compressor_page_count) * pageSize,
            cachedBytes: UInt64(info.external_page_count) * pageSize,
            freeBytes: UInt64(info.free_count) * pageSize,
            isReady: true
        )
    }
}

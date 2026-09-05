import Foundation

/// Root volume capacity via Foundation URL resource values (statfs under the hood).
enum HostDisk {
    static func sample() -> DiskSnapshot {
        let url = URL(fileURLWithPath: "/")
        let keys: Set<URLResourceKey> = [
            .volumeNameKey,
            .volumeTotalCapacityKey,
            .volumeAvailableCapacityForImportantUsageKey,
            .volumeAvailableCapacityKey
        ]
        guard let values = try? url.resourceValues(forKeys: keys) else {
            return .empty
        }

        let total = UInt64(values.volumeTotalCapacity ?? 0)
        let important = values.volumeAvailableCapacityForImportantUsage.map { UInt64(clamping: $0) }
        let available = important ?? UInt64(values.volumeAvailableCapacity ?? 0)
        let name = values.volumeName ?? "/"

        return DiskSnapshot(
            volumeName: name,
            totalBytes: total,
            availableBytes: available,
            isReady: total > 0
        )
    }
}

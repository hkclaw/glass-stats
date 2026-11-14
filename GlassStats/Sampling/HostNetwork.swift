import Darwin
import Foundation
import GlassStatsCore

/// Interface byte counters from `getifaddrs` / `AF_LINK` `if_data`.
/// Throughput is the delta between samples. A decrease is zero, so an interface
/// going away is not treated as a wrapped counter.
struct HostNetwork {
    private var ledger = InterfaceLedger()
    private var previousAt: Date?

    mutating func sample() -> NetworkSnapshot {
        guard let current = Self.readCounters() else { return .empty }
        let now = Date()
        guard let previousAt else {
            self.previousAt = now
            _ = ledger.consume(current)
            return NetworkSnapshot(
                bytesInPerSecond: 0,
                bytesOutPerSecond: 0,
                bytesInThisSample: 0,
                bytesOutThisSample: 0,
                isReady: false
            )
        }
        let elapsed = now.timeIntervalSince(previousAt)
        guard elapsed > 0 else { return .empty }
        self.previousAt = now
        let delta = ledger.consume(current)
        return NetworkSnapshot(
            bytesInPerSecond: UInt64((Double(delta.inbound) / elapsed).rounded()),
            bytesOutPerSecond: UInt64((Double(delta.outbound) / elapsed).rounded()),
            bytesInThisSample: delta.inbound,
            bytesOutThisSample: delta.outbound,
            isReady: delta.ready
        )
    }

    private static func readCounters() -> [InterfaceCounter]? {
        var head: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&head) == 0, let first = head else { return nil }
        defer { freeifaddrs(head) }

        var counters: [InterfaceCounter] = []
        var cursor: UnsafeMutablePointer<ifaddrs>? = first
        while let interface = cursor {
            let flags = Int32(interface.pointee.ifa_flags)
            let isUp = (flags & IFF_UP) == IFF_UP
            let isLoopback = (flags & IFF_LOOPBACK) == IFF_LOOPBACK
            if isUp, !isLoopback, let addr = interface.pointee.ifa_addr, addr.pointee.sa_family == UInt8(AF_LINK),
               let namePtr = interface.pointee.ifa_name, let raw = interface.pointee.ifa_data {
                let data = raw.assumingMemoryBound(to: if_data.self).pointee
                counters.append(
                    InterfaceCounter(
                        name: String(cString: namePtr),
                        inbound: UInt64(data.ifi_ibytes),
                        outbound: UInt64(data.ifi_obytes)
                    )
                )
            }
            cursor = interface.pointee.ifa_next
        }
        return counters
    }
}

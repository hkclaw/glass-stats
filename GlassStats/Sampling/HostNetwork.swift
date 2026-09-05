import Darwin
import Foundation

/// Interface byte counters from `getifaddrs` / `AF_LINK` `if_data`.
/// Throughput is the delta between samples. 32-bit `ifi_*bytes` wrap is handled.
struct HostNetwork {
    private var previous: Counters?
    private var previousAt: Date?

    private struct Counters {
        var inbound: UInt64
        var outbound: UInt64
    }

    mutating func sample() -> NetworkSnapshot {
        guard let current = Self.readCounters() else { return .empty }
        let now = Date()
        defer {
            previous = current
            previousAt = now
        }
        guard let previous, let previousAt else {
            return NetworkSnapshot(bytesInPerSecond: 0, bytesOutPerSecond: 0, isReady: false)
        }
        let elapsed = now.timeIntervalSince(previousAt)
        guard elapsed > 0 else { return .empty }

        let inbound = Self.delta(current.inbound, previous.inbound)
        let outbound = Self.delta(current.outbound, previous.outbound)
        return NetworkSnapshot(
            bytesInPerSecond: UInt64((Double(inbound) / elapsed).rounded()),
            bytesOutPerSecond: UInt64((Double(outbound) / elapsed).rounded()),
            isReady: true
        )
    }

    private static func delta(_ current: UInt64, _ previous: UInt64) -> UInt64 {
        if current >= previous { return current - previous }
        return current &+ (UInt64(UInt32.max) &+ 1) &- previous
    }

    private static func readCounters() -> Counters? {
        var head: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&head) == 0, let first = head else { return nil }
        defer { freeifaddrs(head) }

        var inbound: UInt64 = 0
        var outbound: UInt64 = 0
        var cursor: UnsafeMutablePointer<ifaddrs>? = first
        while let interface = cursor {
            let flags = Int32(interface.pointee.ifa_flags)
            let isUp = (flags & IFF_UP) == IFF_UP
            let isLoopback = (flags & IFF_LOOPBACK) == IFF_LOOPBACK
            if isUp, !isLoopback, let addr = interface.pointee.ifa_addr, addr.pointee.sa_family == UInt8(AF_LINK) {
                if let raw = interface.pointee.ifa_data {
                    let data = raw.assumingMemoryBound(to: if_data.self).pointee
                    inbound += UInt64(data.ifi_ibytes)
                    outbound += UInt64(data.ifi_obytes)
                }
            }
            cursor = interface.pointee.ifa_next
        }
        return Counters(inbound: inbound, outbound: outbound)
    }
}

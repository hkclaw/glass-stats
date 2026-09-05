import Foundation

struct SystemSnapshot: Equatable {
    var timestamp: Date
    var cpu: CPUSnapshot
    var memory: MemorySnapshot
    var disk: DiskSnapshot
    var network: NetworkSnapshot
    var battery: BatterySnapshot

    static let empty = SystemSnapshot(
        timestamp: .distantPast,
        cpu: .empty,
        memory: .empty,
        disk: .empty,
        network: .empty,
        battery: .empty
    )
}

struct CPUSnapshot: Equatable {
    /// Fraction of all logical cores that are busy, 0...1.
    var total: Double
    /// Per-core busy fractions, 0...1, in Mach processor order.
    var cores: [Double]
    /// False until two Mach tick samples exist (utilization is a delta).
    var isReady: Bool

    static let empty = CPUSnapshot(total: 0, cores: [], isReady: false)
}

struct MemorySnapshot: Equatable {
    var physicalBytes: UInt64
    var appBytes: UInt64
    var wiredBytes: UInt64
    var compressedBytes: UInt64
    var cachedBytes: UInt64
    var freeBytes: UInt64
    var isReady: Bool

    /// Activity Monitor–style used = app + wired + compressed (file cache excluded).
    var usedBytes: UInt64 { appBytes + wiredBytes + compressedBytes }

    var usedRatio: Double {
        guard physicalBytes > 0 else { return 0 }
        return min(1, Double(usedBytes) / Double(physicalBytes))
    }

    static let empty = MemorySnapshot(
        physicalBytes: 0,
        appBytes: 0,
        wiredBytes: 0,
        compressedBytes: 0,
        cachedBytes: 0,
        freeBytes: 0,
        isReady: false
    )
}

struct DiskSnapshot: Equatable {
    var volumeName: String
    var totalBytes: UInt64
    var availableBytes: UInt64
    var isReady: Bool

    var usedBytes: UInt64 { totalBytes > availableBytes ? totalBytes - availableBytes : 0 }

    var usedRatio: Double {
        guard totalBytes > 0 else { return 0 }
        return min(1, Double(usedBytes) / Double(totalBytes))
    }

    static let empty = DiskSnapshot(volumeName: "/", totalBytes: 0, availableBytes: 0, isReady: false)
}

struct NetworkSnapshot: Equatable {
    var bytesInPerSecond: UInt64
    var bytesOutPerSecond: UInt64
    var isReady: Bool

    static let empty = NetworkSnapshot(bytesInPerSecond: 0, bytesOutPerSecond: 0, isReady: false)
}

struct BatterySnapshot: Equatable {
    var isPresent: Bool
    var fraction: Double?
    var isCharging: Bool
    var isPluggedIn: Bool
    var timeRemainingMinutes: Int?
    var isReady: Bool

    static let empty = BatterySnapshot(
        isPresent: false,
        fraction: nil,
        isCharging: false,
        isPluggedIn: true,
        timeRemainingMinutes: nil,
        isReady: false
    )
}

struct HistoryPoint: Identifiable, Equatable {
    var id: Date { date }
    var date: Date
    var cpu: Double
    var memory: Double
}

struct ProcessRow: Identifiable, Equatable {
    var id: Int32 { pid }
    var pid: Int32
    var name: String
    /// Share of *all* logical cores, 0...1. Can exceed 1/ncpu on a single core.
    var cpu: Double
    var residentBytes: UInt64
}

struct SampleResult: Equatable {
    var snapshot: SystemSnapshot
    var processes: [ProcessRow]
}

enum Formatters {
    static let byteCount: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .memory
        formatter.allowedUnits = [.useMB, .useGB, .useTB]
        return formatter
    }()

    static func percent(_ value: Double) -> String {
        "\(Int((value * 100).rounded()))%"
    }

    static func bytes(_ value: UInt64) -> String {
        byteCount.string(fromByteCount: Int64(clamping: value))
    }

    static func rate(_ bytesPerSecond: UInt64) -> String {
        let formatted = ByteCountFormatter.string(fromByteCount: Int64(clamping: bytesPerSecond), countStyle: .file)
        return "\(formatted)/s"
    }
}

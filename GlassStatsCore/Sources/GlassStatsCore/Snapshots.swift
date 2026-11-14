import Foundation

public struct SystemSnapshot: Equatable {
    public var timestamp: Date
    public var cpu: CPUSnapshot
    public var memory: MemorySnapshot
    public var disk: DiskSnapshot
    public var network: NetworkSnapshot
    public var battery: BatterySnapshot

    public init(
        timestamp: Date,
        cpu: CPUSnapshot,
        memory: MemorySnapshot,
        disk: DiskSnapshot,
        network: NetworkSnapshot,
        battery: BatterySnapshot
    ) {
        self.timestamp = timestamp
        self.cpu = cpu
        self.memory = memory
        self.disk = disk
        self.network = network
        self.battery = battery
    }

    public static let empty = SystemSnapshot(
        timestamp: .distantPast,
        cpu: .empty,
        memory: .empty,
        disk: .empty,
        network: .empty,
        battery: .empty
    )
}

public struct CPUSnapshot: Equatable {
    /// Fraction of all logical cores that are busy, 0...1.
    public var total: Double
    /// Per-core busy fractions, 0...1, in Mach processor order.
    public var cores: [Double]
    /// False until two Mach tick samples exist (utilization is a delta).
    public var isReady: Bool

    public init(total: Double, cores: [Double], isReady: Bool) {
        self.total = total
        self.cores = cores
        self.isReady = isReady
    }

    public static let empty = CPUSnapshot(total: 0, cores: [], isReady: false)
}

public struct MemorySnapshot: Equatable {
    public var physicalBytes: UInt64
    public var appBytes: UInt64
    public var wiredBytes: UInt64
    public var compressedBytes: UInt64
    public var cachedBytes: UInt64
    public var freeBytes: UInt64
    public var isReady: Bool

    public init(
        physicalBytes: UInt64,
        appBytes: UInt64,
        wiredBytes: UInt64,
        compressedBytes: UInt64,
        cachedBytes: UInt64,
        freeBytes: UInt64,
        isReady: Bool
    ) {
        self.physicalBytes = physicalBytes
        self.appBytes = appBytes
        self.wiredBytes = wiredBytes
        self.compressedBytes = compressedBytes
        self.cachedBytes = cachedBytes
        self.freeBytes = freeBytes
        self.isReady = isReady
    }

    /// Used memory matches Activity Monitor: app + wired + compressed. File cache is excluded.
    public var usedBytes: UInt64 { appBytes + wiredBytes + compressedBytes }

    public var usedRatio: Double {
        guard physicalBytes > 0 else { return 0 }
        return min(1, Double(usedBytes) / Double(physicalBytes))
    }

    public static let empty = MemorySnapshot(
        physicalBytes: 0,
        appBytes: 0,
        wiredBytes: 0,
        compressedBytes: 0,
        cachedBytes: 0,
        freeBytes: 0,
        isReady: false
    )
}

public struct DiskSnapshot: Equatable {
    public var volumeName: String
    public var totalBytes: UInt64
    public var availableBytes: UInt64
    public var isReady: Bool

    public init(volumeName: String, totalBytes: UInt64, availableBytes: UInt64, isReady: Bool) {
        self.volumeName = volumeName
        self.totalBytes = totalBytes
        self.availableBytes = availableBytes
        self.isReady = isReady
    }

    public var usedBytes: UInt64 { totalBytes > availableBytes ? totalBytes - availableBytes : 0 }

    public var usedRatio: Double {
        guard totalBytes > 0 else { return 0 }
        return min(1, Double(usedBytes) / Double(totalBytes))
    }

    public static let empty = DiskSnapshot(volumeName: "/", totalBytes: 0, availableBytes: 0, isReady: false)
}

public struct NetworkSnapshot: Equatable {
    public var bytesInPerSecond: UInt64
    public var bytesOutPerSecond: UInt64
    /// Zero when `isReady` is false.
    public var bytesInThisSample: UInt64
    public var bytesOutThisSample: UInt64
    public var isReady: Bool

    public init(
        bytesInPerSecond: UInt64,
        bytesOutPerSecond: UInt64,
        bytesInThisSample: UInt64,
        bytesOutThisSample: UInt64,
        isReady: Bool
    ) {
        self.bytesInPerSecond = bytesInPerSecond
        self.bytesOutPerSecond = bytesOutPerSecond
        self.bytesInThisSample = bytesInThisSample
        self.bytesOutThisSample = bytesOutThisSample
        self.isReady = isReady
    }

    public static let empty = NetworkSnapshot(
        bytesInPerSecond: 0,
        bytesOutPerSecond: 0,
        bytesInThisSample: 0,
        bytesOutThisSample: 0,
        isReady: false
    )
}

public struct BatterySnapshot: Equatable {
    public var isPresent: Bool
    public var fraction: Double?
    public var isCharging: Bool
    public var isPluggedIn: Bool
    public var timeRemainingMinutes: Int?
    public var isReady: Bool

    public init(
        isPresent: Bool,
        fraction: Double?,
        isCharging: Bool,
        isPluggedIn: Bool,
        timeRemainingMinutes: Int?,
        isReady: Bool
    ) {
        self.isPresent = isPresent
        self.fraction = fraction
        self.isCharging = isCharging
        self.isPluggedIn = isPluggedIn
        self.timeRemainingMinutes = timeRemainingMinutes
        self.isReady = isReady
    }

    public static let empty = BatterySnapshot(
        isPresent: false,
        fraction: nil,
        isCharging: false,
        isPluggedIn: true,
        timeRemainingMinutes: nil,
        isReady: false
    )
}

public struct HistoryPoint: Identifiable, Equatable {
    public var id: Date { date }
    public var date: Date
    public var cpu: Double
    public var memory: Double

    public init(date: Date, cpu: Double, memory: Double) {
        self.date = date
        self.cpu = cpu
        self.memory = memory
    }
}

public struct ProcessRow: Identifiable, Equatable {
    public var id: Int32 { pid }
    public var pid: Int32
    public var name: String
    /// Share of one logical core, matching Activity Monitor. 1.0 is 100% of one core.
    public var cpu: Double
    public var residentBytes: UInt64

    public init(pid: Int32, name: String, cpu: Double, residentBytes: UInt64) {
        self.pid = pid
        self.name = name
        self.cpu = cpu
        self.residentBytes = residentBytes
    }
}

public struct SampleRequest: Equatable {
    public var cpu: Bool
    public var memory: Bool
    public var disk: Bool
    public var network: Bool
    public var battery: Bool
    public var processes: Bool

    public init(cpu: Bool, memory: Bool, disk: Bool, network: Bool, battery: Bool, processes: Bool) {
        self.cpu = cpu
        self.memory = memory
        self.disk = disk
        self.network = network
        self.battery = battery
        self.processes = processes
    }
}

public struct SampledChannels: Equatable {
    public var cpu: Bool
    public var memory: Bool
    public var disk: Bool
    public var network: Bool
    public var battery: Bool
    public var processes: Bool

    public init(cpu: Bool, memory: Bool, disk: Bool, network: Bool, battery: Bool, processes: Bool) {
        self.cpu = cpu
        self.memory = memory
        self.disk = disk
        self.network = network
        self.battery = battery
        self.processes = processes
    }
}

public struct SampleResult: Equatable {
    public var snapshot: SystemSnapshot
    public var processes: [ProcessRow]
    public var sampled: SampledChannels

    public init(snapshot: SystemSnapshot, processes: [ProcessRow], sampled: SampledChannels) {
        self.snapshot = snapshot
        self.processes = processes
        self.sampled = sampled
    }
}

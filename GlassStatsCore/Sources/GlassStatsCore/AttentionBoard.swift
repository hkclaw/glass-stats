import Foundation

public struct SamplingSituation: Equatable {
    public var popoverOpen: Bool
    public var showCPUInMenuBar: Bool
    public var showMemoryInMenuBar: Bool
    public var cpuEnabled: Bool
    public var memoryEnabled: Bool
    public var diskEnabled: Bool
    public var networkEnabled: Bool
    public var batteryEnabled: Bool
    public var processesEnabled: Bool

    public init(
        popoverOpen: Bool,
        showCPUInMenuBar: Bool,
        showMemoryInMenuBar: Bool,
        cpuEnabled: Bool,
        memoryEnabled: Bool,
        diskEnabled: Bool,
        networkEnabled: Bool,
        batteryEnabled: Bool,
        processesEnabled: Bool
    ) {
        self.popoverOpen = popoverOpen
        self.showCPUInMenuBar = showCPUInMenuBar
        self.showMemoryInMenuBar = showMemoryInMenuBar
        self.cpuEnabled = cpuEnabled
        self.memoryEnabled = memoryEnabled
        self.diskEnabled = diskEnabled
        self.networkEnabled = networkEnabled
        self.batteryEnabled = batteryEnabled
        self.processesEnabled = processesEnabled
    }
}

public struct SamplePlan: Equatable {
    public var request: SampleRequest
    public var readPressure: Bool
    public var readSleepHold: Bool
    public var scanFolders: Bool

    public init(request: SampleRequest, readPressure: Bool, readSleepHold: Bool, scanFolders: Bool) {
        self.request = request
        self.readPressure = readPressure
        self.readSleepHold = readSleepHold
        self.scanFolders = scanFolders
    }
}

public struct MenuToken: Equatable {
    public var text: String
    public var accessibility: String

    public init(text: String, accessibility: String) {
        self.text = text
        self.accessibility = accessibility
    }
}

public struct MenuHeadline: Equatable {
    public var cpu: MenuToken?
    public var memory: MenuToken?
    public var accessibilityLabel: String

    public init(cpu: MenuToken?, memory: MenuToken?, accessibilityLabel: String) {
        self.cpu = cpu
        self.memory = memory
        self.accessibilityLabel = accessibilityLabel
    }
}

public struct ProcessDecision: Equatable {
    public var allowed: Bool
    public var copyText: String
    public var confirmTitle: String
    public var confirmMessage: String

    public init(allowed: Bool, copyText: String, confirmTitle: String, confirmMessage: String) {
        self.allowed = allowed
        self.copyText = copyText
        self.confirmTitle = confirmTitle
        self.confirmMessage = confirmMessage
    }

    public static func make(row: ProcessRow, residentDelta: Int64?, thisAppPid: Int32) -> ProcessDecision {
        let protected: Set<String> = ["kernel_task", "launchd", "windowserver", "loginwindow"]
        let allowed = row.pid != 0
            && row.pid != 1
            && row.pid != thisAppPid
            && !protected.contains(row.name.lowercased())
        guard allowed else {
            return ProcessDecision(allowed: false, copyText: "", confirmTitle: "", confirmMessage: "")
        }
        var copy = "\(row.name) \(row.pid) \(TextFormat.percent(row.cpu)) \(TextFormat.bytes(row.residentBytes))"
        if let residentDelta, residentDelta != 0 {
            copy += " \(TextFormat.signedBytes(residentDelta)) since open"
        }
        return ProcessDecision(
            allowed: true,
            copyText: copy,
            confirmTitle: "Quit \(row.name)?",
            confirmMessage: "Sends a normal quit to \(row.name) (pid \(row.pid)). Unsaved work in that app may be lost."
        )
    }
}

public struct ProcessAttention: Equatable, Identifiable {
    public var id: Int32 { row.pid }
    public var row: ProcessRow
    public var residentDelta: Int64?
    public var sinceOpenLabel: String?
    public var decision: ProcessDecision

    public init(row: ProcessRow, residentDelta: Int64?, sinceOpenLabel: String?, decision: ProcessDecision) {
        self.row = row
        self.residentDelta = residentDelta
        self.sinceOpenLabel = sinceOpenLabel
        self.decision = decision
    }
}

public struct SpikeEvent: Equatable, Identifiable, Codable {
    public var id: UUID
    public var at: Date
    public var total: Double
    public var processName: String?
    public var processCPU: Double?

    public init(id: UUID, at: Date, total: Double, processName: String?, processCPU: Double?) {
        self.id = id
        self.at = at
        self.total = total
        self.processName = processName
        self.processCPU = processCPU
    }
}

public enum NetworkDirection: Equatable, Codable {
    case inbound
    case outbound

    public var label: String {
        switch self {
        case .inbound: return "Down"
        case .outbound: return "Up"
        }
    }
}

public struct BurstEvent: Equatable, Identifiable, Codable {
    public var id: UUID
    public var at: Date
    public var direction: NetworkDirection
    public var bytes: UInt64

    public init(id: UUID, at: Date, direction: NetworkDirection, bytes: UInt64) {
        self.id = id
        self.at = at
        self.direction = direction
        self.bytes = bytes
    }
}

public struct DrainRate: Equatable {
    public var line: String

    public init(line: String) {
        self.line = line
    }
}

public struct DiskDrop: Equatable {
    public var bytes: UInt64
    public var detail: String
    public var waitingForCulprits: Bool

    public init(bytes: UInt64, detail: String, waitingForCulprits: Bool) {
        self.bytes = bytes
        self.detail = detail
        self.waitingForCulprits = waitingForCulprits
    }
}

public struct FolderCulprit: Equatable, Identifiable {
    public var id: String { name }
    public var name: String
    public var bytes: UInt64
    public var isPartial: Bool

    public init(name: String, bytes: UInt64, isPartial: Bool) {
        self.name = name
        self.bytes = bytes
        self.isPartial = isPartial
    }

    public var label: String {
        var text = "\(name) \(TextFormat.bytes(bytes))"
        if isPartial {
            text += " or more"
        }
        return text
    }
}

public struct SleepHold: Equatable {
    public var pid: Int32
    public var name: String

    public init(pid: Int32, name: String) {
        self.pid = pid
        self.name = name
    }

    public var line: String { "Idle sleep held by \(name)" }
}

public struct SleepCandidate: Equatable {
    public var pid: Int32
    public var name: String
    public var type: String

    public init(pid: Int32, name: String, type: String) {
        self.pid = pid
        self.name = name
        self.type = type
    }
}

public enum SleepSelection {
    public static let holdingTypes: Set<String> = [
        "PreventUserIdleSystemSleep",
        "NoIdleSleepAssertion",
        "PreventUserIdleDisplaySleep",
        "NoDisplaySleepAssertion",
    ]

    public static let skippedNames: Set<String> = [
        "powerd",
        "kernel_task",
        "launchd",
        "windowserver",
        "loginwindow",
    ]

    public static func holder(from candidates: [SleepCandidate]) -> SleepHold? {
        let match = candidates
            .filter { holdingTypes.contains($0.type) }
            .filter { !skippedNames.contains($0.name.lowercased()) }
            .sorted { $0.pid < $1.pid }
        guard let first = match.first else { return nil }
        let name = first.name.isEmpty ? "pid \(first.pid)" : first.name
        return SleepHold(pid: first.pid, name: name)
    }
}

public enum MemoryPressure: Equatable {
    case normal
    case warning
    case urgent
    case critical

    public var cardLabel: String {
        switch self {
        case .normal: return "Normal"
        case .warning: return "Warning"
        case .urgent: return "Urgent"
        case .critical: return "Critical"
        }
    }

    public static func mapping(_ raw: Int?) -> MemoryPressure {
        switch raw {
        case 2: return .warning
        case 4: return .urgent
        case 8: return .critical
        default: return .normal
        }
    }
}

public struct Attention: Equatable {
    public var headline: MenuHeadline
    public var pressure: MemoryPressure
    public var spikes: [SpikeEvent]
    public var bursts: [BurstEvent]
    public var drain: DrainRate?
    public var sleepHold: SleepHold?
    public var diskDrop: DiskDrop?
    public var culprits: [FolderCulprit]
    public var rows: [ProcessAttention]

    public init(
        headline: MenuHeadline,
        pressure: MemoryPressure,
        spikes: [SpikeEvent],
        bursts: [BurstEvent],
        drain: DrainRate?,
        sleepHold: SleepHold?,
        diskDrop: DiskDrop?,
        culprits: [FolderCulprit],
        rows: [ProcessAttention]
    ) {
        self.headline = headline
        self.pressure = pressure
        self.spikes = spikes
        self.bursts = bursts
        self.drain = drain
        self.sleepHold = sleepHold
        self.diskDrop = diskDrop
        self.culprits = culprits
        self.rows = rows
    }
}

public enum TextFormat {
    public static func percent(_ value: Double) -> String {
        "\(Int((value * 100).rounded()))%"
    }

    public static func bytes(_ value: UInt64) -> String {
        formatMagnitude(Double(value))
    }

    public static func signedBytes(_ delta: Int64) -> String {
        if delta == 0 { return "0 B" }
        let sign = delta > 0 ? "+" : "-"
        let magnitude = delta == Int64.min ? Double(Int64.max) + 1 : Double(abs(delta))
        return sign + formatMagnitude(magnitude)
    }

    private static func formatMagnitude(_ value: Double) -> String {
        let units = ["B", "KB", "MB", "GB", "TB"]
        var amount = value
        var index = 0
        while amount >= 1024, index < units.count - 1 {
            amount /= 1024
            index += 1
        }
        let number: String
        if index == 0 || amount >= 10 {
            number = String(Int(amount.rounded()))
        } else {
            number = oneDecimal(amount)
        }
        return "\(number) \(units[index])"
    }

    static func oneDecimal(_ value: Double) -> String {
        let scaled = Int((value * 10).rounded())
        let whole = scaled / 10
        let fraction = abs(scaled % 10)
        return "\(whole).\(fraction)"
    }
}

public struct AttentionTick {
    enum Kind {
        case sample(SamplePayload)
        case situation
        case folders([FolderCulprit])
    }

    struct SamplePayload {
        var result: SampleResult
        var plan: SamplePlan
        var thisAppPid: Int32
        var logicalCores: Int
        var pressureRaw: Int?
        var sleepHold: SleepHold?
    }

    var at: Date
    var situation: SamplingSituation
    var kind: Kind

    public static func sample(
        result: SampleResult,
        plan: SamplePlan,
        at: Date,
        situation: SamplingSituation,
        thisAppPid: Int32,
        logicalCores: Int,
        pressureRaw: Int?,
        sleepHold: SleepHold?
    ) -> AttentionTick {
        AttentionTick(
            at: at,
            situation: situation,
            kind: .sample(
                SamplePayload(
                    result: result,
                    plan: plan,
                    thisAppPid: thisAppPid,
                    logicalCores: logicalCores,
                    pressureRaw: pressureRaw,
                    sleepHold: sleepHold
                )
            )
        )
    }

    public static func situation(_ situation: SamplingSituation, at: Date) -> AttentionTick {
        AttentionTick(at: at, situation: situation, kind: .situation)
    }

    public static func folders(
        _ folders: [FolderCulprit],
        at: Date,
        situation: SamplingSituation
    ) -> AttentionTick {
        AttentionTick(at: at, situation: situation, kind: .folders(folders))
    }
}

public struct AttentionBoard {
    private var daybook = DiskDaybook()
    private var cpuSlot = NoticeSlot()
    private var memorySlot = NoticeSlot()
    private var spikeLatch = SpikeLatch.idle
    private var inboundBurst = BurstLatch.quiet
    private var outboundBurst = BurstLatch.quiet
    private var baselines: [BaselineKey: Baseline] = [:]
    private var charge: [ChargeSample] = []
    private var culprits: [FolderCulprit] = []
    private var scanSatisfied = false
    private var sleepHold: SleepHold?
    private var pressure = MemoryPressure.normal
    private var rows: [ProcessAttention] = []
    private var spikes: [SpikeEvent] = []
    private var bursts: [BurstEvent] = []
    private var drain: DrainRate?
    private var diskDrop: DiskDrop?
    private var applied: [Channel: Date] = [:]
    private var marks: [Channel: Date] = [:]
    private var lastCPU: CPUSnapshot?
    private var lastMemoryReady = false
    private var lastMemoryRatio = 0.0
    private var situation: SamplingSituation
    private var calendar: Calendar
    private var lastTickAt: Date
    private var lastAppliedAt: Date
    private var headline: MenuHeadline
    private var published: Attention

    public init(
        restoring data: Data? = nil,
        now: Date,
        situation: SamplingSituation,
        calendar: Calendar = .current
    ) {
        self.situation = situation
        self.calendar = calendar
        self.lastTickAt = now
        self.lastAppliedAt = .distantPast
        self.headline = MenuHeadline(cpu: nil, memory: nil, accessibilityLabel: "Glass Stats")
        self.published = Attention(
            headline: MenuHeadline(cpu: nil, memory: nil, accessibilityLabel: "Glass Stats"),
            pressure: .normal,
            spikes: [],
            bursts: [],
            drain: nil,
            sleepHold: nil,
            diskDrop: nil,
            culprits: [],
            rows: []
        )
        if let data, let archive = Archive.decode(data), archive.version == 1 {
            spikes = archive.spikes
            bursts = archive.bursts
            daybook = archive.disk
        }
        prune(at: now)
        refreshDiskPresentation()
        publishTokens()
        published = makeAttention()
    }

    public mutating func ingest(_ tick: AttentionTick) -> Attention {
        guard tick.at >= lastAppliedAt else { return published }
        lastAppliedAt = tick.at
        situation = tick.situation
        lastTickAt = tick.at
        switch tick.kind {
        case .sample(let payload):
            applySample(payload, at: tick.at)
        case .situation:
            break
        case .folders(let folders):
            applyFolders(folders, at: tick.at)
        }
        applyVisibility()
        prune(at: tick.at)
        published = makeAttention()
        return published
    }

    public func plan(at: Date, situation: SamplingSituation) -> SamplePlan {
        let cpu = cpuWanted(situation)
        let memory = memoryWanted(situation)
        let battery = situation.batteryEnabled && (situation.popoverOpen || markMissingOrOlderThan(.battery, seconds: 30, at: at))
        let disk = situation.diskEnabled && (situation.popoverOpen || markMissingOrOlderThan(.disk, seconds: 300, at: at))
        let processes = situation.processesEnabled && (
            situation.popoverOpen || (machineIsHot && markMissingOrOlderThan(.processes, seconds: 2, at: at))
        )
        let dropBytes = daybook.drop(asOf: at, calendar: calendar) ?? 0
        return SamplePlan(
            request: SampleRequest(
                cpu: cpu,
                memory: memory,
                disk: disk,
                network: situation.networkEnabled,
                battery: battery,
                processes: processes
            ),
            readPressure: memory,
            readSleepHold: situation.popoverOpen,
            scanFolders: situation.popoverOpen
                && situation.diskEnabled
                && dropBytes >= Self.twoGiB
                && !scanSatisfied
        )
    }

    public func persistableData() -> Data {
        Archive(version: 1, spikes: spikes, bursts: bursts, disk: daybook).encode()
    }

    public var attention: Attention { published }

    private mutating func applySample(_ payload: AttentionTick.SamplePayload, at: Date) {
        let result = payload.result
        if result.sampled.cpu, claim(.cpu, at: at) {
            lastCPU = result.snapshot.cpu
            let cpu = result.snapshot.cpu
            if cpu.isReady {
                if result.sampled.processes {
                    let owner = ownerToken(cpu: cpu, processes: result.processes, logicalCores: payload.logicalCores)
                    cpuSlot.first.advance(qualifies: owner != nil, fresh: owner)
                } else if !isHot(cpu) {
                    cpuSlot.first.advance(qualifies: false, fresh: nil)
                }
                let pegged = peggedToken(cpu)
                cpuSlot.second.advance(qualifies: pegged != nil, fresh: pegged)
                let hit = cpu.total >= 0.60 || (cpu.cores.max() ?? 0) >= 0.95
                if spikeLatch.observe(hit: hit, at: at) {
                    let top = result.sampled.processes ? result.processes.first : nil
                    let named = (top?.cpu ?? 0) > 0 ? top : nil
                    spikes.insert(
                        SpikeEvent(
                            id: UUID(),
                            at: at,
                            total: cpu.total,
                            processName: named?.name,
                            processCPU: named?.cpu
                        ),
                        at: 0
                    )
                }
            }
        }

        if result.sampled.processes, claim(.processes, at: at) {
            marks[.processes] = at
            rows = makeRows(result.processes, at: at, thisAppPid: payload.thisAppPid)
        }

        if payload.plan.readPressure, claim(.pressure, at: at) {
            let level = MemoryPressure.mapping(payload.pressureRaw)
            pressure = level
            let token = pressureToken(level)
            memorySlot.first.advance(qualifies: token != nil, fresh: token)
        }

        if result.sampled.disk, claim(.disk, at: at) {
            marks[.disk] = at
            if result.snapshot.disk.isReady {
                daybook.record(available: result.snapshot.disk.availableBytes, at: at, calendar: calendar)
                refreshDiskPresentation()
                let qualifies = (diskDrop?.bytes ?? 0) >= Self.twoGiB
                let fresh = qualifies ? diskMenuToken(diskDrop?.bytes ?? 0) : nil
                memorySlot.second.advance(qualifies: qualifies, fresh: fresh)
            }
        }

        if result.sampled.network, claim(.network, at: at), result.snapshot.network.isReady {
            let network = result.snapshot.network
            if inboundBurst.observe(burst: Self.isBurst(bytes: network.bytesInThisSample, rate: network.bytesInPerSecond), at: at) {
                bursts.insert(BurstEvent(id: UUID(), at: at, direction: .inbound, bytes: network.bytesInThisSample), at: 0)
            }
            if outboundBurst.observe(burst: Self.isBurst(bytes: network.bytesOutThisSample, rate: network.bytesOutPerSecond), at: at) {
                bursts.insert(BurstEvent(id: UUID(), at: at, direction: .outbound, bytes: network.bytesOutThisSample), at: 0)
            }
        }

        if result.sampled.memory {
            if result.snapshot.memory.isReady {
                lastMemoryReady = true
                lastMemoryRatio = result.snapshot.memory.usedRatio
            } else {
                lastMemoryReady = false
            }
        }

        if result.sampled.battery, claim(.battery, at: at) {
            marks[.battery] = at
            if result.snapshot.battery.isReady {
                applyBattery(result.snapshot.battery, at: at)
            }
        }

        if payload.plan.readSleepHold, claim(.sleep, at: at) {
            sleepHold = situation.popoverOpen ? payload.sleepHold : nil
        }
    }

    private mutating func applyFolders(_ folders: [FolderCulprit], at: Date) {
        guard claim(.folders, at: at) else { return }
        let drop = daybook.drop(asOf: at, calendar: calendar) ?? 0
        guard situation.popoverOpen, drop >= Self.twoGiB else { return }
        culprits = folders.sorted { $0.bytes > $1.bytes }
        scanSatisfied = true
    }

    private mutating func applyBattery(_ battery: BatterySnapshot, at: Date) {
        guard battery.isPresent, !battery.isPluggedIn, !battery.isCharging, let fraction = battery.fraction else {
            charge.removeAll()
            drain = nil
            return
        }
        charge.append(ChargeSample(at: at, fraction: fraction))
        charge.removeAll { $0.at > at || at.timeIntervalSince($0.at) > 600 }
        charge.sort { $0.at < $1.at }
        guard let oldest = charge.first, let newest = charge.last else {
            drain = nil
            return
        }
        let span = newest.at.timeIntervalSince(oldest.at)
        guard span >= 180, newest.fraction < oldest.fraction else {
            drain = nil
            return
        }
        let hours = span / 3600
        let perHour = (oldest.fraction - newest.fraction) * 100 / hours
        let rounded = Int(perHour.rounded())
        var line = rounded == 0 ? "<1%/h" : "\(rounded)%/h"
        if let top = rows.first, top.row.cpu >= 0.30 {
            line += " · \(top.row.name)"
        }
        drain = DrainRate(line: line)
    }

    private mutating func applyVisibility() {
        if !cpuWanted(situation) {
            cpuSlot = NoticeSlot()
        }
        if !situation.processesEnabled {
            cpuSlot.first = Candidate()
        }
        if !memoryWanted(situation) {
            memorySlot.first = Candidate()
        }
        if !situation.diskEnabled {
            memorySlot.second = Candidate()
        }
        if !situation.popoverOpen {
            culprits = []
            scanSatisfied = false
            sleepHold = nil
        }
        refreshDiskPresentation()
        publishTokens()
    }

    private mutating func refreshDiskPresentation() {
        guard situation.diskEnabled, let drop = daybook.drop(asOf: lastTickAt, calendar: calendar) else {
            diskDrop = nil
            return
        }
        diskDrop = DiskDrop(
            bytes: drop,
            detail: "\(TextFormat.bytes(drop)) less free than yesterday",
            waitingForCulprits: situation.popoverOpen && drop >= Self.twoGiB && !scanSatisfied
        )
    }

    private mutating func publishTokens() {
        let cpuToken: MenuToken?
        if !cpuWanted(situation) {
            cpuToken = nil
        } else if let cpu = lastCPU, cpu.isReady {
            cpuToken = cpuSlot.resolve(
                quiet: MenuToken(
                    text: TextFormat.percent(cpu.total),
                    accessibility: "CPU \(TextFormat.percent(cpu.total))"
                )
            )
        } else {
            cpuToken = MenuToken(text: "—", accessibility: "CPU unavailable")
        }

        let memoryToken: MenuToken?
        if !memoryWanted(situation) {
            memoryToken = nil
        } else if lastMemoryReady || memorySlot.first.latch.isShowing || memorySlot.second.latch.isShowing {
            let quiet = lastMemoryReady
                ? MenuToken(
                    text: TextFormat.percent(lastMemoryRatio),
                    accessibility: "memory \(TextFormat.percent(lastMemoryRatio))"
                )
                : MenuToken(text: "—", accessibility: "memory unavailable")
            memoryToken = memorySlot.resolve(quiet: quiet)
        } else {
            memoryToken = MenuToken(text: "—", accessibility: "memory unavailable")
        }

        let fragments = [cpuToken?.accessibility, memoryToken?.accessibility].compactMap { $0 }
        let label = fragments.isEmpty ? "Glass Stats" : "Glass Stats, " + fragments.joined(separator: ", ")
        headline = MenuHeadline(cpu: cpuToken, memory: memoryToken, accessibilityLabel: label)
    }

    private func makeAttention() -> Attention {
        Attention(
            headline: headline,
            pressure: pressure,
            spikes: spikes,
            bursts: bursts,
            drain: drain,
            sleepHold: sleepHold,
            diskDrop: diskDrop,
            culprits: culprits,
            rows: rows
        )
    }

    private mutating func makeRows(_ processes: [ProcessRow], at: Date, thisAppPid: Int32) -> [ProcessAttention] {
        var current = Set<BaselineKey>()
        let built = processes.map { row -> ProcessAttention in
            let key = BaselineKey(pid: row.pid, name: row.name)
            current.insert(key)
            let delta: Int64?
            if let existing = baselines[key] {
                let difference = Int64(clamping: row.residentBytes) - Int64(clamping: existing.bytes)
                baselines[key] = Baseline(bytes: existing.bytes, seenAt: at)
                delta = difference == 0 ? nil : difference
            } else {
                baselines[key] = Baseline(bytes: row.residentBytes, seenAt: at)
                delta = nil
            }
            let label = delta.map { "\(TextFormat.signedBytes($0)) since open" }
            return ProcessAttention(
                row: row,
                residentDelta: delta,
                sinceOpenLabel: label,
                decision: ProcessDecision.make(row: row, residentDelta: delta, thisAppPid: thisAppPid)
            )
        }
        trimBaselines(keeping: current)
        return built
    }

    private mutating func trimBaselines(keeping current: Set<BaselineKey>) {
        while baselines.count > 300 {
            guard let victim = baselines
                .filter({ !current.contains($0.key) })
                .min(by: { $0.value.seenAt < $1.value.seenAt })?
                .key
            else { return }
            baselines.removeValue(forKey: victim)
        }
    }

    private mutating func prune(at: Date) {
        let cutoff = at.addingTimeInterval(-24 * 60 * 60)
        spikes.removeAll { $0.at < cutoff }
        bursts.removeAll { $0.at < cutoff }
        if spikes.count > 20 {
            spikes.removeLast(spikes.count - 20)
        }
        if bursts.count > 20 {
            bursts.removeLast(bursts.count - 20)
        }
    }

    private mutating func claim(_ channel: Channel, at: Date) -> Bool {
        if applied[channel] == at { return false }
        applied[channel] = at
        return true
    }

    private func markMissingOrOlderThan(_ channel: Channel, seconds: TimeInterval, at: Date) -> Bool {
        guard let mark = marks[channel] else { return true }
        return at.timeIntervalSince(mark) >= seconds
    }

    private var machineIsHot: Bool {
        guard let lastCPU else { return false }
        return isHot(lastCPU)
    }

    private func isHot(_ cpu: CPUSnapshot) -> Bool {
        cpu.isReady && (cpu.total >= 0.25 || (cpu.cores.max() ?? 0) >= 0.80)
    }

    private func cpuWanted(_ situation: SamplingSituation) -> Bool {
        situation.showCPUInMenuBar || (situation.popoverOpen && situation.cpuEnabled)
    }

    private func memoryWanted(_ situation: SamplingSituation) -> Bool {
        situation.showMemoryInMenuBar || (situation.popoverOpen && situation.memoryEnabled)
    }

    private func coreCount(cpu: CPUSnapshot, logicalCores: Int) -> Int {
        if !cpu.cores.isEmpty { return cpu.cores.count }
        return max(logicalCores, 1)
    }

    private func ownerToken(cpu: CPUSnapshot, processes: [ProcessRow], logicalCores: Int) -> MenuToken? {
        let busy = cpu.total * Double(coreCount(cpu: cpu, logicalCores: logicalCores))
        guard busy >= 0.5 else { return nil }
        guard let owner = processes
            .filter({ $0.cpu >= 0.70 && $0.cpu >= 0.5 * busy })
            .max(by: { $0.cpu < $1.cpu })
        else { return nil }
        return MenuToken(text: menuName(owner.name), accessibility: "CPU owned by \(owner.name)")
    }

    private func peggedToken(_ cpu: CPUSnapshot) -> MenuToken? {
        guard !cpu.cores.isEmpty else { return nil }
        guard let maxValue = cpu.cores.max() else { return nil }
        let mean = cpu.cores.reduce(0, +) / Double(cpu.cores.count)
        guard maxValue >= 0.85, cpu.total <= 0.40, maxValue - mean >= 0.45 else { return nil }
        let index = (cpu.cores.firstIndex(of: maxValue) ?? 0) + 1
        let percent = TextFormat.percent(maxValue)
        return MenuToken(text: "\(index)c \(percent)", accessibility: "CPU core \(index) at \(percent)")
    }

    private func pressureToken(_ level: MemoryPressure) -> MenuToken? {
        switch level {
        case .normal:
            return nil
        case .warning:
            return MenuToken(text: "warn", accessibility: "memory warning")
        case .urgent:
            return MenuToken(text: "crit", accessibility: "memory urgent")
        case .critical:
            return MenuToken(text: "crit", accessibility: "memory critical")
        }
    }

    private func diskMenuToken(_ bytes: UInt64) -> MenuToken {
        let gib = Double(bytes) / 1_073_741_824
        let text = gib < 10 ? "-\(TextFormat.oneDecimal(gib))GB" : "-\(Int(gib.rounded()))GB"
        return MenuToken(text: text, accessibility: "disk \(TextFormat.bytes(bytes)) less free than yesterday")
    }

    private func menuName(_ name: String) -> String {
        if name.count <= 16 { return name }
        return String(name.prefix(15)) + "…"
    }

    private static let twoGiB: UInt64 = 2 * 1024 * 1024 * 1024
    private static let twentyMiB: UInt64 = 20 * 1024 * 1024
    private static let eightMiB: UInt64 = 8 * 1024 * 1024
    private static let fiveMiB: UInt64 = 5 * 1024 * 1024

    private static func isBurst(bytes: UInt64, rate: UInt64) -> Bool {
        bytes >= twentyMiB || (bytes >= eightMiB && rate >= fiveMiB)
    }
}

private enum Channel: Hashable {
    case cpu
    case processes
    case pressure
    case disk
    case network
    case battery
    case sleep
    case folders
}

private struct BaselineKey: Hashable {
    var pid: Int32
    var name: String
}

private struct Baseline {
    var bytes: UInt64
    var seenAt: Date
}

private struct ChargeSample {
    var at: Date
    var fraction: Double
}

private enum HeadlineLatch: Equatable {
    case down
    case seenOnce
    case seenTwice
    case up
    case missedOnce

    var isShowing: Bool { self == .up || self == .missedOnce }

    func advance(qualifies: Bool) -> HeadlineLatch {
        switch (self, qualifies) {
        case (.down, true):
            return .seenOnce
        case (.seenOnce, true):
            return .seenTwice
        case (.seenTwice, true):
            return .up
        case (.up, true):
            return .up
        case (.missedOnce, true):
            return .up
        case (.up, false):
            return .missedOnce
        case (.missedOnce, false):
            return .down
        case (_, false):
            return .down
        }
    }
}

private struct Candidate: Equatable {
    var latch = HeadlineLatch.down
    var posted: MenuToken?

    mutating func advance(qualifies: Bool, fresh: MenuToken?) {
        latch = latch.advance(qualifies: qualifies)
        if latch.isShowing, let fresh {
            posted = fresh
        } else if !latch.isShowing {
            posted = nil
        }
    }
}

private struct NoticeSlot: Equatable {
    var first = Candidate()
    var second = Candidate()

    func resolve(quiet: MenuToken) -> MenuToken {
        if first.latch.isShowing, let posted = first.posted { return posted }
        if second.latch.isShowing, let posted = second.posted { return posted }
        return quiet
    }
}

private enum SpikeLatch: Equatable {
    case idle
    case once
    case twice
    case cooling(until: Date)

    mutating func observe(hit: Bool, at: Date) -> Bool {
        if case .cooling(let until) = self {
            if at < until { return false }
            self = .idle
        }
        guard hit else {
            self = .idle
            return false
        }
        switch self {
        case .idle:
            self = .once
            return false
        case .once:
            self = .twice
            return false
        case .twice:
            self = .cooling(until: at.addingTimeInterval(120))
            return true
        case .cooling:
            return false
        }
    }
}

private enum BurstLatch: Equatable {
    case quiet
    case cooling(until: Date)

    mutating func observe(burst: Bool, at: Date) -> Bool {
        if case .cooling(let until) = self {
            if at < until { return false }
            self = .quiet
        }
        guard burst else { return false }
        self = .cooling(until: at.addingTimeInterval(60))
        return true
    }
}

private struct LocalDay: Equatable, Codable {
    var year: Int
    var month: Int
    var day: Int
}

private struct DiskDaybook: Codable {
    var today: LocalDay?
    var todayAvailable: UInt64?
    var yesterday: LocalDay?
    var yesterdayAvailable: UInt64?

    func drop(asOf: Date, calendar: Calendar) -> UInt64? {
        let day = LocalDay.from(asOf, calendar: calendar)
        guard today == day,
              let yesterday,
              yesterday == day.previous(calendar: calendar),
              let todayAvailable,
              let yesterdayAvailable,
              todayAvailable < yesterdayAvailable
        else { return nil }
        return yesterdayAvailable - todayAvailable
    }

    mutating func record(available: UInt64, at: Date, calendar: Calendar) {
        let day = LocalDay.from(at, calendar: calendar)
        guard let today else {
            self.today = day
            todayAvailable = available
            return
        }
        if today == day {
            todayAvailable = available
            return
        }
        if today == day.previous(calendar: calendar) {
            yesterday = today
            yesterdayAvailable = todayAvailable
        } else {
            yesterday = nil
            yesterdayAvailable = nil
        }
        self.today = day
        todayAvailable = available
    }
}

private extension LocalDay {
    static func from(_ date: Date, calendar: Calendar) -> LocalDay {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return LocalDay(year: parts.year ?? 1, month: parts.month ?? 1, day: parts.day ?? 1)
    }

    func previous(calendar: Calendar) -> LocalDay? {
        var parts = DateComponents()
        parts.year = year
        parts.month = month
        parts.day = day
        guard let date = calendar.date(from: parts),
              let previous = calendar.date(byAdding: .day, value: -1, to: date)
        else { return nil }
        return LocalDay.from(previous, calendar: calendar)
    }
}

private struct Archive: Codable {
    var version: Int
    var spikes: [SpikeEvent]
    var bursts: [BurstEvent]
    var disk: DiskDaybook

    func encode() -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        encoder.outputFormatting = [.sortedKeys]
        return (try? encoder.encode(self)) ?? Data()
    }

    static func decode(_ data: Data) -> Archive? {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        return try? decoder.decode(Archive.self, from: data)
    }
}

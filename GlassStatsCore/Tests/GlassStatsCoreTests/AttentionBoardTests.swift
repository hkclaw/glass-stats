import XCTest
import GlassStatsCore

final class AttentionBoardTests: XCTestCase {
    private let start = Date(timeIntervalSince1970: 1_767_225_600) // 2026-01-01 00:00:00 UTC
    private var calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }()

    func testQuietPercents() {
        var board = makeBoard()
        let at = start.addingTimeInterval(12 * 3600)
        board.ingest(tick(at: at, cpu: 0.18, cores: Array(repeating: 0.18, count: 8), memory: 0.46))
        let headline = board.attention.headline
        XCTAssertEqual(headline.cpu?.text, "18%")
        XCTAssertEqual(headline.memory?.text, "46%")
        XCTAssertEqual(headline.accessibilityLabel, "Glass Stats, CPU 18%, memory 46%")
    }

    func testOwnerAppearsOnTheThirdSampleAndClearsOnTheSecondMiss() {
        var board = makeBoard()
        var at = start
        board.ingest(ownerTick(at: at))
        board.ingest(ownerTick(at: at))
        at = at.addingTimeInterval(1)
        board.ingest(ownerTick(at: at))
        XCTAssertEqual(board.attention.headline.cpu?.text, "12%")
        at = at.addingTimeInterval(1)
        board.ingest(ownerTick(at: at))
        XCTAssertEqual(board.attention.headline.cpu?.text, "Xcode")
        XCTAssertEqual(board.attention.headline.cpu?.accessibility, "CPU owned by Xcode")

        at = at.addingTimeInterval(1)
        board.ingest(tick(at: at, cpu: 0.50, cores: Array(repeating: 0.50, count: 8), processes: false))
        XCTAssertEqual(board.attention.headline.cpu?.text, "Xcode")
        at = at.addingTimeInterval(1)
        board.ingest(tick(at: at, cpu: 0.05, cores: Array(repeating: 0.05, count: 8), processes: false))
        XCTAssertEqual(board.attention.headline.cpu?.text, "Xcode")
        at = at.addingTimeInterval(1)
        board.ingest(tick(at: at, cpu: 0.05, cores: Array(repeating: 0.05, count: 8), processes: false))
        XCTAssertEqual(board.attention.headline.cpu?.text, "5%")
    }

    func testHotSampleWithoutProcessesDoesNotResetTheOwner() {
        var board = makeBoard()
        var at = start
        for _ in 0..<3 {
            board.ingest(ownerTick(at: at))
            at = at.addingTimeInterval(1)
        }
        XCTAssertEqual(board.attention.headline.cpu?.text, "Xcode")
        board.ingest(tick(at: at, cpu: 0.40, cores: Array(repeating: 0.40, count: 8), processes: false))
        XCTAssertEqual(board.attention.headline.cpu?.text, "Xcode")
    }

    func testOwnerOutranksAPeggedCore() {
        var board = makeBoard()
        var at = start
        let cores = [0.98, 0.02, 0.02, 0.02]
        for _ in 0..<3 {
            board.ingest(tick(
                at: at,
                cpu: 0.20,
                cores: cores,
                processes: true,
                rows: [ProcessRow(pid: 40, name: "Xcode", cpu: 0.90, residentBytes: 10)]
            ))
            at = at.addingTimeInterval(1)
        }
        XCTAssertEqual(board.attention.headline.cpu?.text, "Xcode")
    }

    func testPeggedCoreHidesACalmAverage() {
        var board = makeBoard()
        var at = start
        for _ in 0..<3 {
            board.ingest(tick(at: at, cpu: 0.10, cores: [0.98, 0.02, 0.02, 0.02], processes: true, rows: []))
            at = at.addingTimeInterval(1)
        }
        XCTAssertEqual(board.attention.headline.cpu?.text, "1c 98%")
        XCTAssertEqual(board.attention.headline.cpu?.accessibility, "CPU core 1 at 98%")
    }

    func testHighTotalDoesNotShowAPeggedCore() {
        var board = makeBoard()
        var at = start
        for _ in 0..<3 {
            board.ingest(tick(at: at, cpu: 0.50, cores: [0.99, 0.40, 0.40, 0.40], processes: true, rows: []))
            at = at.addingTimeInterval(1)
        }
        XCTAssertEqual(board.attention.headline.cpu?.text, "50%")
    }

    func testSpikeRecordsOnTheThirdHitAndAgainAfterTheCooldown() {
        var board = makeBoard()
        var at = start
        board.ingest(tick(at: at, cpu: 0.70, cores: [0.70]))
        at = at.addingTimeInterval(1)
        board.ingest(tick(at: at, cpu: 0.10, cores: [0.10]))
        at = at.addingTimeInterval(1)
        board.ingest(tick(at: at, cpu: 0.70, cores: [0.70]))
        at = at.addingTimeInterval(1)
        board.ingest(tick(at: at, cpu: 0.70, cores: [0.70]))
        XCTAssertTrue(board.attention.spikes.isEmpty)

        var fires: [Date] = []
        at = start
        board = makeBoard()
        for _ in 0..<21 {
            board.ingest(tick(at: at, cpu: 0.70, cores: [0.70], processes: true, rows: [
                ProcessRow(pid: 9, name: "clang", cpu: 1.2, residentBytes: 1)
            ]))
            at = at.addingTimeInterval(1)
            board.ingest(tick(at: at, cpu: 0.70, cores: [0.70], processes: true, rows: [
                ProcessRow(pid: 9, name: "clang", cpu: 1.2, residentBytes: 1)
            ]))
            at = at.addingTimeInterval(1)
            board.ingest(tick(at: at, cpu: 0.70, cores: [0.70], processes: true, rows: [
                ProcessRow(pid: 9, name: "clang", cpu: 1.2, residentBytes: 1)
            ]))
            fires.append(at)
            at = at.addingTimeInterval(121)
        }
        XCTAssertEqual(board.attention.spikes.count, 20)
        XCTAssertEqual(board.attention.spikes.first?.at, fires.last)
        XCTAssertEqual(board.attention.spikes.first?.processName, "clang")
        XCTAssertFalse(board.attention.spikes.contains { $0.at == fires.first })

        var quiet = makeBoard()
        let spikeAt = start
        quiet.ingest(tick(at: spikeAt, cpu: 0.99, cores: [0.99], processes: false))
        quiet.ingest(tick(at: spikeAt.addingTimeInterval(1), cpu: 0.99, cores: [0.99], processes: false))
        quiet.ingest(tick(at: spikeAt.addingTimeInterval(2), cpu: 0.99, cores: [0.99], processes: false))
        XCTAssertEqual(quiet.attention.spikes.count, 1)
        XCTAssertNil(quiet.attention.spikes[0].processName)
    }

    func testPressureWords() {
        var board = makeBoard()
        var at = start
        board.ingest(tick(at: at, cpu: 0.10, cores: [0.10], memory: 0.40, pressure: 2))
        at = at.addingTimeInterval(1)
        board.ingest(tick(at: at, cpu: 0.10, cores: [0.10], memory: 0.40, pressure: 2))
        XCTAssertEqual(board.attention.headline.memory?.text, "40%")
        XCTAssertEqual(board.attention.pressure.cardLabel, "Warning")
        at = at.addingTimeInterval(1)
        board.ingest(tick(at: at, cpu: 0.10, cores: [0.10], memory: 0.40, pressure: 2))
        XCTAssertEqual(board.attention.headline.memory?.text, "warn")
        XCTAssertEqual(board.attention.headline.memory?.accessibility, "memory warning")

        at = at.addingTimeInterval(1)
        board.ingest(tick(at: at, cpu: 0.10, cores: [0.10], memory: 0.40, pressure: 4))
        XCTAssertEqual(board.attention.headline.memory?.text, "crit")
        XCTAssertEqual(board.attention.pressure.cardLabel, "Urgent")
        at = at.addingTimeInterval(1)
        board.ingest(tick(at: at, cpu: 0.10, cores: [0.10], memory: 0.40, pressure: 8))
        XCTAssertEqual(board.attention.headline.memory?.text, "crit")
        XCTAssertEqual(board.attention.pressure.cardLabel, "Critical")
        XCTAssertEqual(board.attention.headline.memory?.accessibility, "memory critical")

        at = at.addingTimeInterval(1)
        board.ingest(tick(at: at, cpu: 0.10, cores: [0.10], memory: 0.40, pressure: nil, includePressure: true))
        XCTAssertEqual(board.attention.pressure, .normal)
        XCTAssertEqual(board.attention.headline.memory?.text, "crit")
        at = at.addingTimeInterval(1)
        board.ingest(tick(at: at, cpu: 0.10, cores: [0.10], memory: 0.40, pressure: 3, includePressure: true))
        XCTAssertEqual(board.attention.headline.memory?.text, "40%")
    }

    func testNetworkBurstsDebouncePerDirection() {
        var board = makeBoard()
        let at = start
        board.ingest(tick(at: at, cpu: 0.1, cores: [0.1], inbound: 20 * 1024 * 1024, inRate: 20 * 1024 * 1024))
        XCTAssertEqual(board.attention.bursts.count, 1)
        XCTAssertEqual(board.attention.bursts[0].direction, .inbound)
        board.ingest(tick(
            at: at.addingTimeInterval(10),
            cpu: 0.1,
            cores: [0.1],
            inbound: 20 * 1024 * 1024,
            outbound: 20 * 1024 * 1024,
            inRate: 1,
            outRate: 1
        ))
        XCTAssertEqual(board.attention.bursts.count, 2)
        XCTAssertEqual(board.attention.bursts[0].direction, .outbound)

        var rates = makeBoard()
        rates.ingest(tick(at: at, cpu: 0.1, cores: [0.1], inbound: 8 * 1024 * 1024, inRate: 5 * 1024 * 1024))
        XCTAssertEqual(rates.attention.bursts.count, 1)
        rates.ingest(tick(at: at.addingTimeInterval(61), cpu: 0.1, cores: [0.1], inbound: 8 * 1024 * 1024, inRate: 1 * 1024 * 1024))
        XCTAssertEqual(rates.attention.bursts.count, 1)
    }

    func testLedgerCapsAndExpiresAndRestoresWithoutLatches() {
        var board = makeBoard()
        var at = start
        board.ingest(tick(at: at, cpu: 0.9, cores: [0.9]))
        board.ingest(tick(at: at.addingTimeInterval(1), cpu: 0.9, cores: [0.9]))
        board.ingest(tick(at: at.addingTimeInterval(2), cpu: 0.9, cores: [0.9]))
        XCTAssertEqual(board.attention.spikes.count, 1)
        let later = at.addingTimeInterval(24 * 3600 + 5)
        board.ingest(tick(at: later, cpu: 0.05, cores: [0.05]))
        XCTAssertTrue(board.attention.spikes.isEmpty)

        var fresh = makeBoard(now: start)
        let dayOne = start.addingTimeInterval(12 * 3600)
        let dayTwo = dayOne.addingTimeInterval(24 * 3600)
        fresh.ingest(diskTick(at: dayOne, available: 100 * gib))
        fresh.ingest(diskTick(at: dayTwo, available: 90 * gib))
        fresh.ingest(tick(at: dayTwo.addingTimeInterval(1), cpu: 0.9, cores: [0.9]))
        fresh.ingest(tick(at: dayTwo.addingTimeInterval(2), cpu: 0.9, cores: [0.9]))
        fresh.ingest(tick(at: dayTwo.addingTimeInterval(3), cpu: 0.9, cores: [0.9]))
        let data = fresh.persistableData()
        let restored = AttentionBoard(restoring: data, now: dayTwo.addingTimeInterval(4), situation: situation(), calendar: calendar)
        XCTAssertEqual(restored.attention.spikes.count, 1)
        XCTAssertNotNil(restored.attention.diskDrop)
        XCTAssertEqual(restored.attention.headline.cpu?.text, "—")
        XCTAssertEqual(restored.attention.headline.memory?.text, "—")
        XCTAssertTrue(restored.attention.rows.isEmpty)
    }

    func testDrainRate() {
        var board = makeBoard()
        let at = start
        board.ingest(batteryTick(at: at, fraction: 0.80))
        board.ingest(batteryTick(at: at.addingTimeInterval(120), fraction: 0.70))
        XCTAssertNil(board.attention.drain)

        board.ingest(batteryTick(at: at.addingTimeInterval(600), fraction: 0.70, process: ProcessRow(pid: 7, name: "Safari", cpu: 0.40, residentBytes: 1)))
        XCTAssertEqual(board.attention.drain?.line, "60%/h · Safari")

        var rising = makeBoard()
        rising.ingest(batteryTick(at: at, fraction: 0.50))
        rising.ingest(batteryTick(at: at.addingTimeInterval(600), fraction: 0.55))
        XCTAssertNil(rising.attention.drain)

        var charging = makeBoard()
        charging.ingest(batteryTick(at: at, fraction: 0.80))
        charging.ingest(batteryTick(at: at.addingTimeInterval(600), fraction: 0.70))
        XCTAssertNotNil(charging.attention.drain)
        charging.ingest(batteryTick(at: at.addingTimeInterval(700), fraction: 0.71, charging: true))
        XCTAssertNil(charging.attention.drain)

        var quietProcess = makeBoard()
        quietProcess.ingest(batteryTick(at: at, fraction: 0.80))
        quietProcess.ingest(batteryTick(at: at.addingTimeInterval(600), fraction: 0.7999, process: ProcessRow(pid: 7, name: "Safari", cpu: 0.10, residentBytes: 1)))
        XCTAssertEqual(quietProcess.attention.drain?.line, "<1%/h")
    }

    func testDiskDaybookAndMenuThreshold() {
        var board = makeBoard()
        let dayOne = start.addingTimeInterval(12 * 3600)
        board.ingest(diskTick(at: dayOne, available: 100 * gib))
        XCTAssertNil(board.attention.diskDrop)

        let dayTwo = dayOne.addingTimeInterval(24 * 3600)
        board.ingest(diskTick(at: dayTwo, available: 99 * gib, memory: 0.46))
        XCTAssertEqual(board.attention.diskDrop?.detail, "1.0 GB less free than yesterday")
        XCTAssertEqual(board.attention.headline.memory?.text, "46%")

        let bigDay = dayTwo.addingTimeInterval(24 * 3600)
        board.ingest(diskTick(at: bigDay, available: 97 * gib, memory: 0.46))
        board.ingest(diskTick(at: bigDay.addingTimeInterval(1), available: 97 * gib, memory: 0.46))
        XCTAssertEqual(board.attention.headline.memory?.text, "46%")
        board.ingest(diskTick(at: bigDay.addingTimeInterval(2), available: 97 * gib, memory: 0.46))
        XCTAssertEqual(board.attention.headline.memory?.text, "-2.0GB")

        let skipped = bigDay.addingTimeInterval(48 * 3600)
        board.ingest(diskTick(at: skipped, available: 90 * gib, memory: 0.46))
        XCTAssertNil(board.attention.diskDrop)
    }

    func testResidentDeltaSinceOpenIsNotPersisted() {
        var board = makeBoard()
        let row = ProcessRow(pid: 12, name: "Notes", cpu: 0.1, residentBytes: 1_000_000)
        var grown = row
        grown.residentBytes = 1_000_000 + 48 * 1024 * 1024
        board.ingest(tick(at: start, cpu: 0.1, cores: [0.1], processes: true, rows: [row]))
        XCTAssertNil(board.attention.rows[0].residentDelta)
        board.ingest(tick(at: start.addingTimeInterval(2), cpu: 0.1, cores: [0.1], processes: true, rows: [grown]))
        XCTAssertEqual(board.attention.rows[0].sinceOpenLabel, "+48 MB since open")
        let restored = AttentionBoard(restoring: board.persistableData(), now: start.addingTimeInterval(3), situation: situation(), calendar: calendar)
        XCTAssertTrue(restored.attention.rows.isEmpty)
    }

    func testSamplePlanCadence() {
        var board = makeBoard()
        var at = start
        var plan = board.plan(at: at, situation: situation())
        XCTAssertFalse(plan.request.processes)
        XCTAssertTrue(plan.request.network)
        XCTAssertTrue(plan.request.battery)
        XCTAssertTrue(plan.request.disk)
        XCTAssertFalse(plan.readSleepHold)
        XCTAssertFalse(plan.scanFolders)

        board.ingest(tick(at: at, cpu: 0.05, cores: [0.05]))
        plan = board.plan(at: at.addingTimeInterval(1), situation: situation())
        XCTAssertFalse(plan.request.processes)

        board.ingest(tick(at: at.addingTimeInterval(2), cpu: 0.50, cores: [0.50]))
        plan = board.plan(at: at.addingTimeInterval(2), situation: situation())
        XCTAssertTrue(plan.request.processes)
        board.ingest(tick(at: at.addingTimeInterval(3), cpu: 0.50, cores: [0.50], processes: true, rows: []))
        plan = board.plan(at: at.addingTimeInterval(4), situation: situation())
        XCTAssertFalse(plan.request.processes)
        plan = board.plan(at: at.addingTimeInterval(5), situation: situation())
        XCTAssertTrue(plan.request.processes)

        board.ingest(batteryTick(at: at.addingTimeInterval(6), fraction: 0.9))
        plan = board.plan(at: at.addingTimeInterval(20), situation: situation())
        XCTAssertFalse(plan.request.battery)
        plan = board.plan(at: at.addingTimeInterval(36), situation: situation())
        XCTAssertTrue(plan.request.battery)
        plan = board.plan(at: at.addingTimeInterval(20), situation: situation(popover: true))
        XCTAssertTrue(plan.request.battery)
        XCTAssertTrue(plan.readSleepHold)

        board.ingest(diskTick(at: at.addingTimeInterval(7), available: 80 * gib))
        plan = board.plan(at: at.addingTimeInterval(100), situation: situation())
        XCTAssertFalse(plan.request.disk)
        plan = board.plan(at: at.addingTimeInterval(7 + 300), situation: situation())
        XCTAssertTrue(plan.request.disk)

        let tomorrow = start.addingTimeInterval(36 * 3600)
        board.ingest(diskTick(at: tomorrow, available: 70 * gib))
        plan = board.plan(at: tomorrow, situation: situation(popover: true))
        XCTAssertTrue(plan.scanFolders)
        plan = board.plan(at: tomorrow, situation: situation(popover: false))
        XCTAssertFalse(plan.scanFolders)
    }

    func testProcessDecisionRefusesProtectedProcesses() {
        let app = ProcessRow(pid: 50, name: "Mail", cpu: 0.2, residentBytes: 2048)
        let allowed = ProcessDecision.make(row: app, residentDelta: 2048, thisAppPid: 99)
        XCTAssertTrue(allowed.allowed)
        XCTAssertEqual(allowed.copyText, "Mail 50 20% 2.0 KB +2.0 KB since open")
        XCTAssertEqual(allowed.confirmTitle, "Quit Mail?")

        for row in [
            ProcessRow(pid: 0, name: "kernel_task", cpu: 0, residentBytes: 0),
            ProcessRow(pid: 1, name: "launchd", cpu: 0, residentBytes: 0),
            ProcessRow(pid: 99, name: "Glass Stats", cpu: 0, residentBytes: 0),
            ProcessRow(pid: 2, name: "WindowServer", cpu: 0, residentBytes: 0),
            ProcessRow(pid: 3, name: "loginwindow", cpu: 0, residentBytes: 0),
        ] {
            XCTAssertFalse(ProcessDecision.make(row: row, residentDelta: nil, thisAppPid: 99).allowed, row.name)
        }
    }

    func testSleepSelectionSkipsPowerdAndKeepsTheLowestApp() {
        let holder = SleepSelection.holder(from: [
            SleepCandidate(pid: 40, name: "powerd", type: "PreventUserIdleSystemSleep"),
            SleepCandidate(pid: 80, name: "Safari", type: "NoIdleSleepAssertion"),
            SleepCandidate(pid: 90, name: "Mail", type: "PreventUserIdleDisplaySleep"),
            SleepCandidate(pid: 70, name: "Chrome", type: "PreventUserIdleSystemSleep"),
        ])
        XCTAssertEqual(holder?.pid, 70)
        XCTAssertEqual(holder?.line, "Idle sleep held by Chrome")
        XCTAssertNil(SleepSelection.holder(from: [
            SleepCandidate(pid: 40, name: "powerd", type: "PreventUserIdleSystemSleep")
        ]))
        XCTAssertEqual(
            SleepSelection.holder(from: [
                SleepCandidate(pid: 15, name: "Preview", type: "PreventUserIdleDisplaySleep")
            ])?.name,
            "Preview"
        )
    }

    func testOlderTickDoesNotRewind() {
        var board = makeBoard()
        let at = start
        board.ingest(tick(at: at.addingTimeInterval(10), cpu: 0.1, cores: [0.1], inbound: 20 * 1024 * 1024, inRate: 1))
        XCTAssertEqual(board.attention.bursts.count, 1)
        board.ingest(tick(at: at.addingTimeInterval(5), cpu: 0.1, cores: [0.1], outbound: 20 * 1024 * 1024, outRate: 1))
        XCTAssertEqual(board.attention.bursts.count, 1)
        XCTAssertEqual(board.attention.bursts[0].direction, .inbound)
    }

    func testTextFormatIsStable() {
        XCTAssertEqual(TextFormat.percent(1.8), "180%")
        XCTAssertEqual(TextFormat.bytes(48 * 1024 * 1024), "48 MB")
        XCTAssertEqual(TextFormat.signedBytes(0), "0 B")
        XCTAssertEqual(TextFormat.signedBytes(-2 * 1024 * 1024), "-2.0 MB")
    }

    private var gib: UInt64 { 1024 * 1024 * 1024 }

    private func makeBoard(now: Date? = nil) -> AttentionBoard {
        AttentionBoard(restoring: nil, now: now ?? start, situation: situation(), calendar: calendar)
    }

    private func situation(popover: Bool = false) -> SamplingSituation {
        SamplingSituation(
            popoverOpen: popover,
            showCPUInMenuBar: true,
            showMemoryInMenuBar: true,
            cpuEnabled: true,
            memoryEnabled: true,
            diskEnabled: true,
            networkEnabled: true,
            batteryEnabled: true,
            processesEnabled: true
        )
    }

    private func ownerTick(at: Date) -> AttentionTick {
        tick(
            at: at,
            cpu: 0.12,
            cores: Array(repeating: 0.12, count: 8),
            processes: true,
            rows: [ProcessRow(pid: 42, name: "Xcode", cpu: 0.90, residentBytes: 20_000_000)]
        )
    }

    private func tick(
        at: Date,
        cpu: Double,
        cores: [Double],
        memory: Double? = nil,
        processes: Bool = false,
        rows: [ProcessRow] = [],
        pressure: Int? = nil,
        includePressure: Bool = false,
        inbound: UInt64 = 0,
        outbound: UInt64 = 0,
        inRate: UInt64 = 0,
        outRate: UInt64 = 0,
        network: Bool = false
    ) -> AttentionTick {
        let memoryReady = memory != nil
        let snapshot = SystemSnapshot(
            timestamp: at,
            cpu: CPUSnapshot(total: cpu, cores: cores, isReady: true),
            memory: MemorySnapshot(
                physicalBytes: 100,
                appBytes: UInt64(((memory ?? 0) * 100).rounded()),
                wiredBytes: 0,
                compressedBytes: 0,
                cachedBytes: 0,
                freeBytes: 0,
                isReady: memoryReady
            ),
            disk: .empty,
            network: NetworkSnapshot(
                bytesInPerSecond: inRate,
                bytesOutPerSecond: outRate,
                bytesInThisSample: inbound,
                bytesOutThisSample: outbound,
                isReady: network || inbound > 0 || outbound > 0
            ),
            battery: .empty
        )
        let sampled = SampledChannels(
            cpu: true,
            memory: memoryReady,
            disk: false,
            network: network || inbound > 0 || outbound > 0,
            battery: false,
            processes: processes
        )
        let current = situation()
        let plan = SamplePlan(
            request: SampleRequest(cpu: true, memory: memoryReady, disk: false, network: sampled.network, battery: false, processes: processes),
            readPressure: includePressure || pressure != nil,
            readSleepHold: false,
            scanFolders: false
        )
        return AttentionTick.sample(
            result: SampleResult(snapshot: snapshot, processes: rows, sampled: sampled),
            plan: plan,
            at: at,
            situation: current,
            thisAppPid: 99,
            logicalCores: max(cores.count, 1),
            pressureRaw: pressure,
            sleepHold: nil
        )
    }

    private func batteryTick(
        at: Date,
        fraction: Double,
        charging: Bool = false,
        process: ProcessRow? = nil
    ) -> AttentionTick {
        let snapshot = SystemSnapshot(
            timestamp: at,
            cpu: CPUSnapshot(total: 0.05, cores: [0.05], isReady: true),
            memory: MemorySnapshot(physicalBytes: 100, appBytes: 46, wiredBytes: 0, compressedBytes: 0, cachedBytes: 0, freeBytes: 0, isReady: true),
            disk: .empty,
            network: .empty,
            battery: BatterySnapshot(
                isPresent: true,
                fraction: fraction,
                isCharging: charging,
                isPluggedIn: charging,
                timeRemainingMinutes: nil,
                isReady: true
            )
        )
        let rows = process.map { [$0] } ?? []
        return AttentionTick.sample(
            result: SampleResult(
                snapshot: snapshot,
                processes: rows,
                sampled: SampledChannels(cpu: true, memory: true, disk: false, network: false, battery: true, processes: process != nil)
            ),
            plan: SamplePlan(
                request: SampleRequest(cpu: true, memory: true, disk: false, network: false, battery: true, processes: process != nil),
                readPressure: false,
                readSleepHold: false,
                scanFolders: false
            ),
            at: at,
            situation: situation(),
            thisAppPid: 99,
            logicalCores: 8,
            pressureRaw: nil,
            sleepHold: nil
        )
    }

    private func diskTick(at: Date, available: UInt64, memory: Double? = nil) -> AttentionTick {
        let snapshot = SystemSnapshot(
            timestamp: at,
            cpu: CPUSnapshot(total: 0.10, cores: [0.10], isReady: true),
            memory: MemorySnapshot(
                physicalBytes: 100,
                appBytes: UInt64(((memory ?? 0) * 100).rounded()),
                wiredBytes: 0,
                compressedBytes: 0,
                cachedBytes: 0,
                freeBytes: 0,
                isReady: memory != nil
            ),
            disk: DiskSnapshot(volumeName: "Macintosh HD", totalBytes: 200 * gib, availableBytes: available, isReady: true),
            network: .empty,
            battery: .empty
        )
        return AttentionTick.sample(
            result: SampleResult(
                snapshot: snapshot,
                processes: [],
                sampled: SampledChannels(cpu: true, memory: memory != nil, disk: true, network: false, battery: false, processes: false)
            ),
            plan: SamplePlan(
                request: SampleRequest(cpu: true, memory: memory != nil, disk: true, network: false, battery: false, processes: false),
                readPressure: false,
                readSleepHold: false,
                scanFolders: false
            ),
            at: at,
            situation: situation(),
            thisAppPid: 99,
            logicalCores: 8,
            pressureRaw: nil,
            sleepHold: nil
        )
    }
}

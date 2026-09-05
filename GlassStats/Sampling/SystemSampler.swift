import Foundation

/// Coordinates local host samples. Nothing leaves the machine.
actor SystemSampler {
    private var cpu = HostCPU()
    private var processes = HostProcesses()
    private var network = HostNetwork()

    func sample() -> SampleResult {
        let cpuSnapshot = cpu.sample()
        let memorySnapshot = HostMemory.sample()
        let diskSnapshot = HostDisk.sample()
        let networkSnapshot = network.sample()
        let batterySnapshot = HostBattery.sample()
        let top = processes.sample()

        let snapshot = SystemSnapshot(
            timestamp: Date(),
            cpu: cpuSnapshot,
            memory: memorySnapshot,
            disk: diskSnapshot,
            network: networkSnapshot,
            battery: batterySnapshot
        )
        return SampleResult(snapshot: snapshot, processes: top)
    }
}

import Foundation

/// Coordinates local host samples. Nothing leaves the machine.
/// Fields omitted from the request keep the previous reading.
actor SystemSampler {
    private var cpu = HostCPU()
    private var processes = HostProcesses()
    private var network = HostNetwork()
    private var last = SystemSnapshot.empty
    private var lastProcesses: [ProcessRow] = []

    func sample(_ request: SampleRequest) -> SampleResult {
        if request.cpu {
            last.cpu = cpu.sample()
        }
        if request.memory {
            last.memory = HostMemory.sample()
        }
        if request.disk {
            last.disk = HostDisk.sample()
        }
        if request.network {
            last.network = network.sample()
        }
        if request.battery {
            last.battery = HostBattery.sample()
        }
        if request.processes {
            lastProcesses = processes.sample()
        }
        if request.cpu || request.memory || request.disk || request.network || request.battery {
            last.timestamp = Date()
        }
        return SampleResult(
            snapshot: last,
            processes: lastProcesses,
            didSampleCPU: request.cpu,
            didSampleMemory: request.memory
        )
    }
}

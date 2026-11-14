import Darwin
import Foundation

enum HostPressure {
    static func read() -> Int? {
        var level: Int32 = 0
        var size = MemoryLayout<Int32>.size
        let result = sysctlbyname("kern.memorystatus_vm_pressure_level", &level, &size, nil, 0)
        guard result == 0 else { return nil }
        return Int(level)
    }
}

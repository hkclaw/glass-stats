import Foundation
import IOKit.ps

/// Internal battery via IOKit power sources (`IOPSCopyPowerSourcesInfo`).
/// Desktop Macs report `isPresent == false`.
enum HostBattery {
    static func sample() -> BatterySnapshot {
        guard let blob = IOPSCopyPowerSourcesInfo()?.takeRetainedValue() else {
            return BatterySnapshot(
                isPresent: false,
                fraction: nil,
                isCharging: false,
                isPluggedIn: true,
                timeRemainingMinutes: nil,
                isReady: true
            )
        }
        guard let list = IOPSCopyPowerSourcesList(blob)?.takeRetainedValue() as? [CFTypeRef] else {
            return BatterySnapshot(
                isPresent: false,
                fraction: nil,
                isCharging: false,
                isPluggedIn: true,
                timeRemainingMinutes: nil,
                isReady: true
            )
        }

        for source in list {
            guard let description = IOPSGetPowerSourceDescription(blob, source)?.takeUnretainedValue() as? [String: Any] else {
                continue
            }
            let type = description[kIOPSTypeKey as String] as? String
            let current = description[kIOPSCurrentCapacityKey as String] as? Int
            let maxCapacity = description[kIOPSMaxCapacityKey as String] as? Int
            guard type == (kIOPSInternalBatteryType as String) || (current != nil && maxCapacity != nil) else {
                continue
            }

            var fraction: Double?
            if let current, let maxCapacity, maxCapacity > 0 {
                fraction = min(1, max(0, Double(current) / Double(maxCapacity)))
            }

            let charging = description[kIOPSIsChargingKey as String] as? Bool ?? false
            let state = description[kIOPSPowerSourceStateKey as String] as? String
            let plugged = state == (kIOPSACPowerValue as String)
            let rawMinutes = (charging
                ? description[kIOPSTimeToFullChargeKey as String]
                : description[kIOPSTimeToEmptyKey as String]) as? Int
            let minutes = (rawMinutes != nil && rawMinutes! >= 0) ? rawMinutes : nil

            return BatterySnapshot(
                isPresent: true,
                fraction: fraction,
                isCharging: charging,
                isPluggedIn: plugged,
                timeRemainingMinutes: minutes,
                isReady: true
            )
        }

        return BatterySnapshot(
            isPresent: false,
            fraction: nil,
            isCharging: false,
            isPluggedIn: true,
            timeRemainingMinutes: nil,
            isReady: true
        )
    }
}

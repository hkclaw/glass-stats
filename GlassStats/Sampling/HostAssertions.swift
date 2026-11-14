import Foundation
import GlassStatsCore
import IOKit.pwr_mgt

enum HostAssertions {
    static func userIdleSleepHolder() -> SleepHold? {
        var blob: Unmanaged<CFDictionary>?
        let status = IOPMCopyAssertionsByProcess(&blob)
        guard status == kIOReturnSuccess, let blob else { return nil }
        let dictionary = blob.takeRetainedValue() as NSDictionary
        return SleepSelection.holder(from: candidates(in: dictionary))
    }

    private static func candidates(in dictionary: NSDictionary) -> [SleepCandidate] {
        var found: [SleepCandidate] = []
        for case let key as NSNumber in dictionary.allKeys {
            guard let entries = dictionary[key] as? NSArray else { continue }
            let pid = key.int32Value
            for case let entry as NSDictionary in entries {
                let declared = entry[kIOPMAssertionTypeKey as String] as? String ?? entry["AssertType"] as? String
                let effective = entry["AssertionTrueType"] as? String
                let type = [effective, declared].compactMap { $0 }.first { SleepSelection.holdingTypes.contains($0) }
                    ?? effective
                    ?? declared
                    ?? ""
                let name = (entry["Process Name"] as? String).flatMap { $0.isEmpty ? nil : $0 } ?? "pid \(pid)"
                found.append(SleepCandidate(pid: pid, name: name, type: type))
            }
        }
        return found
    }
}

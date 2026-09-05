import SwiftUI

struct BatteryModuleView: View {
    @EnvironmentObject private var store: MonitorStore

    var body: some View {
        let battery = store.snapshot.battery
        VStack(alignment: .leading, spacing: 8) {
            Label("Battery", systemImage: battery.isCharging ? "battery.100.bolt" : "battery.75")
                .font(.subheadline.weight(.semibold))

            if !battery.isReady {
                Text("Reading power sources…")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else if !battery.isPresent {
                Text("No internal battery (desktop or adapter-only).")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                if let fraction = battery.fraction {
                    ProgressView(value: fraction)
                        .tint(battery.isCharging ? .green : .yellow)
                    Text("\(Formatters.percent(fraction)) · \(statusText(battery))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text(statusText(battery))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
    }

    private func statusText(_ battery: BatterySnapshot) -> String {
        var parts: [String] = []
        if battery.isCharging {
            parts.append("Charging")
        } else if battery.isPluggedIn {
            parts.append("On adapter")
        } else {
            parts.append("On battery")
        }
        if let minutes = battery.timeRemainingMinutes {
            parts.append("\(minutes) min")
        }
        return parts.joined(separator: " · ")
    }
}

import GlassStatsCore
import SwiftUI

struct MenuBarLabel: View {
    @EnvironmentObject private var store: MonitorStore

    var body: some View {
        let headline = store.attention.headline
        HStack(spacing: 4) {
            if let cpu = headline.cpu {
                Text(cpu.text)
            }
            if headline.cpu != nil, headline.memory != nil {
                Text("·")
                    .foregroundStyle(.secondary)
            }
            if let memory = headline.memory {
                Text(memory.text)
            }
            if headline.cpu == nil, headline.memory == nil {
                Text("Glass")
            }
        }
        .font(.system(size: 11, weight: .semibold, design: .rounded))
        .monospacedDigit()
        .id("\(store.snapshot.timestamp.timeIntervalSinceReferenceDate) \(headline.cpu?.text ?? "") \(headline.memory?.text ?? "")")
        .accessibilityLabel(headline.accessibilityLabel)
    }
}

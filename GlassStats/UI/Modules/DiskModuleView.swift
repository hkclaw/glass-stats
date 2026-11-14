import GlassStatsCore
import SwiftUI

struct DiskModuleView: View {
    @EnvironmentObject private var store: MonitorStore

    var body: some View {
        let disk = store.snapshot.disk
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Label("Disk", systemImage: "internaldrive")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text(disk.isReady ? TextFormat.percent(disk.usedRatio) : "—")
                    .font(.caption.monospacedDigit())
                    .glassSecondaryText()
            }
            if disk.isReady {
                ProgressView(value: disk.usedRatio)
                    .tint(.orange)
                Text("\(disk.volumeName) · \(Formatters.bytes(disk.availableBytes)) free of \(Formatters.bytes(disk.totalBytes))")
                    .font(.caption)
                    .glassSecondaryText()
                if let drop = store.attention.diskDrop {
                    Text(drop.detail)
                        .font(.caption)
                        .glassSecondaryText()
                    if drop.waitingForCulprits {
                        Text("Checking the usual heavy folders…")
                            .font(.caption)
                            .glassSecondaryText()
                    }
                    ForEach(store.attention.culprits) { folder in
                        Text(folder.label)
                            .font(.caption.monospacedDigit())
                            .glassSecondaryText()
                    }
                }
            } else {
                Text("Unable to read the boot volume.")
                    .font(.caption)
                    .glassSecondaryText()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
    }
}

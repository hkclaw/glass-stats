import SwiftUI

struct DiskModuleView: View {
    @EnvironmentObject private var store: MonitorStore

    var body: some View {
        let disk = store.snapshot.disk
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Disk", systemImage: "internaldrive")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text(disk.isReady ? Formatters.percent(disk.usedRatio) : "—")
                    .font(.caption.monospacedDigit())
                    .glassSecondaryText()
            }
            if disk.isReady {
                ProgressView(value: disk.usedRatio)
                    .tint(.orange)
                Text("\(disk.volumeName) · \(Formatters.bytes(disk.availableBytes)) free of \(Formatters.bytes(disk.totalBytes))")
                    .font(.caption)
                    .glassSecondaryText()
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

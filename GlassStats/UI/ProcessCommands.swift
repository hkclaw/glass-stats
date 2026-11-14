import AppKit
import Darwin
import GlassStatsCore

enum ProcessCommands {
    static func copy(_ text: String) {
        guard !text.isEmpty else { return }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }

    static func reveal(pid: Int32, name: String) {
        guard allows(pid: pid, name: name) else { return }
        if let url = NSRunningApplication(processIdentifier: pid)?.bundleURL {
            NSWorkspace.shared.activateFileViewerSelecting([url])
            return
        }
        var path = [CChar](repeating: 0, count: Int(MAXPATHLEN))
        guard proc_pidpath(pid, &path, UInt32(path.count)) > 0 else { return }
        NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: String(cString: path))])
    }

    static func quit(pid: Int32, name: String) {
        guard allows(pid: pid, name: name) else { return }
        if let app = NSRunningApplication(processIdentifier: pid),
           app.localizedName?.caseInsensitiveCompare(name) == .orderedSame {
            app.terminate()
            return
        }
        kill(pid, SIGTERM)
    }

    private static func allows(pid: Int32, name: String) -> Bool {
        ProcessDecision.make(
            row: ProcessRow(pid: pid, name: name, cpu: 0, residentBytes: 0),
            residentDelta: nil,
            thisAppPid: ProcessInfo.processInfo.processIdentifier
        ).allowed
    }
}

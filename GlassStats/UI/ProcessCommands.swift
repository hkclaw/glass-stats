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

    static func quit(pid: Int32, name: String, startToken: UInt64) {
        let app = NSRunningApplication(processIdentifier: pid)
        let procMatches = currentName(pid).caseInsensitiveCompare(name) == .orderedSame
        let localizedMatches = app?.localizedName?.caseInsensitiveCompare(name) == .orderedSame
        let identity = startToken != 0 && currentStartToken(pid) == startToken
        switch QuitAction.choose(
            allowed: allows(pid: pid, name: name),
            hasRunningApplication: app != nil,
            nameStillMatches: procMatches || localizedMatches,
            identityStillMatches: identity
        ) {
        case .terminate:
            app?.terminate()
        case .signal:
            kill(pid, SIGTERM)
        case .refuse:
            break
        }
    }

    private static func currentStartToken(_ pid: Int32) -> UInt64 {
        var info = proc_bsdinfo()
        let size = Int32(MemoryLayout<proc_bsdinfo>.stride)
        let result = withUnsafeMutablePointer(to: &info) { pointer in
            proc_pidinfo(pid, PROC_PIDTBSDINFO, 0, pointer, size)
        }
        guard result == size else { return 0 }
        return info.pbi_start_tvsec &* 1_000_000 &+ info.pbi_start_tvusec
    }

    private static func currentName(_ pid: Int32) -> String {
        var buffer = [CChar](repeating: 0, count: 256)
        let length = proc_name(pid, &buffer, UInt32(buffer.count))
        guard length > 0 else { return "" }
        return String(cString: buffer)
    }

    private static func allows(pid: Int32, name: String) -> Bool {
        ProcessDecision.make(
            row: ProcessRow(pid: pid, name: name, cpu: 0, residentBytes: 0),
            residentDelta: nil,
            thisAppPid: ProcessInfo.processInfo.processIdentifier
        ).allowed
    }
}

import Foundation
import GlassStatsCore

enum FolderScan {
    private struct Root {
        var name: String
        var relativePath: String
    }

    private static let roots = [
        Root(name: "DerivedData", relativePath: "Library/Developer/Xcode/DerivedData"),
        Root(name: "Caches", relativePath: "Library/Caches"),
        Root(name: "Docker", relativePath: "Library/Containers/com.docker.docker"),
        Root(name: "CoreSimulator", relativePath: "Library/Developer/CoreSimulator"),
    ]

    static func knownHeavyFolders() -> [FolderCulprit] {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let fileManager = FileManager.default
        return roots.compactMap { root in
            let url = home.appendingPathComponent(root.relativePath)
            var isDirectory: ObjCBool = false
            guard fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory), isDirectory.boolValue else {
                return nil
            }
            let measured = measure(url, fileManager: fileManager)
            return FolderCulprit(name: root.name, bytes: measured.bytes, isPartial: measured.partial)
        }
    }

    private static func measure(_ root: URL, fileManager: FileManager) -> (bytes: UInt64, partial: Bool) {
        let keys: Set<URLResourceKey> = [
            .totalFileAllocatedSizeKey,
            .fileSizeKey,
            .isSymbolicLinkKey,
            .isDirectoryKey,
        ]
        guard let enumerator = fileManager.enumerator(
            at: root,
            includingPropertiesForKeys: Array(keys),
            options: [],
            errorHandler: { _, _ in true }
        ) else {
            return (0, false)
        }

        let started = Date()
        var files = 0
        var bytes: UInt64 = 0
        var partial = false
        while let item = enumerator.nextObject() as? URL {
            if Task.isCancelled || files >= 8_000 || Date().timeIntervalSince(started) >= 1.5 {
                partial = true
                break
            }
            files += 1
            guard let values = try? item.resourceValues(forKeys: keys) else { continue }
            if values.isSymbolicLink == true {
                enumerator.skipDescendants()
                continue
            }
            if values.isDirectory == true {
                continue
            }
            let size = values.totalFileAllocatedSize ?? values.fileSize ?? 0
            if size > 0 {
                bytes += UInt64(size)
            }
        }
        return (bytes, partial)
    }
}

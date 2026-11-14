import Foundation

enum Formatters {
    static let byteCount: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .memory
        formatter.allowedUnits = [.useMB, .useGB, .useTB]
        return formatter
    }()

    static func bytes(_ value: UInt64) -> String {
        byteCount.string(fromByteCount: Int64(clamping: value))
    }

    static func rate(_ bytesPerSecond: UInt64) -> String {
        let formatted = ByteCountFormatter.string(fromByteCount: Int64(clamping: bytesPerSecond), countStyle: .file)
        return "\(formatted)/s"
    }
}

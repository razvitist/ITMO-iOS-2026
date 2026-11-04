import Foundation

nonisolated enum AppGroup {
    static let id = "group.com.razvit.screenbattery"

    static func file(_ name: String) -> URL? {
        guard let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: id) else { return nil }
        let folder = container.appending(path: "Library/Application Support/ScreenBattery")
        let url = folder.appending(path: name)
        let legacy = container.appending(path: name)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        if !FileManager.default.fileExists(atPath: url.path()), FileManager.default.fileExists(atPath: legacy.path()) {
            try? FileManager.default.moveItem(at: legacy, to: url)
        }
        return url
    }
}

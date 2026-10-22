import Foundation

nonisolated enum RequestLog {
    private static var url: URL? { AppGroup.file("requests.log") }

    static func entries() -> [String] {
        guard let url, let text = try? String(contentsOf: url, encoding: .utf8) else { return [] }
        return text.split(separator: "\n").map(String.init).reversed()
    }

    static func add(_ message: String) {
        let line = Date.now.formatted(date: .omitted, time: .standard) + "  " + message
        write(appending(line, to: entries().reversed(), limit: ConfigStore.load().logLimit))
    }

    static func trim(to limit: Int) {
        write(Array(entries().reversed().suffix(limit)))
    }

    static func clear() {
        write([])
    }

    static func appending(_ line: String, to lines: [String], limit: Int) -> [String] {
        Array((lines + [line]).suffix(max(limit, 0)))
    }

    private static func write(_ lines: [String]) {
        guard let url else { return }
        try? lines.joined(separator: "\n").write(to: url, atomically: true, encoding: .utf8)
    }
}

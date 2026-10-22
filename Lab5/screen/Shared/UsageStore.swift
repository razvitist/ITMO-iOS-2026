import Foundation

nonisolated struct DailyUsage: Codable, Equatable, Sendable {
    var day = DailyUsage.today
    var good = 0
    var bad = 0
    var goodUpdatedAt = Calendar.current.startOfDay(for: .now)
    var badUpdatedAt = Calendar.current.startOfDay(for: .now)
    var goodSeen: Set<Int> = []
    var badSeen: Set<Int> = []

    static var today: String {
        Date.now.formatted(Date.ISO8601FormatStyle(timeZone: .current).year().month().day())
    }

    mutating func record(_ kind: AppKind, minutes: Int, at date: Date = .now) -> Bool {
        self[keyPath: kind.seen].insert(minutes)
        let current = self[keyPath: kind.minutes]
        let allowed = current + Int(date.timeIntervalSince(self[keyPath: kind.updatedAt]) / 60) + 1
        var total = self[keyPath: kind.seen].filter { $0 <= allowed }.max() ?? current
        while self[keyPath: kind.seen].contains(total + 1) { total += 1 }
        guard total > current else { return false }
        self[keyPath: kind.minutes] = total
        self[keyPath: kind.updatedAt] = date
        return true
    }
}

extension DailyUsage {
    nonisolated init(from decoder: Decoder) throws {
        self.init()
        let container = try decoder.container(keyedBy: CodingKeys.self)
        day = try container.decodeIfPresent(String.self, forKey: .day) ?? day
        good = try container.decodeIfPresent(Int.self, forKey: .good) ?? good
        bad = try container.decodeIfPresent(Int.self, forKey: .bad) ?? bad
        goodUpdatedAt = try container.decodeIfPresent(Date.self, forKey: .goodUpdatedAt) ?? goodUpdatedAt
        badUpdatedAt = try container.decodeIfPresent(Date.self, forKey: .badUpdatedAt) ?? badUpdatedAt
        goodSeen = try container.decodeIfPresent(Set<Int>.self, forKey: .goodSeen) ?? goodSeen
        badSeen = try container.decodeIfPresent(Set<Int>.self, forKey: .badSeen) ?? badSeen
    }
}

nonisolated enum UsageStore {
    static var isNewDay: Bool {
        guard let url = AppGroup.file("usage.json"), let data = try? Data(contentsOf: url),
              let usage = try? JSONDecoder().decode(DailyUsage.self, from: data)
        else { return true }
        return usage.day != DailyUsage.today
    }

    static func load() -> DailyUsage {
        guard let url = AppGroup.file("usage.json"), let data = try? Data(contentsOf: url),
              let usage = try? JSONDecoder().decode(DailyUsage.self, from: data), usage.day == DailyUsage.today
        else { return DailyUsage() }
        return usage
    }

    static func save(_ usage: DailyUsage) {
        guard let url = AppGroup.file("usage.json"), let data = try? JSONEncoder().encode(usage) else { return }
        try? data.write(to: url, options: .atomic)
    }
}

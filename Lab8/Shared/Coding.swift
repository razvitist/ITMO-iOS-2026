import Foundation

nonisolated enum CodingPlatform: String, CaseIterable, Identifiable, Sendable {
    case leetcode, codewars, stepik

    var id: Self { self }
    var title: String {
        switch self {
        case .leetcode: "LeetCode"
        case .codewars: "Codewars"
        case .stepik: "Stepik"
        }
    }
    var logo: String { "logo-\(rawValue)" }
    var hint: String {
        switch self {
        case .leetcode: "The username from leetcode.com/u/USERNAME"
        case .codewars: "The username from codewars.com/users/USERNAME"
        case .stepik: "The number from stepik.org/users/NUMBER"
        }
    }
}

nonisolated struct CodingConfig: Codable, Equatable, Sendable {
    static let rateRange = 0.0...50.0

    var leetcodeName = ""
    var leetcodeEasy = 5.0
    var leetcodeMedium = 10.0
    var leetcodeHard = 20.0
    var codewarsName = ""
    var codewarsHonor = 1.0
    var stepikID = ""
    var stepikStep = 10.0

    func account(_ platform: CodingPlatform) -> String {
        let account = switch platform {
        case .leetcode: leetcodeName
        case .codewars: codewarsName
        case .stepik: stepikID
        }
        return account.trimmingCharacters(in: .whitespaces)
    }
}

nonisolated struct LeetCodeCounts: Codable, Equatable, Sendable {
    var easy = 0
    var medium = 0
    var hard = 0
}

nonisolated struct CodingCounter: Codable, Equatable, Sendable {
    var baseline: Int?
    var latest: Int?

    var today: Int { max((latest ?? 0) - (baseline ?? latest ?? 0), 0) }

    mutating func update(_ value: Int) {
        if baseline == nil { baseline = value }
        latest = value
    }

    mutating func reset(to value: Int) {
        baseline = value
        latest = value
    }
}

nonisolated struct CodingBonus: Equatable, Sendable {
    var leetcode = 0.0
    var codewars = 0.0
    var stepik = 0.0

    var total: Double { leetcode + codewars + stepik }

    func value(for platform: CodingPlatform) -> Double {
        switch platform {
        case .leetcode: leetcode
        case .codewars: codewars
        case .stepik: stepik
        }
    }
}

nonisolated struct CodingProgress: Codable, Equatable, Sendable {
    var day = DailyUsage.today
    var updatedAt: Date?
    var leetcodeUser = ""
    var codewarsUser = ""
    var stepikUser = ""
    var easy = CodingCounter()
    var medium = CodingCounter()
    var hard = CodingCounter()
    var honor = CodingCounter()
    var stepikToday = 0

    mutating func update(leetcode: LeetCodeCounts?, honor newHonor: Int?, stepik: Int?,
                         config: CodingConfig, today: String = DailyUsage.today, at date: Date = .now) {
        let newDay = day != today
        if newDay {
            day = today
            stepikToday = 0
            for keyPath in [\CodingProgress.easy, \.medium, \.hard, \.honor] {
                if let latest = self[keyPath: keyPath].latest { self[keyPath: keyPath].baseline = latest }
            }
        }
        if let leetcode {
            if leetcodeUser != config.account(.leetcode) {
                leetcodeUser = config.account(.leetcode)
                easy.reset(to: leetcode.easy)
                medium.reset(to: leetcode.medium)
                hard.reset(to: leetcode.hard)
            } else {
                easy.update(leetcode.easy)
                medium.update(leetcode.medium)
                hard.update(leetcode.hard)
            }
        }
        if let newHonor {
            if codewarsUser != config.account(.codewars) {
                codewarsUser = config.account(.codewars)
                honor.reset(to: newHonor)
            } else {
                honor.update(newHonor)
            }
        }
        if let stepik {
            stepikUser = config.account(.stepik)
            stepikToday = stepik
        }
        updatedAt = date
    }

    func bonus(_ config: CodingConfig, today: String = DailyUsage.today) -> CodingBonus {
        guard day == today else { return CodingBonus() }
        let leetcode = Double(easy.today) * config.leetcodeEasy
            + Double(medium.today) * config.leetcodeMedium
            + Double(hard.today) * config.leetcodeHard
        return CodingBonus(
            leetcode: config.account(.leetcode).isEmpty ? 0 : leetcode,
            codewars: config.account(.codewars).isEmpty ? 0 : Double(honor.today) * config.codewarsHonor,
            stepik: config.account(.stepik).isEmpty ? 0 : Double(stepikToday) * config.stepikStep
        )
    }
}

nonisolated enum CodingStore {
    static func load() -> CodingProgress {
        guard let url = AppGroup.file("coding.json"), let data = try? Data(contentsOf: url),
              let progress = try? JSONDecoder().decode(CodingProgress.self, from: data)
        else { return CodingProgress() }
        return progress
    }

    static func save(_ progress: CodingProgress) {
        guard let url = AppGroup.file("coding.json"), let data = try? JSONEncoder().encode(progress) else { return }
        try? data.write(to: url, options: .atomic)
    }

    static func bonus(_ config: BatteryConfig) -> Double {
        load().bonus(config.coding).total
    }
}

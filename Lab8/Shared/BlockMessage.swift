import Foundation

nonisolated struct BlockMessage: Equatable {
    let title: String
    let subtitle: String
    let level: Double

    init(config: BatteryConfig, usage: DailyUsage, coding: Double = 0) {
        level = config.battery(for: usage, coding: coding).level
        title = "Battery is empty"
        var lines = if let minutes = Self.goodMinutesNeeded(config: config, usage: usage, coding: coding) {
            ["Use good apps for \(minutes) min to unlock.", "Or wait until midnight."]
        } else {
            ["Good apps don't charge it.", "Bad apps unlock at midnight."]
        }
        if CodingPlatform.allCases.contains(where: { !config.coding.account($0).isEmpty }) {
            lines.insert("Solving coding problems charges it too.", at: 1)
        }
        subtitle = "\n" + lines.joined(separator: "\n\n")
    }

    static func percent(_ level: Double) -> String {
        let value = Int((level * 100).rounded())
        return (value < 0 ? "−" : "") + "\(abs(value))%"
    }

    static func goodMinutesNeeded(config: BatteryConfig, usage: DailyUsage, coding: Double = 0) -> Int? {
        guard config.goodRate > 0 else { return nil }
        let battery = config.battery(for: usage, coding: coding)
        let deficit = battery.badDrain - battery.goodCharge - battery.coding - battery.base
        guard deficit >= 0 else { return 0 }
        return Int((deficit / config.goodRate).rounded(.down)) + 1
    }
}

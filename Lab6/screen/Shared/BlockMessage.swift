import Foundation

nonisolated struct BlockMessage: Equatable {
    let title: String
    let subtitle: String

    init(config: BatteryConfig, usage: DailyUsage) {
        let level = "Battery at " + Self.percent(config.battery(for: usage).level) + "."
        title = "Battery is empty"
        if let minutes = Self.goodMinutesNeeded(config: config, usage: usage) {
            subtitle = "\(level) Use good apps for \(minutes) min to unlock, or wait until midnight."
        } else {
            subtitle = "\(level) Good apps don't charge it, so bad apps unlock at midnight."
        }
    }

    static func percent(_ level: Double) -> String {
        let value = Int((level * 100).rounded())
        return (value < 0 ? "−" : "") + "\(abs(value))%"
    }

    static func goodMinutesNeeded(config: BatteryConfig, usage: DailyUsage) -> Int? {
        guard config.goodRate > 0 else { return nil }
        let battery = config.battery(for: usage)
        let deficit = battery.badDrain - battery.goodCharge - 50
        guard deficit >= 0 else { return 0 }
        return Int((deficit / config.goodRate).rounded(.down)) + 1
    }
}

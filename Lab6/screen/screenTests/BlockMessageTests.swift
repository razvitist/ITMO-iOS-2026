import Foundation
import Testing
@testable import screen

struct BlockMessageTests {
    private func config(good: Double, bad: Double) -> BatteryConfig {
        var config = BatteryConfig()
        config.goodRate = good
        config.badRate = bad
        return config
    }

    @Test func oneMinuteNeededAtExactlyZero() {
        #expect(BlockMessage.goodMinutesNeeded(config: config(good: 1, bad: 2), usage: DailyUsage(bad: 25)) == 1)
    }

    @Test func roundsUpPastZero() {
        #expect(BlockMessage.goodMinutesNeeded(config: config(good: 2, bad: 2), usage: DailyUsage(bad: 31)) == 7)
    }

    @Test func exactlyZeroIsNotEnough() {
        #expect(BlockMessage.goodMinutesNeeded(config: config(good: 2, bad: 2), usage: DailyUsage(bad: 30)) == 6)
    }

    @Test func countsGoodMinutesAlreadyUsed() {
        #expect(BlockMessage.goodMinutesNeeded(config: config(good: 1, bad: 2), usage: DailyUsage(good: 3, bad: 30)) == 8)
    }

    @Test func noneNeededAboveZero() {
        #expect(BlockMessage.goodMinutesNeeded(config: config(good: 1, bad: 1), usage: DailyUsage(bad: 10)) == 0)
    }

    @Test func nilWhenGoodAppsDoNotCharge() {
        #expect(BlockMessage.goodMinutesNeeded(config: config(good: 0, bad: 2), usage: DailyUsage(bad: 30)) == nil)
    }

    @Test func titleSaysEmpty() {
        #expect(BlockMessage(config: config(good: 1, bad: 2), usage: DailyUsage(bad: 30)).title == "Battery is empty")
    }

    @Test func subtitleShowsLevelAndMinutes() {
        let config = config(good: 2, bad: 2)
        let usage = DailyUsage(bad: 31)
        let level = BlockMessage.percent(config.battery(for: usage).level)
        let message = BlockMessage(config: config, usage: usage)
        #expect(message.subtitle.contains(level))
        #expect(message.subtitle.contains("7 min"))
        #expect(message.subtitle.contains("midnight"))
    }

    @Test func subtitleExplainsMidnightWithoutCharging() {
        let message = BlockMessage(config: config(good: 0, bad: 2), usage: DailyUsage(bad: 30))
        #expect(message.subtitle.contains("Good apps don't charge it"))
        #expect(!message.subtitle.contains("min to unlock"))
    }

    @Test func percentUsesTypographicMinus() {
        #expect(BlockMessage.percent(-0.16) == "−16%")
        #expect(BlockMessage.percent(0.5) == "50%")
    }
}

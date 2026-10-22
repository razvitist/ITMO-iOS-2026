import Foundation
import Testing
@testable import screen

struct BatteryConfigTests {
    @Test func startsAtHalfWithoutUsage() {
        let battery = BatteryConfig().battery(good: 0, bad: 0)
        #expect(battery.level == 0.5)
    }

    @Test func goodUsageCharges() {
        let battery = BatteryConfig().battery(good: 10 * 60, bad: 0)
        #expect(battery.level == 0.6)
        #expect(battery.goodCharge == 10)
    }

    @Test func badUsageDrains() {
        let battery = BatteryConfig().battery(good: 0, bad: 20 * 60)
        #expect(battery.level == 0.3)
        #expect(battery.badDrain == 20)
    }

    @Test func coefficientsScaleCharge() {
        var config = BatteryConfig()
        config.goodRate = 2
        config.badRate = 0.5
        let battery = config.battery(good: 10 * 60, bad: 20 * 60)
        #expect(battery.level == 0.6)
    }

    @Test(arguments: [(TimeInterval(500 * 60), TimeInterval(0), 5.5), (0, 500 * 60, -4.5)])
    func levelIsNotClamped(good: TimeInterval, bad: TimeInterval, expected: Double) {
        #expect(BatteryConfig().battery(good: good, bad: bad).level == expected)
    }

    @Test func keepsUsageTimes() {
        let battery = BatteryConfig().battery(good: 90, bad: 30)
        #expect(battery.good == 90)
        #expect(battery.bad == 30)
    }

    @Test func badMinutesLeftUntilEmpty() {
        var config = BatteryConfig()
        config.badRate = 2
        #expect(config.battery(good: 0, bad: 0).badMinutesLeft == 25)
        #expect(config.battery(good: 0, bad: 25 * 60).badMinutesLeft == nil)
    }

    @Test func noMinutesLeftWithoutDrain() {
        var config = BatteryConfig()
        config.badRate = 0
        #expect(config.battery(good: 0, bad: 600).badMinutesLeft == nil)
    }

    @Test func survivesJSONRoundTrip() throws {
        var config = BatteryConfig()
        config.goodRate = 2.5
        config.badRate = 4
        config.goodURL = "https://example.com/good"
        config.badURL = "https://example.com/bad"
        config.protection = .morse
        config.difficulty = .hard
        config.passwordHash = "hash"
        config.blockEnabled = true
        config.logLimit = 100
        let data = try JSONEncoder().encode(config)
        #expect(try JSONDecoder().decode(BatteryConfig.self, from: data) == config)
    }

    @Test func decodesOlderSettingsWithDefaults() throws {
        let data = Data(#"{"goodRate": 3, "badURL": "https://example.com/bad", "blockLevel": 0.2}"#.utf8)
        let config = try JSONDecoder().decode(BatteryConfig.self, from: data)
        #expect(config.goodRate == 3)
        #expect(config.badRate == 1)
        #expect(config.badURL == "https://example.com/bad")
        #expect(config.protection == .none)
        #expect(config.difficulty == .medium)
        #expect(!config.blockEnabled)
        #expect(config.logLimit == 30)
    }

    @Test func coefficientRangeGoesUpToTwenty() {
        #expect(BatteryConfig.rateRange == 0...20)
    }

    @Test func defaultLogLimitIsAnOption() {
        #expect(BatteryConfig.logLimits.contains(BatteryConfig().logLimit))
    }

    @Test func batteryCarriesRatesAndBlocking() {
        var config = BatteryConfig()
        config.goodRate = 5
        config.badRate = 20
        config.blockEnabled = true
        let battery = config.battery(good: 0, bad: 0)
        #expect(battery.goodRate == 5)
        #expect(battery.badRate == 20)
        #expect(battery.blockEnabled)
    }

    @Test func batteryFromDailyMinutes() {
        var config = BatteryConfig()
        config.badRate = 4
        let battery = config.battery(for: DailyUsage(good: 5, bad: 10))
        #expect(battery.level == 0.15)
        #expect(battery.good == 300)
        #expect(battery.bad == 600)
    }
}

struct BlockingTests {
    private var enabled: BatteryConfig {
        var config = BatteryConfig()
        config.blockEnabled = true
        config.badRate = 2
        return config
    }

    @Test func blocksAtZero() {
        #expect(enabled.shouldBlock(enabled.battery(for: DailyUsage(bad: 25))))
    }

    @Test func blocksBelowZero() {
        #expect(enabled.shouldBlock(enabled.battery(for: DailyUsage(bad: 40))))
    }

    @Test func doesNotBlockAboveZero() {
        #expect(!enabled.shouldBlock(enabled.battery(for: DailyUsage(bad: 24))))
    }

    @Test func goodMinutesLiftTheBlock() {
        #expect(!enabled.shouldBlock(enabled.battery(for: DailyUsage(good: 1, bad: 25))))
    }

    @Test func neverBlocksWhenDisabled() {
        var config = enabled
        config.blockEnabled = false
        #expect(!config.shouldBlock(config.battery(for: DailyUsage(bad: 100))))
    }
}

struct ProtectionTests {
    @Test func noneIsNotProtected() {
        #expect(!BatteryConfig().isProtected)
    }

    @Test func passwordNeedsHash() {
        var config = BatteryConfig()
        config.protection = .password
        #expect(!config.isProtected)
        config.passwordHash = PasswordHash.make("1234")
        #expect(config.isProtected)
    }

    @Test(arguments: [Protection.math, .morse])
    func tasksProtectWithoutSetup(_ protection: Protection) {
        var config = BatteryConfig()
        config.protection = protection
        #expect(config.isProtected)
    }
}

struct EndpointTests {
    @Test(arguments: ["https://example.com/usage", "  https://abacus.jasoncameron.dev/hit/ns/good  "])
    func acceptsHTTPS(_ link: String) {
        #expect(BatteryConfig.endpoint(from: link) != nil)
    }

    @Test(arguments: ["", "example.com", "http://example.com", "ftp://example.com", "https://"])
    func rejectsInvalid(_ link: String) {
        #expect(BatteryConfig.endpoint(from: link) == nil)
    }

    @Test func trimsWhitespace() {
        #expect(BatteryConfig.endpoint(from: " https://example.com ")?.absoluteString == "https://example.com")
    }
}

struct RequestLogTests {
    @Test func appendsNewestLast() {
        #expect(RequestLog.appending("c", to: ["a", "b"], limit: 10) == ["a", "b", "c"])
    }

    @Test func dropsOldestOverLimit() {
        #expect(RequestLog.appending("d", to: ["a", "b", "c"], limit: 3) == ["b", "c", "d"])
    }

    @Test func shrinksToSmallerLimit() {
        let lines = (1...50).map(String.init)
        #expect(RequestLog.appending("51", to: lines, limit: 10) == (42...51).map(String.init))
    }

    @Test func zeroLimitKeepsNothing() {
        #expect(RequestLog.appending("a", to: ["b"], limit: 0).isEmpty)
    }
}

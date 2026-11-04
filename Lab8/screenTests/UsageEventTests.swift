import Foundation
import DeviceActivity
import Testing
@testable import screen

struct UsageEventTests {
    @Test(arguments: AppKind.allCases, [1, 59, 60, 240])
    func eventNameRoundTrips(kind: AppKind, minutes: Int) throws {
        let usage = try #require(DeviceActivityEvent.Name(kind: kind, minutes: minutes, generation: 1_792_000_000).usage)
        #expect(usage.kind == kind)
        #expect(usage.minutes == minutes)
    }

    @Test func eventNameFormat() {
        #expect(DeviceActivityEvent.Name(kind: .bad, minutes: 37, generation: 5).rawValue == "bad.37.5")
    }

    @Test func generationsMakeDifferentNames() {
        #expect(DeviceActivityEvent.Name(kind: .bad, minutes: 3, generation: 1) != DeviceActivityEvent.Name(kind: .bad, minutes: 3, generation: 2))
    }

    @Test(arguments: ["good", "good.5", "other.5.1", "good.x.1", "good.5.x", "good.5.1.2", ""])
    func rejectsForeignNames(_ name: String) {
        #expect(DeviceActivityEvent.Name(name).usage == nil)
    }
}

struct AppKindTests {
    @Test func keyPathsTargetOwnFields() {
        var config = BatteryConfig()
        config[keyPath: AppKind.good.rate] = 3
        config[keyPath: AppKind.bad.rate] = 4
        config[keyPath: AppKind.good.url] = "good"
        config[keyPath: AppKind.bad.url] = "bad"
        #expect(config.goodRate == 3)
        #expect(config.badRate == 4)
        #expect(config.goodURL == "good")
        #expect(config.badURL == "bad")
    }

    @Test func minutesKeyPathsTargetOwnFields() {
        var usage = DailyUsage()
        usage[keyPath: AppKind.good.minutes] = 7
        usage[keyPath: AppKind.bad.minutes] = 9
        #expect(usage.good == 7)
        #expect(usage.bad == 9)
    }

    @Test func titles() {
        #expect(AppKind.good.title == "Good apps")
        #expect(AppKind.bad.title == "Bad apps")
    }
}

struct DailyUsageTests {
    @Test func startsEmptyForToday() {
        let usage = DailyUsage()
        #expect(usage.day == DailyUsage.today)
        #expect(usage.good == 0)
        #expect(usage.bad == 0)
    }

    @Test func dayIsLocalISODate() {
        #expect(DailyUsage.today.wholeMatch(of: /\d{4}-\d{2}-\d{2}/) != nil)
    }
}

struct DailyUsageDecodingTests {
    @Test func keepsCountsFromOlderFormat() throws {
        let data = Data(#"{"day":"2026-10-22","good":24,"bad":22,"restartedAt":0,"badBurst":[1,2]}"#.utf8)
        let usage = try JSONDecoder().decode(DailyUsage.self, from: data)
        #expect(usage.good == 24)
        #expect(usage.bad == 22)
        #expect(usage.badSeen.isEmpty)
    }
}

struct UsageCountingTests {
    private let midnight = Calendar.current.startOfDay(for: .now)

    private func at(_ minutes: Double) -> Date {
        midnight.addingTimeInterval(minutes * 60)
    }

    @Test func acceptsFirstEventOfTheDay() {
        var usage = DailyUsage()
        let recorded = usage.record(.bad, minutes: 24, at: at(600))
        #expect(recorded)
        #expect(usage.bad == 24)
    }

    @Test func acceptsEveryNextMinute() {
        var usage = DailyUsage()
        for minute in 1...5 { _ = usage.record(.good, minutes: minute, at: at(Double(60 + minute))) }
        #expect(usage.good == 5)
    }

    @Test func rejectsJumpLargerThanElapsedTime() {
        var usage = DailyUsage()
        _ = usage.record(.bad, minutes: 20, at: at(600))
        let jump = usage.record(.bad, minutes: 215, at: at(602))
        #expect(!jump)
        #expect(usage.bad == 20)
    }

    @Test func allowsCatchingUpAfterMissedEvents() {
        var usage = DailyUsage()
        _ = usage.record(.bad, minutes: 20, at: at(600))
        let caughtUp = usage.record(.bad, minutes: 30, at: at(615))
        #expect(caughtUp)
        #expect(usage.bad == 30)
    }

    @Test func shuffledBurstReachesFullTotal() {
        var usage = DailyUsage()
        for minute in [4, 7, 19, 20, 22, 11, 18, 2, 10, 1, 5, 6, 3, 8, 9, 12, 13, 14, 15, 16, 17, 21] {
            _ = usage.record(.bad, minutes: minute, at: at(1356))
        }
        #expect(usage.bad == 22)
    }

    @Test func isolatedFakeValueNeverCounts() {
        var usage = DailyUsage()
        _ = usage.record(.bad, minutes: 20, at: at(600))
        _ = usage.record(.bad, minutes: 215, at: at(601))
        _ = usage.record(.bad, minutes: 21, at: at(602))
        #expect(usage.bad == 21)
    }

    @Test func rejectsMoreMinutesThanSinceMidnight() {
        var usage = DailyUsage()
        let recorded = usage.record(.bad, minutes: 200, at: at(10))
        #expect(!recorded)
        #expect(usage.bad == 0)
    }

    @Test func ignoresOlderOrRepeatedEvents() {
        var usage = DailyUsage()
        _ = usage.record(.good, minutes: 6, at: at(600))
        let repeated = usage.record(.good, minutes: 6, at: at(601))
        let older = usage.record(.good, minutes: 4, at: at(602))
        #expect(!repeated)
        #expect(!older)
        #expect(usage.good == 6)
    }

    @Test func groupsCountSeparately() {
        var usage = DailyUsage()
        _ = usage.record(.good, minutes: 3, at: at(600))
        _ = usage.record(.bad, minutes: 7, at: at(600))
        #expect(usage.good == 3)
        #expect(usage.bad == 7)
        #expect(usage.goodUpdatedAt == at(600))
    }

    @Test func newDayStartsAtMidnight() {
        #expect(DailyUsage().badUpdatedAt == midnight)
    }
}

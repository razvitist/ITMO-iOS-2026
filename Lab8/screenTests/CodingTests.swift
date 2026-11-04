import Foundation
import Testing
@testable import screen

struct CodingParsingTests {
    @Test func parsesLeetCodeCounts() throws {
        let json = #"{"data":{"matchedUser":{"submitStatsGlobal":{"acSubmissionNum":[{"difficulty":"All","count":689},{"difficulty":"Easy","count":126},{"difficulty":"Medium","count":413},{"difficulty":"Hard","count":150}]}}}}"#
        let counts = try CodingClient.parseLeetCode(Data(json.utf8))
        #expect(counts == LeetCodeCounts(easy: 126, medium: 413, hard: 150))
    }

    @Test func unknownLeetCodeUserFails() {
        let json = #"{"errors":[{"message":"That user does not exist."}],"data":{"matchedUser":null}}"#
        #expect(throws: CodingError.userNotFound) { try CodingClient.parseLeetCode(Data(json.utf8)) }
    }

    @Test func parsesCodewarsHonor() throws {
        let json = #"{"id":"545207bac8e60b30fc000942","username":"g964","honor":489430,"clan":"None"}"#
        #expect(try CodingClient.parseCodewars(Data(json.utf8)) == 489430)
    }

    @Test func parsesStepikToday() throws {
        let json = #"{"meta":{"page":1},"user-activities":[{"id":1,"pins":[7,3,0,2]}]}"#
        #expect(try CodingClient.parseStepik(Data(json.utf8)) == 7)
    }

    @Test func emptyStepikActivityFails() {
        let json = #"{"user-activities":[]}"#
        #expect(throws: CodingError.noActivity) { try CodingClient.parseStepik(Data(json.utf8)) }
    }

    @Test func brokenJSONFails() {
        #expect(throws: (any Error).self) { try CodingClient.parseCodewars(Data("not json".utf8)) }
    }
}

struct CodingProgressTests {
    private var config: CodingConfig {
        var config = CodingConfig()
        config.leetcodeName = "lee"
        config.codewarsName = "g964"
        config.stepikID = "1"
        return config
    }

    private func progress(_ counts: LeetCodeCounts, honor: Int = 0, stepik: Int = 0, day: String = "2026-10-24") -> CodingProgress {
        var progress = CodingProgress(day: day)
        progress.update(leetcode: counts, honor: honor, stepik: stepik, config: config, today: day)
        return progress
    }

    @Test func firstCheckStartsAtZero() {
        let progress = progress(LeetCodeCounts(easy: 100, medium: 50, hard: 10), honor: 900)
        #expect(progress.easy.today == 0)
        #expect(progress.honor.today == 0)
        #expect(progress.bonus(config, today: "2026-10-24") == CodingBonus())
    }

    @Test func newSolvesChargeByDifficulty() {
        var progress = progress(LeetCodeCounts(easy: 100, medium: 50, hard: 10))
        progress.update(leetcode: LeetCodeCounts(easy: 101, medium: 52, hard: 10), honor: nil, stepik: nil,
                        config: config, today: "2026-10-24")
        #expect(progress.bonus(config, today: "2026-10-24").leetcode == 5 + 2 * 10)
    }

    @Test func codewarsChargesPerHonor() {
        var progress = progress(LeetCodeCounts(), honor: 900)
        progress.update(leetcode: nil, honor: 912, stepik: nil, config: config, today: "2026-10-24")
        #expect(progress.bonus(config, today: "2026-10-24").codewars == 12)
    }

    @Test func stepikUsesTodaysSteps() {
        let progress = progress(LeetCodeCounts(), stepik: 4)
        #expect(progress.bonus(config, today: "2026-10-24").stepik == 8)
    }

    @Test func bonusHasNoDailyLimit() {
        var progress = progress(LeetCodeCounts())
        progress.update(leetcode: LeetCodeCounts(hard: 10), honor: nil, stepik: nil, config: config, today: "2026-10-24")
        #expect(progress.bonus(config, today: "2026-10-24").leetcode == 200)
    }

    @Test func olderSettingsWithDailyMaxStillLoad() throws {
        let json = #"{"leetcodeName":"lee","leetcodeEasy":3,"leetcodeMedium":10,"leetcodeHard":20,"leetcodeMax":50,"codewarsName":"","codewarsHonor":1,"codewarsMax":50,"stepikID":"","stepikStep":2,"stepikMax":50}"#
        let config = try JSONDecoder().decode(CodingConfig.self, from: Data(json.utf8))
        #expect(config.leetcodeName == "lee")
        #expect(config.leetcodeEasy == 3)
    }

    @Test func newDayStartsFromYesterdaysLastCheck() {
        var progress = progress(LeetCodeCounts(easy: 100), honor: 900, stepik: 3, day: "2026-10-23")
        progress.update(leetcode: LeetCodeCounts(easy: 102), honor: 905, stepik: 1, config: config, today: "2026-10-24")
        #expect(progress.easy.today == 2)
        #expect(progress.honor.today == 5)
        #expect(progress.stepikToday == 1)
        #expect(progress.day == "2026-10-24")
    }

    @Test func staleDayGivesNoBonus() {
        var progress = progress(LeetCodeCounts(easy: 1), day: "2026-10-23")
        progress.update(leetcode: LeetCodeCounts(easy: 3), honor: nil, stepik: nil, config: config, today: "2026-10-23")
        #expect(progress.bonus(config, today: "2026-10-24") == CodingBonus())
    }

    @Test func changingAccountResetsCounters() {
        var progress = progress(LeetCodeCounts(easy: 100))
        var other = config
        other.leetcodeName = "someone"
        progress.update(leetcode: LeetCodeCounts(easy: 500), honor: nil, stepik: nil, config: other, today: "2026-10-24")
        #expect(progress.easy.today == 0)
        #expect(progress.leetcodeUser == "someone")
    }

    @Test func emptyAccountGivesNoBonus() {
        var progress = progress(LeetCodeCounts())
        progress.update(leetcode: LeetCodeCounts(easy: 2), honor: nil, stepik: nil, config: config, today: "2026-10-24")
        var noAccount = config
        noAccount.leetcodeName = " "
        #expect(progress.bonus(noAccount, today: "2026-10-24").leetcode == 0)
    }

    @Test func failedCheckKeepsPreviousValues() {
        var progress = progress(LeetCodeCounts(easy: 10))
        progress.update(leetcode: LeetCodeCounts(easy: 12), honor: nil, stepik: nil, config: config, today: "2026-10-24")
        progress.update(leetcode: nil, honor: nil, stepik: nil, config: config, today: "2026-10-24")
        #expect(progress.easy.today == 2)
    }
}

struct CodingBatteryTests {
    @Test func codingBonusRaisesBattery() {
        let battery = BatteryConfig().battery(good: 0, bad: 0, coding: 20)
        #expect(battery.level == 0.7)
    }

    @Test func codingBonusLiftsBlock() {
        var config = BatteryConfig()
        config.blockEnabled = true
        config.badRate = 2
        #expect(config.shouldBlock(config.battery(for: DailyUsage(bad: 25))))
        #expect(!config.shouldBlock(config.battery(for: DailyUsage(bad: 25), coding: 5)))
    }

    @Test func codingReducesGoodMinutesNeeded() {
        var config = BatteryConfig()
        config.badRate = 2
        #expect(BlockMessage.goodMinutesNeeded(config: config, usage: DailyUsage(bad: 35)) == 21)
        #expect(BlockMessage.goodMinutesNeeded(config: config, usage: DailyUsage(bad: 35), coding: 10) == 11)
    }

    @Test func blockScreenMentionsCodingWhenConnected() {
        var config = BatteryConfig()
        config.coding.codewarsName = "g964"
        #expect(BlockMessage(config: config, usage: DailyUsage(bad: 60)).subtitle.contains("coding problems"))
        #expect(!BlockMessage(config: BatteryConfig(), usage: DailyUsage(bad: 60)).subtitle.contains("coding problems"))
    }

    @Test func olderSettingsGetDefaultCoding() throws {
        let config = try JSONDecoder().decode(BatteryConfig.self, from: Data(#"{"goodRate": 2}"#.utf8))
        #expect(config.coding == CodingConfig())
    }
}

struct CodingPlatformTests {
    @Test func bonusValuePerPlatform() {
        let bonus = CodingBonus(leetcode: 5, codewars: 2, stepik: 4)
        #expect(bonus.value(for: .leetcode) == 5)
        #expect(bonus.value(for: .codewars) == 2)
        #expect(bonus.value(for: .stepik) == 4)
        #expect(bonus.total == 11)
    }

    @Test(arguments: CodingPlatform.allCases)
    func everyPlatformHasLogoAndHint(_ platform: CodingPlatform) {
        #expect(platform.logo == "logo-\(platform.rawValue)")
        #expect(!platform.hint.isEmpty)
    }
}

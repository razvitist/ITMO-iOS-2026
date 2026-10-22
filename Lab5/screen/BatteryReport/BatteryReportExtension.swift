import DeviceActivity
import ExtensionKit
import FamilyControls
import ManagedSettings
import SwiftUI

@main
struct BatteryReportExtension: DeviceActivityReportExtension {
    var body: some DeviceActivityReportScene {
        BatteryReport { BatteryView(battery: $0) }
    }
}

struct BatteryReport: DeviceActivityReportScene {
    let context: DeviceActivityReport.Context = .battery
    let content: (Battery) -> BatteryView

    nonisolated func makeConfiguration(representing data: DeviceActivityResults<DeviceActivityData>) async -> Battery {
        let config = ConfigStore.load()
        var good: TimeInterval = 0
        var bad: TimeInterval = 0
        var goodApps: [ApplicationToken: TimeInterval] = [:]
        var badApps: [ApplicationToken: TimeInterval] = [:]
        for await device in data {
            for await segment in device.activitySegments {
                for await category in segment.categories {
                    for await app in category.applications {
                        let token = app.application.token
                        let duration = app.totalActivityDuration
                        switch config.isGood(token, in: category.category.token) {
                        case true?:
                            good += duration
                            if let token { goodApps[token, default: 0] += duration }
                        case false?:
                            bad += duration
                            if let token { badApps[token, default: 0] += duration }
                        case nil:
                            break
                        }
                    }
                }
            }
        }
        var battery = config.battery(for: DailyUsage(good: Int(good / 60), bad: Int(bad / 60)))
        battery.goodApps = AppUsage.top(goodApps)
        battery.badApps = AppUsage.top(badApps)
        return battery
    }
}

private extension BatteryConfig {
    nonisolated func isGood(_ app: ApplicationToken?, in category: ActivityCategoryToken?) -> Bool? {
        if let app {
            if good.applicationTokens.contains(app) { return true }
            if bad.applicationTokens.contains(app) { return false }
        }
        if let category {
            if good.categoryTokens.contains(category) { return true }
            if bad.categoryTokens.contains(category) { return false }
        }
        return nil
    }
}

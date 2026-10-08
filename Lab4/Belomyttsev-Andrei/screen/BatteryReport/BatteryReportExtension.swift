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
        for await device in data {
            for await segment in device.activitySegments {
                for await category in segment.categories {
                    for await app in category.applications {
                        switch config.isGood(app.application.token, in: category.category.token) {
                        case true?: good += app.totalActivityDuration
                        case false?: bad += app.totalActivityDuration
                        case nil: break
                        }
                    }
                }
            }
        }
        return config.battery(good: good, bad: bad)
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

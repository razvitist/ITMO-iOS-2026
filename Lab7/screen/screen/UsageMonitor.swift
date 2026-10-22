import DeviceActivity
import FamilyControls
import Foundation

enum UsageMonitor {
    static let version = 8

    static var needsStart: Bool {
        !DeviceActivityCenter().activities.contains(.usage)
            || UserDefaults.standard.integer(forKey: "monitorVersion") < version
    }

    static func start(_ config: BatteryConfig) throws {
        let center = DeviceActivityCenter()
        center.stopMonitoring([.usage])

        UserDefaults.standard.set(version, forKey: "monitorVersion")

        let generation = Int(Date.now.timeIntervalSince1970)
        var events: [DeviceActivityEvent.Name: DeviceActivityEvent] = [:]
        for kind in AppKind.allCases {
            let selection = config[keyPath: kind.selection]
            guard !selection.applicationTokens.isEmpty || !selection.categoryTokens.isEmpty else { continue }
            for minutes in UsageThresholds.all {
                events[DeviceActivityEvent.Name(kind: kind, minutes: minutes, generation: generation)] = DeviceActivityEvent(
                    applications: selection.applicationTokens,
                    categories: selection.categoryTokens,
                    threshold: DateComponents(hour: minutes / 60, minute: minutes % 60),
                    includesPastActivity: true
                )
            }
        }
        guard !events.isEmpty else {
            RequestLog.add("Monitoring off: no apps selected")
            return
        }

        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59, second: 59),
            repeats: true
        )
        try center.startMonitoring(.usage, during: schedule, events: events)
        RequestLog.add("Monitoring started: \(events.count) events")
    }
}

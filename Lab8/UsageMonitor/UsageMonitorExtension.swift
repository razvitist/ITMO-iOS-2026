import DeviceActivity
import Foundation

final class UsageMonitorExtension: DeviceActivityMonitor {
    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        guard UsageStore.isNewDay else { return }
        let usage = DailyUsage()
        UsageStore.save(usage)
        AppBlocker.update(config: ConfigStore.load(), usage: usage)
        RequestLog.add("Monitoring interval started")
    }

    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)
        guard let hit = event.usage else { return }

        var usage = UsageStore.load()
        let counted = usage.record(hit.kind, minutes: hit.minutes)
        UsageStore.save(usage)
        guard counted else { return }

        let config = ConfigStore.load()
        let wasBlocking = AppBlocker.isBlocking
        let isBlocking = AppBlocker.update(config: config, usage: usage)
        if isBlocking != wasBlocking {
            RequestLog.add(isBlocking ? "Battery empty: bad apps blocked" : "Battery above 0%: bad apps unblocked")
        }

        let label = "\(hit.kind.rawValue) \(usage[keyPath: hit.kind.minutes]) min"
        if let url = BatteryConfig.endpoint(from: config[keyPath: hit.kind.url]) {
            send(url, label: label)
        } else {
            RequestLog.add("\(label) counted")
        }
    }

    private func send(_ url: URL, label: String) {
        let done = DispatchSemaphore(value: 0)
        URLSession.shared.dataTask(with: url) { data, response, error in
            let result = if let error {
                error.localizedDescription
            } else {
                "HTTP \((response as? HTTPURLResponse)?.statusCode ?? 0) " + String(decoding: (data ?? Data()).prefix(80), as: UTF8.self)
            }
            RequestLog.add("\(label) → \(result)")
            done.signal()
        }.resume()
        _ = done.wait(timeout: .now() + 10)
    }
}

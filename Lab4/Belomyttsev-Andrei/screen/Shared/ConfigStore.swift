import Foundation

nonisolated enum ConfigStore {
    private static var url: URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: "group.com.razvit.screenbattery")?
            .appending(path: "config.json")
    }

    static func load() -> BatteryConfig {
        guard let url, let data = try? Data(contentsOf: url),
              let config = try? JSONDecoder().decode(BatteryConfig.self, from: data)
        else { return BatteryConfig() }
        return config
    }

    static func save(_ config: BatteryConfig) {
        guard let url, let data = try? JSONEncoder().encode(config) else { return }
        try? data.write(to: url, options: .atomic)
    }
}

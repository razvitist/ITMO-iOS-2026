import FamilyControls
import ManagedSettings

nonisolated enum AppBlocker {
    static var isBlocking: Bool {
        let store = ManagedSettingsStore()
        return store.shield.applications != nil || store.shield.applicationCategories != nil
    }

    @discardableResult
    static func update(config: BatteryConfig, usage: DailyUsage) -> Bool {
        let store = ManagedSettingsStore()
        guard config.shouldBlock(config.battery(for: usage)) else {
            store.clearAllSettings()
            return false
        }
        let apps = config.bad.applicationTokens
        let categories = config.bad.categoryTokens
        store.shield.applications = apps.isEmpty ? nil : apps
        store.shield.applicationCategories = categories.isEmpty ? nil : .specific(categories)
        return !apps.isEmpty || !categories.isEmpty
    }
}

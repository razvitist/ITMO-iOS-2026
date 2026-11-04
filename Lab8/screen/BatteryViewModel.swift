import DeviceActivity
import FamilyControls
import Foundation
import Observation

@Observable
final class BatteryViewModel {
    enum Access { case checking, granted, denied }

    static let isUITesting = ProcessInfo.processInfo.arguments.contains("-uiTesting")

    var config = BatteryViewModel.isUITesting ? BatteryConfig() : ConfigStore.load() {
        didSet {
            guard config != oldValue else { return }
            if config.isProtected, !oldValue.isProtected { isUnlocked = true }
            reloadReport()
            guard !Self.isUITesting else { return }
            ConfigStore.save(config)
            if config.good != oldValue.good || config.bad != oldValue.bad { startMonitoring() }
            if config.logLimit != oldValue.logLimit {
                RequestLog.trim(to: config.logLimit)
                reloadLog()
            }
            if CodingPlatform.allCases.contains(where: { config.coding.account($0) != oldValue.coding.account($0) }) {
                Task { await refreshCoding() }
            }
            refreshBlocking()
        }
    }
    var challenge: Challenge?
    private(set) var access = Access.checking
    private(set) var errorMessage: String?
    private(set) var monitorError: String?
    private(set) var requestLog = BatteryViewModel.isUITesting ? [] : RequestLog.entries()
    private(set) var isUnlocked = false
    private(set) var coding = BatteryViewModel.isUITesting ? CodingProgress() : CodingStore.load()
    private(set) var codingErrors: [CodingPlatform: String] = [:]
    private(set) var isRefreshingCoding = false
    private(set) var filter = BatteryViewModel.todayFilter(hourly: false)
    @ObservationIgnored private var hourly = false

    var isLocked: Bool { config.isProtected && !isUnlocked }
    var codingBonus: CodingBonus { coding.bonus(config.coding) }

    func authorize() async {
        guard !Self.isUITesting else {
            access = .granted
            return
        }
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            access = .granted
            errorMessage = nil
            if UsageMonitor.needsStart { startMonitoring() }
            refreshBlocking()
            await refreshCoding()
        } catch {
            access = .denied
            errorMessage = error.localizedDescription
        }
    }

    func becameActive() {
        reloadReport()
        reloadLog()
        refreshBlocking()
        Task { await refreshCoding() }
    }

    func beginUnlock() {
        challenge = Challenge.make(for: config)
    }

    func submit(_ answer: String) -> Bool {
        guard let challenge, challenge.accepts(answer) else { return false }
        isUnlocked = true
        self.challenge = nil
        return true
    }

    func lock() {
        isUnlocked = false
        challenge = nil
    }

    func setPassword(_ password: String) {
        config.passwordHash = PasswordHash.make(password)
    }

    func refreshCoding() async {
        guard !Self.isUITesting, !isRefreshingCoding else { return }
        isRefreshingCoding = true
        defer { isRefreshingCoding = false }
        let result = await CodingClient().fetch(config.coding)
        var progress = CodingStore.load()
        progress.update(
            leetcode: try? result.leetcode?.get(),
            honor: try? result.codewars?.get(),
            stepik: try? result.stepik?.get(),
            config: config.coding
        )
        CodingStore.save(progress)
        coding = progress
        codingErrors = result.errors
        reloadReport()
        refreshBlocking()
    }

    func reloadReport() {
        hourly.toggle()
        filter = Self.todayFilter(hourly: hourly)
    }

    func reloadLog() {
        guard !Self.isUITesting else { return }
        requestLog = RequestLog.entries()
    }

    func clearLog() {
        guard !Self.isUITesting else { return }
        RequestLog.clear()
        reloadLog()
    }

    private func refreshBlocking() {
        guard access == .granted, !Self.isUITesting else { return }
        AppBlocker.update(config: config, usage: UsageStore.load())
    }

    private func startMonitoring() {
        do {
            try UsageMonitor.start(config)
            monitorError = nil
        } catch {
            monitorError = error.localizedDescription
            RequestLog.add("Monitoring failed: \(error.localizedDescription)")
        }
        reloadLog()
    }

    private static func todayFilter(hourly: Bool) -> DeviceActivityFilter {
        let today = DateInterval(start: Calendar.current.startOfDay(for: .now), end: .now)
        return DeviceActivityFilter(segment: hourly ? .hourly(during: today) : .daily(during: today))
    }
}

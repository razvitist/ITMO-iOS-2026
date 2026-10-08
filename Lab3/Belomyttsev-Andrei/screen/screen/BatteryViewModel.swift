import DeviceActivity
import FamilyControls
import Foundation
import Observation

@Observable
final class BatteryViewModel {
    enum Access { case checking, granted, denied }

    var config = ConfigStore.load() {
        didSet {
            guard config != oldValue else { return }
            ConfigStore.save(config)
            reloadReport()
        }
    }
    private(set) var access = Access.checking
    private(set) var errorMessage: String?
    private(set) var filter = BatteryViewModel.todayFilter(hourly: false)
    @ObservationIgnored private var hourly = false

    func authorize() async {
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            access = .granted
            errorMessage = nil
        } catch {
            access = .denied
            errorMessage = error.localizedDescription
        }
    }

    func reloadReport() {
        hourly.toggle()
        filter = Self.todayFilter(hourly: hourly)
    }

    private static func todayFilter(hourly: Bool) -> DeviceActivityFilter {
        let today = DateInterval(start: Calendar.current.startOfDay(for: .now), end: .now)
        return DeviceActivityFilter(segment: hourly ? .hourly(during: today) : .daily(during: today))
    }
}

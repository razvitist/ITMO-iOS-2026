import FamilyControls
import Foundation

nonisolated struct BatteryConfig: Codable, Equatable {
    var good = FamilyActivitySelection()
    var bad = FamilyActivitySelection()
    var goodRate = 1.0
    var badRate = 1.0

    func battery(good goodTime: TimeInterval, bad badTime: TimeInterval) -> Battery {
        let charge = 50 + goodTime / 60 * goodRate - badTime / 60 * badRate
        return Battery(good: goodTime, bad: badTime, level: min(max(charge, 0), 100) / 100)
    }
}

nonisolated struct Battery: Sendable {
    let good: TimeInterval
    let bad: TimeInterval
    let level: Double
}

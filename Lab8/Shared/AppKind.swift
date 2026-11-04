import FamilyControls
import Foundation

nonisolated enum AppKind: String, CaseIterable, Identifiable, Sendable {
    case good, bad

    var id: Self { self }
    var title: String { self == .good ? "Good apps" : "Bad apps" }
    var selection: WritableKeyPath<BatteryConfig, FamilyActivitySelection> { self == .good ? \.good : \.bad }
    var rate: WritableKeyPath<BatteryConfig, Double> { self == .good ? \.goodRate : \.badRate }
    var url: WritableKeyPath<BatteryConfig, String> { self == .good ? \.goodURL : \.badURL }
    var minutes: WritableKeyPath<DailyUsage, Int> { self == .good ? \.good : \.bad }
    var updatedAt: WritableKeyPath<DailyUsage, Date> { self == .good ? \.goodUpdatedAt : \.badUpdatedAt }
    var seen: WritableKeyPath<DailyUsage, Set<Int>> { self == .good ? \.goodSeen : \.badSeen }
}

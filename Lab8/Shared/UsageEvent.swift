import DeviceActivity

extension DeviceActivityName {
    nonisolated static let usage = Self("usage")
}

nonisolated enum UsageThresholds {
    static let all = Array(1...240)
}

extension DeviceActivityEvent.Name {
    nonisolated init(kind: AppKind, minutes: Int, generation: Int) {
        self.init("\(kind.rawValue).\(minutes).\(generation)")
    }

    nonisolated var usage: (kind: AppKind, minutes: Int)? {
        let parts = rawValue.split(separator: ".")
        guard parts.count == 3, let kind = AppKind(rawValue: String(parts[0])),
              let minutes = Int(parts[1]), Int(parts[2]) != nil
        else { return nil }
        return (kind, minutes)
    }
}

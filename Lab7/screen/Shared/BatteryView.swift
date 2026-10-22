import FamilyControls
import SwiftUI

struct BatteryView: View {
    let battery: Battery

    private var color: Color {
        switch battery.level {
        case 0.5...: .green
        case 0.2...: .yellow
        case 0.0.nextUp...: .orange
        default: .red
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Battery")
                    .font(.largeTitle.bold())
                if battery.level <= 0, battery.blockEnabled {
                    Label("Bad apps are blocked until the battery is above 0%", systemImage: "hand.raised.fill")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(.red, in: .rect(cornerRadius: 16))
                }
                content
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 120)
        }
        .scrollBounceBehavior(.always)
    }

    private var content: some View {
        VStack(spacing: 20) {
            BatteryGauge(level: battery.level, color: color)
            status
            HStack(spacing: 12) {
                StatCard(title: "Good", systemImage: "arrow.up.circle.fill", time: battery.good,
                         change: "+" + Self.percent(battery.goodCharge),
                         rate: "+" + Self.percent(battery.goodRate), color: .green)
                StatCard(title: "Bad", systemImage: "arrow.down.circle.fill", time: battery.bad,
                         change: "−" + Self.percent(battery.badDrain),
                         rate: "−" + Self.percent(battery.badRate), color: .red)
            }
            TopApps(title: "Top good apps", apps: battery.goodApps, color: .green)
            TopApps(title: "Top bad apps", apps: battery.badApps, color: .red)
        }
    }

    @ViewBuilder private var status: some View {
        Group {
            if battery.level <= 0 {
                Label("Battery is empty", systemImage: "battery.0percent")
                    .foregroundStyle(.red)
            } else if battery.level > 1 {
                Label("Overcharged by good apps", systemImage: "bolt.fill")
                    .foregroundStyle(.green)
            } else if let minutes = battery.badMinutesLeft {
                Label("About \(Int(minutes)) min of bad apps left", systemImage: "hourglass")
                    .foregroundStyle(.secondary)
            } else {
                Label("Bad apps don't drain the battery", systemImage: "checkmark.circle")
                    .foregroundStyle(.secondary)
            }
        }
        .font(.subheadline.weight(.medium))
    }

    private static func percent(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0...1))) + "%"
    }
}

private struct BatteryGauge: View {
    let level: Double
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 26)
                    .stroke(.secondary.opacity(0.4), lineWidth: 5)
                GeometryReader { proxy in
                    RoundedRectangle(cornerRadius: 17)
                        .fill(color.gradient)
                        .frame(width: proxy.size.width * min(max(level, 0), 1))
                }
                .padding(10)
                Text(level, format: .percent.precision(.fractionLength(0)))
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(level <= 0 ? .red : .primary)
            }
            .frame(width: 240, height: 110)
            Capsule()
                .fill(.secondary.opacity(0.4))
                .frame(width: 10, height: 40)
        }
    }
}

private struct StatCard: View {
    let title: String
    let systemImage: String
    let time: TimeInterval
    let change: String
    let rate: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Label(title, systemImage: systemImage)
                    .font(.subheadline.bold())
                    .foregroundStyle(color)
                Spacer(minLength: 4)
                Text(rate + "/min")
                    .font(.caption.weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(color.opacity(0.15), in: .capsule)
            }
            Text(Duration.seconds(time).formatted(.units(allowed: [.hours, .minutes], width: .narrow)))
                .font(.title2.bold())
                .monospacedDigit()
            Text(change + " battery")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.fill.tertiary, in: .rect(cornerRadius: 16))
    }
}

private struct TopApps: View {
    let title: String
    let apps: [AppUsage]
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.subheadline.bold())
            if apps.isEmpty {
                Text("No usage yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            ForEach(apps) { app in
                HStack(spacing: 12) {
                    Label(app.token)
                        .labelStyle(.iconOnly)
                        .font(.title)
                        .frame(width: 40, height: 40)
                    VStack(alignment: .leading, spacing: 6) {
                        Label(app.token)
                            .labelStyle(.titleOnly)
                            .font(.subheadline.weight(.medium))
                            .dynamicTypeSize(.small)
                            .lineLimit(1)
                        HStack(spacing: 10) {
                            ProgressView(value: app.duration, total: apps[0].duration)
                                .tint(color)
                            Text(Self.time(app.duration))
                                .font(.footnote.weight(.semibold))
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                                .fixedSize()
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.fill.tertiary, in: .rect(cornerRadius: 16))
    }

    private static func time(_ duration: TimeInterval) -> String {
        Duration.seconds(duration).formatted(.units(allowed: [.hours, .minutes], width: .narrow))
    }
}

#Preview {
    BatteryView(battery: BatteryConfig().battery(good: 1800, bad: 2700))
}

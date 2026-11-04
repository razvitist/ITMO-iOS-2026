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
                Text("Screen Battery")
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
            let platforms = CodingPlatform.allCases.filter { battery.codingBonus.value(for: $0) > 0 }
            if !platforms.isEmpty {
                VStack(spacing: 12) {
                    ForEach(platforms) { platform in
                        HStack(spacing: 12) {
                            PlatformLogo(platform: platform, size: 32)
                            Text(platform.title)
                                .font(.subheadline.weight(.semibold))
                            Spacer()
                            Text("+" + Self.percent(battery.codingBonus.value(for: platform)) + " battery")
                                .font(.subheadline.weight(.semibold))
                                .monospacedDigit()
                                .foregroundStyle(.green)
                        }
                    }
                }
                .padding()
                .background(.fill.tertiary, in: .rect(cornerRadius: 16))
            }
            TopApps(title: "Top good apps", apps: battery.goodApps, rate: battery.goodRate, sign: "+", color: .green)
            TopApps(title: "Top bad apps", apps: battery.badApps, rate: battery.badRate, sign: "−", color: .red)
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
    let rate: Double
    let sign: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.headline)
            if apps.isEmpty {
                Text("No usage yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            ForEach(apps) { app in
                let minutes = (app.duration / 60).rounded(.down)
                let change = minutes * rate
                HStack(spacing: 12) {
                    Label(app.token)
                        .labelStyle(.iconOnly)
                        .scaleEffect(1.5)
                        .frame(width: 36, height: 36)
                    VStack(alignment: .leading, spacing: 0) {
                        HStack(spacing: 8) {
                            Label(app.token)
                                .labelStyle(.titleOnly)
                                .font(.subheadline.weight(.semibold))
                                .dynamicTypeSize(.small)
                                .lineLimit(1)
                            Spacer(minLength: 4)
                            Text((change > 0 ? sign : "") + change.formatted(.number.precision(.fractionLength(0...1))) + "%")
                                .font(.caption.weight(.semibold))
                                .monospacedDigit()
                                .foregroundStyle(color)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(color.opacity(0.15), in: .capsule)
                                .fixedSize()
                            Text(Self.time(minutes * 60))
                                .font(.subheadline.weight(.semibold))
                                .monospacedDigit()
                                .fixedSize()
                        }
                        Spacer(minLength: 4)
                        UsageBar(fraction: app.duration / apps[0].duration, color: color)
                            .padding(.bottom, 2)
                    }
                    .frame(height: 36)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(.fill.tertiary, in: .rect(cornerRadius: 20))
    }

    private static func time(_ duration: TimeInterval) -> String {
        Duration.seconds(duration).formatted(.units(allowed: [.hours, .minutes], width: .narrow))
    }
}

private struct UsageBar: View {
    let fraction: Double
    let color: Color

    var body: some View {
        Capsule()
            .fill(color.opacity(0.18))
            .overlay(alignment: .leading) {
                GeometryReader { proxy in
                    Capsule()
                        .fill(color)
                        .frame(width: max(proxy.size.width * min(fraction, 1), 5))
                }
            }
            .frame(height: 5)
    }
}

#Preview {
    BatteryView(battery: BatteryConfig().battery(good: 1800, bad: 2700))
}

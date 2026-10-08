import SwiftUI

struct BatteryView: View {
    let battery: Battery

    private var color: Color {
        switch battery.level {
        case 0.5...: .green
        case 0.2...: .yellow
        default: .red
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 4) {
                RoundedRectangle(cornerRadius: 14)
                    .stroke(.primary, lineWidth: 4)
                    .overlay(alignment: .leading) {
                        GeometryReader { proxy in
                            RoundedRectangle(cornerRadius: 8)
                                .fill(color)
                                .frame(width: proxy.size.width * battery.level)
                        }
                        .padding(8)
                    }
                    .overlay {
                        Text(battery.level, format: .percent.precision(.fractionLength(0)))
                            .font(.title.bold())
                    }
                    .frame(width: 180, height: 80)
                RoundedRectangle(cornerRadius: 3)
                    .fill(.primary)
                    .frame(width: 8, height: 28)
            }
            HStack(spacing: 24) {
                Label(Duration.seconds(battery.good).formatted(.units(width: .narrow)), systemImage: "arrow.up")
                    .foregroundStyle(.green)
                Label(Duration.seconds(battery.bad).formatted(.units(width: .narrow)), systemImage: "arrow.down")
                    .foregroundStyle(.red)
            }
            .font(.subheadline)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
}

#Preview {
    BatteryView(battery: Battery(good: 1800, bad: 2700, level: 0.35))
}

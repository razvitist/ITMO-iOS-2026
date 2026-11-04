import ManagedSettings
import ManagedSettingsUI
import UIKit

final class ShieldConfigurationExtension: ShieldConfigurationDataSource {
    override func configuration(shielding application: Application) -> ShieldConfiguration {
        Self.makeConfiguration()
    }

    override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration {
        Self.makeConfiguration()
    }

    private static let red = UIColor(red: 1, green: 0.27, blue: 0.23, alpha: 1)
    private static let green = UIColor(red: 0x30 / 255, green: 0xD1 / 255, blue: 0x58 / 255, alpha: 1)

    private static func makeConfiguration() -> ShieldConfiguration {
        let config = ConfigStore.load()
        let message = BlockMessage(config: config, usage: UsageStore.load(), coding: CodingStore.bonus(config))
        return ShieldConfiguration(
            backgroundBlurStyle: nil,
            backgroundColor: UIColor(red: 0.08, green: 0.08, blue: 0.09, alpha: 1),
            icon: batteryIcon(level: message.level),
            title: ShieldConfiguration.Label(text: message.title, color: .white),
            subtitle: ShieldConfiguration.Label(text: message.subtitle, color: UIColor(white: 1, alpha: 0.72)),
            primaryButtonLabel: ShieldConfiguration.Label(text: "OK", color: .black),
            primaryButtonBackgroundColor: green
        )
    }

    private static func batteryIcon(level: Double) -> UIImage {
        UIGraphicsImageRenderer(size: CGSize(width: 300, height: 170)).image { _ in
            let body = CGRect(x: 4, y: 4, width: 270, height: 162)
            red.withAlphaComponent(0.16).setFill()
            UIBezierPath(roundedRect: body, cornerRadius: 38).fill()
            let outline = UIBezierPath(roundedRect: body.insetBy(dx: 7, dy: 7), cornerRadius: 31)
            outline.lineWidth = 14
            red.setStroke()
            outline.stroke()
            red.setFill()
            UIBezierPath(roundedRect: CGRect(x: 280, y: 55, width: 18, height: 60), cornerRadius: 8).fill()

            let text = BlockMessage.percent(level) as NSString
            var fontSize: CGFloat = 96
            var attributes: [NSAttributedString.Key: Any] = [:]
            repeat {
                attributes = [.font: UIFont.systemFont(ofSize: fontSize, weight: .heavy), .foregroundColor: red]
                fontSize -= 2
            } while text.size(withAttributes: attributes).width > body.width - 56
            let size = text.size(withAttributes: attributes)
            text.draw(at: CGPoint(x: body.midX - size.width / 2, y: body.midY - size.height / 2), withAttributes: attributes)
        }
    }
}

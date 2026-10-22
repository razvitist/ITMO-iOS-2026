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

    private static func makeConfiguration() -> ShieldConfiguration {
        let message = BlockMessage(config: ConfigStore.load(), usage: UsageStore.load())
        let symbol = UIImage.SymbolConfiguration(pointSize: 64, weight: .medium)
        return ShieldConfiguration(
            backgroundBlurStyle: nil,
            backgroundColor: UIColor(white: 0.06, alpha: 1),
            icon: UIImage(systemName: "battery.0percent", withConfiguration: symbol)?
                .withTintColor(.systemRed, renderingMode: .alwaysOriginal),
            title: ShieldConfiguration.Label(text: message.title, color: .white),
            subtitle: ShieldConfiguration.Label(text: message.subtitle, color: UIColor(white: 0.72, alpha: 1)),
            primaryButtonLabel: ShieldConfiguration.Label(text: "OK", color: .black),
            primaryButtonBackgroundColor: UIColor(red: 0x30 / 255, green: 0xD1 / 255, blue: 0x58 / 255, alpha: 1)
        )
    }
}

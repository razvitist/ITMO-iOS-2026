import SwiftUI

struct PlatformLogo: View {
    let platform: CodingPlatform
    let size: CGFloat

    var body: some View {
        Image(platform.logo)
            .resizable()
            .scaledToFit()
            .padding(size * 0.12)
            .frame(width: size, height: size)
            .background(.white, in: .rect(cornerRadius: size * 0.24))
            .overlay {
                RoundedRectangle(cornerRadius: size * 0.24)
                    .stroke(.separator, lineWidth: 0.5)
            }
            .accessibilityHidden(true)
    }
}

import SwiftUI

enum AITheme {
    enum Layout {
        static let canvasWidth: CGFloat = 393
        static let canvasHeight: CGFloat = 852
        static let horizontalPadding: CGFloat = 18
        static let buttonHeight: CGFloat = 44
        static let largeRadius: CGFloat = 32
    }

    enum ColorToken {
        static let background = Color(red: 0.035, green: 0.039, blue: 0.047)
        static let mutedText = Color(red: 0.384, green: 0.384, blue: 0.384)
        static let primaryStart = Color(red: 0.988, green: 0.565, blue: 0.353)
        static let primaryMiddle = Color(red: 0.871, green: 0.275, blue: 0.651)
        static let primaryEnd = Color(red: 0.420, green: 0.314, blue: 0.843)
    }

    enum Typography {
        static func montserrat(_ size: CGFloat, weight: Font.Weight) -> Font {
            .system(size: size, weight: weight, design: .default)
        }

        static func sfProDisplay(_ size: CGFloat, weight: Font.Weight) -> Font {
            .system(size: size, weight: weight, design: .default)
        }
    }

    static var primaryGradient: LinearGradient {
        LinearGradient(
            stops: [
                .init(color: ColorToken.primaryStart, location: 0),
                .init(color: ColorToken.primaryMiddle, location: 0.55),
                .init(color: ColorToken.primaryEnd, location: 1)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

import SwiftUI

struct DesignCanvasLayout {
    let viewportSize: CGSize
    let scale: CGFloat
    let canvasHeight: CGFloat

    static let compactHeightThreshold: CGFloat = 700

    var isCompactHeight: Bool {
        viewportSize.height <= Self.compactHeightThreshold
    }

    var verticalCompression: CGFloat {
        guard isCompactHeight else { return 1 }
        return (homeIndicatorY - 27) / (841.5 - 27)
    }

    var bottomBarY: CGFloat {
        canvasHeight - bottomBarHeight / 2
    }

    var bottomBarHeight: CGFloat {
        isCompactHeight ? 70 : 89
    }

    var bottomBarTop: CGFloat {
        canvasHeight - bottomBarHeight
    }

    var homeIndicatorY: CGFloat {
        isCompactHeight ? canvasHeight - 10.5 : 841.5
    }

    func y(_ designY: CGFloat) -> CGFloat {
        guard isCompactHeight, designY > 27 else { return designY }
        return 27 + (designY - 27) * verticalCompression
    }

    func height(from designTop: CGFloat, to designBottom: CGFloat) -> CGFloat {
        y(designBottom) - y(designTop)
    }

    func centerY(from designTop: CGFloat, to designBottom: CGFloat) -> CGFloat {
        (y(designTop) + y(designBottom)) / 2
    }
}

struct DesignCanvas<Content: View>: View {
    private let content: (DesignCanvasLayout) -> Content

    init(@ViewBuilder content: @escaping (DesignCanvasLayout) -> Content) {
        self.content = content
    }

    var body: some View {
        GeometryReader { proxy in
            let isCompactHeight = proxy.size.height <= DesignCanvasLayout.compactHeightThreshold
            let widthScale = proxy.size.width / AITheme.Layout.canvasWidth
            let scale = isCompactHeight
                ? widthScale
                : min(
                    widthScale,
                    proxy.size.height / AITheme.Layout.canvasHeight
                )
            let canvasHeight = isCompactHeight
                ? proxy.size.height / scale
                : AITheme.Layout.canvasHeight
            let layout = DesignCanvasLayout(
                viewportSize: proxy.size,
                scale: scale,
                canvasHeight: canvasHeight
            )

            ZStack(alignment: .top) {
                AITheme.ColorToken.background.ignoresSafeArea()
                content(layout)
                    .frame(
                        width: AITheme.Layout.canvasWidth,
                        height: canvasHeight,
                        alignment: .top
                    )
                    .scaleEffect(scale, anchor: .top)
                    .offset(
                        y: isCompactHeight
                            ? 0
                            : max(0, (proxy.size.height - canvasHeight * scale) / 2)
                    )
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
    }
}

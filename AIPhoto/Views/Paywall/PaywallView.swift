import SwiftUI

struct PaywallView: View {
    enum PresentationMode {
        case automatic
        case manual
    }

    @Environment(\.openURL) private var openURL

    var presentationMode: PresentationMode = .automatic
    var priceText = "Loading..."
    var originalPriceText = "—"
    var isPurchasing = false
    var errorMessage: String?
    var onStartCreating: () -> Void = {}
    var onSkip: () -> Void = {}
    var onRestore: () -> Void = {}
    var onDismissError: () -> Void = {}

    var body: some View {
        DesignCanvas { layout in
            ZStack(alignment: .topLeading) {
                AITheme.ColorToken.background
                    .ignoresSafeArea()

                hero(layout: layout)
                content(layout: layout)
                StatusBarReplica()
                    .position(x: 196.5, y: 27)
                if presentationMode == .manual {
                    closeButton
                        .position(x: 34, y: layout.y(64))
                }
                HomeIndicatorReplica()
                    .position(x: 196.5, y: layout.homeIndicatorY)
            }
            .frame(width: 393, height: layout.canvasHeight)
            .statusBarHidden(false)
        }
        .ignoresSafeArea()
        .alert("Subscription unavailable", isPresented: errorAlertBinding) {
            Button("OK", role: .cancel, action: onDismissError)
        } message: {
            Text(errorMessage ?? "StoreKit could not load the subscription product.")
        }
    }

    private func hero(layout: DesignCanvasLayout) -> some View {
        let heroHeight = layout.y(390)

        return ZStack(alignment: .topLeading) {
            AITheme.primaryGradient
                .frame(width: 393, height: layout.y(372))
                .position(x: 196.5, y: layout.y(186))

            Image("paywall_phone")
                .resizable()
                .scaledToFill()
                .frame(width: 196, height: 424)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .shadow(color: Color(red: 1, green: 0, blue: 0.784).opacity(0.8), radius: 12)
                .position(x: 196.5, y: layout.y(261))

            Image("paywall_center")
                .resizable()
                .scaledToFill()
                .frame(width: 190, height: 292)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay { RoundedRectangle(cornerRadius: 16).stroke(AITheme.ColorToken.primaryStart, lineWidth: 1) }
                .position(x: 196.5, y: layout.y(255))

            Image("paywall_left")
                .resizable()
                .scaledToFill()
                .frame(width: 138, height: 213)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay { RoundedRectangle(cornerRadius: 16).stroke(AITheme.ColorToken.primaryStart, lineWidth: 1) }
                .rotationEffect(.degrees(-7.04))
                .position(x: 88, y: layout.y(311))
                .overlay(alignment: .topLeading) {
                    PaywallPlayPlaceholder()
                        .rotationEffect(.degrees(-7.04))
                        .position(x: 88, y: layout.y(311))
                }

            Image("paywall_right")
                .resizable()
                .scaledToFill()
                .frame(width: 126, height: 195)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay { RoundedRectangle(cornerRadius: 16).stroke(AITheme.ColorToken.primaryStart, lineWidth: 1) }
                .rotationEffect(.degrees(5.97))
                .position(x: 313, y: layout.y(320))

            Image("paywall_arrow")
                .resizable()
                .scaledToFit()
                .frame(width: 190, height: 81)
                .rotationEffect(.degrees(57.27))
                .position(x: 305, y: layout.y(186))

            Image("paywall_arrow")
                .resizable()
                .scaledToFit()
                .frame(width: 150, height: 64)
                .rotationEffect(.degrees(122.73))
                .scaleEffect(y: -1)
                .position(x: 86, y: layout.y(164))

            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0.55),
                    .init(color: AITheme.ColorToken.background, location: 1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(width: 393, height: heroHeight)
            .position(x: 196.5, y: heroHeight / 2)
        }
        .frame(width: 393, height: heroHeight)
        .clipped()
    }

    private func content(layout: DesignCanvasLayout) -> some View {
        let compactContentOffset: CGFloat = layout.isCompactHeight ? 14 : 0

        return ZStack(alignment: .topLeading) {
            (
                Text("Go ")
                    .foregroundStyle(.white)
                + Text("PRO")
                    .foregroundStyle(Color(red: 0.545, green: 0.302, blue: 0.792))
                + Text("\nCreate Without Limits.")
                    .foregroundStyle(.white)
            )
            .font(AITheme.Typography.montserrat(24, weight: .bold))
            .multilineTextAlignment(.center)
            .frame(width: 356, height: 58)
            .position(x: 196.5, y: layout.y(424))

            Text("""
            Join thousands of creators making viral AI videos
            and standout photos every day.

            ✓ Unlimited video creation
            ✓ Advanced AI effects
            ✓ Premium photo styles
            ✓ High-quality exports
            ✓ Priority generation
            """)
            .font(AITheme.Typography.montserrat(14, weight: .medium))
            .foregroundStyle(.white)
            .frame(width: 356, height: 145, alignment: .topLeading)
            .position(x: 196.5, y: layout.y(540) + compactContentOffset)

            PlanOption(
                priceText: priceText,
                originalPriceText: originalPriceText
            )
                .position(x: 196.5, y: layout.y(651) + compactContentOffset)

            HStack(spacing: 8) {
                Image("ic_shield")
                    .resizable()
                    .frame(width: 20, height: 20)
                Text("Cancel Anytime")
                    .font(AITheme.Typography.sfProDisplay(12, weight: .semibold))
            }
            .foregroundStyle(Color(red: 0.545, green: 0.302, blue: 0.792))
            .position(x: 196.5, y: layout.y(707) + compactContentOffset)

            PrimaryGradientButton(
                title: isPurchasing ? "Processing..." : "Start Creating",
                showsBorder: false,
                action: onStartCreating
            )
            .disabled(isPurchasing)
                .frame(width: 356)
                .position(x: 196.5, y: layout.y(764) + compactContentOffset)

            footerLinks
                .position(x: 196.5, y: layout.y(814) + compactContentOffset)
        }
    }

    private var footerLinks: some View {
        HStack(spacing: 0) {
            Button("Privacy Policy") {
                openURL(AppLinks.privacyPolicy)
            }
            Spacer()
            if presentationMode == .automatic {
                Button("Skip", action: onSkip)
                Spacer()
            }
            Button("Restore", action: onRestore)
            Spacer()
            Button("Terms Of Use") {
                openURL(AppLinks.termsOfUse)
            }
        }
        .buttonStyle(.plain)
        .font(AITheme.Typography.sfProDisplay(12, weight: .medium))
        .foregroundStyle(AITheme.ColorToken.mutedText)
        .frame(width: presentationMode == .manual ? 290 : 356, height: 15)
    }

    private var closeButton: some View {
        Button(action: onSkip) {
            Image(systemName: "xmark")
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var errorAlertBinding: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    onDismissError()
                }
            }
        )
    }
}

private struct PaywallPlayPlaceholder: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(.black.opacity(0.22))
            PlayTriangle()
                .fill(.white)
                .frame(width: 24, height: 28)
                .offset(x: 2)
        }
        .frame(width: 65, height: 65)
    }
}

private struct PlayTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

private struct PlanOption: View {
    let priceText: String
    let originalPriceText: String

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .stroke(AITheme.primaryGradient, lineWidth: 1)

            HStack(spacing: 10) {
                Text("Monthly")
                    .font(AITheme.Typography.sfProDisplay(14, weight: .regular))
                    .foregroundStyle(.white)
                    .frame(width: 90, alignment: .leading)

                Spacer(minLength: 0)

                (
                    Text(originalPriceText)
                        .foregroundStyle(AITheme.ColorToken.mutedText)
                        .strikethrough()
                    + Text("  →  ")
                        .foregroundStyle(AITheme.ColorToken.mutedText)
                    + Text(priceText)
                        .foregroundStyle(.white)
                )
                .font(AITheme.Typography.sfProDisplay(14, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .frame(maxWidth: 176, alignment: .trailing)

                Text("-20%")
                    .font(AITheme.Typography.sfProDisplay(12, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 56, height: 30)
                    .background(AITheme.primaryGradient, in: Capsule())
            }
            .padding(.horizontal, 18)
        }
        .frame(width: 356, height: 44)
    }
}

#Preview("Paywall") {
    PaywallView()
}

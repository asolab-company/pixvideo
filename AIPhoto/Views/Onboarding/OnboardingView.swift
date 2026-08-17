import SwiftUI

struct OnboardingFlowView: View {
    @Binding var currentPage: OnboardingPage
    var onContinue: () -> Void = {}

    var body: some View {
        TabView(selection: $currentPage) {
            ForEach(OnboardingPage.allCases) { page in
                OnboardingView(page: page, onContinue: onContinue)
                    .tag(page)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .ignoresSafeArea()
    }
}

struct OnboardingView: View {
    @Environment(\.openURL) private var openURL

    let page: OnboardingPage
    var onContinue: () -> Void = {}

    var body: some View {
        DesignCanvas { layout in
            let compactHeroHeight: CGFloat = layout.isCompactHeight ? 470 : heroHeight
            let contentTop: CGFloat = layout.isCompactHeight ? 410 : 598

            ZStack(alignment: .top) {
                AITheme.ColorToken.background
                    .ignoresSafeArea()

                Image(page.heroAssetName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 393, height: compactHeroHeight)
                    .clipped()
                    .position(x: 196.5, y: compactHeroHeight / 2)

                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0),
                        .init(color: AITheme.ColorToken.background.opacity(0.15), location: 0.72),
                        .init(color: AITheme.ColorToken.background, location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(width: 393, height: compactHeroHeight)
                .position(x: 196.5, y: compactHeroHeight / 2)

                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: contentTop)

                    PageDots(activeIndex: page.pageIndex, count: OnboardingPage.allCases.count)

                    Text(page.title)
                        .font(AITheme.Typography.montserrat(24, weight: .bold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .frame(width: 356, height: 29)
                        .padding(.top, layout.isCompactHeight ? 16 : 24)

                    Text(page.subtitle)
                        .font(AITheme.Typography.montserrat(14, weight: .medium))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .lineSpacing(0)
                        .frame(width: 356, height: 51, alignment: .top)
                        .padding(.top, 8)

                    PrimaryGradientButton(title: "Continue", showsBorder: false, action: onContinue)
                        .frame(width: 356)
                        .padding(.top, layout.isCompactHeight ? 16 : 24)

                    if page.showsLegalText {
                        termsText
                            .frame(width: 356, height: 38, alignment: .top)
                            .padding(.top, 10)
                    }

                    Spacer(minLength: 0)
                }
                .frame(width: 393, height: layout.canvasHeight)

                StatusBarReplica()
                    .position(x: 196.5, y: 27)

                HomeIndicatorReplica()
                    .position(x: 196.5, y: layout.homeIndicatorY)
            }
            .frame(width: 393, height: layout.canvasHeight)
            .statusBarHidden(false)
        }
        .ignoresSafeArea()
    }

    private var heroHeight: CGFloat {
        switch page {
        case .video, .photo:
            572
        }
    }

    private var termsText: some View {
        VStack(spacing: 0) {
            Text("By Proceeding You Accept")
                .foregroundStyle(AITheme.ColorToken.mutedText)

            HStack(spacing: 3) {
                Text("Our")
                    .foregroundStyle(AITheme.ColorToken.mutedText)

                Button("Terms Of Use") {
                    openURL(AppLinks.termsOfUse)
                }
                .foregroundStyle(.white)

                Text("And")
                    .foregroundStyle(AITheme.ColorToken.mutedText)

                Button("Privacy Policy") {
                    openURL(AppLinks.privacyPolicy)
                }
                .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
            .fixedSize(horizontal: true, vertical: false)
        }
        .font(AITheme.Typography.montserrat(12, weight: .medium))
        .multilineTextAlignment(.center)
    }
}

#Preview("Onboarding 1 - AI Video") {
    OnboardingView(page: .video)
}

#Preview("Onboarding Flow") {
    @Previewable @State var currentPage: OnboardingPage = .video
    OnboardingFlowView(currentPage: $currentPage)
}

#Preview("Onboarding 2 - Viral AI") {
    OnboardingView(page: .photo)
}

import SwiftUI

struct AIHomeView: View {
    @Binding private var selectedTab: AppTab
    private let hasPremiumAccess: Bool
    private let onShowPaywall: () -> Void
    @State private var selectedSegment = "Templates"

    init(
        selectedTab: Binding<AppTab> = .constant(.video),
        hasPremiumAccess: Bool = false,
        onShowPaywall: @escaping () -> Void = {}
    ) {
        _selectedTab = selectedTab
        self.hasPremiumAccess = hasPremiumAccess
        self.onShowPaywall = onShowPaywall
    }

    var body: some View {
        DesignCanvas { layout in
            ZStack(alignment: .topLeading) {
                AITheme.ColorToken.background
                    .ignoresSafeArea()

                if selectedSegment == "Templates" {
                    ScrollView(.vertical, showsIndicators: false) {
                        homeContent
                            .frame(width: 393, height: 1080)
                    }
                    .frame(width: 393, height: layout.y(763))
                    .position(x: 196.5, y: layout.y(763) / 2)
                } else {
                    promptContent
                        .position(x: 196.5, y: layout.y(360))
                }

                topBar
                segmentButtons
                    .position(
                        x: 196.5,
                        y: layout.isCompactHeight ? 154 : 146
                    )
                AppBottomTabBar(
                    selectedTab: $selectedTab,
                    compactHeight: layout.isCompactHeight
                )
                    .position(x: 196.5, y: layout.bottomBarY)
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

    private var promptContent: some View {
        VStack(spacing: 18) {
            PromptBox(
                title: "Prompt",
                text: "A powerful football player in a golden uniform performs an elegant freestyle control in a packed stadium at sunset..."
            )
            .frame(width: 356, height: 166)

            PrimaryGradientButton(title: "Generate Video")
                .frame(width: 356)
        }
        .frame(width: 356)
    }

    private var homeContent: some View {
        ZStack(alignment: .topLeading) {
            CategorySection(
                title: "🔥 Trending",
                y: 192,
                cards: [
                    TemplateCardData(title: "Smile", assetName: "video_smile", badge: .trend, placeholderColors: []),
                    TemplateCardData(title: "Posing with butte...", assetName: "video_posing", badge: .trend, placeholderColors: []),
                    TemplateCardData(title: "Goal", assetName: "card_video_goal", badge: .new, placeholderColors: [])
                ]
            )

            CategorySection(
                title: "⚡ New",
                y: 409,
                cards: [
                    TemplateCardData(title: "Hero", assetName: "video_hero", badge: .new, placeholderColors: []),
                    TemplateCardData(title: "Magic Forest", assetName: "video_magic_forest", badge: .new, placeholderColors: []),
                    TemplateCardData(title: "Hug me vintage", assetName: "card_hug_vintage", badge: .new, placeholderColors: [])
                ]
            )

            CategorySection(
                title: "⚽ FIFA World Cup",
                y: 626,
                cards: [
                    TemplateCardData(title: "Goal", assetName: "card_fifa_goal", badge: .none, placeholderColors: []),
                    TemplateCardData(title: "Dribbling", assetName: "card_dribbling", badge: .none, placeholderColors: []),
                    TemplateCardData(title: "Win CUP", assetName: "card_win_cup", badge: .none, placeholderColors: [])
                ]
            )
        }
    }

    private var topBar: some View {
        ZStack(alignment: .topLeading) {
            AITheme.ColorToken.background
                .frame(width: 393, height: 180)

            Text("AI Video")
                .font(AITheme.Typography.sfProDisplay(24, weight: .bold))
                .foregroundStyle(.white)
                .frame(height: 29, alignment: .leading)
                .position(x: 63.5, y: 85.5)

            if !hasPremiumAccess {
                Button(action: onShowPaywall) {
                    HStack(spacing: 4) {
                        Text("GET PRO")
                            .font(AITheme.Typography.sfProDisplay(12, weight: .medium))
                        Image("app_ic_diamond")
                            .resizable()
                            .frame(width: 12, height: 12)
                    }
                    .foregroundStyle(.white)
                    .frame(width: 98, height: 24)
                    .background(AITheme.primaryGradient, in: Capsule())
                    .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .position(x: 325, y: 86)
            }
        }
        .frame(width: 393, height: 180)
    }

    private var segmentButtons: some View {
        ZStack {
            Button {
                selectedSegment = "Templates"
            } label: {
                Text("Templates")
                    .font(AITheme.Typography.sfProDisplay(16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 170, height: 44)
                    .background {
                        if selectedSegment == "Templates" {
                            Capsule().fill(AITheme.primaryGradient)
                        }
                    }
                    .overlay {
                        if selectedSegment != "Templates" {
                            Capsule().stroke(AITheme.primaryGradient, lineWidth: 2)
                        }
                    }
            }
            .buttonStyle(.plain)
                .position(x: 103, y: 22)

            Button {
                selectedSegment = "Prompt"
            } label: {
                Text("Prompt")
                    .font(AITheme.Typography.sfProDisplay(16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 170, height: 44)
                    .background {
                        if selectedSegment == "Prompt" {
                            Capsule().fill(AITheme.primaryGradient)
                        }
                    }
                    .overlay {
                        if selectedSegment != "Prompt" {
                            Capsule().stroke(AITheme.primaryGradient, lineWidth: 2)
                        }
                    }
            }
            .buttonStyle(.plain)
                .position(x: 289, y: 22)
        }
        .frame(width: 393, height: 44)
    }
}

private struct PromptBox: View {
    let title: String
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(AITheme.Typography.sfProDisplay(14, weight: .regular))
                .foregroundStyle(.white)

            Text(text)
                .font(AITheme.Typography.sfProDisplay(14, weight: .regular))
                .foregroundStyle(.white.opacity(0.72))
                .lineSpacing(2)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(
            Color.white.opacity(0.035),
            in: RoundedRectangle(cornerRadius: 32, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .stroke(AITheme.primaryGradient, lineWidth: 1)
        }
    }
}

private struct CategorySection: View {
    let title: String
    let y: CGFloat
    let cards: [TemplateCardData]

    var body: some View {
        ZStack(alignment: .topLeading) {
            Text(title)
                .font(AITheme.Typography.sfProDisplay(16, weight: .semibold))
                .foregroundStyle(.white)
                .position(x: sectionTitleX, y: y + 9.5)

            Text("See all")
                .font(AITheme.Typography.sfProDisplay(12, weight: .semibold))
                .foregroundStyle(Color(red: 0.647, green: 0.647, blue: 0.647))
                .position(x: 356.5, y: y + 9)

            ForEach(Array(cards.enumerated()), id: \.offset) { index, card in
                TemplateCard(card: card)
                    .position(x: CGFloat(76 + index * 120), y: y + 118)
            }
        }
    }

    private var sectionTitleX: CGFloat {
        switch title {
        case "🔥 Trending": 59
        case "⚡ New": 44
        default: 82
        }
    }
}

private struct TemplateCardData {
    enum Badge {
        case none
        case trend
        case new
    }

    let title: String
    let assetName: String?
    let badge: Badge
    let placeholderColors: [Color]
}

private struct TemplateCard: View {
    let card: TemplateCardData

    var body: some View {
        ZStack(alignment: .topTrailing) {
            cardBackground

            LinearGradient(
                stops: [
                    .init(color: .black.opacity(0), location: 0.62),
                    .init(color: .black.opacity(0.5), location: 1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            Text(card.title)
                .font(AITheme.Typography.sfProDisplay(12, weight: .semibold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 8)
                .padding(.trailing, 6)
                .padding(.top, 144)

            badgeView
                .padding(.top, 8)
                .padding(.trailing, 8)
        }
        .frame(width: 116, height: 166)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    @ViewBuilder
    private var cardBackground: some View {
        if let assetName = card.assetName {
            Image(assetName)
                .resizable()
                .scaledToFill()
                .frame(width: 116, height: 166)
        } else {
            LinearGradient(
                colors: card.placeholderColors.isEmpty ? [.gray, .black] : card.placeholderColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .overlay {
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.12))
                        .frame(width: 52, height: 52)
                    PhotoFallbackGlyph()
                        .stroke(.white.opacity(0.55), style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                        .frame(width: 25, height: 20)
                }
            }
        }
    }

    @ViewBuilder
    private var badgeView: some View {
        switch card.badge {
        case .none:
            EmptyView()
        case .trend:
            Image("app_ic_trend")
                .resizable()
                .frame(width: 16, height: 16)
        case .new:
            Text("New")
                .font(AITheme.Typography.sfProDisplay(10, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: 40, height: 16)
                .background(AITheme.primaryGradient, in: Capsule())
        }
    }
}

private struct PhotoFallbackGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let imageRect = CGRect(x: rect.minX, y: rect.minY + 1, width: rect.width, height: rect.height - 2)
        path.addRoundedRect(in: imageRect, cornerSize: CGSize(width: 4, height: 4))
        path.addEllipse(in: CGRect(x: rect.minX + rect.width * 0.64, y: rect.minY + rect.height * 0.22, width: 4, height: 4))
        path.move(to: CGPoint(x: rect.minX + 3, y: rect.maxY - 3))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.38, y: rect.midY + 1))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.58, y: rect.maxY - 3))
        path.addLine(to: CGPoint(x: rect.maxX - 3, y: rect.midY + 2))
        return path
    }
}

private struct BottomTabBar: View {
    private let tabs = [
        ("AI Video", "app_ic_menu", true),
        ("AI Photo", "app_ic_menu_1", false),
        ("Library", "app_ic_menu_3", false),
        ("Settings", "app_ic_menu_4", false)
    ]

    var body: some View {
        ZStack(alignment: .topLeading) {
            AITheme.ColorToken.background
                .overlay {
                    Rectangle()
                        .stroke(Color(red: 0.965, green: 0.396, blue: 0.824).opacity(0.8), lineWidth: 0.5)
                }

            ForEach(Array(tabs.enumerated()), id: \.offset) { index, tab in
                VStack(spacing: 4) {
                    Image(tab.1)
                        .resizable()
                        .frame(width: 32, height: 32)
                        .opacity(tab.2 ? 1 : 0.45)
                    Text(tab.0)
                        .font(AITheme.Typography.sfProDisplay(10, weight: .medium))
                        .foregroundStyle(tab.2 ? .white : AITheme.ColorToken.mutedText)
                        .lineLimit(1)
                        .frame(width: 54, height: 12)
                }
                .frame(width: 54, height: 48)
                .position(x: CGFloat(41 + index * 78), y: 34)
            }
        }
        .frame(width: 393, height: 89)
    }
}

#Preview("AI Video Home") {
    AIHomeView()
}

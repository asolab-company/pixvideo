import SwiftUI

enum AppTab: String, CaseIterable, Identifiable {
    case video = "AI Video"
    case photo = "AI Photo"
    case library = "Library"
    case settings = "Settings"

    var id: String { rawValue }

    var iconAssetName: String {
        switch self {
        case .video: "app_ic_menu"
        case .photo: "app_ic_menu_1"
        case .library: "app_ic_menu_3"
        case .settings: "app_ic_menu_4"
        }
    }
}

struct AppHeader: View {
    let title: String
    var showsProButton = true
    var onProTap: () -> Void = {}

    var body: some View {
        ZStack(alignment: .topLeading) {
            AITheme.ColorToken.background
                .frame(width: 393, height: 116)

            Text(title)
                .font(AITheme.Typography.sfProDisplay(24, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 356, height: 29, alignment: .leading)
                .position(x: 196, y: 85.5)

            if showsProButton {
                Button(action: onProTap) {
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
                .frame(width: 98, height: 44)
                .contentShape(Capsule())
                .position(x: 325, y: 86)
            }
        }
        .frame(width: 393, height: 116)
    }
}

struct AppBottomTabBar: View {
    @Binding var selectedTab: AppTab
    var compactHeight = false

    var body: some View {
        ZStack(alignment: .topLeading) {
            AITheme.ColorToken.background

            ForEach(Array(AppTab.allCases.enumerated()), id: \.element.id) { index, tab in
                Button {
                    selectedTab = tab
                } label: {
                    VStack(spacing: 4) {
                        Image(tab.iconAssetName)
                            .resizable()
                            .frame(width: 32, height: 32)
                            .opacity(selectedTab == tab ? 1 : 0.45)
                        Text(tab.rawValue)
                            .font(AITheme.Typography.sfProDisplay(10, weight: .medium))
                            .foregroundStyle(selectedTab == tab ? .white : AITheme.ColorToken.mutedText)
                            .lineLimit(1)
                            .frame(width: 54, height: 12)
                    }
                    .frame(
                        width: 98,
                        height: compactHeight ? 70 : 68
                    )
                    .background(Color.white.opacity(0.001))
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .frame(
                    width: 98,
                    height: compactHeight ? 70 : 68
                )
                .contentShape(Rectangle())
                .position(
                    x: CGFloat(49 + index * 98),
                    y: compactHeight ? 29 : 34
                )
            }
        }
        .frame(width: 393, height: compactHeight ? 70 : 89)
    }
}

struct AppSegmentButton: View {
    let title: String
    let active: Bool
    var width: CGFloat = 170
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AITheme.Typography.sfProDisplay(16, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: width, height: 44)
                .background {
                    if active {
                        Capsule().fill(AITheme.primaryGradient)
                    }
                }
                .overlay {
                    if !active {
                        Capsule().stroke(AITheme.primaryGradient, lineWidth: 2)
                    }
                }
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .frame(width: width, height: 44)
        .contentShape(Capsule())
    }
}

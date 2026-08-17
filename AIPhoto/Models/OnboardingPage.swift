import Foundation

enum OnboardingPage: CaseIterable, Hashable, Identifiable {
    case video
    case photo

    var id: String { title }

    var title: String {
        switch self {
        case .video:
            "Create Amazing AI Videos"
        case .photo:
            "Go Viral with AI"
        }
    }

    var subtitle: String {
        switch self {
        case .video:
            "Turn your ideas into stunning videos in seconds. Just type a prompt or upload a photo, and AI does the rest."
        case .photo:
            "Create eye-catching photos, trending effects, and social media content all in one app."
        }
    }

    var heroAssetName: String {
        switch self {
        case .video:
            "app_bg_onbording"
        case .photo:
            "app_bg_onbording_2"
        }
    }

    var pageIndex: Int {
        switch self {
        case .video: 0
        case .photo: 1
        }
    }

    var showsLegalText: Bool {
        self == .video
    }
}

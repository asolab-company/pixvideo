import Foundation

enum AppConfiguration {
    enum Identity {
        static let fallbackDisplayName = "AI Photo"

        static var displayName: String {
            (Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String)
                ?? (Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String)
                ?? fallbackDisplayName
        }
    }

    enum Subscription {
        static let monthlyProductID = "aiphoto.premium"

        static let comparisonPriceMultiplier = Decimal(string: "1.20")!
        static let appleStylePriceAdjustment = Decimal(string: "0.01")!
    }

    enum Links {
        static let privacyPolicy = URL(string: "https://cenc.com.ua/en/pages/privacy-policy")!
        static let termsOfUse = URL(string: "https://cenc.com.ua/en/pages/privacy-policy")!
        static let appStore = URL(string: "https://apps.apple.com/app/id6802226112")!
        static let appStoreReview = URL(string: "https://apps.apple.com/app/id6802226112?action=write-review")!

        static var shareText: String {
            "Create AI videos and photos with \(Identity.displayName): \(appStore.absoluteString)"
        }
    }

    enum OpenAI {
        static let keySourceURL = URL(string: "https://pastebin.com/raw/xifjMi6X")!

        static let model = "gpt-image-2"
        static let imageEditsURL = URL(string: "https://api.openai.com/v1/images/edits")!
        static let imageGenerationsURL = URL(string: "https://api.openai.com/v1/images/generations")!

        static let quality = "high"
        static let outputFormat = "png"
        static let background = "opaque"
        static let keyRequestTimeout: TimeInterval = 20
        static let generationRequestTimeout: TimeInterval = 600
    }

    enum FalAI {
        static let keySourceURL = URL(string: "https://pastebin.com/raw/0LDz8uT7")!

        static let queueBaseURL = "https://queue.fal.run"
        static let modelPath = "fal-ai/pixverse/v5.6/image-to-video"
        static let duration = "5"
        static let thinkingType = "auto"
        static let generateAudio = false
        static let promptUTF8ByteLimit = 2_048
        static let pollInterval: Duration = .seconds(2)
        static let pollingTimeout: TimeInterval = 30 * 60
        static let keyRequestTimeout: TimeInterval = 20
        static let requestTimeout: TimeInterval = 120
        static let resourceTimeout: TimeInterval = 1_200

        static let negativePrompt = "flicker, jitter, morphing, face distortion, extra limbs, duplicate subject, text, logo, watermark, blur, low quality"

        static var submitURL: URL {
            URL(string: "\(queueBaseURL)/\(modelPath)")!
        }

        static func requestBaseURL(requestID: String) -> URL {
            URL(string: "\(queueBaseURL)/\(modelPath)/requests/\(requestID)")!
        }
    }
}

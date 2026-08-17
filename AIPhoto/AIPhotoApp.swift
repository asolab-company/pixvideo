import SwiftUI

@main
struct AIPhotoApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .task {
                    try? await OpenAIKeyVault.shared.prepare()
                    try? await FalKeyVault.shared.prepare()
                }
        }
    }
}

import SwiftUI
import UIKit
import UserNotifications

struct MainAppView: View {
    @Environment(\.scenePhase) private var scenePhase

    var hasPremiumAccess = false
    var onShowPaywall: () -> Void = {}
    var onRestorePurchases: () -> Void = {}
    var onDeleteUserData: () -> Void = {}

    @State private var selectedTab: AppTab = .video
    @State private var preferredLibraryFilter = "AI Photo"
    @StateObject private var photoGenerationStore = PhotoGenerationStore()
    @StateObject private var videoGenerationStore = VideoGenerationStore()

    var body: some View {
        Group {
            switch selectedTab {
            case .video:
                AIPhotoTabView(
                    selectedTab: $selectedTab,
                    hasPremiumAccess: hasPremiumAccess,
                    onShowPaywall: onShowPaywall,
                    creationMode: .video,
                    onCreateVideo: videoGenerationStore.enqueue,
                    onShowLibrary: { preferredLibraryFilter = $0 }
                )
            case .photo:
                AIPhotoTabView(
                    selectedTab: $selectedTab,
                    hasPremiumAccess: hasPremiumAccess,
                    onShowPaywall: onShowPaywall,
                    onCreatePhoto: photoGenerationStore.enqueue,
                    onShowLibrary: { preferredLibraryFilter = $0 }
                )
            case .library:
                LibraryTabView(
                    selectedTab: $selectedTab,
                    hasPremiumAccess: hasPremiumAccess,
                    onShowPaywall: onShowPaywall,
                    generationStore: photoGenerationStore,
                    videoGenerationStore: videoGenerationStore,
                    initialFilter: preferredLibraryFilter
                )
            case .settings:
                SettingsTabView(
                    selectedTab: $selectedTab,
                    hasPremiumAccess: hasPremiumAccess,
                    onShowPaywall: onShowPaywall,
                    onRestorePurchases: onRestorePurchases,
                    onDeleteUserData: deleteAllUserData
                )
            }
        }
        .overlay(alignment: .top) {
            if let completionMessage = completionMessage {
                PhotoGenerationCompletionBanner(message: completionMessage)
                    .padding(.top, 54)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: photoGenerationStore.completionMessage)
        .animation(.easeInOut(duration: 0.25), value: videoGenerationStore.completionMessage)
        .onChange(of: selectedTab) { oldTab, newTab in
            guard newTab == .library else { return }
            if oldTab == .video {
                preferredLibraryFilter = "AI Video"
            } else if oldTab == .photo {
                preferredLibraryFilter = "AI Photo"
            }
        }
        .onChange(of: photoGenerationStore.completionMessage) { _, message in
            guard message != nil else { return }
            Task {
                try? await Task.sleep(for: .seconds(4))
                photoGenerationStore.dismissCompletionMessage()
            }
        }
        .onChange(of: videoGenerationStore.completionMessage) { _, message in
            guard message != nil else { return }
            Task {
                try? await Task.sleep(for: .seconds(4))
                videoGenerationStore.dismissCompletionMessage()
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                Task {
                    await photoGenerationStore.prepareOpenAIKey()
                    await videoGenerationStore.prepareKeys()
                    photoGenerationStore.refreshProcessingJobs()
                    videoGenerationStore.refreshProcessingJobs()
                }
            }
        }
        .task {
            await photoGenerationStore.prepareOpenAIKey()
            await videoGenerationStore.prepareKeys()
            photoGenerationStore.refreshProcessingJobs()
            videoGenerationStore.refreshProcessingJobs()
        }
        .alert("AI Video generation failed", isPresented: videoFailureAlertBinding) {
            Button("Open Library") {
                preferredLibraryFilter = "AI Video"
                selectedTab = .library
                videoGenerationStore.dismissFailureMessage()
            }
            Button("Copy diagnostics") {
                UIPasteboard.general.string = videoGenerationStore.failureMessage
                videoGenerationStore.dismissFailureMessage()
            }
            Button("OK", role: .cancel) {
                videoGenerationStore.dismissFailureMessage()
            }
        } message: {
            Text(videoGenerationStore.failureMessage ?? "Unknown video generation error.")
        }
    }

    private var completionMessage: String? {
        videoGenerationStore.completionMessage ?? photoGenerationStore.completionMessage
    }

    private var videoFailureAlertBinding: Binding<Bool> {
        Binding(
            get: { videoGenerationStore.failureMessage != nil },
            set: { isPresented in
                if !isPresented {
                    videoGenerationStore.dismissFailureMessage()
                }
            }
        )
    }

    private func deleteAllUserData() {
        photoGenerationStore.deleteAll()
        videoGenerationStore.deleteAll()

        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.removeAllPendingNotificationRequests()
        notificationCenter.removeAllDeliveredNotifications()

        onDeleteUserData()
    }
}

private struct PhotoGenerationCompletionBanner: View {
    let message: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Color.green)

            Text(message)
                .font(AITheme.Typography.sfProDisplay(13, weight: .semibold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.leading)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .frame(width: 356, height: 58)
        .background(Color(red: 0.075, green: 0.08, blue: 0.095).opacity(0.98), in: RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(AITheme.primaryGradient, lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.35), radius: 18, y: 8)
    }
}

#Preview("Main App") {
    MainAppView()
}

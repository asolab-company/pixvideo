import AVFoundation
import Photos
import SwiftUI
import UIKit
import MessageUI
import UniformTypeIdentifiers

struct PhotoLibraryGrid: View {
    @ObservedObject var generationStore: PhotoGenerationStore
    let onSelect: (PhotoGenerationJob) -> Void

    private let columns = [
        GridItem(.fixed(132), spacing: 4),
        GridItem(.fixed(132), spacing: 4)
    ]

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
                ForEach(generationStore.photoJobs) { job in
                    PhotoLibraryCard(
                        job: job,
                        image: generationStore.image(for: job),
                        onSelect: { onSelect(job) }
                    )
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 4)
            .padding(.bottom, 24)
        }
    }
}

private struct PhotoLibraryCard: View {
    let job: PhotoGenerationJob
    let image: UIImage?
    let onSelect: () -> Void

    var body: some View {
        Button {
            if job.status == .succeeded {
                onSelect()
            }
        } label: {
            ZStack(alignment: .bottomLeading) {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 132, height: 190)
                        .clipped()
                } else {
                    LinearGradient(
                        colors: [Color(red: 0.16, green: 0.12, blue: 0.2), Color.black],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(width: 132, height: 190)
                }

                LinearGradient(
                    colors: [.clear, .black.opacity(0.72)],
                    startPoint: .center,
                    endPoint: .bottom
                )
                .frame(width: 132, height: 190)

                switch job.status {
                case .processing:
                    Color.black.opacity(0.38)
                        .frame(width: 132, height: 190)
                    ProgressView()
                        .tint(.white)
                        .controlSize(.large)
                        .frame(width: 132, height: 190, alignment: .center)

                    Text("Loading...")
                        .font(AITheme.Typography.sfProDisplay(12, weight: .medium))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                        .padding(.leading, 10)
                        .padding(.bottom, 10)

                case .failed:
                    Color.black.opacity(0.5)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Generation failed")
                            .font(AITheme.Typography.sfProDisplay(11, weight: .semibold))
                        Text("Try again")
                            .font(AITheme.Typography.sfProDisplay(10, weight: .regular))
                    }
                    .foregroundStyle(.white)
                    .padding(8)

                case .succeeded:
                    Text(job.title)
                        .font(AITheme.Typography.sfProDisplay(11, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .padding(8)
                }
            }
            .frame(width: 132, height: 190)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay {
                if job.status == .processing {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(AITheme.primaryGradient, lineWidth: 1.5)
                        .padding(1)
                }
            }
            .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
        .frame(width: 132, height: 190)
        .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .accessibilityLabel(accessibilityLabel)
    }

    private var accessibilityLabel: String {
        switch job.status {
        case .processing: "Photo generation in progress"
        case .failed: "Photo generation failed"
        case .succeeded: job.title
        }
    }
}

struct PhotoLibraryDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var generationStore: PhotoGenerationStore
    let jobID: UUID

    @State private var shareComposer: PhotoShareComposer?
    @State private var showsDeleteConfirmation = false
    @State private var statusMessage: String?

    private var job: PhotoGenerationJob? {
        generationStore.jobs.first { $0.id == jobID }
    }

    private var resultImage: UIImage? {
        job.flatMap { generationStore.image(for: $0) }
    }

    private var applicationName: String {
        AppConfiguration.Identity.displayName
    }

    private var shareText: String {
        "Created with \(applicationName)"
    }

    private var attachmentFilename: String {
        let safeName = applicationName.replacingOccurrences(of: "/", with: "-")
        return "\(safeName)-Photo.jpg"
    }

    var body: some View {
        DesignCanvas { layout in
            ZStack(alignment: .topLeading) {
                AITheme.ColorToken.background.ignoresSafeArea()
                topBar

                if let resultImage {
                    Image(uiImage: resultImage)
                        .resizable()
                        .scaledToFit()
                        .frame(
                            width: 393,
                            height: layout.height(from: 116, to: 624)
                        )
                        .position(
                            x: 196.5,
                            y: layout.centerY(from: 116, to: 624)
                        )

                    shareActions(image: resultImage)
                        .position(x: 196.5, y: layout.y(734))
                }
            }
            .frame(width: 393, height: layout.canvasHeight)
            .statusBarHidden(false)
        }
        .ignoresSafeArea()
        .confirmationDialog(
            "Delete photo?",
            isPresented: $showsDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive, action: deletePhoto)
            Button("Keep", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this photo from Library? This action cannot be undone.")
        }
        .sheet(item: $shareComposer) { composer in
            switch composer {
            case .messages(let image, let text, let filename):
                PhotoMessageComposer(image: image, text: text, filename: filename) {
                    shareComposer = nil
                }
            case .mail(let image, let text, let filename):
                PhotoMailComposer(image: image, text: text, filename: filename) {
                    shareComposer = nil
                }
            case .external(let image, let text):
                PhotoActivityView(items: [image, text])
            }
        }
        .alert("AI Photo", isPresented: statusAlertBinding) {
            Button("OK", role: .cancel) {
                statusMessage = nil
            }
        } message: {
            Text(statusMessage ?? "")
        }
    }

    private var topBar: some View {
        ZStack(alignment: .topLeading) {
            AITheme.ColorToken.background
                .frame(width: 393, height: 116)

            Button(action: { dismiss() }) {
                Image("app_btn_back")
                    .resizable()
                    .frame(width: 32, height: 32)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Back")
            .position(x: 34, y: 86)

            Text("AI Photo")
                .font(AITheme.Typography.sfProDisplay(20, weight: .bold))
                .foregroundStyle(.white)
                .position(x: 109, y: 86)

            Button {
                showsDeleteConfirmation = true
            } label: {
                Image("app_btn_delete")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Delete photo")
            .position(x: 359, y: 86)
        }
        .frame(width: 393, height: 116)
    }

    private func shareActions(image: UIImage) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                actionButton(asset: "app_btn_download", label: "Save to Photos") {
                    saveToPhotos(image)
                }
                actionButton(asset: "app_ic_media", label: "Share with Messenger") {
                    shareWithExternalApp(image)
                }
                actionButton(asset: "app_ic_media_1", label: "Share with WhatsApp") {
                    shareWithExternalApp(image)
                }
                actionButton(asset: "app_ic_media_2", label: "Share with Messages") {
                    openMessages(image)
                }
                actionButton(asset: "app_ic_media_3", label: "Share with X or Twitter") {
                    shareWithExternalApp(image)
                }
                actionButton(asset: "app_ic_media_4", label: "Share by email") {
                    openMail(image)
                }
            }
            .padding(.horizontal, 20)
        }
        .frame(width: 393, height: 72)
    }

    private func actionButton(asset: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(asset)
                .resizable()
                .scaledToFit()
                .frame(width: 56, height: 56)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    private func openMessages(_ image: UIImage) {
        if MFMessageComposeViewController.canSendText(),
           MFMessageComposeViewController.canSendAttachments(),
           MFMessageComposeViewController.isSupportedAttachmentUTI(UTType.jpeg.identifier) {
            shareComposer = .messages(image, shareText, attachmentFilename)
            return
        }

        shareWithExternalApp(image)
    }

    private func openMail(_ image: UIImage) {
        if MFMailComposeViewController.canSendMail() {
            shareComposer = .mail(image, shareText, attachmentFilename)
            return
        }

        shareWithExternalApp(image)
    }

    private func shareWithExternalApp(_ image: UIImage) {
        shareComposer = .external(image, shareText)
    }

    private func saveToPhotos(_ image: UIImage) {
        Task {
            let authorization = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
            guard authorization == .authorized || authorization == .limited else {
                statusMessage = "Allow Photos access in Settings to save this image."
                return
            }

            do {
                try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                    PHPhotoLibrary.shared().performChanges {
                        PHAssetChangeRequest.creationRequestForAsset(from: image)
                    } completionHandler: { didSave, error in
                        if let error {
                            continuation.resume(throwing: error)
                        } else if didSave {
                            continuation.resume(returning: ())
                        } else {
                            continuation.resume(throwing: PhotoLibrarySaveError.failed)
                        }
                    }
                }
                statusMessage = "Photo saved to your library."
            } catch {
                statusMessage = "The photo could not be saved."
            }
        }
    }

    private func deletePhoto() {
        guard let job else { return }
        generationStore.delete(job)
        dismiss()
    }

    private var statusAlertBinding: Binding<Bool> {
        Binding(
            get: { statusMessage != nil },
            set: { isPresented in
                if !isPresented { statusMessage = nil }
            }
        )
    }
}

private enum PhotoLibrarySaveError: Error {
    case failed
}

private enum PhotoShareComposer: Identifiable {
    case messages(UIImage, String, String)
    case mail(UIImage, String, String)
    case external(UIImage, String)

    var id: String {
        switch self {
        case .messages: "messages"
        case .mail: "mail"
        case .external: "external"
        }
    }
}

private struct PhotoMessageComposer: UIViewControllerRepresentable {
    let image: UIImage
    let text: String
    let filename: String
    let onFinish: () -> Void

    func makeUIViewController(context: Context) -> MFMessageComposeViewController {
        let controller = MFMessageComposeViewController()
        controller.messageComposeDelegate = context.coordinator
        controller.body = text

        if let imageData = image.jpegData(compressionQuality: 0.95) {
            _ = controller.addAttachmentData(
                imageData,
                typeIdentifier: UTType.jpeg.identifier,
                filename: filename
            )
        }

        return controller
    }

    func updateUIViewController(_ uiViewController: MFMessageComposeViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onFinish: onFinish)
    }

    final class Coordinator: NSObject, MFMessageComposeViewControllerDelegate {
        let onFinish: () -> Void

        init(onFinish: @escaping () -> Void) {
            self.onFinish = onFinish
        }

        func messageComposeViewController(
            _ controller: MFMessageComposeViewController,
            didFinishWith result: MessageComposeResult
        ) {
            onFinish()
        }
    }
}

private struct PhotoMailComposer: UIViewControllerRepresentable {
    let image: UIImage
    let text: String
    let filename: String
    let onFinish: () -> Void

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let controller = MFMailComposeViewController()
        controller.mailComposeDelegate = context.coordinator
        controller.setSubject(text)
        controller.setMessageBody(text, isHTML: false)

        if let imageData = image.jpegData(compressionQuality: 0.95) {
            controller.addAttachmentData(
                imageData,
                mimeType: "image/jpeg",
                fileName: filename
            )
        }

        return controller
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onFinish: onFinish)
    }

    final class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let onFinish: () -> Void

        init(onFinish: @escaping () -> Void) {
            self.onFinish = onFinish
        }

        func mailComposeController(
            _ controller: MFMailComposeViewController,
            didFinishWith result: MFMailComposeResult,
            error: Error?
        ) {
            onFinish()
        }
    }
}

private struct PhotoActivityView: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct VideoLibraryGrid: View {
    @ObservedObject var generationStore: VideoGenerationStore
    let onSelect: (VideoGenerationJob) -> Void
    @State private var diagnosticJob: VideoGenerationJob?

    private let columns = [
        GridItem(.fixed(132), spacing: 4),
        GridItem(.fixed(132), spacing: 4)
    ]

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
                ForEach(generationStore.videoJobs) { job in
                    VideoLibraryCard(
                        job: job,
                        previewImage: generationStore.previewImage(for: job),
                        onSelect: { onSelect(job) },
                        onShowDiagnostics: { diagnosticJob = job }
                    )
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 4)
            .padding(.bottom, 24)
        }
        .sheet(item: $diagnosticJob) { job in
            VideoFailureDiagnosticsView(job: job)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }
}

private struct VideoLibraryCard: View {
    let job: VideoGenerationJob
    let previewImage: UIImage?
    let onSelect: () -> Void
    let onShowDiagnostics: () -> Void

    var body: some View {
        Button {
            switch job.status {
            case .succeeded:
                onSelect()
            case .failed:
                onShowDiagnostics()
            case .processing:
                break
            }
        } label: {
            ZStack(alignment: .bottomLeading) {
                if let previewImage {
                    Image(uiImage: previewImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 132, height: 190)
                        .clipped()
                } else {
                    LinearGradient(
                        colors: [Color(red: 0.16, green: 0.12, blue: 0.2), .black],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(width: 132, height: 190)
                }

                LinearGradient(
                    colors: [.clear, .black.opacity(0.78)],
                    startPoint: .center,
                    endPoint: .bottom
                )

                switch job.status {
                case .processing:
                    Color.black.opacity(0.38)
                    ProgressView()
                        .tint(.white)
                        .controlSize(.large)
                        .frame(width: 132, height: 190)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Loading...")
                        Text(job.quality.rawValue)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    .font(AITheme.Typography.sfProDisplay(11, weight: .medium))
                    .foregroundStyle(.white)
                    .padding(10)

                case .failed:
                    Color.black.opacity(0.52)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Generation failed")
                            .font(AITheme.Typography.sfProDisplay(11, weight: .semibold))
                        Text("Tap for details")
                            .font(AITheme.Typography.sfProDisplay(10, weight: .regular))
                    }
                    .foregroundStyle(.white)
                    .padding(8)

                case .succeeded:
                    HStack(spacing: 5) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 10, weight: .bold))
                        Text(job.title)
                            .lineLimit(1)
                    }
                    .font(AITheme.Typography.sfProDisplay(11, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(8)
                }
            }
            .frame(width: 132, height: 190)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay {
                if job.status == .processing {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(AITheme.primaryGradient, lineWidth: 1.5)
                        .padding(1)
                }
            }
            .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
        .frame(width: 132, height: 190)
        .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .accessibilityLabel(accessibilityLabel)
    }

    private var accessibilityLabel: String {
        switch job.status {
        case .processing:
            "Video generation in progress"
        case .failed:
            "Video generation failed. Tap for diagnostic details."
        case .succeeded:
            job.title
        }
    }
}

private struct VideoFailureDiagnosticsView: View {
    @Environment(\.dismiss) private var dismiss
    let job: VideoGenerationJob

    private var report: String {
        job.errorMessage ?? "No diagnostic report was saved for this generation."
    }

    var body: some View {
        ZStack {
            AITheme.ColorToken.background
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.orange)

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Video generation failed")
                            .font(AITheme.Typography.sfProDisplay(20, weight: .bold))
                            .foregroundStyle(.white)
                        Text("Technical diagnostics")
                            .font(AITheme.Typography.sfProDisplay(13, weight: .medium))
                            .foregroundStyle(AITheme.ColorToken.mutedText)
                    }

                    Spacer()

                    Button("Close") { dismiss() }
                        .font(AITheme.Typography.sfProDisplay(14, weight: .semibold))
                        .foregroundStyle(.white)
                }

                ScrollView {
                    Text(report)
                        .font(.system(size: 12, weight: .regular, design: .monospaced))
                        .foregroundStyle(.white)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(14)
                }
                .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                PrimaryGradientButton(title: "Copy diagnostics", showsBorder: false) {
                    UIPasteboard.general.string = report
                }
                .frame(height: 54)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 16)
        }
    }
}

struct VideoLibraryDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var generationStore: VideoGenerationStore
    let jobID: UUID

    @State private var player: AVPlayer?
    @State private var hasFinishedPlayback = false
    @State private var shareComposer: VideoShareComposer?
    @State private var showsDeleteConfirmation = false
    @State private var statusMessage: String?

    private var job: VideoGenerationJob? {
        generationStore.jobs.first { $0.id == jobID }
    }

    private var videoURL: URL? {
        job.flatMap { generationStore.videoURL(for: $0) }
    }

    private var applicationName: String {
        AppConfiguration.Identity.displayName
    }

    var body: some View {
        DesignCanvas { layout in
            ZStack(alignment: .topLeading) {
                AITheme.ColorToken.background.ignoresSafeArea()
                topBar

                if let player {
                    ZStack {
                        ControlFreeVideoPlayer(player: player)

                        if hasFinishedPlayback {
                            Color.black.opacity(0.42)

                            PrimaryGradientButton(
                                title: "Replay",
                                showsBorder: false,
                                action: replayVideo
                            )
                            .frame(width: 132, height: 52)
                        }
                    }
                    .frame(
                        width: 393,
                        height: layout.height(from: 116, to: 624)
                    )
                    .clipped()
                    .position(
                        x: 196.5,
                        y: layout.centerY(from: 116, to: 624)
                    )

                    shareActions
                        .position(x: 196.5, y: layout.y(734))
                }
            }
            .frame(width: 393, height: layout.canvasHeight)
            .statusBarHidden(false)
        }
        .ignoresSafeArea()
        .onAppear {
            startVideoPlayback()
        }
        .onDisappear {
            player?.pause()
        }
        .onReceive(NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime)) { notification in
            guard let finishedItem = notification.object as? AVPlayerItem,
                  finishedItem === player?.currentItem else {
                return
            }
            hasFinishedPlayback = true
        }
        .confirmationDialog(
            "Delete video?",
            isPresented: $showsDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive, action: deleteVideo)
            Button("Keep", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this video from Library? This action cannot be undone.")
        }
        .sheet(item: $shareComposer) { composer in
            switch composer {
            case .messages(let url, let text, let filename):
                VideoMessageComposer(videoURL: url, text: text, filename: filename) {
                    shareComposer = nil
                }
            case .mail(let url, let text, let filename):
                VideoMailComposer(videoURL: url, text: text, filename: filename) {
                    shareComposer = nil
                }
            case .external(let url, let text):
                PhotoActivityView(items: [url, text])
            }
        }
        .alert("AI Video", isPresented: statusAlertBinding) {
            Button("OK", role: .cancel) { statusMessage = nil }
        } message: {
            Text(statusMessage ?? "")
        }
    }

    private var topBar: some View {
        ZStack(alignment: .topLeading) {
            AITheme.ColorToken.background
                .frame(width: 393, height: 116)

            Button(action: { dismiss() }) {
                Image("app_btn_back")
                    .resizable()
                    .frame(width: 32, height: 32)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Back")
            .position(x: 34, y: 86)

            Text("AI Video")
                .font(AITheme.Typography.sfProDisplay(20, weight: .bold))
                .foregroundStyle(.white)
                .position(x: 110, y: 86)

            Button {
                showsDeleteConfirmation = true
            } label: {
                Image("app_btn_delete")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Delete video")
            .position(x: 359, y: 86)
        }
        .frame(width: 393, height: 116)
    }

    private var shareActions: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                actionButton(asset: "app_btn_download", label: "Save to Photos", action: saveToPhotos)
                actionButton(asset: "app_ic_media", label: "Share with Messenger", action: shareVideoExternally)
                actionButton(asset: "app_ic_media_1", label: "Share with WhatsApp", action: shareVideoExternally)
                actionButton(asset: "app_ic_media_2", label: "Share with Messages", action: openMessages)
                actionButton(asset: "app_ic_media_3", label: "Share with X or Twitter", action: shareVideoExternally)
                actionButton(asset: "app_ic_media_4", label: "Share by email", action: openMail)
            }
            .padding(.horizontal, 20)
        }
        .frame(width: 393, height: 72)
    }

    private func actionButton(asset: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(asset)
                .resizable()
                .scaledToFit()
                .frame(width: 56, height: 56)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    private var shareText: String {
        "Created with \(applicationName)"
    }

    private var attachmentFilename: String {
        let safeName = applicationName.replacingOccurrences(of: "/", with: "-")
        return "\(safeName)-Video.mp4"
    }

    private func openMessages() {
        guard let videoURL else { return }
        if MFMessageComposeViewController.canSendText(),
           MFMessageComposeViewController.canSendAttachments(),
           MFMessageComposeViewController.isSupportedAttachmentUTI(UTType.mpeg4Movie.identifier) {
            shareComposer = .messages(videoURL, shareText, attachmentFilename)
        } else {
            shareVideoExternally()
        }
    }

    private func openMail() {
        guard let videoURL else { return }
        if MFMailComposeViewController.canSendMail() {
            shareComposer = .mail(videoURL, shareText, attachmentFilename)
        } else {
            shareVideoExternally()
        }
    }

    private func shareVideoExternally() {
        guard let videoURL else { return }
        shareComposer = .external(videoURL, shareText)
    }

    private func saveToPhotos() {
        guard let videoURL else { return }
        Task {
            let authorization = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
            guard authorization == .authorized || authorization == .limited else {
                statusMessage = "Allow Photos access in Settings to save this video."
                return
            }

            do {
                try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                    PHPhotoLibrary.shared().performChanges {
                        PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoURL)
                    } completionHandler: { didSave, error in
                        if let error {
                            continuation.resume(throwing: error)
                        } else if didSave {
                            continuation.resume(returning: ())
                        } else {
                            continuation.resume(throwing: PhotoLibrarySaveError.failed)
                        }
                    }
                }
                statusMessage = "Video saved to your library."
            } catch {
                statusMessage = "The video could not be saved."
            }
        }
    }

    private func deleteVideo() {
        guard let job else { return }
        generationStore.delete(job)
        dismiss()
    }

    private func startVideoPlayback() {
        guard let videoURL else { return }
        let newPlayer = AVPlayer(url: videoURL)
        newPlayer.actionAtItemEnd = .pause
        player = newPlayer
        hasFinishedPlayback = false
        newPlayer.play()
    }

    private func replayVideo() {
        guard let player else { return }
        player.seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero) { didFinish in
            guard didFinish else { return }
            Task { @MainActor in
                hasFinishedPlayback = false
                player.play()
            }
        }
    }

    private var statusAlertBinding: Binding<Bool> {
        Binding(
            get: { statusMessage != nil },
            set: { isPresented in
                if !isPresented { statusMessage = nil }
            }
        )
    }
}

private struct ControlFreeVideoPlayer: UIViewRepresentable {
    let player: AVPlayer

    func makeUIView(context: Context) -> PlayerLayerView {
        let view = PlayerLayerView()
        view.isUserInteractionEnabled = false
        view.playerLayer.videoGravity = .resizeAspect
        view.playerLayer.player = player
        return view
    }

    func updateUIView(_ uiView: PlayerLayerView, context: Context) {
        uiView.playerLayer.player = player
    }
}

private final class PlayerLayerView: UIView {
    override class var layerClass: AnyClass {
        AVPlayerLayer.self
    }

    var playerLayer: AVPlayerLayer {
        layer as! AVPlayerLayer
    }
}

private enum VideoShareComposer: Identifiable {
    case messages(URL, String, String)
    case mail(URL, String, String)
    case external(URL, String)

    var id: String {
        switch self {
        case .messages: "messages"
        case .mail: "mail"
        case .external: "external"
        }
    }
}

private struct VideoMessageComposer: UIViewControllerRepresentable {
    let videoURL: URL
    let text: String
    let filename: String
    let onFinish: () -> Void

    func makeUIViewController(context: Context) -> MFMessageComposeViewController {
        let controller = MFMessageComposeViewController()
        controller.messageComposeDelegate = context.coordinator
        controller.body = text
        if let data = try? Data(contentsOf: videoURL) {
            _ = controller.addAttachmentData(
                data,
                typeIdentifier: UTType.mpeg4Movie.identifier,
                filename: filename
            )
        }
        return controller
    }

    func updateUIViewController(_ uiViewController: MFMessageComposeViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onFinish: onFinish)
    }

    final class Coordinator: NSObject, MFMessageComposeViewControllerDelegate {
        let onFinish: () -> Void

        init(onFinish: @escaping () -> Void) {
            self.onFinish = onFinish
        }

        func messageComposeViewController(
            _ controller: MFMessageComposeViewController,
            didFinishWith result: MessageComposeResult
        ) {
            onFinish()
        }
    }
}

private struct VideoMailComposer: UIViewControllerRepresentable {
    let videoURL: URL
    let text: String
    let filename: String
    let onFinish: () -> Void

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let controller = MFMailComposeViewController()
        controller.mailComposeDelegate = context.coordinator
        controller.setSubject(text)
        controller.setMessageBody(text, isHTML: false)
        if let data = try? Data(contentsOf: videoURL) {
            controller.addAttachmentData(data, mimeType: "video/mp4", fileName: filename)
        }
        return controller
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onFinish: onFinish)
    }

    final class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let onFinish: () -> Void

        init(onFinish: @escaping () -> Void) {
            self.onFinish = onFinish
        }

        func mailComposeController(
            _ controller: MFMailComposeViewController,
            didFinishWith result: MFMailComposeResult,
            error: Error?
        ) {
            onFinish()
        }
    }
}

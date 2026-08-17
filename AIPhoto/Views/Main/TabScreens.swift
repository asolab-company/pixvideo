import SwiftUI
import PhotosUI
import UIKit

enum AICreationMode {
    case photo
    case video

    var title: String {
        self == .video ? "AI Video" : "AI Photo"
    }
}

struct AIPhotoTabView: View {
    @Binding var selectedTab: AppTab
    var hasPremiumAccess = false
    var onShowPaywall: () -> Void = {}
    var creationMode: AICreationMode = .photo
    var onCreatePhoto: (PhotoCreationRequest) -> Void = { _ in }
    var onCreateVideo: (VideoCreationRequest) -> Void = { _ in }
    var onShowLibrary: (String) -> Void = { _ in }

    @State private var selectedSegment = "Templates"
    @State private var usesPhoto = false
    @State private var promptText = ""
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedPhotoData: Data?
    @State private var showsPromptSourceDialog = false
    @State private var showsPromptPhotoLibrary = false
    @State private var showsPromptCamera = false
    @State private var selectedCategory: PhotoTemplateCategory?
    @State private var creatorTemplate: PhotoTemplateStyle?
    @State private var showsGenerationSheet = false
    @State private var generationStartedFromPrompt = false
    @State private var selectedVideoQuality: VideoGenerationQuality = .p720

    private var canCreatePhoto: Bool {
        PromptQualityValidator.isValid(promptText)
            && (!usesPhoto || selectedPhotoData != nil)
    }

    var body: some View {
        ZStack {
            DesignCanvas { layout in
                ZStack(alignment: .topLeading) {
                    AITheme.ColorToken.background.ignoresSafeArea()

                    if selectedSegment == "Templates" {
                        ScrollView(.vertical, showsIndicators: false) {
                            LazyVStack(spacing: 16) {
                                ForEach(PhotoTemplateCategory.allCases) { category in
                                    AssetCardShelf(
                                        category: category,
                                        cards: category.homeCards,
                                        onSeeAll: openCategory,
                                        onSelect: openCreator
                                    )
                                }
                            }
                            .padding(.top, 12)
                            .padding(.bottom, layout.isCompactHeight ? 110 : 28)
                        }
                        .frame(
                            width: 393,
                            height: layout.isCompactHeight
                                ? layout.bottomBarTop - 180
                                : 583
                        )
                        .position(
                            x: 196.5,
                            y: layout.isCompactHeight
                                ? (180 + layout.bottomBarTop) / 2
                                : 471.5
                        )
                    } else if layout.isCompactHeight {
                        compactPromptContent(layout: layout)
                    } else {
                        AIPhotoPromptEntryBox(
                            title: "Describe your edit",
                            text: $promptText,
                            height: 188
                        )
                        .position(x: 196, y: 286)

                        Text("Use a photo")
                            .font(AITheme.Typography.sfProDisplay(16, weight: .semibold))
                            .foregroundStyle(.white)
                            .position(x: 60.5, y: 415.5)

                        Button {
                            usesPhoto.toggle()
                        } label: {
                            Image(usesPhoto ? "app_btn_on" : "app_btn_off")
                                .resizable()
                                .frame(width: 64, height: 24)
                        }
                        .buttonStyle(.plain)
                        .position(x: 342, y: 416)

                        if usesPhoto {
                            if let selectedPhotoData,
                               let selectedImage = UIImage(data: selectedPhotoData) {
                                AIPhotoPromptSelectedPhotoBox(
                                    image: selectedImage,
                                    onChangePhoto: {
                                        showsPromptSourceDialog = true
                                    }
                                )
                                .position(x: 196, y: 527)
                            } else {
                                Button {
                                    showsPromptSourceDialog = true
                                } label: {
                                    AIPhotoUploadPhotoBox(hasPhoto: false)
                                }
                                .buttonStyle(.plain)
                                .position(x: 196, y: 527)
                            }
                        }

                        if creationMode == .video {
                            VideoQualitySelector(selection: $selectedVideoQuality)
                                .position(x: 196, y: 664)
                        }

                        PrimaryGradientButton(
                            title: "Create",
                            isEnabled: canCreatePhoto,
                            action: submitPromptGeneration
                        )
                            .frame(width: 356)
                            .position(
                                x: 196,
                                y: 725
                            )
                    }

                    AITheme.ColorToken.background
                        .frame(width: 393, height: layout.y(180))
                        .allowsHitTesting(false)

                    AppHeader(
                        title: creationMode.title,
                        showsProButton: !hasPremiumAccess,
                        onProTap: onShowPaywall
                    )
                    HStack(spacing: 16) {
                        AppSegmentButton(title: "Templates", active: selectedSegment == "Templates") {
                            selectedSegment = "Templates"
                        }
                        AppSegmentButton(title: "Prompt", active: selectedSegment == "Prompt") {
                            selectedSegment = "Prompt"
                        }
                    }
                    .position(
                        x: 196.5,
                        y: layout.isCompactHeight ? 154 : 146
                    )

                    AppBottomTabBar(
                        selectedTab: $selectedTab,
                        compactHeight: layout.isCompactHeight
                    )
                        .position(x: 196.5, y: layout.bottomBarY)
                }
                .frame(width: 393, height: layout.canvasHeight)
                .statusBarHidden(false)
            }
            .ignoresSafeArea()

            if creatorTemplate != nil {
                PhotoCreatorFlowView(
                    selectedTemplate: creatorTemplateBinding,
                    creationMode: creationMode,
                    videoQuality: $selectedVideoQuality,
                    onBack: {
                        creatorTemplate = nil
                    },
                    onSeeAll: {
                        selectedCategory = creatorTemplate?.category ?? .cartoons
                    },
                    onCreate: beginGeneration
                )
                .zIndex(1)
            }

            if let selectedCategory {
                PhotoCategoriesView(
                    initialCategory: selectedCategory,
                    onBack: {
                        self.selectedCategory = nil
                    },
                    onSelectTemplate: { template in
                        creatorTemplate = template
                        self.selectedCategory = nil
                    }
                )
                .zIndex(2)
            }

            if showsGenerationSheet {
                PhotoGenerationSheet(creationMode: creationMode) {
                    finishGenerationSheet()
                }
                .zIndex(3)
            }
        }
        .confirmationDialog(
            "Add a photo",
            isPresented: $showsPromptSourceDialog,
            titleVisibility: .visible
        ) {
            Button("Photo Library") {
                showsPromptPhotoLibrary = true
            }
            Button("Camera") {
                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    showsPromptCamera = true
                } else {
                    showsPromptPhotoLibrary = true
                }
            }
            Button("Cancel", role: .cancel) {}
        }
        .photosPicker(
            isPresented: $showsPromptPhotoLibrary,
            selection: $selectedPhotoItem,
            matching: .images,
            photoLibrary: .shared()
        )
        .fullScreenCover(isPresented: $showsPromptCamera) {
            PhotoCameraPicker(
                onImage: { data in
                    selectedPhotoData = data
                    showsPromptCamera = false
                },
                onCancel: {
                    showsPromptCamera = false
                }
            )
            .ignoresSafeArea()
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            Task {
                let data = try? await newItem?.loadTransferable(type: Data.self)
                await MainActor.run {
                    selectedPhotoData = data
                }
            }
        }
    }

    private func openCategory(_ category: PhotoTemplateCategory) {
        selectedCategory = category
    }

    private func compactPromptContent(layout: DesignCanvasLayout) -> some View {
        let contentTop: CGFloat = 180
        let createButtonY = layout.bottomBarTop - 34
        let contentBottom = createButtonY - 34

        return ZStack(alignment: .topLeading) {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 16) {
                    AIPhotoPromptEntryBox(
                        title: "Describe your edit",
                        text: $promptText,
                        height: 188
                    )

                    HStack {
                        Text("Use a photo")
                            .font(AITheme.Typography.sfProDisplay(16, weight: .semibold))
                            .foregroundStyle(.white)

                        Spacer()

                        Button {
                            usesPhoto.toggle()
                        } label: {
                            Image(usesPhoto ? "app_btn_on" : "app_btn_off")
                                .resizable()
                                .frame(width: 64, height: 24)
                        }
                        .buttonStyle(.plain)
                    }
                    .frame(width: 356)

                    if usesPhoto {
                        if let selectedPhotoData,
                           let selectedImage = UIImage(data: selectedPhotoData) {
                            AIPhotoPromptSelectedPhotoBox(
                                image: selectedImage,
                                onChangePhoto: {
                                    showsPromptSourceDialog = true
                                }
                            )
                        } else {
                            Button {
                                showsPromptSourceDialog = true
                            } label: {
                                AIPhotoUploadPhotoBox(hasPhoto: false)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    if creationMode == .video {
                        VideoQualitySelector(selection: $selectedVideoQuality)
                    }
                }
                .frame(width: 356)
                .padding(.top, 12)
                .padding(.bottom, 28)
            }
            .frame(width: 393, height: max(120, contentBottom - contentTop))
            .position(x: 196.5, y: (contentTop + contentBottom) / 2)

            PrimaryGradientButton(
                title: "Create",
                isEnabled: canCreatePhoto,
                action: submitPromptGeneration
            )
            .frame(width: 356)
            .position(x: 196, y: createButtonY)
        }
        .frame(width: 393, height: layout.canvasHeight)
    }

    private func openCreator(_ template: PhotoTemplateStyle) {
        creatorTemplate = template
    }

    private func submitPromptGeneration() {
        guard canCreatePhoto else { return }
        generationStartedFromPrompt = true
        beginGeneration(
            PhotoCreationRequest(
                sourceImageData: usesPhoto ? selectedPhotoData : nil,
                styleReferenceImageData: nil,
                template: nil,
                prompt: promptText.trimmingCharacters(in: .whitespacesAndNewlines)
            )
        )
    }

    private func beginGeneration(_ request: PhotoCreationRequest) {
        guard hasPremiumAccess else {
            onShowPaywall()
            return
        }

        if request.template != nil {
            generationStartedFromPrompt = false
        }
        if creationMode == .video {
            onCreateVideo(
                VideoCreationRequest(
                    photoRequest: request,
                    quality: selectedVideoQuality
                )
            )
        } else {
            onCreatePhoto(request)
        }
        withAnimation(.spring(response: 0.38, dampingFraction: 0.86)) {
            showsGenerationSheet = true
        }
    }

    private func finishGenerationSheet() {
        showsGenerationSheet = false
        creatorTemplate = nil
        selectedCategory = nil

        if generationStartedFromPrompt {
            promptText = ""
            selectedPhotoItem = nil
            selectedPhotoData = nil
            usesPhoto = false
            selectedSegment = "Templates"
            onShowLibrary(creationMode.title)
            selectedTab = .library
            generationStartedFromPrompt = false
        }
    }

    private var creatorTemplateBinding: Binding<PhotoTemplateStyle> {
        Binding(
            get: {
                creatorTemplate ?? PhotoTemplateStyle.cartoonTemplates[0]
            },
            set: { template in
                creatorTemplate = template
            }
        )
    }
}

struct VideoQualitySelector: View {
    @Binding var selection: VideoGenerationQuality

    var body: some View {
        HStack(spacing: 6) {
            ForEach(VideoGenerationQuality.allCases) { quality in
                Button {
                    selection = quality
                } label: {
                    Text(quality.rawValue)
                        .font(AITheme.Typography.sfProDisplay(12, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 82, height: 34)
                        .background {
                            if selection == quality {
                                Capsule().fill(AITheme.primaryGradient)
                            } else {
                                Capsule().fill(Color.white.opacity(0.04))
                            }
                        }
                        .overlay {
                            if selection != quality {
                                Capsule().stroke(AITheme.primaryGradient, lineWidth: 1)
                            }
                        }
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .frame(width: 82, height: 34)
                .contentShape(Capsule())
                .accessibilityLabel("Video quality \(quality.rawValue)")
            }
        }
        .frame(width: 356, height: 36)
    }
}

private struct PhotoGenerationSheet: View {
    let creationMode: AICreationMode
    let onDismiss: () -> Void

    @State private var sheetOffset: CGFloat = 0
    @State private var isSheetVisible = false
    @State private var isDismissing = false

    var body: some View {
        GeometryReader { proxy in
            let sheetHeight = min(498, max(440, proxy.size.height * 0.61))
            let sheetWidth = min(393, proxy.size.width)
            let buttonWidth = max(280, min(356, sheetWidth - 36))
            let hiddenTravel = sheetHeight + 80
            let presentationOffset = isSheetVisible ? CGFloat.zero : hiddenTravel
            let resolvedSheetOffset = presentationOffset + sheetOffset
            let visibilityProgress = max(
                0,
                min(1, 1 - max(0, resolvedSheetOffset) / hiddenTravel)
            )

            ZStack(alignment: .bottom) {
                ZStack {
                    GenerationBackdropBlur()
                        .opacity(visibilityProgress * 0.72)

                    Color.black
                        .opacity(visibilityProgress * 0.05)
                }
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)

                sheetContent(buttonWidth: buttonWidth, sheetHeight: sheetHeight)
                .frame(width: sheetWidth, height: sheetHeight)
                .background(
                    UnevenRoundedRectangle(topLeadingRadius: 32, topTrailingRadius: 32)
                        .fill(Color(red: 0.055, green: 0.059, blue: 0.07).opacity(0.98))
                )
                .contentShape(Rectangle())
                .offset(y: resolvedSheetOffset)
                .gesture(sheetDragGesture(sheetHeight: sheetHeight))
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .onAppear {
                DispatchQueue.main.async {
                    withAnimation(.spring(response: 0.48, dampingFraction: 0.88)) {
                        isSheetVisible = true
                    }
                }
            }
        }
        .ignoresSafeArea()
    }

    private func sheetContent(buttonWidth: CGFloat, sheetHeight: CGFloat) -> some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(.white)
                .frame(width: 36, height: 4)
                .padding(.top, 14)

            Image("app_ic_loading")
                .resizable()
                .scaledToFit()
                .frame(width: 96, height: 112)
                .padding(.top, 47)

            Text("Generation")
                .font(AITheme.Typography.sfProDisplay(28, weight: .bold))
                .foregroundStyle(.white)
                .padding(.top, 38)

            Text(creationMode == .video
                 ? "Your video is being generated,\nyou can find it in the library."
                 : "Your photo is being generated,\nyou can find it in the library.")
                .font(AITheme.Typography.sfProDisplay(16, weight: .regular))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
                .padding(.top, 18)

            Spacer(minLength: 16)

            PrimaryGradientButton(title: "OK", showsBorder: false) {
                dismissSheet(sheetHeight: sheetHeight)
            }
            .frame(width: buttonWidth)
            .padding(.bottom, 34)
        }
    }

    private func sheetDragGesture(sheetHeight: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 2)
            .onChanged { value in
                guard isSheetVisible, !isDismissing else { return }
                let translation = value.translation.height
                sheetOffset = translation < 0
                    ? max(-72, translation * 0.28)
                    : translation
            }
            .onEnded { value in
                guard !isDismissing else { return }
                if value.translation.height > 110 || value.predictedEndTranslation.height > 180 {
                    dismissSheet(sheetHeight: sheetHeight)
                } else {
                    withAnimation(.spring(response: 0.34, dampingFraction: 0.82)) {
                        sheetOffset = 0
                    }
                }
            }
    }

    private func dismissSheet(sheetHeight: CGFloat) {
        guard !isDismissing else { return }
        isDismissing = true
        withAnimation(.easeInOut(duration: 0.28)) {
            sheetOffset = 0
            isSheetVisible = false
        }
        Task {
            try? await Task.sleep(for: .milliseconds(280))
            onDismiss()
        }
    }
}

private struct GenerationBackdropBlur: UIViewRepresentable {
    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}

struct LibraryTabView: View {
    @Binding var selectedTab: AppTab
    var hasPremiumAccess = false
    var onShowPaywall: () -> Void = {}
    @ObservedObject var generationStore: PhotoGenerationStore
    @ObservedObject var videoGenerationStore: VideoGenerationStore
    var initialFilter = "AI Photo"

    @State private var selectedFilter = "AI Photo"
    @State private var selectedJob: PhotoGenerationJob?
    @State private var selectedVideoJob: VideoGenerationJob?
    private let filters = ["AI Video", "AI Photo"]

    var body: some View {
        DesignCanvas { layout in
            ZStack(alignment: .topLeading) {
                AITheme.ColorToken.background.ignoresSafeArea()
                AppHeader(
                    title: "Library",
                    showsProButton: !hasPremiumAccess,
                    onProTap: onShowPaywall
                )

                HStack(spacing: 16) {
                    ForEach(filters, id: \.self) { filter in
                        AppSegmentButton(
                            title: filter,
                            active: selectedFilter == filter,
                            width: 170
                        ) {
                            selectedFilter = filter
                        }
                    }
                }
                .position(
                    x: 196,
                    y: layout.isCompactHeight ? 154 : 146
                )

                if selectedFilter == "AI Photo" && !generationStore.photoJobs.isEmpty {
                    PhotoLibraryGrid(generationStore: generationStore) { job in
                        selectedJob = job
                    }
                    .frame(
                        width: 356,
                        height: layout.isCompactHeight
                            ? layout.bottomBarTop - 193
                            : 550
                    )
                    .position(
                        x: 196,
                        y: layout.isCompactHeight
                            ? (193 + layout.bottomBarTop) / 2
                            : 468
                    )
                } else if selectedFilter == "AI Video" && !videoGenerationStore.videoJobs.isEmpty {
                    VideoLibraryGrid(generationStore: videoGenerationStore) { job in
                        selectedVideoJob = job
                    }
                    .frame(
                        width: 356,
                        height: layout.isCompactHeight
                            ? layout.bottomBarTop - 193
                            : 550
                    )
                    .position(
                        x: 196,
                        y: layout.isCompactHeight
                            ? (193 + layout.bottomBarTop) / 2
                            : 468
                    )
                } else {
                    VStack(spacing: 15) {
                        Image("box_1")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 124, height: 124)
                        Text(emptyTitle)
                            .font(AITheme.Typography.sfProDisplay(24, weight: .bold))
                            .foregroundStyle(.white)
                        Text("Your generated content will\nappear here")
                            .font(AITheme.Typography.sfProDisplay(14, weight: .medium))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                            .lineSpacing(1)
                    }
                    .frame(width: 230)
                    .position(x: 196.5, y: layout.y(413))
                }

                AppBottomTabBar(
                    selectedTab: $selectedTab,
                    compactHeight: layout.isCompactHeight
                )
                    .position(x: 196.5, y: layout.bottomBarY)
            }
            .frame(width: 393, height: layout.canvasHeight)
            .statusBarHidden(false)
        }
        .ignoresSafeArea()
        .onAppear {
            selectedFilter = initialFilter
        }
        .onChange(of: initialFilter) { _, newValue in
            selectedFilter = newValue
        }
        .fullScreenCover(item: $selectedJob) { job in
            PhotoLibraryDetailView(generationStore: generationStore, jobID: job.id)
        }
        .fullScreenCover(item: $selectedVideoJob) { job in
            VideoLibraryDetailView(generationStore: videoGenerationStore, jobID: job.id)
        }
    }

    private var emptyTitle: String {
        switch selectedFilter {
        case "AI Photo": "No AI Photo yet"
        default: "No AI Video yet"
        }
    }
}

struct SettingsTabView: View {
    @Environment(\.openURL) private var openURL

    @Binding var selectedTab: AppTab
    var hasPremiumAccess = false
    var onShowPaywall: () -> Void = {}
    var onRestorePurchases: () -> Void = {}
    var onDeleteUserData: () -> Void = {}

    @State private var showsDeleteDataConfirmation = false

    var body: some View {
        DesignCanvas { layout in
            ZStack(alignment: .topLeading) {
                AITheme.ColorToken.background.ignoresSafeArea()
                AppHeader(
                    title: "Settings",
                    showsProButton: !hasPremiumAccess,
                    onProTap: onShowPaywall
                )

                VStack(alignment: .leading, spacing: 16) {
                    SettingsSection(title: "Support & Legal", rows: [
                        .init(title: "Privacy", iconAsset: "app_ic_set06") {
                            openURL(AppLinks.privacyPolicy)
                        },
                        .init(title: "Terms and Conditions", iconAsset: "app_ic_set03") {
                            openURL(AppLinks.termsOfUse)
                        }
                    ])

                    SettingsSection(title: "General", rows: generalRows)
                }
                .frame(width: 356, alignment: .leading)
                .offset(x: 18, y: layout.y(124))

                AppBottomTabBar(
                    selectedTab: $selectedTab,
                    compactHeight: layout.isCompactHeight
                )
                    .position(x: 196.5, y: layout.bottomBarY)
            }
            .frame(width: 393, height: layout.canvasHeight)
            .statusBarHidden(false)
        }
        .ignoresSafeArea()
        .alert("Delete all data?", isPresented: $showsDeleteDataConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("OK", role: .destructive, action: onDeleteUserData)
        } message: {
            Text("All generated photos, videos, active generation jobs, and saved app data will be permanently deleted.")
        }
    }

    private var generalRows: [SettingsRowData] {
        var rows: [SettingsRowData] = []

        rows.append(.init(
            title: "Share app",
            iconAsset: "app_ic_set05",
            shareText: AppLinks.shareText
        ))

        rows.append(.init(title: "Rate Us", iconAsset: "app_ic_set02") {
            openURL(AppLinks.appStoreReview)
        })

        if !hasPremiumAccess {
            rows.append(.init(title: "Restore", iconAsset: "app_ic_set04", action: onRestorePurchases))
        }

        rows.append(.init(title: "Delete Data", iconAsset: "app_ic_set01") {
            showsDeleteDataConfirmation = true
        })

        return rows
    }
}

private struct TemplateAssetCardData {
    let title: String
    let asset: String
    let badge: PhotoTemplateBadge
    let isPrecomposed: Bool

    func creatorTemplate(in category: PhotoTemplateCategory) -> PhotoTemplateStyle {
        PhotoTemplateStyle(
            title: title,
            asset: asset,
            isPrecomposed: isPrecomposed,
            category: category
        )
    }
}

private extension PhotoTemplateCategory {
    var homeCards: [TemplateAssetCardData] {
        PhotoTemplateStyle.previewTemplates(for: self)
            .enumerated()
            .map { index, template in
                TemplateAssetCardData(
                    title: template.title,
                    asset: template.asset,
                    badge: PhotoTemplateStyle.badge(for: template, at: index, in: self),
                    isPrecomposed: template.isPrecomposed
                )
            }
    }
}

private struct AssetCardShelf: View {
    let category: PhotoTemplateCategory
    let cards: [TemplateAssetCardData]
    let onSeeAll: (PhotoTemplateCategory) -> Void
    let onSelect: (PhotoTemplateStyle) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(category.title)
                    .font(AITheme.Typography.sfProDisplay(16, weight: .bold))
                    .foregroundStyle(.white)

                Spacer()

                Button {
                    onSeeAll(category)
                } label: {
                    Text("See all")
                        .font(AITheme.Typography.sfProDisplay(12, weight: .semibold))
                        .foregroundStyle(Color(red: 0.647, green: 0.647, blue: 0.647))
                        .frame(width: 64, height: 28, alignment: .trailing)
                }
                .buttonStyle(.plain)
                .frame(width: 64, height: 28)
                .contentShape(Rectangle())
                .accessibilityLabel("See all \(category.title)")
            }
            .frame(width: 356, height: 19)

            HStack(spacing: 4) {
                ForEach(Array(cards.enumerated()), id: \.offset) { _, card in
                    Button {
                        onSelect(card.creatorTemplate(in: category))
                    } label: {
                        TemplateAssetCard(card: card)
                    }
                    .buttonStyle(.plain)
                    .frame(width: 116, height: 166)
                    .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
            }
        }
        .frame(width: 356, height: 201, alignment: .topLeading)
    }
}

private struct TemplateAssetCard: View {
    let card: TemplateAssetCardData

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Image(card.asset)
                .resizable()
                .scaledToFill()
                .frame(width: 116, height: 166)

            if !card.isPrecomposed {
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
            }

            badgeView
                .padding(.top, 8)
                .padding(.trailing, 8)
        }
        .frame(width: 116, height: 166)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
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

private struct AIPhotoPromptEntryBox: View {
    let title: String?
    @Binding var text: String
    let height: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let title {
                Text(title)
                    .font(AITheme.Typography.sfProDisplay(14, weight: .regular))
                    .foregroundStyle(.white)
            }

            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text("Cinematic sci-fi close-up, soft neon light, detailed outfit, dramatic background...")
                        .font(AITheme.Typography.sfProDisplay(14, weight: .regular))
                        .foregroundStyle(.white.opacity(0.62))
                        .lineSpacing(2)
                        .padding(.top, 8)
                        .allowsHitTesting(false)
                }

                TextEditor(text: $text)
                    .font(AITheme.Typography.sfProDisplay(14, weight: .regular))
                    .foregroundStyle(.white)
                    .lineSpacing(2)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .tint(.white)
                    .padding(.horizontal, -5)
                    .onChange(of: text) { _, newValue in
                        if newValue.count > 300 {
                            text = String(newValue.prefix(300))
                        }
                    }
            }
            .frame(width: 307, height: title == nil ? 136 : 91, alignment: .topLeading)

            Spacer()

            Text("\(text.count) / 300")
                .font(AITheme.Typography.sfProDisplay(14, weight: .regular))
                .foregroundStyle(PromptQualityValidator.isValid(text) ? .white.opacity(0.62) : .white.opacity(0.36))
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .frame(width: 356, height: height, alignment: .leading)
        .background(Color.white.opacity(0.035), in: RoundedRectangle(cornerRadius: 32, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .stroke(AITheme.primaryGradient, lineWidth: 1)
        }
    }
}

private enum PromptQualityValidator {
    static func isValid(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 16, trimmed.count <= 300 else { return false }

        let words = trimmed
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .map { $0.lowercased() }
            .filter { $0.count >= 2 }

        guard words.count >= 3, Set(words).count >= 2 else { return false }
        guard words.contains(where: { $0.count >= 4 }) else { return false }
        guard !hasLongRepeatedRun(trimmed) else { return false }

        let characters = Array(trimmed)
        let letters = characters.filter { $0.isLetter }.count
        guard Double(letters) / Double(max(characters.count, 1)) > 0.55 else { return false }

        let uniqueCharacters = Set(characters.filter { !$0.isWhitespace })
        return uniqueCharacters.count >= 8
    }

    private static func hasLongRepeatedRun(_ text: String) -> Bool {
        var previous: Character?
        var runLength = 0

        for character in text.lowercased() {
            if character == previous {
                runLength += 1
                if runLength >= 5 {
                    return true
                }
            } else {
                previous = character
                runLength = 1
            }
        }

        return false
    }
}

private struct AIPhotoUploadPhotoBox: View {
    let hasPhoto: Bool

    var body: some View {
        ZStack {
            Image("app_bg_add")
                .resizable()
                .frame(width: 356, height: 166)

            VStack(spacing: 8) {
                Image("app_ic_add")
                    .resizable()
                    .frame(width: 36, height: 36)

                Text("Click to upload photo")
                    .font(AITheme.Typography.sfProDisplay(10, weight: .regular))
                    .foregroundStyle(.white)
            }

            if hasPhoto {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.green)
                    .position(x: 330, y: 24)
            }
        }
        .frame(width: 356, height: 166)
    }
}

private struct AIPhotoPromptSelectedPhotoBox: View {
    let image: UIImage
    let onChangePhoto: () -> Void

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black

            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(width: 356, height: 166)

            Button(action: onChangePhoto) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 16, weight: .semibold))
                    .symbolRenderingMode(.monochrome)
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(Color.black.opacity(0.42), in: Circle())
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Change photo")
            .padding(.bottom, 12)
        }
        .frame(width: 356, height: 166)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct SettingsRowData {
    let title: String
    let iconAsset: String
    var shareText: String?
    var action: () -> Void = {}
}

private struct SettingsSection: View {
    let title: String
    let rows: [SettingsRowData]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(AITheme.Typography.sfProDisplay(16, weight: .semibold))
                .foregroundStyle(.white)

            VStack(spacing: 8) {
                ForEach(rows, id: \.title) { row in
                    if let shareText = row.shareText {
                        ShareLink(item: shareText) {
                            SettingsRowLabel(row: row)
                        }
                        .buttonStyle(.plain)
                        .frame(width: 356, height: 44)
                        .contentShape(Capsule())
                    } else {
                        Button(action: row.action) {
                            SettingsRowLabel(row: row)
                        }
                        .buttonStyle(.plain)
                        .frame(width: 356, height: 44)
                        .contentShape(Capsule())
                    }
                }
            }
        }
    }
}

private struct SettingsRowLabel: View {
    let row: SettingsRowData

    var body: some View {
        HStack(spacing: 12) {
            Image(row.iconAsset)
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
            Text(row.title)
                .font(AITheme.Typography.sfProDisplay(14, weight: .regular))
                .foregroundStyle(.white)
            Spacer()
            Image("app_ic_arrow")
                .resizable()
                .scaledToFit()
                .frame(width: 12, height: 24)
        }
        .padding(.horizontal, 16)
        .frame(width: 356, height: 44)
        .background(Color.white.opacity(0.001), in: Capsule())
        .overlay {
            Capsule()
                .stroke(AITheme.primaryGradient, lineWidth: 1)
        }
        .contentShape(Capsule())
    }
}

#Preview("AI Photo Tab") {
    AIPhotoTabView(selectedTab: .constant(.photo))
}

#Preview("Library Tab") {
    LibraryTabView(
        selectedTab: .constant(.library),
        generationStore: PhotoGenerationStore(),
        videoGenerationStore: VideoGenerationStore()
    )
}

#Preview("Settings Tab") {
    SettingsTabView(selectedTab: .constant(.settings))
}

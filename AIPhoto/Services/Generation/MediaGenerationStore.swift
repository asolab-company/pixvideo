import Combine
import Foundation
import UIKit
import UserNotifications

enum PhotoGenerationStatus: String, Codable {
    case processing
    case succeeded
    case failed
}

struct PhotoGenerationJob: Identifiable, Codable, Equatable {
    let id: UUID
    let createdAt: Date
    let title: String
    let prompt: String
    var status: PhotoGenerationStatus
    var remoteJobID: String?
    var previewFileName: String?
    var outputFileName: String?
    var errorMessage: String?
}

@MainActor
final class PhotoGenerationStore: ObservableObject {
    @Published private(set) var jobs: [PhotoGenerationJob] = []
    @Published var completionMessage: String?

    private let fileManager: FileManager
    private let storageDirectory: URL
    private let metadataURL: URL
    private let apiClient: OpenAIPhotoAPIClient
    private var generationTasks: [UUID: Task<Void, Never>] = [:]

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        let applicationSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        storageDirectory = applicationSupport.appendingPathComponent("PhotoGenerations", isDirectory: true)
        metadataURL = storageDirectory.appendingPathComponent("jobs.json")
        apiClient = OpenAIPhotoAPIClient()

        try? fileManager.createDirectory(at: storageDirectory, withIntermediateDirectories: true)
        loadJobs()
    }

    deinit {
        generationTasks.values.forEach { $0.cancel() }
    }

    var photoJobs: [PhotoGenerationJob] {
        jobs.sorted { $0.createdAt > $1.createdAt }
    }

    func enqueue(_ request: PhotoCreationRequest) {
        let localID = UUID()
        let previewData = request.sourceImageData ?? request.styleReferenceImageData
        let previewFileName = previewData.map { _ in "\(localID.uuidString)-preview.jpg" }

        if let previewData, let previewFileName {
            try? previewData.write(to: storageDirectory.appendingPathComponent(previewFileName), options: .atomic)
        }

        let job = PhotoGenerationJob(
            id: localID,
            createdAt: Date(),
            title: request.template?.title ?? "Custom Prompt",
            prompt: request.prompt,
            status: .processing,
            remoteJobID: nil,
            previewFileName: previewFileName,
            outputFileName: nil,
            errorMessage: nil
        )

        jobs.insert(job, at: 0)
        persistJobs()
        requestNotificationPermission()

        generationTasks[localID] = Task { [weak self] in
            await self?.startGeneration(localID: localID, request: request)
        }
    }

    func prepareOpenAIKey() async {
        try? await apiClient.prepareKey()
    }

    func refreshProcessingJobs() {
        for job in jobs where job.status == .processing && generationTasks[job.id] == nil {
            markFailed(
                localID: job.id,
                message: "This generation was interrupted. Please create it again."
            )
        }
    }

    func dismissCompletionMessage() {
        completionMessage = nil
    }

    func imageData(for job: PhotoGenerationJob) -> Data? {
        let fileName = job.outputFileName ?? job.previewFileName
        guard let fileName else { return nil }
        return try? Data(contentsOf: storageDirectory.appendingPathComponent(fileName))
    }

    func image(for job: PhotoGenerationJob) -> UIImage? {
        imageData(for: job).flatMap(UIImage.init(data:))
    }

    func delete(_ job: PhotoGenerationJob) {
        generationTasks[job.id]?.cancel()
        generationTasks[job.id] = nil

        [job.previewFileName, job.outputFileName]
            .compactMap { $0 }
            .forEach { try? fileManager.removeItem(at: storageDirectory.appendingPathComponent($0)) }

        jobs.removeAll { $0.id == job.id }
        persistJobs()
    }

    func deleteAll() {
        generationTasks.values.forEach { $0.cancel() }
        generationTasks.removeAll()

        try? fileManager.removeItem(at: storageDirectory)
        try? fileManager.createDirectory(
            at: storageDirectory,
            withIntermediateDirectories: true
        )

        jobs.removeAll()
        completionMessage = nil
    }

    private func startGeneration(localID: UUID, request: PhotoCreationRequest) async {
        do {
            let outputData = try await apiClient.generatePhoto(request)
            try completeGeneration(localID: localID, outputData: outputData)
            generationTasks[localID] = nil
        } catch {
            markFailed(localID: localID, message: error.localizedDescription)
            generationTasks[localID] = nil
        }
    }

    private func completeGeneration(localID: UUID, outputData: Data) throws {
        guard let index = jobs.firstIndex(where: { $0.id == localID }) else { return }

        let outputFileName = "\(localID.uuidString)-result.png"
        try outputData.write(
            to: storageDirectory.appendingPathComponent(outputFileName),
            options: .atomic
        )
        jobs[index].outputFileName = outputFileName
        jobs[index].status = .succeeded
        jobs[index].errorMessage = nil
        persistJobs()
        publishCompletionNotification()
    }

    private func markFailed(localID: UUID, message: String) {
        guard let index = jobs.firstIndex(where: { $0.id == localID }) else { return }
        jobs[index].status = .failed
        jobs[index].errorMessage = message
        persistJobs()
    }

    private func job(with id: UUID) -> PhotoGenerationJob? {
        jobs.first { $0.id == id }
    }

    private func loadJobs() {
        guard let data = try? Data(contentsOf: metadataURL),
              let decoded = try? JSONDecoder().decode([PhotoGenerationJob].self, from: data) else {
            return
        }
        jobs = decoded
    }

    private func persistJobs() {
        guard let data = try? JSONEncoder().encode(jobs) else { return }
        try? data.write(to: metadataURL, options: .atomic)
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    private func publishCompletionNotification() {
        let message = "Your AI photo has been generated successfully."
        completionMessage = message

        let content = UNMutableNotificationContent()
        content.title = "AI Photo is ready"
        content.body = message
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }
}

actor OpenAIKeyVault {
    static let shared = OpenAIKeyVault()

    private let sourceURL = AppConfiguration.OpenAI.keySourceURL
    private let session: URLSession
    private var cachedKey: String?
    private var loadingTask: Task<String, Error>?

    init() {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        configuration.urlCache = nil
        configuration.httpCookieStorage = nil
        configuration.waitsForConnectivity = true
        configuration.timeoutIntervalForRequest = AppConfiguration.OpenAI.keyRequestTimeout
        session = URLSession(configuration: configuration)
    }

    func prepare() async throws {
        _ = try await key()
    }

    func key() async throws -> String {
        if let cachedKey {
            return cachedKey
        }

        if let loadingTask {
            return try await loadingTask.value
        }

        var request = URLRequest(
            url: sourceURL,
            cachePolicy: .reloadIgnoringLocalAndRemoteCacheData,
            timeoutInterval: AppConfiguration.OpenAI.keyRequestTimeout
        )
        request.setValue("no-store", forHTTPHeaderField: "Cache-Control")

        let task = Task { [session] in
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  (200..<300).contains(httpResponse.statusCode) else {
                throw OpenAIPhotoError.keyUnavailable
            }

            guard let rawValue = String(data: data, encoding: .utf8) else {
                throw OpenAIPhotoError.invalidKey
            }

            let value = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
            guard value.hasPrefix("sk-"),
                  value.count >= 40,
                  value.count <= 256,
                  value.rangeOfCharacter(from: .whitespacesAndNewlines) == nil else {
                throw OpenAIPhotoError.invalidKey
            }
            return value
        }

        loadingTask = task

        do {
            let value = try await task.value
            cachedKey = value
            loadingTask = nil
            return value
        } catch {
            loadingTask = nil
            throw error
        }
    }
}

struct OpenAIPhotoAPIClient {
    private let keyVault = OpenAIKeyVault.shared
    private let session: URLSession

    init() {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        configuration.urlCache = nil
        configuration.httpCookieStorage = nil
        configuration.waitsForConnectivity = true
        configuration.timeoutIntervalForRequest = AppConfiguration.OpenAI.generationRequestTimeout
        configuration.timeoutIntervalForResource = AppConfiguration.OpenAI.generationRequestTimeout
        session = URLSession(configuration: configuration)
    }

    func prepareKey() async throws {
        try await keyVault.prepare()
    }

    func generatePhoto(_ request: PhotoCreationRequest) async throws -> Data {
        let key = try await keyVault.key()
        let output: Data

        if request.sourceImageData != nil || request.styleReferenceImageData != nil {
            output = try await editImage(request, key: key)
        } else {
            output = try await generateImage(request, key: key)
        }
        return outputMatchingSourceCrop(output, sourceImageData: request.sourceImageData)
    }

    private func editImage(_ creation: PhotoCreationRequest, key: String) async throws -> Data {
        let boundary = "Boundary-\(UUID().uuidString)"
        var form = MultipartFormData(boundary: boundary)
        form.addText(name: "model", value: AppConfiguration.OpenAI.model)
        form.addText(name: "prompt", value: editPrompt(for: creation))
        form.addText(name: "size", value: outputSize(for: creation))
        form.addText(name: "quality", value: AppConfiguration.OpenAI.quality)
        form.addText(name: "output_format", value: AppConfiguration.OpenAI.outputFormat)
        form.addText(name: "background", value: AppConfiguration.OpenAI.background)

        if let sourceImageData = creation.sourceImageData {
            guard let jpegData = UIImage(data: sourceImageData)?.jpegData(compressionQuality: 0.94) else {
                throw OpenAIPhotoError.invalidInputImage
            }
            form.addFile(
                name: "image[]",
                filename: "source.jpg",
                mimeType: "image/jpeg",
                data: jpegData
            )
        }

        if let styleReferenceImageData = creation.styleReferenceImageData {
            guard let pngData = UIImage(data: styleReferenceImageData)?.pngData() else {
                throw OpenAIPhotoError.invalidInputImage
            }
            form.addFile(
                name: "image[]",
                filename: "style.png",
                mimeType: "image/png",
                data: pngData
            )
        }

        var urlRequest = URLRequest(
            url: AppConfiguration.OpenAI.imageEditsURL,
            timeoutInterval: AppConfiguration.OpenAI.generationRequestTimeout
        )
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("no-store", forHTTPHeaderField: "Cache-Control")
        urlRequest.httpBody = form.finalizedData()
        return try await perform(urlRequest)
    }

    private func editPrompt(for creation: PhotoCreationRequest) -> String {
        if creation.sourceImageData != nil && creation.styleReferenceImageData != nil {
            return """
            Image 1 is the user's exact cropped identity and composition source. Preserve only the visible content, pose, camera angle, aspect, framing, and crop boundaries from Image 1. Never zoom out, uncrop, extend the canvas, or reconstruct any face, head, limb, clothing, or environment outside that crop. Image 2 is a visual style reference only. Apply its rendering language, palette, materials, lighting, wardrobe treatment, and atmosphere without copying the identity or subject from Image 2.

            \(creation.prompt)
            """
        }

        if creation.sourceImageData != nil {
            return "Use Image 1 as the exact crop and composition source. Transform only what is visible. Do not zoom out, uncrop, extend, or reconstruct content outside its edges.\n\n\(creation.prompt)"
        }

        return "Use Image 1 as a visual style reference.\n\n\(creation.prompt)"
    }

    private func generateImage(_ creation: PhotoCreationRequest, key: String) async throws -> Data {
        var urlRequest = URLRequest(
            url: AppConfiguration.OpenAI.imageGenerationsURL,
            timeoutInterval: AppConfiguration.OpenAI.generationRequestTimeout
        )
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("no-store", forHTTPHeaderField: "Cache-Control")
        urlRequest.httpBody = try JSONEncoder().encode(
            OpenAIImageGenerationPayload(
                model: AppConfiguration.OpenAI.model,
                prompt: creation.prompt,
                size: outputSize(for: creation),
                quality: AppConfiguration.OpenAI.quality,
                outputFormat: AppConfiguration.OpenAI.outputFormat,
                background: AppConfiguration.OpenAI.background
            )
        )
        return try await perform(urlRequest)
    }

    private func outputSize(for creation: PhotoCreationRequest) -> String {
        guard let imageData = creation.sourceImageData,
              let image = UIImage(data: imageData),
              image.size.height > 0 else {
            return "1024x1536"
        }

        let ratio = image.size.width / image.size.height
        if ratio > 1.12 {
            return "1536x1024"
        }
        if ratio < 0.89 {
            return "1024x1536"
        }
        return "1024x1024"
    }

    private func outputMatchingSourceCrop(_ outputData: Data, sourceImageData: Data?) -> Data {
        guard let sourceImageData,
              let sourceImage = UIImage(data: sourceImageData),
              sourceImage.size.height > 0,
              let outputImage = UIImage(data: outputData),
              let cgImage = outputImage.cgImage else {
            return outputData
        }

        let targetRatio = sourceImage.size.width / sourceImage.size.height
        let outputWidth = CGFloat(cgImage.width)
        let outputHeight = CGFloat(cgImage.height)
        let outputRatio = outputWidth / outputHeight
        guard abs(targetRatio - outputRatio) > 0.002 else { return outputData }

        let cropRect: CGRect
        if outputRatio > targetRatio {
            let width = outputHeight * targetRatio
            cropRect = CGRect(x: (outputWidth - width) * 0.5, y: 0, width: width, height: outputHeight)
        } else {
            let height = outputWidth / targetRatio
            cropRect = CGRect(x: 0, y: (outputHeight - height) * 0.5, width: outputWidth, height: height)
        }

        guard let croppedCGImage = cgImage.cropping(to: cropRect.integral) else { return outputData }
        return UIImage(cgImage: croppedCGImage).pngData() ?? outputData
    }

    private func perform(_ request: URLRequest) async throws -> Data {
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIPhotoError.invalidResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            let envelope = try? JSONDecoder().decode(OpenAIErrorEnvelope.self, from: data)
            let serverMessage = envelope?.error.message ?? "OpenAI could not generate this photo."
            throw OpenAIPhotoError.api(
                safeErrorMessage(serverMessage, statusCode: httpResponse.statusCode)
            )
        }

        let result = try JSONDecoder().decode(OpenAIImageResponse.self, from: data)
        guard let encodedImage = result.data.first?.b64JSON,
              let imageData = Data(base64Encoded: encodedImage) else {
            throw OpenAIPhotoError.missingImage
        }
        return imageData
    }

    private func safeErrorMessage(_ message: String, statusCode: Int) -> String {
        switch statusCode {
        case 401, 403:
            return "OpenAI authorization failed."
        case 429:
            return "The OpenAI generation limit or account quota was reached."
        default:
            if message.lowercased().contains("api key") || message.lowercased().contains("authorization") {
                return "OpenAI authorization failed."
            }
            return message
        }
    }
}

private struct MultipartFormData {
    let boundary: String
    private var data = Data()

    init(boundary: String) {
        self.boundary = boundary
    }

    mutating func addText(name: String, value: String) {
        append("--\(boundary)\r\n")
        append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n")
        append(value)
        append("\r\n")
    }

    mutating func addFile(name: String, filename: String, mimeType: String, data fileData: Data) {
        append("--\(boundary)\r\n")
        append("Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(filename)\"\r\n")
        append("Content-Type: \(mimeType)\r\n\r\n")
        data.append(fileData)
        append("\r\n")
    }

    func finalizedData() -> Data {
        var result = data
        result.append(Data("--\(boundary)--\r\n".utf8))
        return result
    }

    private mutating func append(_ string: String) {
        data.append(Data(string.utf8))
    }
}

private struct OpenAIImageGenerationPayload: Encodable {
    let model: String
    let prompt: String
    let size: String
    let quality: String
    let outputFormat: String
    let background: String

    enum CodingKeys: String, CodingKey {
        case model, prompt, size, quality, background
        case outputFormat = "output_format"
    }
}

private struct OpenAIImageResponse: Decodable {
    struct ImageData: Decodable {
        let b64JSON: String?

        enum CodingKeys: String, CodingKey {
            case b64JSON = "b64_json"
        }
    }

    let data: [ImageData]
}

private struct OpenAIErrorEnvelope: Decodable {
    struct APIError: Decodable {
        let message: String
    }

    let error: APIError
}

private enum OpenAIPhotoError: LocalizedError {
    case keyUnavailable
    case invalidKey
    case invalidResponse
    case invalidInputImage
    case missingImage
    case api(String)

    var errorDescription: String? {
        switch self {
        case .keyUnavailable:
            "OpenAI access is temporarily unavailable."
        case .invalidKey:
            "OpenAI access configuration is invalid."
        case .invalidResponse:
            "OpenAI returned an invalid response."
        case .invalidInputImage:
            "The selected photo could not be prepared for generation."
        case .missingImage:
            "OpenAI finished without returning an image."
        case .api(let message):
            message
        }
    }
}

enum VideoGenerationQuality: String, CaseIterable, Codable, Identifiable {
    case p360 = "360p"
    case p540 = "540p"
    case p720 = "720p"
    case p1080 = "1080p"

    var id: String { rawValue }
}

struct VideoCreationRequest {
    let photoRequest: PhotoCreationRequest
    let quality: VideoGenerationQuality
}

private enum VideoGenerationStage: String {
    case generatingFirstFrame = "OpenAI: generating the first frame"
    case savingFirstFrame = "Device: saving the generated first frame"
    case submittingToFal = "fal.ai: submitting the image-to-video request"
    case waitingForFal = "fal.ai: waiting for, fetching, or downloading the video"
    case savingVideo = "Device: saving the downloaded video"
}

struct VideoGenerationJob: Identifiable, Codable, Equatable {
    let id: UUID
    let createdAt: Date
    let title: String
    let prompt: String
    let quality: VideoGenerationQuality
    var status: PhotoGenerationStatus
    var remoteJobID: String?
    var remoteStatusURL: String?
    var remoteResponseURL: String?
    var previewFileName: String?
    var outputFileName: String?
    var errorMessage: String?
}

@MainActor
final class VideoGenerationStore: ObservableObject {
    @Published private(set) var jobs: [VideoGenerationJob] = []
    @Published var completionMessage: String?
    @Published var failureMessage: String?

    private let fileManager: FileManager
    private let storageDirectory: URL
    private let metadataURL: URL
    private let photoClient: OpenAIPhotoAPIClient
    private let videoClient: FalVideoAPIClient
    private var generationTasks: [UUID: Task<Void, Never>] = [:]
    private var backgroundTasks: [UUID: UIBackgroundTaskIdentifier] = [:]

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        let applicationSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        storageDirectory = applicationSupport.appendingPathComponent("VideoGenerations", isDirectory: true)
        metadataURL = storageDirectory.appendingPathComponent("jobs.json")
        photoClient = OpenAIPhotoAPIClient()
        videoClient = FalVideoAPIClient()

        try? fileManager.createDirectory(at: storageDirectory, withIntermediateDirectories: true)
        loadJobs()
    }

    deinit {
        generationTasks.values.forEach { $0.cancel() }
    }

    var videoJobs: [VideoGenerationJob] {
        jobs.sorted { $0.createdAt > $1.createdAt }
    }

    func enqueue(_ request: VideoCreationRequest) {
        let localID = UUID()
        let previewData = request.photoRequest.sourceImageData ?? request.photoRequest.styleReferenceImageData
        let previewFileName = previewData.map { _ in "\(localID.uuidString)-preview.jpg" }

        if let previewData, let previewFileName {
            try? previewData.write(to: storageDirectory.appendingPathComponent(previewFileName), options: .atomic)
        }

        let job = VideoGenerationJob(
            id: localID,
            createdAt: Date(),
            title: request.photoRequest.template?.title ?? "Custom Prompt",
            prompt: request.photoRequest.prompt,
            quality: request.quality,
            status: .processing,
            remoteJobID: nil,
            remoteStatusURL: nil,
            remoteResponseURL: nil,
            previewFileName: previewFileName,
            outputFileName: nil,
            errorMessage: nil
        )

        jobs.insert(job, at: 0)
        persistJobs()
        requestNotificationPermission()

        generationTasks[localID] = Task { [weak self] in
            await self?.startGeneration(localID: localID, request: request)
        }
    }

    func prepareKeys() async {
        try? await photoClient.prepareKey()
        try? await videoClient.prepareKey()
    }

    func refreshProcessingJobs() {
        for job in jobs where job.status == .processing && generationTasks[job.id] == nil {
            guard let remoteJobID = job.remoteJobID else {
                markFailed(
                    localID: job.id,
                    message: "This generation was interrupted before video processing started. Please create it again."
                )
                continue
            }

            let handle = FalVideoRequestHandle(
                requestID: remoteJobID,
                statusURLString: job.remoteStatusURL,
                responseURLString: job.remoteResponseURL
            )
            generationTasks[job.id] = Task { [weak self] in
                await self?.resumeFalGeneration(localID: job.id, handle: handle)
            }
        }
    }

    func dismissCompletionMessage() {
        completionMessage = nil
    }

    func dismissFailureMessage() {
        failureMessage = nil
    }

    func previewImage(for job: VideoGenerationJob) -> UIImage? {
        guard let fileName = job.previewFileName,
              let data = try? Data(contentsOf: storageDirectory.appendingPathComponent(fileName)) else {
            return nil
        }
        return UIImage(data: data)
    }

    func videoURL(for job: VideoGenerationJob) -> URL? {
        guard let fileName = job.outputFileName else { return nil }
        let url = storageDirectory.appendingPathComponent(fileName)
        return fileManager.fileExists(atPath: url.path) ? url : nil
    }

    func delete(_ job: VideoGenerationJob) {
        generationTasks[job.id]?.cancel()
        generationTasks[job.id] = nil
        endBackgroundExecution(for: job.id)

        [job.previewFileName, job.outputFileName]
            .compactMap { $0 }
            .forEach { try? fileManager.removeItem(at: storageDirectory.appendingPathComponent($0)) }

        jobs.removeAll { $0.id == job.id }
        persistJobs()
    }

    func deleteAll() {
        generationTasks.values.forEach { $0.cancel() }
        generationTasks.removeAll()

        Array(backgroundTasks.keys).forEach(endBackgroundExecution)

        try? fileManager.removeItem(at: storageDirectory)
        try? fileManager.createDirectory(
            at: storageDirectory,
            withIntermediateDirectories: true
        )

        jobs.removeAll()
        completionMessage = nil
        failureMessage = nil
    }

    private func startGeneration(localID: UUID, request: VideoCreationRequest) async {
        let startedAt = Date()
        var stage = VideoGenerationStage.generatingFirstFrame
        var remoteJobID: String?
        beginBackgroundExecution(for: localID)
        defer { endBackgroundExecution(for: localID) }

        do {
            let styledFrame = try await photoClient.generatePhoto(request.photoRequest)

            stage = .savingFirstFrame
            try saveStyledPreview(localID: localID, data: styledFrame)

            stage = .submittingToFal
            let handle = try await videoClient.submitVideo(
                imageData: styledFrame,
                prompt: motionPrompt(from: request.photoRequest.prompt),
                quality: request.quality
            )
            remoteJobID = handle.requestID
            updateRemoteJob(localID: localID, handle: handle)

            endBackgroundExecution(for: localID)

            stage = .waitingForFal
            let videoData = try await videoClient.awaitVideo(handle: handle)

            stage = .savingVideo
            try completeGeneration(localID: localID, outputData: videoData)
            generationTasks[localID] = nil
        } catch is CancellationError {
            generationTasks[localID] = nil
        } catch {
            let report = diagnosticReport(
                localID: localID,
                remoteJobID: remoteJobID,
                quality: request.quality,
                stage: stage,
                startedAt: startedAt,
                error: error
            )
            markFailed(localID: localID, message: report)
            generationTasks[localID] = nil
        }
    }

    private func resumeFalGeneration(localID: UUID, handle: FalVideoRequestHandle) async {
        let startedAt = Date()
        let quality = jobs.first(where: { $0.id == localID })?.quality ?? .p720

        do {
            let videoData = try await videoClient.awaitVideo(handle: handle)
            try completeGeneration(localID: localID, outputData: videoData)
            generationTasks[localID] = nil
        } catch is CancellationError {
            generationTasks[localID] = nil
        } catch {
            let report = diagnosticReport(
                localID: localID,
                remoteJobID: handle.requestID,
                quality: quality,
                stage: .waitingForFal,
                startedAt: startedAt,
                error: error
            )
            markFailed(localID: localID, message: report)
            generationTasks[localID] = nil
        }
    }

    private func motionPrompt(from photoPrompt: String) -> String {
        let trimmed = photoPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
        let context = String(trimmed.prefix(1200))
        return """
        Animate this exact generated first frame into a coherent five-second video. Keep the same subject, identity, crop, composition, wardrobe, environment, and visual style. Add natural breathing and body motion, subtle environmental movement, realistic hair and fabric motion, and a gentle cinematic camera move. Never zoom out to invent content beyond the frame, never add people or limbs, and do not change the subject's identity. Avoid flicker, warping, morphing, duplicated features, text, and logos.

        Scene context: \(context)
        """
    }

    private func saveStyledPreview(localID: UUID, data: Data) throws {
        guard let index = jobs.firstIndex(where: { $0.id == localID }) else { return }
        if let oldFileName = jobs[index].previewFileName {
            try? fileManager.removeItem(at: storageDirectory.appendingPathComponent(oldFileName))
        }
        let fileName = "\(localID.uuidString)-styled.png"
        try data.write(to: storageDirectory.appendingPathComponent(fileName), options: .atomic)
        jobs[index].previewFileName = fileName
        persistJobs()
    }

    private func updateRemoteJob(localID: UUID, handle: FalVideoRequestHandle) {
        guard let index = jobs.firstIndex(where: { $0.id == localID }) else { return }
        jobs[index].remoteJobID = handle.requestID
        jobs[index].remoteStatusURL = handle.statusURL.absoluteString
        jobs[index].remoteResponseURL = handle.responseURL.absoluteString
        persistJobs()
    }

    private func completeGeneration(localID: UUID, outputData: Data) throws {
        guard let index = jobs.firstIndex(where: { $0.id == localID }) else { return }
        let outputFileName = "\(localID.uuidString)-result.mp4"
        try outputData.write(to: storageDirectory.appendingPathComponent(outputFileName), options: .atomic)
        jobs[index].outputFileName = outputFileName
        jobs[index].status = .succeeded
        jobs[index].errorMessage = nil
        persistJobs()
        publishCompletionNotification()
    }

    private func markFailed(localID: UUID, message: String) {
        guard let index = jobs.firstIndex(where: { $0.id == localID }) else { return }
        jobs[index].status = .failed
        jobs[index].errorMessage = message
        persistJobs()
        failureMessage = message
    }

    private func diagnosticReport(
        localID: UUID,
        remoteJobID: String?,
        quality: VideoGenerationQuality,
        stage: VideoGenerationStage,
        startedAt: Date,
        error: Error
    ) -> String {
        let nsError = error as NSError
        var lines = [
            "AI VIDEO GENERATION DIAGNOSTICS",
            "Stage: \(stage.rawValue)",
            "Local job ID: \(localID.uuidString)",
            "fal.ai request ID: \(remoteJobID ?? "not created")",
            "Quality: \(quality.rawValue)",
            "Time: \(ISO8601DateFormatter().string(from: Date()))",
            "Elapsed: \(String(format: "%.2f", Date().timeIntervalSince(startedAt))) seconds",
            "Error: \(error.localizedDescription)",
            "System domain: \(nsError.domain)",
            "System code: \(nsError.code)"
        ]

        if let failureReason = nsError.localizedFailureReason, !failureReason.isEmpty {
            lines.append("Failure reason: \(failureReason)")
        }
        if let recoverySuggestion = nsError.localizedRecoverySuggestion, !recoverySuggestion.isEmpty {
            lines.append("Recovery suggestion: \(recoverySuggestion)")
        }
        if let failingURL = nsError.userInfo[NSURLErrorFailingURLErrorKey] as? URL {
            lines.append("Failing URL: \(failingURL.absoluteString)")
        }
        if let falError = error as? FalVideoError {
            lines.append("fal.ai details: \(falError.diagnosticDescription)")
        }

        return lines.joined(separator: "\n")
    }

    private func loadJobs() {
        guard let data = try? Data(contentsOf: metadataURL),
              let decoded = try? JSONDecoder().decode([VideoGenerationJob].self, from: data) else {
            return
        }
        jobs = decoded
    }

    private func persistJobs() {
        guard let data = try? JSONEncoder().encode(jobs) else { return }
        try? data.write(to: metadataURL, options: .atomic)
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    private func beginBackgroundExecution(for localID: UUID) {
        guard backgroundTasks[localID] == nil else { return }
        let identifier = UIApplication.shared.beginBackgroundTask(withName: "AI Video Generation") { [weak self] in
            Task { @MainActor [weak self] in
                self?.endBackgroundExecution(for: localID)
            }
        }
        if identifier != .invalid {
            backgroundTasks[localID] = identifier
        }
    }

    private func endBackgroundExecution(for localID: UUID) {
        guard let identifier = backgroundTasks.removeValue(forKey: localID) else { return }
        UIApplication.shared.endBackgroundTask(identifier)
    }

    private func publishCompletionNotification() {
        let message = "Your AI video has been generated successfully."
        completionMessage = message

        let content = UNMutableNotificationContent()
        content.title = "AI Video is ready"
        content.body = message
        content.sound = .default

        UNUserNotificationCenter.current().add(
            UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        )
    }
}

actor FalKeyVault {
    static let shared = FalKeyVault()

    private let sourceURL = AppConfiguration.FalAI.keySourceURL
    private let session: URLSession
    private var cachedKey: String?
    private var loadingTask: Task<String, Error>?

    init() {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        configuration.urlCache = nil
        configuration.httpCookieStorage = nil
        configuration.waitsForConnectivity = true
        configuration.timeoutIntervalForRequest = AppConfiguration.FalAI.keyRequestTimeout
        session = URLSession(configuration: configuration)
    }

    func prepare() async throws {
        _ = try await key()
    }

    func key() async throws -> String {
        if let cachedKey { return cachedKey }
        if let loadingTask { return try await loadingTask.value }

        var request = URLRequest(
            url: sourceURL,
            cachePolicy: .reloadIgnoringLocalAndRemoteCacheData,
            timeoutInterval: AppConfiguration.FalAI.keyRequestTimeout
        )
        request.setValue("no-store", forHTTPHeaderField: "Cache-Control")

        let task = Task { [session] in
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  (200..<300).contains(httpResponse.statusCode),
                  let rawValue = String(data: data, encoding: .utf8) else {
                throw FalVideoError.keyUnavailable
            }

            var value = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
            if value.hasPrefix("FAL_KEY=") {
                value.removeFirst("FAL_KEY=".count)
            }
            value = value.trimmingCharacters(in: CharacterSet(charactersIn: "\"' "))

            guard value.count >= 20,
                  value.count <= 512,
                  value.rangeOfCharacter(from: .whitespacesAndNewlines) == nil else {
                throw FalVideoError.invalidKey
            }
            return value
        }

        loadingTask = task
        do {
            let value = try await task.value
            cachedKey = value
            loadingTask = nil
            return value
        } catch {
            loadingTask = nil
            throw error
        }
    }
}

fileprivate struct FalVideoRequestHandle {
    let requestID: String
    let statusURL: URL
    let responseURL: URL

    init(
        requestID: String,
        statusURLString: String? = nil,
        responseURLString: String? = nil
    ) {
        self.requestID = requestID
        let requestBase = AppConfiguration.FalAI.requestBaseURL(requestID: requestID)
        statusURL = statusURLString.flatMap { URL(string: $0) }
            ?? requestBase.appendingPathComponent("status")
        responseURL = responseURLString.flatMap { URL(string: $0) }
            ?? requestBase.appendingPathComponent("response")
    }
}

struct FalVideoAPIClient {
    private let keyVault = FalKeyVault.shared
    private let session: URLSession

    init() {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        configuration.urlCache = nil
        configuration.httpCookieStorage = nil
        configuration.waitsForConnectivity = true
        configuration.timeoutIntervalForRequest = AppConfiguration.FalAI.requestTimeout
        configuration.timeoutIntervalForResource = AppConfiguration.FalAI.resourceTimeout
        session = URLSession(configuration: configuration)
    }

    func prepareKey() async throws {
        try await keyVault.prepare()
    }

    fileprivate func submitVideo(
        imageData: Data,
        prompt: String,
        quality: VideoGenerationQuality
    ) async throws -> FalVideoRequestHandle {
        let key = try await keyVault.key()
        let uploadData = UIImage(data: imageData)?.jpegData(compressionQuality: 0.94) ?? imageData
        let dataURI = "data:image/jpeg;base64,\(uploadData.base64EncodedString())"
        let payload = FalVideoPayload(
            prompt: prompt.utf8Prefix(maxByteCount: AppConfiguration.FalAI.promptUTF8ByteLimit),
            resolution: quality.rawValue,
            duration: AppConfiguration.FalAI.duration,
            negativePrompt: AppConfiguration.FalAI.negativePrompt.utf8Prefix(
                maxByteCount: AppConfiguration.FalAI.promptUTF8ByteLimit
            ),
            generateAudio: AppConfiguration.FalAI.generateAudio,
            thinkingType: AppConfiguration.FalAI.thinkingType,
            imageURL: dataURI
        )

        var request = URLRequest(
            url: AppConfiguration.FalAI.submitURL,
            timeoutInterval: AppConfiguration.FalAI.requestTimeout
        )
        request.httpMethod = "POST"
        request.setValue("Key \(key)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("no-store", forHTTPHeaderField: "Cache-Control")
        request.httpBody = try JSONEncoder().encode(payload)

        let data = try await perform(request)
        let response: FalQueueSubmitResponse
        do {
            response = try JSONDecoder().decode(FalQueueSubmitResponse.self, from: data)
        } catch {
            throw FalVideoError.decoding(
                operation: "submit response",
                responseBody: responseSnippet(data),
                underlying: error.localizedDescription
            )
        }
        guard !response.requestID.isEmpty else {
            throw FalVideoError.decoding(
                operation: "submit response",
                responseBody: responseSnippet(data),
                underlying: "request_id was empty"
            )
        }
        let handle = FalVideoRequestHandle(
            requestID: response.requestID,
            statusURLString: response.statusURL,
            responseURLString: response.responseURL
        )
        return handle
    }

    fileprivate func awaitVideo(handle: FalVideoRequestHandle) async throws -> Data {
        let key = try await keyVault.key()
        let deadline = Date().addingTimeInterval(AppConfiguration.FalAI.pollingTimeout)
        var lastStatus: String?

        while true {
            try Task.checkCancellation()
            guard Date() < deadline else {
                throw FalVideoError.pollingTimedOut(
                    requestID: handle.requestID,
                    lastStatus: lastStatus ?? "no status received",
                    timeout: AppConfiguration.FalAI.pollingTimeout
                )
            }

            let status = try await fetchStatus(handle: handle, key: key)
            let normalizedStatus = status.status.uppercased()

            if lastStatus != normalizedStatus {
                lastStatus = normalizedStatus
            }

            switch normalizedStatus {
            case "COMPLETED":
                if let error = status.error, !error.isEmpty {
                    throw FalVideoError.terminalStatus(
                        status: normalizedStatus,
                        serverMessage: error,
                        logs: status.logs.map(\.message)
                    )
                }
                return try await fetchResult(handle: handle, key: key)
            case "IN_QUEUE", "IN_PROGRESS":
                try await Task.sleep(for: AppConfiguration.FalAI.pollInterval)
            case "FAILED", "CANCELLED", "CANCELED":
                throw FalVideoError.terminalStatus(
                    status: normalizedStatus,
                    serverMessage: status.error,
                    logs: status.logs.map(\.message)
                )
            default:
                throw FalVideoError.terminalStatus(
                    status: normalizedStatus,
                    serverMessage: status.error ?? "fal.ai returned an unknown queue status.",
                    logs: status.logs.map(\.message)
                )
            }
        }
    }

    private func fetchStatus(handle: FalVideoRequestHandle, key: String) async throws -> FalQueueStatusResponse {
        var components = URLComponents(url: handle.statusURL, resolvingAgainstBaseURL: false)!
        var queryItems = components.queryItems ?? []
        queryItems.removeAll { $0.name == "logs" }
        queryItems.append(URLQueryItem(name: "logs", value: "1"))
        components.queryItems = queryItems
        var request = URLRequest(
            url: components.url!,
            timeoutInterval: AppConfiguration.FalAI.requestTimeout
        )
        request.setValue("Key \(key)", forHTTPHeaderField: "Authorization")
        request.setValue("no-store", forHTTPHeaderField: "Cache-Control")
        let data: Data
        do {
            data = try await perform(request)
        } catch FalVideoError.http(let statusCode, _, _, _) where statusCode == 405 {
            var fallbackRequest = URLRequest(
                url: handle.statusURL,
                timeoutInterval: AppConfiguration.FalAI.requestTimeout
            )
            fallbackRequest.setValue("Key \(key)", forHTTPHeaderField: "Authorization")
            fallbackRequest.setValue("no-store", forHTTPHeaderField: "Cache-Control")
            data = try await perform(fallbackRequest)
        }

        let envelope: FalQueueStatusEnvelope
        do {
            envelope = try JSONDecoder().decode(FalQueueStatusEnvelope.self, from: data)
        } catch {
            throw FalVideoError.decoding(
                operation: "queue status",
                responseBody: responseSnippet(data),
                underlying: error.localizedDescription
            )
        }

        return FalQueueStatusResponse(
            status: envelope.status,
            error: jsonFieldDescription(named: "error", in: data),
            logs: envelope.logs ?? []
        )
    }

    private func fetchResult(handle: FalVideoRequestHandle, key: String) async throws -> Data {
        var request = URLRequest(
            url: handle.responseURL,
            timeoutInterval: AppConfiguration.FalAI.requestTimeout
        )
        request.setValue("Key \(key)", forHTTPHeaderField: "Authorization")
        request.setValue("no-store", forHTTPHeaderField: "Cache-Control")
        let data: Data
        do {
            data = try await perform(request)
        } catch FalVideoError.http(let statusCode, _, _, _) where statusCode == 405 {
            let alternateURL: URL
            if handle.responseURL.lastPathComponent == "response" {
                alternateURL = handle.responseURL.deletingLastPathComponent()
            } else {
                alternateURL = handle.responseURL.appendingPathComponent("response")
            }
            var fallbackRequest = URLRequest(
                url: alternateURL,
                timeoutInterval: AppConfiguration.FalAI.requestTimeout
            )
            fallbackRequest.setValue("Key \(key)", forHTTPHeaderField: "Authorization")
            fallbackRequest.setValue("no-store", forHTTPHeaderField: "Cache-Control")
            data = try await perform(fallbackRequest)
        }

        let result: FalVideoResult
        do {
            result = try JSONDecoder().decode(FalVideoResult.self, from: data)
        } catch {
            throw FalVideoError.decoding(
                operation: "video result",
                responseBody: responseSnippet(data),
                underlying: error.localizedDescription
            )
        }
        guard let videoURL = URL(string: result.video.url) else {
            throw FalVideoError.missingVideo(responseBody: responseSnippet(data))
        }

        let (videoData, response) = try await session.data(from: videoURL)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw FalVideoError.invalidResponse
        }
        guard (200..<300).contains(httpResponse.statusCode), !videoData.isEmpty else {
            throw FalVideoError.videoDownload(
                statusCode: httpResponse.statusCode,
                contentType: httpResponse.value(forHTTPHeaderField: "Content-Type"),
                byteCount: videoData.count,
                endpoint: videoURL.absoluteString
            )
        }
        return videoData
    }

    private func perform(_ request: URLRequest) async throws -> Data {
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw FalVideoError.invalidResponse
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw FalVideoError.http(
                statusCode: httpResponse.statusCode,
                method: request.httpMethod ?? "GET",
                endpoint: request.url?.absoluteString ?? "unknown endpoint",
                responseBody: responseSnippet(data)
            )
        }
        return data
    }

    private func responseSnippet(_ data: Data) -> String {
        guard !data.isEmpty else { return "<empty response body>" }
        let text = String(data: data, encoding: .utf8) ?? "<\(data.count) non-UTF8 bytes>"
        return String(text.prefix(4_000))
    }

    private func jsonFieldDescription(named name: String, in data: Data) -> String? {
        guard let jsonObject = try? JSONSerialization.jsonObject(with: data),
              let object = jsonObject as? [String: Any],
              let value = object[name],
              !(value is NSNull) else {
            return nil
        }
        if let string = value as? String { return string }
        if let encoded = try? JSONSerialization.data(withJSONObject: value),
           let string = String(data: encoded, encoding: .utf8) {
            return String(string.prefix(4_000))
        }
        return String(describing: value)
    }
}

private struct FalVideoPayload: Encodable {
    let prompt: String
    let resolution: String
    let duration: String
    let negativePrompt: String
    let generateAudio: Bool
    let thinkingType: String
    let imageURL: String

    enum CodingKeys: String, CodingKey {
        case prompt, resolution, duration
        case negativePrompt = "negative_prompt"
        case generateAudio = "generate_audio_switch"
        case thinkingType = "thinking_type"
        case imageURL = "image_url"
    }
}

private struct FalQueueSubmitResponse: Decodable {
    let requestID: String
    let statusURL: String?
    let responseURL: String?

    enum CodingKeys: String, CodingKey {
        case requestID = "request_id"
        case statusURL = "status_url"
        case responseURL = "response_url"
    }
}

private struct FalQueueStatusResponse {
    let status: String
    let error: String?
    let logs: [FalQueueLog]
}

private struct FalQueueStatusEnvelope: Decodable {
    let status: String
    let logs: [FalQueueLog]?
}

private struct FalQueueLog: Decodable {
    let message: String

    enum CodingKeys: String, CodingKey {
        case message
    }

    init(from decoder: Decoder) throws {
        if let singleValue = try? decoder.singleValueContainer(),
           let string = try? singleValue.decode(String.self) {
            message = string
            return
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)
        message = (try? container.decode(String.self, forKey: .message)) ?? "<log entry without a message>"
    }
}

private struct FalVideoResult: Decodable {
    struct Video: Decodable {
        let url: String
    }
    let video: Video
}

private enum FalVideoError: LocalizedError {
    case keyUnavailable
    case invalidKey
    case invalidResponse
    case missingVideo(responseBody: String)
    case api(String)
    case http(statusCode: Int, method: String, endpoint: String, responseBody: String)
    case decoding(operation: String, responseBody: String, underlying: String)
    case videoDownload(statusCode: Int, contentType: String?, byteCount: Int, endpoint: String)
    case terminalStatus(status: String, serverMessage: String?, logs: [String])
    case pollingTimedOut(requestID: String, lastStatus: String, timeout: TimeInterval)

    var errorDescription: String? {
        switch self {
        case .keyUnavailable:
            "fal.ai access is temporarily unavailable."
        case .invalidKey:
            "fal.ai access configuration is invalid."
        case .invalidResponse:
            "fal.ai returned an invalid response."
        case .missingVideo:
            "fal.ai finished without returning a video."
        case .api(let message):
            message
        case .http(let statusCode, _, _, let responseBody):
            switch statusCode {
            case 401, 403:
                "fal.ai authorization failed (HTTP \(statusCode)). Response: \(responseBody)"
            case 413:
                "fal.ai rejected the request because its payload was too large (HTTP 413). Response: \(responseBody)"
            case 422:
                "fal.ai rejected one or more request parameters (HTTP 422). Response: \(responseBody)"
            case 429:
                "The fal.ai generation limit, rate limit, or account quota was reached (HTTP 429). Response: \(responseBody)"
            default:
                "fal.ai request failed with HTTP \(statusCode). Response: \(responseBody)"
            }
        case .decoding(let operation, _, let underlying):
            "Could not decode the fal.ai \(operation): \(underlying)"
        case .videoDownload(let statusCode, let contentType, let byteCount, _):
            "The generated video download failed (HTTP \(statusCode), content type \(contentType ?? "unknown"), \(byteCount) bytes)."
        case .terminalStatus(let status, let serverMessage, _):
            "fal.ai queue finished with status \(status). \(serverMessage ?? "No server error message was returned.")"
        case .pollingTimedOut(_, let lastStatus, let timeout):
            "fal.ai did not finish within \(Int(timeout)) seconds. Last status: \(lastStatus)."
        }
    }

    var diagnosticDescription: String {
        switch self {
        case .keyUnavailable:
            return "The remote FAL_KEY source could not be loaded."
        case .invalidKey:
            return "The loaded FAL_KEY did not pass local format validation."
        case .invalidResponse:
            return "The URL response was not a valid HTTP response."
        case .missingVideo(let responseBody):
            return "Result contained no valid video URL. Raw response: \(responseBody)"
        case .api(let message):
            return message
        case .http(let statusCode, let method, let endpoint, let responseBody):
            return "HTTP \(statusCode); method=\(method); endpoint=\(endpoint); response=\(responseBody)"
        case .decoding(let operation, let responseBody, let underlying):
            return "operation=\(operation); decoderError=\(underlying); response=\(responseBody)"
        case .videoDownload(let statusCode, let contentType, let byteCount, let endpoint):
            return "downloadHTTP=\(statusCode); contentType=\(contentType ?? "unknown"); bytes=\(byteCount); endpoint=\(endpoint)"
        case .terminalStatus(let status, let serverMessage, let logs):
            let recentLogs = logs.suffix(10).joined(separator: " | ")
            return "queueStatus=\(status); serverError=\(serverMessage ?? "none"); recentLogs=\(recentLogs.isEmpty ? "none" : recentLogs)"
        case .pollingTimedOut(let requestID, let lastStatus, let timeout):
            return "requestID=\(requestID); timeout=\(Int(timeout))s; lastStatus=\(lastStatus)"
        }
    }
}

private extension String {
    func utf8Prefix(maxByteCount: Int) -> String {
        guard utf8.count > maxByteCount else { return self }

        var result = ""
        var byteCount = 0
        for character in self {
            let characterText = String(character)
            let characterByteCount = characterText.utf8.count
            guard byteCount + characterByteCount <= maxByteCount else { break }
            result.append(character)
            byteCount += characterByteCount
        }
        return result
    }
}

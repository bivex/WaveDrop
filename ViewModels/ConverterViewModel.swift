import Foundation
import Combine

struct LogEntry: Identifiable {
    let id = UUID()
    let date = Date()
    let text: String
}

enum ConversionState: Equatable {
    case idle
    case converting(progress: Double)
    case completed(filesCount: Int)
    case failed(error: String)
}

enum SettingsBitrate: Int, CaseIterable {
    case kbps128 = 128
    case kbps192 = 192
    case kbps256 = 256
    case kbps320 = 320

    var label: String {
        "\(rawValue) kbps"
    }
}

enum OutputFolderMode: String, CaseIterable {
    case same = "Same folder as source"
    case custom = "Custom folder"

    var label: String { rawValue }
}

@MainActor
final class ConverterViewModel: ObservableObject {
    @Published private(set) var audioFiles: [AudioFile] = []
    @Published private(set) var conversionState: ConversionState = .idle
    @Published private(set) var logEntries: [LogEntry] = []
    @Published var selectedBitrate: SettingsBitrate = .kbps320
    @Published var outputFolderMode: OutputFolderMode = .same
    @Published var customOutputFolder: URL?

    private let ffmpegService = FFmpegService.shared
    private let fileService = FileService.shared
    private var cancellables = Set<AnyCancellable>()
    @MainActor private let logLock = NSLock()

    @MainActor
    private func log(_ text: String) {
        logLock.lock()
        let entry = LogEntry(text: text)
        logEntries.append(entry)
        logLock.unlock()
    }

    var logText: String {
        logEntries.map {
            let time = DateFormatter.localizedString(from: $0.date, dateStyle: .none, timeStyle: .medium)
            return "[\(time)] \($0.text)"
        }.joined(separator: "\n")
    }
    private var concurrentLimit = 3

    init() {
        ffmpegService.$isProcessing
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isProcessing in
                guard let self = self else { return }
                if !isProcessing {
                    let doneCount = self.audioFiles.filter { $0.status == .done }.count
                    let errorCount = self.audioFiles.filter { $0.status == .error }.count
                    if doneCount + errorCount == self.audioFiles.count, self.audioFiles.count > 0 {
                        self.conversionState = .completed(filesCount: doneCount)
                    }
                }
            }
            .store(in: &cancellables)
    }

    func addFiles(urls: [URL]) {
        for url in urls {
            guard fileService.validateWAVFile(url) else {
                log("⚠️ Skipped invalid file: \(url.lastPathComponent)")
                continue
            }
            let fileSize = (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int64) ?? 0
            let audioFile = AudioFile(url: url, name: url.lastPathComponent, size: fileSize)
            audioFiles.append(audioFile)
            log("📥 Added: \(audioFile.name) (\(fileSize / 1_048_576) MB)")
        }
        log("Queue now has \(self.audioFiles.count) file(s)")
        reloadDurations()
    }

    func removeFile(_ file: AudioFile) {
        audioFiles.removeAll { $0.id == file.id }
    }

    func retryFile(_ file: AudioFile) {
        if let index = audioFiles.firstIndex(where: { $0.id == file.id }) {
            audioFiles[index].status = .waiting
            audioFiles[index].errorMessage = nil
        }
    }

    func removeFiles(at indexSet: IndexSet) {
        audioFiles.remove(atOffsets: indexSet)
    }

    func clearQueue() {
        ffmpegService.cancelAll()
        audioFiles.removeAll()
        conversionState = .idle
    }

    private func reloadDurations() {
        Task { @MainActor in
            for index in audioFiles.indices {
                if audioFiles[index].duration == 0 {
                    do {
                        let metadata = try await AudioMetadataService.shared.getMetadata(for: audioFiles[index].url)
                        audioFiles[index].duration = metadata.duration
                    } catch {
                        // keep default duration of 0
                    }
                }
            }
        }
    }

    func startConversion() {
        guard !audioFiles.isEmpty else { return }
        guard conversionState != .converting(progress: 0) else { return }
        log("🔄 Starting conversion (\(audioFiles.count) files, \(selectedBitrate.rawValue)kbps)")

        let outputFolder = outputFolderMode == .custom ? customOutputFolder : nil

        audioFiles = audioFiles.map { file in
            if file.status == .waiting || file.status == .error {
                var updated = file
                updated.status = .converting
                updated.progress = 0.0
                updated.errorMessage = nil
                return updated
            }
            return file
        }

        conversionState = .converting(progress: 0.0)
        processNextBatch(outputFolder: outputFolder)
    }

    private func processNextBatch(outputFolder: URL?) {
        let available = audioFiles.filter { $0.status == .converting }
        if available.isEmpty {
            let doneCount = audioFiles.filter { $0.status == .done }.count
            let errorCount = audioFiles.filter { $0.status == .error }.count
            if doneCount + errorCount == audioFiles.count, audioFiles.count > 0 {
                conversionState = .completed(filesCount: doneCount)
            }
            return
        }

        let batch = available.prefix(concurrentLimit)
        let dispatchGroup = DispatchGroup()

        for file in batch {
            dispatchGroup.enter()
            ffmpegService.convertFile(
                file,
                bitrate: selectedBitrate.rawValue,
                outputFolder: outputFolder,
                log: { [weak self] text in
                    DispatchQueue.main.async { self?.log(text) }
                },
            ) { [weak self] result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let outputURL):
                        if let index = self?.audioFiles.firstIndex(where: { $0.id == file.id }) {
                            self?.audioFiles[index].status = .done
                            self?.audioFiles[index].progress = 1.0
                        }
                    case .failure(let error):
                        if let index = self?.audioFiles.firstIndex(where: { $0.id == file.id }) {
                            self?.audioFiles[index].status = .error
                            self?.audioFiles[index].errorMessage = error.localizedDescription
                        }
                    }
                    dispatchGroup.leave()
                }
            }
        }

        dispatchGroup.notify(queue: .main) { [weak self] in
            self?.processNextBatch(outputFolder: outputFolder)
        }
    }

    func revealInFinder(_ file: AudioFile) {
        fileService.revealInFinder(file.outputURL)
    }

    func cancelFile(_ file: AudioFile) {
        ffmpegService.cancelConversion(file.id)
        if let index = audioFiles.firstIndex(where: { $0.id == file.id }) {
            audioFiles[index].status = .waiting
            audioFiles[index].progress = 0.0
        }
    }
}

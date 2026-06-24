import Foundation
import Combine

final class FFmpegService: ObservableObject, @unchecked Sendable {
    static let shared = FFmpegService()

    private var activeProcesses: [UUID: Process] = [:]
    private let lock = NSLock()

    @Published private(set) var isProcessing = false
    @Published private(set) var currentFileId: UUID?
    @Published private(set) var globalProgress: Double = 0.0

    private final class MutableData: @unchecked Sendable {
        var data = Data()
        func append(_ newData: Data) {
            data.append(newData)
        }
    }

    private final class CompletionBox: @unchecked Sendable {
        private let completion: (Result<URL, Error>) -> Void
        private var completed = false

        init(completion: @escaping (Result<URL, Error>) -> Void) {
            self.completion = completion
        }

        func complete(_ result: Result<URL, Error>) {
            guard !completed else { return }
            completed = true
            completion(result)
        }
    }

    private final class LogBox: @unchecked Sendable {
        let log: @Sendable (String) -> Void
        init(_ log: @escaping @Sendable (String) -> Void) { self.log = log }
        func call(_ text: String) { log(text) }
    }

    func convertFile(
        _ audioFile: AudioFile,
        bitrate: Int,
        outputFolder: URL?,
        log: @escaping @Sendable (String) -> Void = { _ in },
        completion: @escaping (Result<URL, Error>) -> Void
    ) -> UUID? {
        let process = Process()
        let fileId = audioFile.id

        let ffmpegPath: String
        if let bundled = Bundle.main.path(forResource: "ffmpeg", ofType: nil) {
            ffmpegPath = bundled
        } else if let system = findSystemFFmpeg() {
            ffmpegPath = system
        } else {
            log("❌ FFmpeg not found (bundled or system)")
            completion(.failure(FFmpegError.ffmpegNotFound))
            return nil
        }

        let outputURL: URL
        if let outputFolder {
            outputURL = outputFolder.appendingPathComponent(audioFile.name)
                .deletingPathExtension()
                .appendingPathExtension("mp3")
        } else {
            outputURL = audioFile.outputURL
        }

        process.executableURL = URL(fileURLWithPath: ffmpegPath)
        process.arguments = [
            "-i", audioFile.url.path,
            "-codec:a", "libmp3lame",
            "-b:a", "\(bitrate)k",
            "-y",
            outputURL.path
        ]

        let fileName = audioFile.name
        let sourcePath = audioFile.url.path
        let outputPath = outputURL.path
        let commandStr = process.arguments!.joined(separator: " ")
        log("🚀 Converting: \(fileName)")
        log("   Source: \(sourcePath)")
        log("   Output: \(outputPath)")
        log("   Command: ffmpeg \(commandStr)")

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        let outputHandle = pipe.fileHandleForReading
        let outputData = MutableData()
        let completionBox = CompletionBox(completion: completion)
        let logBox = LogBox(log)

        outputHandle.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            if data.count > 0 {
                outputData.append(data)
                self?.parseProgress(from: data, fileId: fileId)
            }
        }

        process.terminationHandler = { [weak self] process in
            outputHandle.readabilityHandler = nil

            let exitCode = process.terminationStatus
            let output = String(data: outputData.data, encoding: .utf8) ?? ""

            if exitCode == 0 {
                logBox.call("✅ Completed: \(fileName) -> \(outputURL.lastPathComponent)")
                self?.advanceProgress()
                completionBox.complete(.success(outputURL))
            } else {
                logBox.call("❌ Failed: \(fileName) — exit code \(exitCode)")
                if !output.isEmpty { logBox.call("   FFmpeg output: \(output)") }
                let error = FFmpegError.conversionFailed(
                    FileManager.default.fileExists(atPath: outputURL.path) ? nil : output
                )
                completionBox.complete(.failure(error))
            }

            self?.removeProcess(fileId)
        }

        lock.lock()
        activeProcesses[fileId] = process
        currentFileId = fileId
        globalProgress = 0.0
        isProcessing = true
        lock.unlock()

        do {
            try process.run()
        } catch {
            logBox.call("❌ Failed to launch ffmpeg for \(fileName): \(error.localizedDescription)")
            lock.lock()
            activeProcesses.removeValue(forKey: fileId)
            isProcessing = activeProcesses.isEmpty
            lock.unlock()
            completionBox.complete(.failure(error))
            return nil
        }

        return fileId
    }

    private func advanceProgress() {
        lock.lock()
        let current = globalProgress
        globalProgress = min(current + (100.0 / 3.0), 100.0)
        let empty = activeProcesses.isEmpty
        lock.unlock()
        if empty {
            isProcessing = false
        }
    }

    private func removeProcess(_ fileId: UUID) {
        lock.lock()
        activeProcesses.removeValue(forKey: fileId)
        if activeProcesses.isEmpty {
            isProcessing = false
            globalProgress = 0.0
            currentFileId = nil
        }
        lock.unlock()
    }

    func cancelConversion(_ fileId: UUID) {
        lock.lock()
        let process = activeProcesses[fileId]
        activeProcesses.removeValue(forKey: fileId)
        if activeProcesses.isEmpty {
            isProcessing = false
            globalProgress = 0.0
            currentFileId = nil
        }
        lock.unlock()
        process?.terminate()
    }

    func cancelAll() {
        lock.lock()
        let processes = Array(activeProcesses.values)
        activeProcesses.removeAll()
        isProcessing = false
        globalProgress = 0.0
        currentFileId = nil
        lock.unlock()

        for process in processes {
            process.terminate()
        }
    }

    private func parseProgress(from data: Data, fileId: UUID) {
        guard let output = String(data: data, encoding: .utf8) else { return }
        let lines = output.components(separatedBy: .newlines)

        for line in lines {
            if line.contains("time="), let timeRange = line.range(of: "time=") {
                let timeString = String(line[timeRange.upperBound...]).trimmingCharacters(in: .whitespaces)
                if parseTime(timeString) != nil {
                    // Progress is updated externally via AudioFile duration
                }
            }
        }
    }

    private func parseTime(_ timeString: String) -> TimeInterval? {
        let parts = timeString.split(separator: ":")
        guard parts.count == 3 else { return nil }

        let hours = Double(parts[0]) ?? 0
        let minutes = Double(parts[1]) ?? 0
        let seconds = Double(parts[2]) ?? 0

        return hours * 3600 + minutes * 60 + seconds
    }
}

enum FFmpegError: LocalizedError {
    case ffmpegNotFound
    case conversionFailed(String?)

    var errorDescription: String? {
        switch self {
        case .ffmpegNotFound:
            return "FFmpeg binary not found. Please ensure the application is properly installed."
        case .conversionFailed(let message):
            return message ?? "Conversion failed. The file may be corrupted or in an unsupported format."
        }
    }
}

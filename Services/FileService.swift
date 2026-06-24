import Foundation
import UniformTypeIdentifiers
import AVFoundation
import AppKit

@MainActor
final class FileService {
    static let shared = FileService()

    private init() {}

    func validateWAVFile(_ url: URL) -> Bool {
        UTType(filenameExtension: url.pathExtension) == .wav ||
        url.pathExtension.lowercased() == "wav"
    }

    func readMetadata(for url: URL) async throws -> (size: Int64, duration: TimeInterval) {
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        let fileSize = attributes[.size] as? Int64 ?? 0

        let asset = AVURLAsset(url: url)
        try await asset.load(.duration)
        let duration = CMTimeGetSeconds(asset.duration)

        return (fileSize, duration)
    }

    func openFileDialog(allowedTypes: [UTType] = [.wav], allowsMultiple: Bool = true) -> [URL]? {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = allowedTypes
        panel.allowsMultipleSelection = allowsMultiple
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.prompt = "Open"

        return panel.runModal() == .OK ? panel.urls : nil
    }

    func chooseOutputFolder() -> URL? {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Choose"

        return panel.runModal() == .OK ? panel.url : nil
    }

    func revealInFinder(_ url: URL) {
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }
}

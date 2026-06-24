import SwiftUI
import UniformTypeIdentifiers
import AppKit

struct DropZoneView: View {
    @State private var isDraggingOver = false
    let onFilesDropped: ([URL]) -> Void

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    isDraggingOver ? Color.accentColor : Color.secondary.opacity(0.3),
                    style: StrokeStyle(lineWidth: 2, dash: [6])
                )

            VStack(spacing: 12) {
                Image(systemName: "waveform.path")
                    .font(.system(size: 48))
                    .foregroundStyle(isDraggingOver ? Color.accentColor : .secondary)

                Text("Drop WAV files here")
                    .font(.headline)
                    .foregroundStyle(isDraggingOver ? Color.accentColor : .primary)

                Text("or use Cmd+O to open files")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(40)
        .background(isDraggingOver ? Color.accentColor.opacity(0.1) : Color.clear)
        .animation(.easeInOut(duration: 0.15), value: isDraggingOver)
        .onDrop(
            of: [UTType.fileURL],
            isTargeted: $isDraggingOver,
            perform: dropFiles
        )
    }

    private func dropFiles(_ providers: [NSItemProvider]) -> Bool {
        var urls: [URL] = []

        for provider in providers {
            guard provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) else {
                continue
            }

            let semaphore = DispatchSemaphore(value: 0)
            var loadedURL: URL?

            provider.loadObject(ofClass: URL.self) { url, _ in
                loadedURL = url
                semaphore.signal()
            }

            semaphore.wait()
            if let url = loadedURL {
                urls.append(url)
            }
        }

        let validURLs = urls.filter { $0.pathExtension.lowercased() == "wav" }

                if validURLs.count != urls.count && validURLs.count > 0 {
                    showToast("Some files were skipped (only WAV supported)")
                }

        if !validURLs.isEmpty {
            onFilesDropped(validURLs)
        }

        return !validURLs.isEmpty
    }

    private func showToast(_ message: String) {
        NotificationCenter.default.post(
            name: Notification.Name("wavedrop.showToast"),
            object: message
        )
    }
}

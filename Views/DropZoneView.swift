import SwiftUI
import UniformTypeIdentifiers

struct DropZoneView: View {
    @State private var isDraggingOver = false
    let onFilesDropped: ([URL]) -> Void

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .stroke(isDraggingOver ? Color.accentColor : Color.secondary.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [6]))

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
        .onDrop(of: [.fileURL], isTargeted: $isDraggingOver) { providers in
            var urls: [URL] = []

            for provider in providers {
                if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                    provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                        if let url = item as? URL {
                            DispatchQueue.main.async {
                                urls.append(url)
                            }
                        }
                    }
                }
            }

            let validURLs = urls.filter { url in
                url.pathExtension.lowercased() == "wav"
            }

            if validURLs.count != urls.count && validURLs.count > 0 {
                showToast(message: "Some files were skipped (only WAV supported)")
            }

            if !validURLs.isEmpty {
                onFilesDropped(validURLs)
            }

            return !validURLs.isEmpty
        }
    }

    private func showToast(message: String) {
        NotificationCenter.default.post(
            name: Notification.Name("wavedrop.showToast"),
            object: message
        )
    }
}

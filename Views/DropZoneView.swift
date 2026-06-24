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
        let group = DispatchGroup()

        for provider in providers {
            guard provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) else {
                continue
            }

            group.enter()
            provider.loadObject(ofClass: URL.self) { [self] url, _ in
                defer { group.leave() }
                guard let url = url else { return }
                let isValid = url.pathExtension.lowercased() == "wav"
                if isValid {
                    DispatchQueue.main.async {
                        onFilesDropped([url])
                    }
                }
            }
        }

        // Fire a background group notification to show toast if needed
        group.notify(queue: .main) {
            // Drop accepted, files are being processed
        }

        // Accept the drop optimistically — file loading happens asynchronously
        return true
    }

    private func showToast(_ message: String) {
        NotificationCenter.default.post(
            name: Notification.Name("wavedrop.showToast"),
            object: message
        )
    }
}

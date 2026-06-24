import SwiftUI

struct FolderPicker: View {
    @Environment(\.dismiss) private var dismiss
    let onSelect: (URL) -> Void

    var body: some View {
        VStack {
            Text("Select Output Folder")
                .font(.headline)
                .padding()

            Button("Select Folder") {
                let panel = NSOpenPanel()
                panel.canChooseFiles = false
                panel.canChooseDirectories = true
                panel.allowsMultipleSelection = false
                panel.prompt = "Select"

                if panel.runModal() == .OK, let url = panel.url {
                    onSelect(url)
                }
                dismiss()
            }

            Button("Cancel") {
                dismiss()
            }
            .keyboardShortcut(.cancelAction)
        }
        .frame(width: 300)
    }
}

import SwiftUI

struct WaveDropApp: App {
    @StateObject private var viewModel = ConverterViewModel()
    @State private var toastMessage: String?
    @State private var toastType: ToastType = .info

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
                .frame(minWidth: 600, maxWidth: .infinity, minHeight: 400)
                .onReceive(NotificationCenter.default.publisher(for: Notification.Name("wavedrop.showToast"))) { notification in
                    if let message = notification.object as? String {
                        showToast(message, type: .info)
                    }
                }
        }
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .appInfo) { }
            CommandGroup(after: .newItem) { }
            CommandGroup(replacing: .newItem) { }

            CommandMenu("File") {
                Button("Open Files...") {
                    if let urls = FileService.shared.openFileDialog() {
                        viewModel.addFiles(urls: urls)
                    }
                }
                .keyboardShortcut("o", modifiers: .command)

                Button("Clear Queue") {
                    viewModel.clearQueue()
                }
                .keyboardShortcut("k", modifiers: .command)
                .disabled(viewModel.audioFiles.isEmpty)

                Divider()

                Button("Convert") {
                    viewModel.startConversion()
                }
                .keyboardShortcut(.return, modifiers: .command)
                .disabled(viewModel.audioFiles.isEmpty)
            }
        }
    }

    private func showToast(_ message: String, type: ToastType) {
        toastMessage = message
        toastType = type

        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            if toastMessage == message {
                toastMessage = nil
            }
        }
    }
}

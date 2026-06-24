import SwiftUI

struct FileListView: View {
    @ObservedObject var viewModel: ConverterViewModel

    var body: some View {
        List {
            ForEach(viewModel.audioFiles) { file in
                FileRowView(file: file, viewModel: viewModel)
            }
            .onDelete { indexSet in
                viewModel.removeFiles(at: indexSet)
            }
        }
        .listStyle(.inset)
        .overlay {
            if viewModel.audioFiles.isEmpty {
                ContentUnavailableView(
                    "No Files",
                    systemImage: "waveform",
                    description: Text("Drop WAV files to get started")
                )
            }
        }
    }
}

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: ConverterViewModel

    var body: some View {
        VStack(spacing: 0) {
            headerView
                .padding()

            if viewModel.audioFiles.isEmpty {
                DropZoneView { urls in
                    viewModel.addFiles(urls: urls)
                }
                .padding()
            } else {
                VStack(spacing: 0) {
                    FileListView(viewModel: viewModel)
                        .frame(maxHeight: .infinity)

                    if case .converting = viewModel.conversionState {
                        ConversionProgressView(viewModel: viewModel)
                            .padding(.horizontal)
                            .padding(.bottom)
                    }
                }
            }

            if !viewModel.audioFiles.isEmpty {
                SettingsView(viewModel: viewModel)
                    .background(.bar)
                    .cornerRadius(12)
                    .padding()

                HStack(spacing: 12) {
                    Button("Clear") {
                        viewModel.clearQueue()
                    }
                    .keyboardShortcut("k", modifiers: .command)

                    Spacer()

                    Button("Convert") {
                        withAnimation {
                            viewModel.startConversion()
                        }
                    }
                    .keyboardShortcut(.return, modifiers: .command)
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.audioFiles.isEmpty)
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
        .frame(minWidth: 600, minHeight: 400)
        .background(.windowBackground)
    }

    private var headerView: some View {
        HStack {
            Image(systemName: "waveform.path")
                .font(.title2)
                .foregroundStyle(Color.accentColor)

            VStack(alignment: .leading, spacing: 2) {
                Text("WaveDrop")
                    .font(.title2.bold())

                if !viewModel.audioFiles.isEmpty {
                    Text("\(viewModel.audioFiles.count) file\(viewModel.audioFiles.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if !viewModel.audioFiles.isEmpty {
                Button {
                    if let urls = FileService.shared.openFileDialog() {
                        viewModel.addFiles(urls: urls)
                    }
                } label: {
                    Image(systemName: "plus")
                }
                .buttonStyle(.borderless)
                .help("Add files")
            }
        }
    }
}


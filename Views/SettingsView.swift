import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: ConverterViewModel
    @State private var showFolderPicker = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("Bitrate")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)

                Picker("Bitrate", selection: $viewModel.selectedBitrate) {
                    ForEach(SettingsBitrate.allCases, id: \.self) { bitrate in
                        Text(bitrate.label).tag(bitrate)
                    }
                }
                .pickerStyle(.segmented)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Output")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)

                Picker("Output Folder", selection: $viewModel.outputFolderMode) {
                    ForEach(OutputFolderMode.allCases, id: \.self) { mode in
                        Text(mode.label).tag(mode)
                    }
                }
                .pickerStyle(.radioGroup)

                if viewModel.outputFolderMode == .custom {
                    HStack {
                        Text(viewModel.customOutputFolder?.lastPathComponent ?? "Not selected")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Spacer()

                        Button("Choose Folder") {
                            showFolderPicker = true
                        }
                        .controlSize(.small)
                    }
                    .padding(.top, 4)
                }
            }
        }
        .padding(.horizontal)
        .padding(.bottom)
        .sheet(isPresented: $showFolderPicker) {
            FolderPicker { url in
                viewModel.customOutputFolder = url
                showFolderPicker = false
            }
        }
    }
}

import SwiftUI

struct ConversionProgressView: View {
    @ObservedObject var viewModel: ConverterViewModel

    var body: some View {
        VStack(spacing: 12) {
            switch viewModel.conversionState {
            case .converting(let progress):
                VStack(spacing: 8) {
                    ProgressView(value: progress, total: 100)
                        .progressViewStyle(.linear)
                        .scaleEffect(x: 1, y: 2, anchor: .center)

                    Text("Converting...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)

                    Text(String(format: "%.0f%%", progress))
                        .font(.title2.bold())
                        .foregroundStyle(Color.accentColor)
                }

            case .completed(let filesCount):
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.green)

                    Text("Conversion Complete")
                        .font(.title3.bold())

                    Text("\(filesCount) file\(filesCount == 1 ? "" : "s") successfully converted")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 12) {
                        Button {
                            if let lastFile = viewModel.audioFiles.last {
                                viewModel.revealInFinder(lastFile)
                            }
                        } label: {
                            Label("Reveal in Finder", systemImage: "folder")
                        }
                        .buttonStyle(.borderedProminent)

                        Button("Convert More") {
                            viewModel.clearQueue()
                        }
                        .buttonStyle(.bordered)
                    }
                }

            case .failed(let error):
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.red)

                    Text("Conversion Failed")
                        .font(.title3.bold())

                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Button("Retry") {
                        viewModel.startConversion()
                    }
                    .buttonStyle(.borderedProminent)
                }

            default:
                EmptyView()
            }
        }
        .padding()
        .transition(.opacity.combined(with: .scale))
    }
}

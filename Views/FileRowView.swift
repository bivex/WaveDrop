import SwiftUI
import UniformTypeIdentifiers

struct FileRowView: View {
    let file: AudioFile
    @ObservedObject var viewModel: ConverterViewModel

    var body: some View {
        HStack(spacing: 12) {
            statusIcon
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(file.name)
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(.primary)

                HStack(spacing: 8) {
                    Text(file.durationFormatted)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("•")
                        .foregroundStyle(.tertiary)
                    Text(file.sizeFormatted)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if file.status == .converting {
                ProgressView(value: file.progress)
                    .progressViewStyle(.linear)
                    .frame(width: 100)
            }

            statusBadge
                .font(.caption.bold())

            if file.status == .error, let error = file.errorMessage {
                Button {
                    viewModel.retryFile(file)
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .foregroundStyle(.orange)
                }
                .buttonStyle(.plain)
                .help("Retry")
            }

            Button {
                viewModel.removeFile(file)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.tertiary)
            }
            .buttonStyle(.plain)
            .help("Remove")
        }
        .padding(.vertical, 6)
    }

    @ViewBuilder
    private var statusIcon: some View {
        switch file.status {
        case .waiting:
            Image(systemName: "waveform")
                .foregroundStyle(.secondary)
        case .converting:
            Image(systemName: "waveform.path")
                .foregroundStyle(.blue)
                .symbolEffect(.pulse, options: .repeating)
        case .done:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
        case .error:
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
        }
    }

    @ViewBuilder
    private var statusBadge: some View {
        Text(file.status.rawValue)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                Capsule()
                    .fill(statusColor.opacity(0.15))
            )
            .foregroundStyle(statusColor)
    }

    private var statusColor: Color {
        switch file.status {
        case .waiting: return .secondary
        case .converting: return .blue
        case .done: return .green
        case .error: return .red
        }
    }
}

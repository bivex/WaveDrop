import SwiftUI

struct LogView: View {
    let logText: String
    @State private var searchText = ""

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Log")
                    .font(.headline)

                Spacer()

                Button("Copy All") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(logText, forType: .string)
                }
                .buttonStyle(.borderless)
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 4)

            TextEditor(text: .constant(logText))
                .font(.system(.caption, design: .monospaced))
                .scrollContentBackground(.hidden)
                .background(Color(NSColor.controlBackgroundColor))
                .border(Color.secondary.opacity(0.3), width: 1)
                .padding(.horizontal)
                .padding(.bottom)
        }
    }
}

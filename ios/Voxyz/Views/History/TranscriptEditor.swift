import SwiftUI

struct TranscriptEditor: View {
    let segment: Segment
    var onEdit: (String) -> Void

    @State private var isEditing = false
    @State private var editText: String = ""

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(formatTime(segment.startTime))
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 60, alignment: .leading)

            if isEditing {
                TextField("Text", text: $editText, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit {
                        onEdit(editText)
                        isEditing = false
                    }
            } else {
                Text(segment.text)
                    .font(.system(size: AppSettings.shared.fontSize))
                    .onTapGesture {
                        editText = segment.text
                        isEditing = true
                    }
            }
        }
        .padding(.vertical, 4)
    }

    private func formatTime(_ seconds: Double) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

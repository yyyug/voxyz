import SwiftUI

struct LivePreviewView: View {
    let text: String
    let isRecording: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Live Preview")
                    .font(.headline)
                if isRecording {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                        .opacity(isRecording ? 1 : 0)
                        .animation(.easeInOut(duration: 0.5).repeatForever(), value: isRecording)
                }
            }

            if text.isEmpty {
                VStack {
                    Spacer()
                    Text("Press the microphone to start recording")
                        .foregroundColor(.secondary)
                        .font(.body)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                ScrollView {
                    Text(text)
                        .font(.system(size: AppSettings.shared.fontSize))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

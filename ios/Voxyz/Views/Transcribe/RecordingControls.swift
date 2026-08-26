import SwiftUI

struct RecordingControls: View {
    let isRecording: Bool
    let audioLevel: Float
    let duration: String
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            Button(action: onToggle) {
                ZStack {
                    Circle()
                        .fill(isRecording ? Color.red : Color.blue)
                        .frame(width: 64, height: 64)

                    if isRecording {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white)
                            .frame(width: 20, height: 20)
                    } else {
                        Image(systemName: "mic.fill")
                            .foregroundColor(.white)
                            .font(.title2)
                    }
                }
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading) {
                Text(duration)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(isRecording ? .red : .secondary)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 6)

                        RoundedRectangle(cornerRadius: 2)
                            .fill(isRecording ? Color.green : Color.gray)
                            .frame(width: CGFloat(audioLevel) * geo.size.width, height: 6)
                    }
                }
                .frame(height: 6)
            }
        }
    }
}

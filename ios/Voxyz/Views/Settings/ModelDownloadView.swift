import SwiftUI

struct ModelDownloadView: View {
    @State private var downloadURL = ""
    @State private var isDownloading = false
    @State private var progress: Double = 0
    @State private var statusMessage = ""

    var body: some View {
        VStack(spacing: 16) {
            Text("Model Download")
                .font(.headline)

            Text("Download ONNX models for SenseVoice and GGUF models for Qwen translation.")
                .font(.subheadline)
                .foregroundColor(.secondary)

            if isDownloading {
                ProgressView(value: progress)
                    .progressViewStyle(.linear)
                Text(statusMessage)
                    .font(.caption)
            }

            Text("Place model files in: \(AppPaths.modelsDirectory.path)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

import SwiftUI

struct TranscribeView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = TranscribeViewModel()
    @State private var showPresenterMode = false

    var body: some View {
        VStack(spacing: 20) {
            headerSection
            recordingControlsSection
            livePreviewSection
        }
        .padding()
        .fullScreenCover(isPresented: $showPresenterMode) {
            PresenterView(
                text: viewModel.livePreviewText,
                onDismiss: { showPresenterMode = false }
            )
        }
    }

    private var headerSection: some View {
        HStack {
            Text("Transcribe")
                .font(.largeTitle)
                .fontWeight(.bold)
            Spacer()
            if appState.senseVoiceReady {
                Label("SenseVoice Ready", systemImage: "checkmark.circle.fill")
                    .foregroundColor(.green)
            } else {
                Label("No Model", systemImage: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
            }
        }
    }

    private var recordingControlsSection: some View {
        HStack(spacing: 20) {
            RecordingControls(
                isRecording: viewModel.isRecording,
                audioLevel: viewModel.recordingState.audioLevel,
                duration: viewModel.recordingState.formattedDuration,
                onToggle: { viewModel.toggleRecording() }
            )
            .frame(maxWidth: .infinity)

            Button(action: { showPresenterMode = true }) {
                Image(systemName: "rectangle.inset.filled.and.person.filled")
                    .font(.title2)
            }
            .disabled(viewModel.livePreviewText.isEmpty)
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(12)
    }

    private var livePreviewSection: some View {
        LivePreviewView(text: viewModel.livePreviewText, isRecording: viewModel.isRecording)
            .frame(maxHeight: .infinity)
    }
}

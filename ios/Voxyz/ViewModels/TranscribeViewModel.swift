import Foundation
import AVFoundation

@MainActor
class TranscribeViewModel: ObservableObject {
    @Published var isRecording = false
    @Published var recordingState = RecordingState()
    @Published var livePreviewText = ""
    @Published var segments: [Segment] = []
    @Published var errorMessage: String?
    @Published var isLiveTranscriptionActive = false

    private let audioRecorder = AudioRecorder()
    private let senseVoiceEngine = SenseVoiceEngine.shared
    private var currentJobId: String?
    private let databaseManager = DatabaseManager()

    init() {
        setupBindings()
    }

    func setupBindings() {
        audioRecorder.onAudioChunk = { [weak self] data, frameCount in
            Task { @MainActor [weak self] in
                self?.handleAudioChunk(data: data, frameCount: frameCount)
            }
        }
        audioRecorder.onStateChanged = { [weak self] state in
            Task { @MainActor [weak self] in
                self?.recordingState = state
                self?.isRecording = state.isRecording
            }
        }
    }

    func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }

    private func startRecording() {
        Task {
            let granted = await audioRecorder.requestPermission()
            guard granted else {
                errorMessage = "Microphone permission required"
                return
            }

            do {
                let job = try databaseManager.createJob()
                currentJobId = job.id
                try databaseManager.updateJobStatus(id: job.id, status: .recording)
                segments = []
                livePreviewText = ""
                audioRecorder.start()
                isLiveTranscriptionActive = true
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func stopRecording() {
        audioRecorder.stop()
        isLiveTranscriptionActive = false

        if let jobId = currentJobId {
            try? databaseManager.updateJobStatus(id: jobId, status: .completed)
        }
    }

    private func handleAudioChunk(data: Data, frameCount: Int) {
        guard isLiveTranscriptionActive else { return }
        guard senseVoiceEngine != nil else { return }

        Task {
            do {
                let result = try await senseVoiceEngine.transcribe(audioData: data, sampleRate: 16000)
                let offset = recordingState.duration - 15.0
                let adjustedSegments = result.segments.map { seg -> Segment in
                    var s = seg
                    s.startTime = max(0, seg.startTime + offset)
                    s.endTime = seg.endTime + offset
                    return s
                }
                segments.append(contentsOf: adjustedSegments)
                livePreviewText = segments.map(\.text).joined(separator: "\n")

                if let jobId = currentJobId {
                    let fullText = segments.map(\.text).joined(separator: "\n")
                    try? databaseManager.saveJobTranscript(id: jobId, text: fullText, segments: segments)
                }
            } catch {
                errorMessage = "Transcription error: \(error.localizedDescription)"
            }
        }
    }
}

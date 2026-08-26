import Foundation

struct RecordingState {
    var isRecording = false
    var isPaused = false
    var duration: TimeInterval = 0
    var audioLevel: Float = 0
    var segmentCount = 0

    var formattedDuration: String {
        let mins = Int(duration) / 60
        let secs = Int(duration) % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}

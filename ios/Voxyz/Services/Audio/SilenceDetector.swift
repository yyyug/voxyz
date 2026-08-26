import Foundation

class SilenceDetector {
    private let threshold: Float
    private var silentFrames = 0
    private let maxSilentFrames: Int

    init(threshold: Float = 0.02, maxSilentSeconds: Int = 3, sampleRate: Int = 16000) {
        self.threshold = threshold
        self.maxSilentFrames = maxSilentSeconds * sampleRate / 4096
    }

    func isSilent(_ level: Float) -> Bool {
        if level < threshold {
            silentFrames += 1
        } else {
            silentFrames = 0
        }
        return silentFrames > maxSilentFrames
    }

    func reset() {
        silentFrames = 0
    }
}

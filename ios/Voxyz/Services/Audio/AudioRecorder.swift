import Foundation
import AVFoundation

enum AudioRecorderError: Error, LocalizedError {
    case permissionDenied
    case engineFailed(String)
    case recorderFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied: return "Microphone permission denied"
        case .engineFailed(let msg): return "Audio engine failed: \(msg)"
        case .recorderFailed(let msg): return "Recorder failed: \(msg)"
        }
    }
}

class AudioRecorder: NSObject, ObservableObject {
    @Published var state = RecordingState()
    @Published var permissionGranted = false

    var onAudioChunk: ((Data, Int) -> Void)?
    var onStateChanged: ((RecordingState) -> Void)?

    private let engine = AVAudioEngine()
    private var format: AVAudioFormat?
    private var isConfigured = false

    private var chunkBuffer = Data()
    private var chunkFrameCount = Int(0)
    private let lock = NSLock()

    private var silenceDetector: SilenceDetector?
    private var timer: Timer?

    private let targetSampleRate: Int = 16000
    private let chunkDurationSeconds: Int = 15

    func requestPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                DispatchQueue.main.async {
                    self.permissionGranted = granted
                    continuation.resume(returning: granted)
                }
            }
        }
    }

    func start() {
        guard permissionGranted else { return }

        do {
            try configureAudioSession()
            try startEngine()
            state.isRecording = true
            state.duration = 0
            startTimer()
            notifyStateChanged()
        } catch {
            print("Failed to start recording: \(error)")
        }
    }

    func stop() {
        stopEngine()
        state.isRecording = false
        flushChunkBuffer()
        stopTimer()
        notifyStateChanged()
    }

    func pause() {
        engine.pause()
        state.isPaused = true
        notifyStateChanged()
    }

    func resume() {
        engine.start()
        state.isPaused = false
        notifyStateChanged()
    }

    private func configureAudioSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .default, options: [.defaultToSpeaker])
        try session.setActive(true)
    }

    private func startEngine() throws {
        let inputNode = engine.inputNode
        format = inputNode.outputFormat(forBus: 0)
        guard let format = format else {
            throw AudioRecorderError.engineFailed("Cannot get audio format")
        }

        let hwSampleRate = Int(format.sampleRate)
        let converter = AVAudioConverter(from: format, to: AVAudioFormat(
            commonFormat: .pcmFormatInt16,
            sampleRate: Double(targetSampleRate),
            channels: 1,
            interleaved: true
        )!)

        silenceDetector = SilenceDetector(threshold: Float(AppSettings.shared.silenceThreshold))

        inputNode.installTap(onBus: 0, bufferSize: 4096, format: format) { [weak self] buffer, _ in
            guard let self = self else { return }
            self.processAudioBuffer(buffer, converter: converter, hwSampleRate: hwSampleRate)
        }

        guard engine.isRunning else {
            try engine.start()
            return
        }
    }

    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer, converter: AVAudioConverter?, hwSampleRate: Int) {
        guard !state.isPaused else { return }

        let level = calculateLevel(buffer: buffer)
        DispatchQueue.main.async {
            self.state.audioLevel = level
        }

        guard let silenceDetector = silenceDetector else { return }
        if silenceDetector.isSilent(level) { return }

        let downsampled = downsample(buffer: buffer, converter: converter, hwSampleRate: hwSampleRate)
        guard !downsampled.isEmpty else { return }

        lock.lock()
        chunkBuffer.append(downsampled)
        chunkFrameCount += downsampled.count / 2
        let framesPerChunk = targetSampleRate * chunkDurationSeconds
        let shouldFlush = chunkFrameCount >= framesPerChunk
        lock.unlock()

        if shouldFlush {
            flushChunkBuffer()
        }
    }

    private func flushChunkBuffer() {
        lock.lock()
        let data = chunkBuffer
        let frameCount = chunkFrameCount
        chunkBuffer = Data()
        chunkFrameCount = 0
        lock.unlock()

        guard !data.isEmpty, frameCount > 0 else { return }
        DispatchQueue.main.async {
            self.onAudioChunk?(data, frameCount)
        }
    }

    private func downsample(buffer: AVAudioPCMBuffer, converter: AVAudioConverter?, hwSampleRate: Int) -> Data {
        guard let converter = converter else { return Data() }

        let ratio = hwSampleRate / targetSampleRate
        let outputFrameCount = Int(buffer.frameLength) / ratio
        guard outputFrameCount > 0 else { return Data() }

        guard let outputBuffer = AVAudioPCMBuffer(
            pcmFormat: converter.outputFormat,
            frameCapacity: AVAudioFrameCount(outputFrameCount)
        ) else { return Data() }

        var error: NSError?
        var isDone = false
        converter.convert(to: outputBuffer, error: &error) { _, outStatus in
            if isDone {
                outStatus.pointee = .noDataNow
                return nil
            }
            isDone = true
            outStatus.pointee = .haveData
            return buffer
        }

        guard error == nil, let channelData = outputBuffer.int16ChannelData else { return Data() }
        let frameCount = Int(outputBuffer.frameLength)
        return Data(bytes: channelData[0], count: frameCount * MemoryLayout<Int16>.size)
    }

    private func calculateLevel(buffer: AVAudioPCMBuffer) -> Float {
        guard let data = buffer.floatChannelData else { return 0 }
        let frames = Int(buffer.frameLength)
        guard frames > 0 else { return 0 }
        let samples = data[0]
        var sum: Float = 0
        for i in 0..<frames {
            let sample = samples[i]
            sum += sample * sample
        }
        let rms = sqrtf(sum / Float(frames))
        return min(rms * 10, 1.0)
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, self.state.isRecording, !self.state.isPaused else { return }
            self.state.duration += 0.1
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func stopEngine() {
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        try? AVAudioSession.sharedInstance().setActive(false)
    }

    private func notifyStateChanged() {
        DispatchQueue.main.async {
            self.onStateChanged?(self.state)
        }
    }
}

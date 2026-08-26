import Foundation

enum SenseVoiceError: Error, LocalizedError {
    case modelNotFound(String)
    case modelLoadFailed(String)
    case transcriptionFailed(String)
    case invalidAudioFormat(String)

    var errorDescription: String? {
        switch self {
        case .modelNotFound(let path): return "SenseVoice model not found at: \(path)"
        case .modelLoadFailed(let msg): return "Failed to load model: \(msg)"
        case .transcriptionFailed(let msg): return "Transcription failed: \(msg)"
        case .invalidAudioFormat(let msg): return "Invalid audio format: \(msg)"
        }
    }
}

final class SenseVoiceEngine {
    static let shared = SenseVoiceEngine()

    private var isLoaded = false
    private var modelPath: String?
    private let queue = DispatchQueue(label: "com.vozxyz.senseVoice", qos: .userInitiated)

    private init() {}

    func configure(modelPath: String) {
        self.modelPath = modelPath
        self.isLoaded = false
    }

    func warmup() throws {
        guard let path = modelPath, FileManager.default.fileExists(atPath: path) else {
            throw SenseVoiceError.modelNotFound(modelPath ?? "nil")
        }
        isLoaded = true
    }

    func transcribe(audioData: Data, sampleRate: Int = 16000) async throws -> TranscriptionResult {
        guard isLoaded else {
            throw SenseVoiceError.modelLoadFailed("Model not warmed up. Call warmup() first.")
        }

        return try await withCheckedThrowingContinuation { continuation in
            queue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(throwing: SenseVoiceError.transcriptionFailed("Engine deallocated"))
                    return
                }

                do {
                    let result = try self.runTranscription(audioData: audioData, sampleRate: sampleRate)
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private func runTranscription(audioData: Data, sampleRate: Int) throws -> TranscriptionResult {
        let startTime = Date()

        let pcmSamples = extractPCMSamples(from: audioData)
        guard !pcmSamples.isEmpty else {
            throw SenseVoiceError.invalidAudioFormat("No valid PCM samples found")
        }

        let placeholder = SenseVoicePlaceholder.transcribe(
            samples: pcmSamples,
            sampleRate: sampleRate
        )

        let processingTime = Date().timeIntervalSince(startTime)

        return TranscriptionResult(
            segments: placeholder.segments,
            fullText: placeholder.fullText,
            language: placeholder.language,
            processingTime: processingTime
        )
    }

    private func extractPCMSamples(from data: Data) -> [Int16] {
        guard data.count >= 44 else { return [] }

        var offset = 0
        var audioStart = 44
        var bitsPerSample: Int16 = 16
        var numChannels: Int16 = 1

        while offset + 8 <= data.count {
            let chunkID = data[offset..<offset+4]
            if String(data: chunkID, encoding: .ascii) == "data" {
                audioStart = offset + 8
                break
            }
            let chunkSize = Int(data.withUnsafeBytes { $0.load(fromByteOffset: offset + 4, as: UInt32.self) })
            offset += 12
            if chunkSize == 0 { break }
        }

        if audioStart == 44 {
            if data.count >= 22 {
                numChannels = data.withUnsafeBytes { $0.load(fromByteOffset: 22, as: Int16.self) }
                bitsPerSample = data.withUnsafeBytes { $0.load(fromByteOffset: 34, as: Int16.self) }
            }
        }

        let bytesPerSample = Int(bitsPerSample) / 8
        guard bytesPerSample == 2 else { return [] }

        var samples: [Int16] = []
        var pos = audioStart
        let end = data.count

        while pos + 2 <= end {
            let sample = data.withUnsafeBytes { $0.load(fromByteOffset: pos, as: Int16.self) }
            samples.append(sample)
            pos += bytesPerSample * Int(numChannels)
        }

        return samples
    }
}

enum SenseVoicePlaceholder {
    static func transcribe(samples: [Int16], sampleRate: Int) -> (segments: [Segment], fullText: String, language: String) {
        let duration = Double(samples.count) / Double(sampleRate)
        let text = "[SenseVoice transcription - requires ONNX model] \(samples.count) samples, \(String(format: "%.1f", duration))s"
        let segment = Segment(
            startTime: 0,
            endTime: duration,
            text: text,
            language: "zh"
        )
        return (segments: [segment], fullText: text, language: "zh")
    }
}

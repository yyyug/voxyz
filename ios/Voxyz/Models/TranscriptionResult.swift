import Foundation

struct TranscriptionResult {
    let segments: [Segment]
    let fullText: String
    let language: String
    let processingTime: TimeInterval
}

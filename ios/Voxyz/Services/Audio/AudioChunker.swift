import Foundation

class AudioChunker {
    private var buffer = Data()
    private let chunkSize: Int

    init(chunkSeconds: Int = 15, sampleRate: Int = 16000) {
        self.chunkSize = chunkSeconds * sampleRate * 2
    }

    func append(data: Data) -> [Data] {
        buffer.append(data)
        var chunks: [Data] = []

        while buffer.count >= chunkSize {
            let chunk = buffer.prefix(chunkSize)
            chunks.append(Data(chunk))
            buffer.removeFirst(chunkSize)
        }

        return chunks
    }

    func flush() -> Data? {
        guard !buffer.isEmpty else { return nil }
        let remaining = buffer
        buffer = Data()
        return remaining
    }

    func reset() {
        buffer = Data()
    }
}

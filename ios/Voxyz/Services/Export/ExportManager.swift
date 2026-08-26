import Foundation

enum ExportFormat: String, CaseIterable, Identifiable {
    case txt = "TXT"
    case srt = "SRT"
    case vtt = "VTT"
    case json = "JSON"
    case bilingual = "Bilingual"

    var id: String { rawValue }
}

class ExportManager {
    static func export(job: Job, segments: [Segment], format: ExportFormat) throws -> URL {
        let exportDir = AppPaths.exportsDirectory
        let timestamp = ISO8601DateFormatter().string(from: Date()).replacingOccurrences(of: ":", with: "-")
        let baseName = (job.name ?? job.id).replacingOccurrences(of: " ", with: "_")
        let ext = format == .bilingual ? "txt" : format.rawValue.lowercased()
        let fileURL = exportDir.appendingPathComponent("\(baseName)_\(timestamp).\(ext)")

        let content: String
        switch format {
        case .txt:
            content = job.text
        case .srt:
            content = generateSRT(segments: segments)
        case .vtt:
            content = generateVTT(segments: segments)
        case .json:
            content = generateJSON(job: job, segments: segments)
        case .bilingual:
            content = generateBilingual(job: job, segments: segments)
        }

        try content.write(to: fileURL, atomically: true, encoding: .utf8)
        return fileURL
    }

    private static func generateSRT(segments: [Segment]) -> String {
        var srt = ""
        for (index, seg) in segments.enumerated() {
            srt += "\(index + 1)\n"
            srt += "\(formatTime(seg.startTime)) --> \(formatTime(seg.endTime))\n"
            srt += "\(seg.text)\n\n"
        }
        return srt
    }

    private static func generateVTT(segments: [Segment]) -> String {
        var vtt = "WEBVTT\n\n"
        for (index, seg) in segments.enumerated() {
            vtt += "\(index + 1)\n"
            vtt += "\(formatTime(seg.startTime)) --> \(formatTime(seg.endTime))\n"
            vtt += "\(seg.text)\n\n"
        }
        return vtt
    }

    private static func generateJSON(job: Job, segments: [Segment]) -> String {
        let dict: [String: Any] = [
            "id": job.id,
            "text": job.text,
            "translatedText": job.translatedText ?? "",
            "segments": segments.map { [
                "id": $0.id,
                "startTime": $0.startTime,
                "endTime": $0.endTime,
                "text": $0.text,
                "language": $0.language
            ]}
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted),
              let str = String(data: data, encoding: .utf8) else { return "{}" }
        return str
    }

    private static func generateBilingual(job: Job, segments: [Segment]) -> String {
        var result = "=== Original ===\n\(job.text)\n\n"
        if let translated = job.translatedText, !translated.isEmpty {
            result += "=== Translated (\(job.translatedLanguage ?? "?")) ===\n\(translated)"
        }
        return result
    }

    private static func formatTime(_ seconds: Double) -> String {
        let h = Int(seconds) / 3600
        let m = (Int(seconds) % 3600) / 60
        let s = Int(seconds) % 60
        let ms = Int((seconds - Double(Int(seconds))) * 1000)
        return String(format: "%02d:%02d:%02d,%03d", h, m, s, ms)
    }
}

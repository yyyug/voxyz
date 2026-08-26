import Foundation

enum QwenTranslationError: Error, LocalizedError {
    case modelNotFound(String)
    case modelLoadFailed(String)
    case translationFailed(String)
    case notAvailable(String)

    var errorDescription: String? {
        switch self {
        case .modelNotFound(let path): return "GGUF model not found at: \(path)"
        case .modelLoadFailed(let msg): return "Failed to load model: \(msg)"
        case .translationFailed(let msg): return "Translation failed: \(msg)"
        case .notAvailable(let msg): return "Translation not available: \(msg)"
        }
    }
}

struct LanguageOption: Identifiable {
    let code: String
    let name: String
    var id: String { code }

    static let all: [LanguageOption] = [
        .init(code: "ar", name: "Arabic"),
        .init(code: "de", name: "German"),
        .init(code: "en", name: "English"),
        .init(code: "es", name: "Spanish"),
        .init(code: "fr", name: "French"),
        .init(code: "id", name: "Indonesian"),
        .init(code: "it", name: "Italian"),
        .init(code: "ja", name: "Japanese"),
        .init(code: "ko", name: "Korean"),
        .init(code: "nl", name: "Dutch"),
        .init(code: "pl", name: "Polish"),
        .init(code: "pt", name: "Portuguese"),
        .init(code: "ru", name: "Russian"),
        .init(code: "th", name: "Thai"),
        .init(code: "uk", name: "Ukrainian"),
        .init(code: "vi", name: "Vietnamese"),
        .init(code: "yue", name: "Cantonese"),
        .init(code: "zh", name: "Chinese"),
    ]

    static func name(for code: String) -> String {
        all.first { $0.code == code }?.name ?? code
    }
}

final class QwenTranslationEngine {
    static let shared = QwenTranslationEngine()

    private var isLoaded = false
    private var ggufPath: String?
    private let queue = DispatchQueue(label: "com.vozxyz.qwenTranslation", qos: .userInitiated)

    private init() {}

    func configure(ggufPath: String) {
        self.ggufPath = ggufPath
        self.isLoaded = false
    }

    func warmup() throws {
        guard let path = ggufPath, FileManager.default.fileExists(atPath: path) else {
            throw QwenTranslationError.modelNotFound(ggufPath ?? "nil")
        }
        isLoaded = true
    }

    func translate(
        text: String,
        sourceLanguage: String,
        targetLanguage: String
    ) async throws -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }

        guard isLoaded else {
            throw QwenTranslationError.notAvailable("Model not warmed up. Call warmup() first.")
        }

        return try await withCheckedThrowingContinuation { continuation in
            queue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(throwing: QwenTranslationError.translationFailed("Engine deallocated"))
                    return
                }

                do {
                    let result = try self.runTranslation(
                        text: trimmed,
                        sourceLanguage: sourceLanguage,
                        targetLanguage: targetLanguage
                    )
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private func runTranslation(
        text: String,
        sourceLanguage: String,
        targetLanguage: String
    ) throws -> String {
        let output = QwenPlaceholder.processTranslation(
            text: text,
            sourceLanguage: sourceLanguage,
            targetLanguage: targetLanguage
        )
        return output
    }

    static func listLanguages() -> [LanguageOption] {
        LanguageOption.all
    }

    func findGGUFFile() -> String? {
        guard let path = ggufPath else { return nil }
        if FileManager.default.fileExists(atPath: path) {
            return path
        }
        let dir = (path as NSString).deletingLastPathComponent
        guard let files = try? FileManager.default.contentsOfDirectory(atPath: dir) else {
            return nil
        }
        return files.first { $0.hasSuffix(".gguf") }
            .map { "\(dir)/\($0)" }
    }

    func validateConfig() -> (valid: Bool, messages: [String]) {
        var messages: [String] = []
        var valid = true

        if let path = findGGUFFile() {
            let attrs = try? FileManager.default.attributesOfItem(atPath: path)
            let sizeMB = (attrs?[.size] as? Int64 ?? 0) / (1024 * 1024)
            messages.append("GGUF model found at \(path) (\(sizeMB) MB)")
        } else {
            valid = false
            messages.append("GGUF model not found at \(ggufPath ?? "nil")")
        }

        if isLoaded {
            messages.append("Translation engine is warmed up and ready")
        } else {
            messages.append("Translation engine not yet warmed up")
        }

        return (valid, messages)
    }
}

enum QwenPlaceholder {
    static func processTranslation(
        text: String,
        sourceLanguage: String,
        targetLanguage: String
    ) -> String {
        let sourceName = LanguageOption.name(for: sourceLanguage)
        let targetName = LanguageOption.name(for: targetLanguage)
        return "[Translation from \(sourceName) to \(targetName) - requires llama.cpp GGUF model]"
    }
}

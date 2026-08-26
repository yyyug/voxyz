import Foundation

enum ModelUtils {
    static func findGGUFFile(in directory: String) -> String? {
        guard let files = try? FileManager.default.contentsOfDirectory(atPath: directory) else {
            return nil
        }
        return files.first { $0.hasSuffix(".gguf") }
            .map { "\(directory)/\($0)" }
    }

    static func configureAllEngines(appState: AppState) {
        let settings = AppSettings.shared

        if !settings.senseVoiceModelPath.isEmpty {
            SenseVoiceEngine.shared.configure(modelPath: settings.senseVoiceModelPath)
            do {
                try SenseVoiceEngine.shared.warmup()
                appState.senseVoiceReady = true
            } catch {
                print("SenseVoice warmup failed: \(error)")
            }
        }

        if !settings.qwenModelPath.isEmpty {
            QwenTranslationEngine.shared.configure(ggufPath: settings.qwenModelPath)
            do {
                try QwenTranslationEngine.shared.warmup()
                appState.qwenReady = true
            } catch {
                print("Qwen warmup failed: \(error)")
            }
        }
    }
}

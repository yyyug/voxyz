import Foundation
import AVFoundation

@MainActor
class SettingsViewModel: ObservableObject {
    @Published var settings = AppSettings.shared
    @Published var senseVoiceStatus: ModelStatus = .notLoaded
    @Published var qwenStatus: ModelStatus = .notLoaded
    @Published var selectedSenseVoicePath: String = ""
    @Published var selectedQwenPath: String = ""
    @Published var validationMessages: [String] = []

    enum ModelStatus: String {
        case notLoaded = "Not Loaded"
        case loading = "Loading..."
        case ready = "Ready"
        case error = "Error"
    }

    func validateModels() {
        validationMessages.removeAll()

        if !selectedSenseVoicePath.isEmpty {
            let exists = FileManager.default.fileExists(atPath: selectedSenseVoicePath)
            validationMessages.append("SenseVoice: \(exists ? "Found" : "Not found") at \(selectedSenseVoicePath)")
        }

        if !selectedQwenPath.isEmpty {
            let result = QwenTranslationEngine.shared.validateConfig()
            validationMessages.append(contentsOf: result.messages)
        }
    }

    func saveSettings() {
        settings.senseVoiceModelPath = selectedSenseVoicePath
        settings.qwenModelPath = selectedQwenPath
    }
}

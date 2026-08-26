import Foundation

class AppSettings: ObservableObject {
    static let shared = AppSettings()

    @Published var defaultLanguage: String {
        didSet { UserDefaults.standard.set(defaultLanguage, forKey: "defaultLanguage") }
    }
    @Published var translateTo: String {
        didSet { UserDefaults.standard.set(translateTo, forKey: "translateTo") }
    }
    @Published var autoTranslate: Bool {
        didSet { UserDefaults.standard.set(autoTranslate, forKey: "autoTranslate") }
    }
    @Published var senseVoiceModelPath: String {
        didSet { UserDefaults.standard.set(senseVoiceModelPath, forKey: "senseVoiceModelPath") }
    }
    @Published var qwenModelPath: String {
        didSet { UserDefaults.standard.set(qwenModelPath, forKey: "qwenModelPath") }
    }
    @Published var silenceThreshold: Double {
        didSet { UserDefaults.standard.set(silenceThreshold, forKey: "silenceThreshold") }
    }
    @Published var chunkDurationSeconds: Double {
        didSet { UserDefaults.standard.set(chunkDurationSeconds, forKey: "chunkDurationSeconds") }
    }
    @Published var presenterMode: Bool {
        didSet { UserDefaults.standard.set(presenterMode, forKey: "presenterMode") }
    }
    @Published var fontSize: Double {
        didSet { UserDefaults.standard.set(fontSize, forKey: "fontSize") }
    }

    private init() {
        let d = UserDefaults.standard
        d.register(defaults: [
            "defaultLanguage": "zh",
            "translateTo": "en",
            "autoTranslate": false,
            "senseVoiceModelPath": "",
            "qwenModelPath": "",
            "silenceThreshold": 0.02,
            "chunkDurationSeconds": 15.0,
            "presenterMode": false,
            "fontSize": 16.0
        ])
        self.defaultLanguage = d.string(forKey: "defaultLanguage")!
        self.translateTo = d.string(forKey: "translateTo")!
        self.autoTranslate = d.bool(forKey: "autoTranslate")
        self.senseVoiceModelPath = d.string(forKey: "senseVoiceModelPath")!
        self.qwenModelPath = d.string(forKey: "qwenModelPath")!
        self.silenceThreshold = d.double(forKey: "silenceThreshold")
        self.chunkDurationSeconds = d.double(forKey: "chunkDurationSeconds")
        self.presenterMode = d.bool(forKey: "presenterMode")
        self.fontSize = d.double(forKey: "fontSize")
    }
}

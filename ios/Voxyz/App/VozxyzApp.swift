import SwiftUI
import GRDB

@main
struct VoxyzApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
        }
    }
}

@MainActor
class AppState: ObservableObject {
    @Published var isTranscribing = false
    @Published var senseVoiceReady = false
    @Published var qwenReady = false

    let databaseManager = DatabaseManager()

    func initialize() {
        databaseManager.setup()
        ModelUtils.configureAllEngines(appState: self)
    }
}

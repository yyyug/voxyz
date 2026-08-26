import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        Sidebar()
            .frame(minWidth: 800, minHeight: 500)
            .onAppear {
                appState.initialize()
            }
    }
}

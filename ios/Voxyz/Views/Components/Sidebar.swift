import SwiftUI

enum Tab: String, CaseIterable, Identifiable {
    case transcribe
    case history
    case settings
    var id: String { rawValue }
}

struct Sidebar: View {
    @State private var selectedTab: Tab = .transcribe

    var body: some View {
        NavigationSplitView {
            List {
                ForEach(Tab.allCases) { tab in
                    Label(tabTitle(tab), systemImage: tabIcon(tab))
                        .contentShape(Rectangle())
                        .onTapGesture { selectedTab = tab }
                        .background(selectedTab == tab ? Color.accentColor.opacity(0.15) : Color.clear)
                }
            }
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
        } detail: {
            switch selectedTab {
            case .transcribe:
                TranscribeView()
            case .history:
                HistoryView()
            case .settings:
                SettingsView()
            }
        }
    }

    private func tabTitle(_ tab: Tab) -> String {
        switch tab {
        case .transcribe: return "Transcribe"
        case .history: return "History"
        case .settings: return "Settings"
        }
    }

    private func tabIcon(_ tab: Tab) -> String {
        switch tab {
        case .transcribe: return "mic.fill"
        case .history: return "clock.fill"
        case .settings: return "gearshape.fill"
        }
    }
}

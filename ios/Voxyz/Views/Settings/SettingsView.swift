import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()

    var body: some View {
        Form {
            Section("Models") {
                HStack {
                    Text("SenseVoice Model")
                    Spacer()
                    TextField("Path", text: $viewModel.selectedSenseVoicePath)
                        .frame(maxWidth: 400)
                    if viewModel.senseVoiceStatus == .ready {
                        Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                    }
                }
                HStack {
                    Text("Qwen Translation Model")
                    Spacer()
                    TextField("Path", text: $viewModel.selectedQwenPath)
                        .frame(maxWidth: 400)
                    if viewModel.qwenStatus == .ready {
                        Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                    }
                }
                Button("Validate Models") { viewModel.validateModels() }
                if !viewModel.validationMessages.isEmpty {
                    ForEach(viewModel.validationMessages, id: \.self) { msg in
                        Text(msg).font(.caption).foregroundColor(.secondary)
                    }
                }
            }

            Section("Audio") {
                HStack {
                    Text("Silence Threshold")
                    Slider(value: $viewModel.settings.silenceThreshold, in: 0...0.1, step: 0.005)
                    Text(String(format: "%.3f", viewModel.settings.silenceThreshold))
                        .monospacedDigit()
                }
                HStack {
                    Text("Chunk Duration (seconds)")
                    Stepper("\(Int(viewModel.settings.chunkDurationSeconds))", value: $viewModel.settings.chunkDurationSeconds, in: 5...60, step: 5)
                }
            }

            Section("Language") {
                Picker("Default Language", selection: $viewModel.settings.defaultLanguage) {
                    ForEach(LanguageOption.all) { lang in
                        Text(lang.name).tag(lang.code)
                    }
                }
                Picker("Translate To", selection: $viewModel.settings.translateTo) {
                    ForEach(LanguageOption.all) { lang in
                        Text(lang.name).tag(lang.code)
                    }
                }
                Toggle("Auto Translate", isOn: $viewModel.settings.autoTranslate)
            }

            Section("Display") {
                HStack {
                    Text("Font Size")
                    Slider(value: $viewModel.settings.fontSize, in: 12...32, step: 1)
                    Text("\(Int(viewModel.settings.fontSize))pt")
                        .monospacedDigit()
                }
                Toggle("Presenter Mode Default", isOn: $viewModel.settings.presenterMode)
            }

            Section {
                Button("Save Settings") { viewModel.saveSettings() }
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .navigationTitle("Settings")
    }
}

import SwiftUI

struct JobDetailView: View {
    let job: Job
    @ObservedObject var viewModel: HistoryViewModel
    @State private var editableText: String = ""
    @State private var showPresenterMode = false

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            content
        }
        .onAppear {
            editableText = job.text
        }
        .fullScreenCover(isPresented: $showPresenterMode) {
            PresenterView(
                text: editableText,
                onDismiss: { showPresenterMode = false }
            )
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(job.name ?? "Untitled")
                    .font(.title2)
                    .fontWeight(.bold)
                Text(job.createdAt.iso8601String)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()

            Button(action: { showPresenterMode = true }) {
                Image(systemName: "rectangle.inset.filled.and.person.filled")
            }
            .disabled(editableText.isEmpty)

            Menu {
                ForEach(ExportFormat.allCases) { format in
                    Button(format.rawValue) {
                        viewModel.exportJob(format: format)
                    }
                }
            } label: {
                Image(systemName: "square.and.arrow.up")
            }

            Button(action: { viewModel.showTranslateSheet = true }) {
                Image(systemName: "translate")
            }

            Button(action: {
                if job.name != nil {
                    viewModel.deleteJobs(at: IndexSet(integer: viewModel.jobs.firstIndex(where: { $0.id == job.id }) ?? 0))
                }
            }) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
        }
        .padding()
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if !viewModel.jobSegments.isEmpty {
                    ForEach(viewModel.jobSegments) { segment in
                        TranscriptEditor(segment: segment) { newText in
                            if let idx = viewModel.jobSegments.firstIndex(where: { $0.id == segment.id }) {
                                viewModel.jobSegments[idx].text = newText
                            }
                        }
                    }
                } else {
                    TextEditor(text: $editableText)
                        .font(.system(size: AppSettings.shared.fontSize))
                        .frame(minHeight: 300)
                }

                if let translated = job.translatedText, !translated.isEmpty {
                    Divider()
                    Text("Translation (\(job.translatedLanguage ?? "?"))")
                        .font(.headline)
                    Text(translated)
                        .font(.system(size: AppSettings.shared.fontSize))
                }
            }
            .padding()
        }
    }
}

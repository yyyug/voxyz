import SwiftUI

struct HistoryView: View {
    @StateObject private var viewModel = HistoryViewModel()

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("History")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Spacer()
                Button(action: { viewModel.loadJobs() }) {
                    Image(systemName: "arrow.clockwise")
                }
            }
            .padding()

            Divider()

            if viewModel.jobs.isEmpty {
                VStack {
                    Spacer()
                    Text("No recordings yet")
                        .foregroundColor(.secondary)
                    Spacer()
                }
            } else {
                List(viewModel.jobs) { job in
                    jobRow(job)
                        .tag(job.id)
                }
            }
        }
        .sheet(isPresented: $viewModel.showExportSheet) {
            exportSheet
        }
        .sheet(isPresented: $viewModel.showTranslateSheet) {
            translateSheet
        }
        .onAppear { viewModel.loadJobs() }
    }

    private func jobRow(_ job: Job) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(job.name ?? job.id)
                    .font(.headline)
                Text(job.displayText)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            Spacer()
            statusBadge(job.status)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            viewModel.selectJob(job)
        }
    }

    private func statusBadge(_ status: JobStatus) -> some View {
        Text(status.rawValue)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(statusColor(status).opacity(0.2))
            .foregroundColor(statusColor(status))
            .cornerRadius(8)
    }

    private func statusColor(_ status: JobStatus) -> Color {
        switch status {
        case .completed: return .green
        case .failed: return .red
        case .transcribing, .translating: return .blue
        default: return .gray
        }
    }

    private var exportSheet: some View {
        VStack(spacing: 16) {
            Text("Export")
                .font(.headline)
            Picker("Format", selection: $viewModel.exportFormat) {
                ForEach(ExportFormat.allCases) { format in
                    Text(format.rawValue).tag(format)
                }
            }
            .pickerStyle(.segmented)

            HStack {
                Button("Cancel") { viewModel.showExportSheet = false }
                Button("Export") { viewModel.exportJob(format: viewModel.exportFormat) }
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(width: 300)
    }

    private var translateSheet: some View {
        VStack(spacing: 16) {
            Text("Translate")
                .font(.headline)
            Picker("Target Language", selection: $viewModel.targetLanguage) {
                ForEach(LanguageOption.all) { lang in
                    Text(lang.name).tag(lang.code)
                }
            }

            HStack {
                Button("Cancel") { viewModel.showTranslateSheet = false }
                Button("Translate") { viewModel.translateJob(to: viewModel.targetLanguage) }
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(width: 300)
    }
}

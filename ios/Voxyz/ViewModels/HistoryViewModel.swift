import Foundation
import SwiftUI

@MainActor
class HistoryViewModel: ObservableObject {
    @Published var jobs: [Job] = []
    @Published var selectedJob: Job?
    @Published var jobSegments: [Segment] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showExportSheet = false
    @Published var showTranslateSheet = false
    @Published var exportFormat: ExportFormat = .srt
    @Published var targetLanguage = "en"

    private let databaseManager = DatabaseManager()

    func loadJobs() {
        jobs = databaseManager.getAllJobs()
    }

    func selectJob(_ job: Job) {
        selectedJob = job
        jobSegments = databaseManager.getSegments(forJobId: job.id)
    }

    func deleteJobs(at offsets: IndexSet) {
        for index in offsets {
            let job = jobs[index]
            try? databaseManager.deleteJob(id: job.id)
        }
        loadJobs()
    }

    func exportJob(format: ExportFormat) {
        guard let job = selectedJob else { return }
        showExportSheet = false
        do {
            let url = try ExportManager.export(job: job, segments: jobSegments, format: format)
            print("Exported to: \(url.path)")
        } catch {
            errorMessage = "Export failed: \(error.localizedDescription)"
        }
    }

    func translateJob(to language: String) {
        guard let job = selectedJob else { return }
        showTranslateSheet = false

        Task {
            do {
                try databaseManager.updateJobStatus(id: job.id, status: .translating)
                let translated = try await QwenTranslationEngine.shared.translate(
                    text: job.text,
                    sourceLanguage: "zh",
                    targetLanguage: language
                )
                try databaseManager.saveJobTranslation(id: job.id, translatedText: translated, language: language)
                try databaseManager.updateJobStatus(id: job.id, status: .completed)
                loadJobs()
                if let updatedJob = databaseManager.getJob(id: job.id) {
                    selectJob(updatedJob)
                }
            } catch {
                errorMessage = "Translation failed: \(error.localizedDescription)"
                try? databaseManager.updateJobStatus(id: job.id, status: .failed, error: error.localizedDescription)
            }
        }
    }
}

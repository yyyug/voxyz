import Foundation
import GRDB

enum JobStatus: String, Codable, DatabaseValueConvertible {
    case pending
    case recording
    case transcribing
    case translating
    case completed
    case failed
    case cancelled
}

struct Job: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "jobs"

    var id: String
    var name: String?
    var text: String
    var translatedText: String?
    var translatedLanguage: String?
    var status: JobStatus
    var error: String?
    var progress: Double
    var statusMessage: String?
    var audioDuration: Double?
    var sampleRate: Int?
    var notes: String?
    var createdAt: Date
    var updatedAt: Date
    var completedAt: Date?

    init(
        id: String = UUID().uuidString,
        name: String? = nil,
        text: String = "",
        translatedText: String? = nil,
        translatedLanguage: String? = nil,
        status: JobStatus = .pending,
        error: String? = nil,
        progress: Double = 0.0,
        statusMessage: String? = nil,
        audioDuration: Double? = nil,
        sampleRate: Int? = nil,
        notes: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        completedAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.text = text
        self.translatedText = translatedText
        self.translatedLanguage = translatedLanguage
        self.status = status
        self.error = error
        self.progress = progress
        self.statusMessage = statusMessage
        self.audioDuration = audioDuration
        self.sampleRate = sampleRate
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.completedAt = completedAt
    }

    init(row: Row) {
        id = row["id"]
        name = row["name"]
        text = row["text"]
        translatedText = row["translated_text"]
        translatedLanguage = row["translated_language"]
        status = row["status"]
        error = row["error"]
        progress = row["progress"]
        statusMessage = row["status_message"]
        audioDuration = row["audio_duration"]
        sampleRate = row["sample_rate"]
        notes = row["notes"]
        createdAt = row["created_at"]
        updatedAt = row["updated_at"]
        completedAt = row["completed_at"]
    }

    func encode(to container: inout PersistenceContainer) {
        container["id"] = id
        container["name"] = name
        container["text"] = text
        container["translated_text"] = translatedText
        container["translated_language"] = translatedLanguage
        container["status"] = status.rawValue
        container["error"] = error
        container["progress"] = progress
        container["status_message"] = statusMessage
        container["audio_duration"] = audioDuration
        container["sample_rate"] = sampleRate
        container["notes"] = notes
        container["created_at"] = createdAt
        container["updated_at"] = updatedAt
        container["completed_at"] = completedAt
    }

    var displayText: String {
        text.isEmpty ? "(No transcript)" : String(text.prefix(100))
    }
}

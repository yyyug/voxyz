import Foundation
import GRDB

struct Segment: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "segments"

    var id: String
    var jobId: String
    var startTime: Double
    var endTime: Double
    var text: String
    var confidence: Double
    var language: String
    var createdAt: Date

    init(
        id: String = UUID().uuidString,
        jobId: String = "",
        startTime: Double,
        endTime: Double,
        text: String,
        confidence: Double = 1.0,
        language: String = "zh",
        createdAt: Date = Date()
    ) {
        self.id = id
        self.jobId = jobId
        self.startTime = startTime
        self.endTime = endTime
        self.text = text
        self.confidence = confidence
        self.language = language
        self.createdAt = createdAt
    }

    init(row: Row) {
        id = row["id"]
        jobId = row["job_id"]
        startTime = row["start_time"]
        endTime = row["end_time"]
        text = row["text"]
        confidence = row["confidence"]
        language = row["language"]
        createdAt = row["created_at"]
    }

    func encode(to container: inout PersistenceContainer) {
        container["id"] = id
        container["job_id"] = jobId
        container["start_time"] = startTime
        container["end_time"] = endTime
        container["text"] = text
        container["confidence"] = confidence
        container["language"] = language
        container["created_at"] = createdAt
    }
}

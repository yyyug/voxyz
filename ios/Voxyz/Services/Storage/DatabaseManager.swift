import Foundation
import GRDB

class DatabaseManager {
    private var dbPool: DatabasePool?

    func setup() {
        let paths = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        guard let appSupport = paths.first else { return }
        let dbURL = appSupport.appendingPathComponent("voxyz.db")

        do {
            dbPool = try DatabasePool(path: dbURL.path)
            try createTables()
        } catch {
            print("Database setup failed: \(error)")
        }
    }

    private func createTables() throws {
        guard let dbPool = dbPool else { return }
        try dbPool.write { db in
            try db.execute(sql: """
                CREATE TABLE IF NOT EXISTS settings (
                    key TEXT PRIMARY KEY,
                    value TEXT NOT NULL
                )
            """)

            try db.execute(sql: """
                CREATE TABLE IF NOT EXISTS jobs (
                    id TEXT PRIMARY KEY,
                    name TEXT,
                    text TEXT NOT NULL DEFAULT '',
                    translated_text TEXT,
                    translated_language TEXT,
                    status TEXT NOT NULL DEFAULT 'pending',
                    error TEXT,
                    progress REAL DEFAULT 0.0,
                    status_message TEXT,
                    audio_duration REAL,
                    sample_rate INTEGER,
                    notes TEXT,
                    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                    completed_at TIMESTAMP
                )
            """)

            try db.execute(sql: """
                CREATE TABLE IF NOT EXISTS segments (
                    id TEXT PRIMARY KEY,
                    job_id TEXT NOT NULL,
                    start_time REAL NOT NULL,
                    end_time REAL NOT NULL,
                    text TEXT NOT NULL DEFAULT '',
                    confidence REAL DEFAULT 1.0,
                    language TEXT DEFAULT 'zh',
                    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                    FOREIGN KEY (job_id) REFERENCES jobs(id) ON DELETE CASCADE
                )
            """)
        }
    }

    func saveSetting(key: String, value: String) throws {
        guard let dbPool = dbPool else { return }
        try dbPool.write { db in
            try db.execute(
                sql: "INSERT OR REPLACE INTO settings (key, value) VALUES (?, ?)",
                arguments: [key, value]
            )
        }
    }

    func getSetting(key: String) -> String? {
        var value: String?
        try? dbPool?.read { db in
            value = try String.fetchOne(db, sql: "SELECT value FROM settings WHERE key = ?", arguments: [key])
        }
        return value
    }

    func createJob(name: String? = nil) throws -> Job {
        let job = Job(name: name)
        guard let dbPool = dbPool else { return job }
        try dbPool.write { db in
            try job.insert(db)
        }
        return job
    }

    func getAllJobs() -> [Job] {
        var jobs: [Job] = []
        try? dbPool?.read { db in
            jobs = try Job.fetchAll(db, sql: "SELECT * FROM jobs ORDER BY created_at DESC")
        }
        return jobs
    }

    func getJob(id: String) -> Job? {
        var job: Job?
        try? dbPool?.read { db in
            job = try Job.fetchOne(db, sql: "SELECT * FROM jobs WHERE id = ?", arguments: [id])
        }
        return job
    }

    func deleteJob(id: String) throws {
        guard let dbPool = dbPool else { return }
        try dbPool.write { db in
            try db.execute(sql: "DELETE FROM segments WHERE job_id = ?", arguments: [id])
            try db.execute(sql: "DELETE FROM jobs WHERE id = ?", arguments: [id])
        }
    }

    func saveJobTranscript(id: String, text: String, segments: [Segment]) throws {
        guard let dbPool = dbPool else { return }
        try dbPool.write { db in
            try db.execute(
                sql: "UPDATE jobs SET text = ?, updated_at = ? WHERE id = ?",
                arguments: [text, Date().iso8601String, id]
            )
            try db.execute(sql: "DELETE FROM segments WHERE job_id = ?", arguments: [id])
            for seg in segments {
                var segmentWithJobId = seg
                segmentWithJobId.jobId = id
                try segmentWithJobId.insert(db)
            }
        }
    }

    func saveJobTranslation(id: String, translatedText: String, language: String) throws {
        guard let dbPool = dbPool else { return }
        try dbPool.write { db in
            try db.execute(
                sql: "UPDATE jobs SET translated_text = ?, translated_language = ?, updated_at = ? WHERE id = ?",
                arguments: [translatedText, language, Date().iso8601String, id]
            )
        }
    }

    func updateJobStatus(id: String, status: JobStatus, error: String? = nil, progress: Double? = nil, statusMessage: String? = nil) throws {
        guard let dbPool = dbPool else { return }
        try dbPool.write { db in
            var sets: [String] = ["status = ?", "updated_at = ?"]
            var args: [Any] = [status.rawValue, Date().iso8601String]
            if let error = error { sets.append("error = ?"); args.append(error) }
            if let progress = progress { sets.append("progress = ?"); args.append(progress) }
            if let msg = statusMessage { sets.append("status_message = ?"); args.append(msg) }
            if status == .completed { sets.append("completed_at = ?"); args.append(Date().iso8601String) }
            args.append(id)
            try db.execute(sql: "UPDATE jobs SET \(sets.joined(separator: ", ")) WHERE id = ?", arguments: args)
        }
    }

    func updateJobMetadata(id: String, name: String?, notes: String?) throws {
        guard let dbPool = dbPool else { return }
        try dbPool.write { db in
            try db.execute(
                sql: "UPDATE jobs SET name = ?, notes = ?, updated_at = ? WHERE id = ?",
                arguments: [name, notes, Date().iso8601String, id]
            )
        }
    }

    func getSegments(forJobId jobId: String) -> [Segment] {
        var segments: [Segment] = []
        try? dbPool?.read { db in
            segments = try Segment.fetchAll(db, sql: "SELECT * FROM segments WHERE job_id = ? ORDER BY start_time", arguments: [jobId])
        }
        return segments
    }
}

//
//  NotificationReader.swift
//  Peninsula
//
//  Reads the macOS Notification Center database safely (read-only) and
//  decodes basic fields from the binary plist.
//  Note: On macOS 15+ (Sequoia) you must grant Full Disk Access to this app
//  or the hosting terminal for reads to succeed. Sandboxed apps cannot read it.
//

import Foundation
import SQLite3

struct NotificationRecord: Identifiable, Codable {
    let id = UUID()
    let appIdentifier: String
    let title: String?
    let subtitle: String?
    let body: String?
    let delivered: Date
}

enum NotifDBError: LocalizedError {
    case notFound
    case openFailed(String)
    case queryFailed(String)

    var errorDescription: String? {
        switch self {
        case .notFound:
            return "Notification Center database not found. On macOS 15+, grant Full Disk Access."
        case .openFailed(let msg):
            return "Failed to open database (\(msg)). If this is macOS 15+, ensure Full Disk Access."
        case .queryFailed(let msg):
            return "Database query failed (\(msg))."
        }
    }
}

enum NotificationReader {
    // Locate Notification Center DB for Sequoia and legacy macOS.
    nonisolated static func locateDB() throws -> URL {
        let fm = FileManager.default
        // Prefer Sequoia path
        let sequoia = fm.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Group Containers/group.com.apple.usernoted/db2/db")
        if fm.fileExists(atPath: sequoia.path) { return sequoia }

        // Legacy via DARWIN_USER_DIR
        let getconf = Process()
        getconf.executableURL = URL(fileURLWithPath: "/usr/bin/getconf")
        getconf.arguments = ["DARWIN_USER_DIR"]
        let pipe = Pipe()
        getconf.standardOutput = pipe
        try getconf.run(); getconf.waitUntilExit()
        guard getconf.terminationStatus == 0,
              let base = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines),
              !base.isEmpty else {
            throw NotifDBError.notFound
        }
        let legacy = URL(fileURLWithPath: base)
            .appendingPathComponent("com.apple.notificationcenter/db2/db")
        guard fm.fileExists(atPath: legacy.path) else { throw NotifDBError.notFound }
        return legacy
    }

    // Copy db, db-wal, db-shm into a temporary directory for safe read.
    nonisolated static func safeCopy(_ dbURL: URL) throws -> URL {
        let fm = FileManager.default
        let tmp = fm.temporaryDirectory.appendingPathComponent("notif-read-\(UUID().uuidString)")
        try fm.createDirectory(at: tmp, withIntermediateDirectories: true)

        let destDB = tmp.appendingPathComponent("db")
        try fm.copyItem(at: dbURL, to: destDB)
        let dir = dbURL.deletingLastPathComponent()
        for name in ["db-wal", "db-shm"] {
            let src = dir.appendingPathComponent(name)
            if fm.fileExists(atPath: src.path) {
                try? fm.copyItem(at: src, to: tmp.appendingPathComponent(name))
            }
        }
        return destDB
    }

    nonisolated private static func fetchNotifications(
        sql: String,
        bind: (OpaquePointer?) -> Void = { _ in }
    ) throws -> [NotificationRecord] {
        let original = try locateDB()
        let safeURL = try safeCopy(original)

        var db: OpaquePointer?
        let openCode = sqlite3_open_v2(safeURL.path, &db, SQLITE_OPEN_READONLY, nil)
        guard openCode == SQLITE_OK else {
            let msg = String(cString: sqlite3_errstr(Int32(openCode)))
            throw NotifDBError.openFailed(msg)
        }
        defer { sqlite3_close(db) }

        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            let msg = String(cString: sqlite3_errmsg(db))
            throw NotifDBError.queryFailed(msg)
        }
        defer { sqlite3_finalize(stmt) }
        bind(stmt)

        var out: [NotificationRecord] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            let ident = String(cString: sqlite3_column_text(stmt, 0))
            let deliveredAppleEpoch = sqlite3_column_double(stmt, 1)
            let delivered = Date(timeIntervalSinceReferenceDate: deliveredAppleEpoch)

            var title: String? = nil
            var subtitle: String? = nil
            var body: String? = nil

            if let bytes = sqlite3_column_blob(stmt, 2) {
                let count = Int(sqlite3_column_bytes(stmt, 2))
                if count > 0 {
                    let data = Data(bytes: bytes, count: count)
                    if let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any] {
                        if let req = plist["req"] as? [String: Any] {
                            title = (req["titl"] as? String) ?? (req["title"] as? String)
                            subtitle = (req["subt"] as? String) ?? (req["subtitle"] as? String)
                            body = (req["body"] as? String) ?? (req["message"] as? String)
                        } else {
                            title = (plist["titl"] as? String) ?? (plist["title"] as? String)
                            subtitle = (plist["subt"] as? String) ?? (plist["subtitle"] as? String)
                            body = (plist["body"] as? String) ?? (plist["message"] as? String)
                        }
                    }
                }
            }

            out.append(NotificationRecord(appIdentifier: ident, title: title, subtitle: subtitle, body: body, delivered: delivered))
        }
        return out
    }

    nonisolated static func read(limit: Int = 50) throws -> [NotificationRecord] {
        let sql = """
        SELECT app.identifier, record.delivered_date, record.data
        FROM record
        JOIN app ON app.app_id = record.app_id
        ORDER BY record.delivered_date DESC
        LIMIT ?;
        """

        return try fetchNotifications(sql: sql) { stmt in
            guard let stmt else { return }
            sqlite3_bind_int(stmt, 1, Int32(limit))
        }
    }

    nonisolated static func read(after date: Date, limit: Int? = nil) throws -> [NotificationRecord] {
        if let limit {
            let sql = """
            SELECT app.identifier, record.delivered_date, record.data
            FROM record
            JOIN app ON app.app_id = record.app_id
            WHERE record.delivered_date > ?
            ORDER BY record.delivered_date DESC
            LIMIT ?;
            """
            return try fetchNotifications(sql: sql) { stmt in
                guard let stmt else { return }
                sqlite3_bind_double(stmt, 1, date.timeIntervalSinceReferenceDate)
                sqlite3_bind_int(stmt, 2, Int32(limit))
            }
        } else {
            let sql = """
            SELECT app.identifier, record.delivered_date, record.data
            FROM record
            JOIN app ON app.app_id = record.app_id
            WHERE record.delivered_date > ?
            ORDER BY record.delivered_date DESC;
            """
            return try fetchNotifications(sql: sql) { stmt in
                guard let stmt else { return }
                sqlite3_bind_double(stmt, 1, date.timeIntervalSinceReferenceDate)
            }
        }
    }
}

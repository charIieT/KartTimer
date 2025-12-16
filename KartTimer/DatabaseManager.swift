//
//  DatabaseManager.swift
//  KartTimer
//
//  Created by Charlie Taylor on 13/12/2025.
//

import Foundation
import SQLite3

class KartTimerDatabaseManager {
    static let shared = KartTimerDatabaseManager()
    
    private var db: OpaquePointer?
    private let dbPath: String
    
    init() {
        let fileManager = FileManager.default
        let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        dbPath = documentDirectory.appendingPathComponent("karttimer.db").path
        
        openDatabase()
        createTables()
    }
    
    private func openDatabase() {
        sqlite3_open(dbPath, &db)
    }
    
    private func createTables() {
        let createSessionTableQuery = """
        CREATE TABLE IF NOT EXISTS sessions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            sessionName TEXT NOT NULL,
            driverName TEXT NOT NULL,
            kartNumber TEXT NOT NULL,
            isWet INTEGER DEFAULT 0,
            createdAt DATETIME DEFAULT CURRENT_TIMESTAMP
        );
        """
        
        let createLapsTableQuery = """
        CREATE TABLE IF NOT EXISTS laps (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            sessionId INTEGER NOT NULL,
            lapTime REAL NOT NULL,
            lapNumber INTEGER NOT NULL,
            FOREIGN KEY(sessionId) REFERENCES sessions(id) ON DELETE CASCADE
        );
        """
        
        let createMultipleSessionTableQuery = """
        CREATE TABLE IF NOT EXISTS multipleSessions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            sessionName TEXT NOT NULL,
            createdAt DATETIME DEFAULT CURRENT_TIMESTAMP
        );
        """
        
        let createMultipleDriversTableQuery = """
        CREATE TABLE IF NOT EXISTS multipleDrivers (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            multipleSessionId INTEGER NOT NULL,
            driverName TEXT NOT NULL,
            kartNumber TEXT NOT NULL,
            FOREIGN KEY(multipleSessionId) REFERENCES multipleSessions(id) ON DELETE CASCADE
        );
        """
        
        let createMultipleLapsTableQuery = """
        CREATE TABLE IF NOT EXISTS multipleLaps (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            multipleDriverId INTEGER NOT NULL,
            lapTime REAL NOT NULL,
            lapNumber INTEGER NOT NULL,
            FOREIGN KEY(multipleDriverId) REFERENCES multipleDrivers(id) ON DELETE CASCADE
        );
        """
        
        executeQuery(createSessionTableQuery)
        executeQuery(createLapsTableQuery)
        executeQuery(createMultipleSessionTableQuery)
        executeQuery(createMultipleDriversTableQuery)
        executeQuery(createMultipleLapsTableQuery)
        
        // Migration: Try to add isWet column (will fail silently if already exists)
        let addIsWetColumnQuery = "ALTER TABLE sessions ADD COLUMN isWet INTEGER DEFAULT 0;"
        var errorMessage: UnsafeMutablePointer<CChar>?
        sqlite3_exec(db, addIsWetColumnQuery.cString(using: .utf8)!, nil, nil, &errorMessage)
        if errorMessage != nil {
            sqlite3_free(errorMessage)
        }
    }
    
    private func executeQuery(_ query: String) {
        var errorMessage: UnsafeMutablePointer<CChar>?
        
        if sqlite3_exec(db, query.cString(using: .utf8)!, nil, nil, &errorMessage) != SQLITE_OK {
            if let error = errorMessage {
                sqlite3_free(error)
            }
        }
    }
    
    func saveSession(sessionName: String, driverName: String, kartNumber: String, laps: [TimeInterval], weatherCondition: Int = 0) {
        let query = "INSERT INTO sessions (sessionName, driverName, kartNumber, isWet) VALUES (?, ?, ?, ?);"
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, query.cString(using: .utf8)!, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (sessionName as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 2, (driverName as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 3, (kartNumber as NSString).utf8String, -1, nil)
            sqlite3_bind_int(statement, 4, Int32(weatherCondition))
            
            if sqlite3_step(statement) == SQLITE_DONE {
                let sessionId = sqlite3_last_insert_rowid(db)
                saveLaps(sessionId: sessionId, laps: laps)
            }
        }
        sqlite3_finalize(statement)
    }
    
    private func saveLaps(sessionId: Int64, laps: [TimeInterval]) {
        let query = "INSERT INTO laps (sessionId, lapTime, lapNumber) VALUES (?, ?, ?);"
        
        for (index, lapTime) in laps.enumerated() {
            var statement: OpaquePointer?
            
            if sqlite3_prepare_v2(db, query.cString(using: .utf8)!, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_int64(statement, 1, sessionId)
                sqlite3_bind_double(statement, 2, lapTime)
                sqlite3_bind_int(statement, 3, Int32(index + 1))
                sqlite3_step(statement)
            }
            sqlite3_finalize(statement)
        }
    }
    
    func fetchAllSessions() -> [SessionData] {
        let query = "SELECT id, sessionName, driverName, kartNumber, isWet, createdAt FROM sessions ORDER BY createdAt DESC LIMIT 100;"
        var statement: OpaquePointer?
        var sessions: [SessionData] = []
        
        if sqlite3_prepare_v2(db, query.cString(using: .utf8)!, -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                let id = sqlite3_column_int64(statement, 0)
                let sessionName = sqlite3_column_text(statement, 1) != nil ? String(cString: sqlite3_column_text(statement, 1)) : ""
                let driverName = sqlite3_column_text(statement, 2) != nil ? String(cString: sqlite3_column_text(statement, 2)) : ""
                let kartNumber = sqlite3_column_text(statement, 3) != nil ? String(cString: sqlite3_column_text(statement, 3)) : ""
                let isWet = Int(sqlite3_column_int(statement, 4))
                let createdAt = sqlite3_column_text(statement, 5) != nil ? String(cString: sqlite3_column_text(statement, 5)) : ""
                
                let laps = fetchLaps(sessionId: id)
                sessions.append(SessionData(id: id, sessionName: sessionName, driverName: driverName, kartNumber: kartNumber, isWet: isWet, laps: laps, createdAt: createdAt))
            }
        }
        sqlite3_finalize(statement)
        return sessions
    }
    
    private func fetchLaps(sessionId: Int64) -> [LapData] {
        let query = "SELECT id, lapTime, lapNumber FROM laps WHERE sessionId = ? ORDER BY lapNumber ASC;"
        var statement: OpaquePointer?
        var laps: [LapData] = []
        
        if sqlite3_prepare_v2(db, query.cString(using: .utf8)!, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_int64(statement, 1, sessionId)
            
            while sqlite3_step(statement) == SQLITE_ROW {
                let id = sqlite3_column_int64(statement, 0)
                let lapTime = sqlite3_column_double(statement, 1)
                let lapNumber = sqlite3_column_int(statement, 2)
                laps.append(LapData(id: id, lapTime: lapTime, lapNumber: Int(lapNumber)))
            }
        }
        sqlite3_finalize(statement)
        return laps
    }
    
    func deleteSession(id: Int64) {
        let query = "DELETE FROM sessions WHERE id = ?;"
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, query.cString(using: .utf8)!, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_int64(statement, 1, id)
            sqlite3_step(statement)
        }
        sqlite3_finalize(statement)
    }
    
    func saveMultipleSession(sessionName: String, drivers: [DriverTimer]) {
        let query = "INSERT INTO multipleSessions (sessionName) VALUES (?);"
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, query.cString(using: .utf8)!, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (sessionName as NSString).utf8String, -1, nil)
            
            if sqlite3_step(statement) == SQLITE_DONE {
                let multipleSessionId = sqlite3_last_insert_rowid(db)
                saveMultipleDrivers(multipleSessionId: multipleSessionId, drivers: drivers)
            }
        }
        sqlite3_finalize(statement)
    }
    
    private func saveMultipleDrivers(multipleSessionId: Int64, drivers: [DriverTimer]) {
        let query = "INSERT INTO multipleDrivers (multipleSessionId, driverName, kartNumber) VALUES (?, ?, ?);"
        
        for driver in drivers {
            var statement: OpaquePointer?
            
            if sqlite3_prepare_v2(db, query.cString(using: .utf8)!, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_int64(statement, 1, multipleSessionId)
                sqlite3_bind_text(statement, 2, (driver.name as NSString).utf8String, -1, nil)
                sqlite3_bind_text(statement, 3, (driver.kartNumber as NSString).utf8String, -1, nil)
                
                if sqlite3_step(statement) == SQLITE_DONE {
                    let multipleDriverId = sqlite3_last_insert_rowid(db)
                    saveMultipleLaps(multipleDriverId: multipleDriverId, laps: driver.laps)
                }
            }
            sqlite3_finalize(statement)
        }
    }
    
    private func saveMultipleLaps(multipleDriverId: Int64, laps: [TimeInterval]) {
        let query = "INSERT INTO multipleLaps (multipleDriverId, lapTime, lapNumber) VALUES (?, ?, ?);"
        
        for (index, lapTime) in laps.enumerated() {
            var statement: OpaquePointer?
            
            if sqlite3_prepare_v2(db, query.cString(using: .utf8)!, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_int64(statement, 1, multipleDriverId)
                sqlite3_bind_double(statement, 2, lapTime)
                sqlite3_bind_int(statement, 3, Int32(index + 1))
                sqlite3_step(statement)
            }
            sqlite3_finalize(statement)
        }
    }
    
    func fetchAllMultipleSessions() -> [MultipleSessionData] {
        let query = "SELECT id, sessionName, createdAt FROM multipleSessions ORDER BY createdAt DESC;"
        var statement: OpaquePointer?
        var sessions: [MultipleSessionData] = []
        
        if sqlite3_prepare_v2(db, query.cString(using: .utf8)!, -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                let id = sqlite3_column_int64(statement, 0)
                let sessionNamePtr = sqlite3_column_text(statement, 1)
                let createdAtPtr = sqlite3_column_text(statement, 2)
                
                let sessionName = sessionNamePtr != nil ? String(cString: sessionNamePtr!) : ""
                let createdAt = createdAtPtr != nil ? String(cString: createdAtPtr!) : ""
                
                let drivers = fetchMultipleDrivers(multipleSessionId: id)
                sessions.append(MultipleSessionData(id: id, sessionName: sessionName, drivers: drivers, createdAt: createdAt))
            }
        }
        sqlite3_finalize(statement)
        return sessions
    }
    
    private func fetchMultipleDrivers(multipleSessionId: Int64) -> [MultipleDriverData] {
        let query = "SELECT id, driverName, kartNumber FROM multipleDrivers WHERE multipleSessionId = ? ORDER BY id ASC;"
        var statement: OpaquePointer?
        var drivers: [MultipleDriverData] = []
        
        if sqlite3_prepare_v2(db, query.cString(using: .utf8)!, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_int64(statement, 1, multipleSessionId)
            
            while sqlite3_step(statement) == SQLITE_ROW {
                let id = sqlite3_column_int64(statement, 0)
                let driverNamePtr = sqlite3_column_text(statement, 1)
                let kartNumberPtr = sqlite3_column_text(statement, 2)
                
                let driverName = driverNamePtr != nil ? String(cString: driverNamePtr!) : ""
                let kartNumber = kartNumberPtr != nil ? String(cString: kartNumberPtr!) : ""
                
                let laps = fetchMultipleLaps(multipleDriverId: id)
                drivers.append(MultipleDriverData(id: id, driverName: driverName, kartNumber: kartNumber, laps: laps))
            }
        }
        sqlite3_finalize(statement)
        return drivers
    }
    
    private func fetchMultipleLaps(multipleDriverId: Int64) -> [MultipleLapData] {
        let query = "SELECT id, lapTime, lapNumber FROM multipleLaps WHERE multipleDriverId = ? ORDER BY lapNumber ASC;"
        var statement: OpaquePointer?
        var laps: [MultipleLapData] = []
        
        if sqlite3_prepare_v2(db, query.cString(using: .utf8)!, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_int64(statement, 1, multipleDriverId)
            
            while sqlite3_step(statement) == SQLITE_ROW {
                let id = sqlite3_column_int64(statement, 0)
                let lapTime = sqlite3_column_double(statement, 1)
                let lapNumber = sqlite3_column_int(statement, 2)
                laps.append(MultipleLapData(id: id, lapTime: lapTime, lapNumber: Int(lapNumber)))
            }
        }
        sqlite3_finalize(statement)
        return laps
    }
    
    func deleteMultipleSession(id: Int64) {
        let query = "DELETE FROM multipleSessions WHERE id = ?;"
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, query.cString(using: .utf8)!, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_int64(statement, 1, id)
            sqlite3_step(statement)
        }
        sqlite3_finalize(statement)
    }
    
    deinit {
        sqlite3_close(db)
    }
}

struct SessionData: Identifiable {
    let id: Int64
    let sessionName: String
    let driverName: String
    let kartNumber: String
    let isWet: Int
    let laps: [LapData]
    let createdAt: String
}

struct LapData: Identifiable {
    let id: Int64
    let lapTime: TimeInterval
    let lapNumber: Int
}

struct MultipleSessionData: Identifiable {
    let id: Int64
    let sessionName: String
    let drivers: [MultipleDriverData]
    let createdAt: String
}

struct MultipleDriverData: Identifiable {
    let id: Int64
    let driverName: String
    let kartNumber: String
    let laps: [MultipleLapData]
}

struct MultipleLapData: Identifiable {
    let id: Int64
    let lapTime: TimeInterval
    let lapNumber: Int
}

struct DriverTimer: Identifiable {
    let id: Int
    var name: String
    var kartNumber: String = ""
    var elapsedTime: TimeInterval = 0
    var isRunning = false
    var laps: [TimeInterval] = []
    var timer: Timer?
}

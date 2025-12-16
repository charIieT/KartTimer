//
//  LogsView.swift
//  KartTimer
//
//  Created by Charlie Taylor on 13/12/2025.
//

import SwiftUI

func getWeatherDisplay(_ weatherCode: Int) -> (icon: String, label: String, color: Color) {
    switch weatherCode {
    case 0:
        return ("sun.max.fill", "DRY", .yellow)
    case 1:
        return ("cloud.rain.fill", "WET", .blue)
    case 2:
        return ("cloud.sun.rain.fill", "GREASY", .orange)
    default:
        return ("sun.max.fill", "DRY", .yellow)
    }
}

struct LogsView: View {
    @State private var sessions: [SessionData] = []
    @State private var multipleSessions: [MultipleSessionData] = []
    @State private var selectedSession: SessionData?
    @State private var selectedMultipleSession: MultipleSessionData?
    @State private var logType: LogType = .single
    @State private var isLoading = false
    
    enum LogType {
        case single
        case multiple
    }
    
    var body: some View {
        ZStack {
            Color(red: 0.153, green: 0.149, blue: 0.149)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                HStack {
                    Text("SESSION LOGS")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.red)
                        .tracking(1.2)
                    
                    Spacer()
                    
                    Picker("Log Type", selection: $logType) {
                        Text("Single").tag(LogType.single)
                        Text("Multiple").tag(LogType.multiple)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 140)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                
                Divider()
                    .background(Color.white.opacity(0.1))
                
                if logType == .single {
                    if isLoading {
                        ProgressView()
                            .frame(maxHeight: .infinity)
                    } else if sessions.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "doc.text")
                                .font(.system(size: 56))
                                .foregroundColor(.gray.opacity(0.5))
                            Text("No Sessions Yet")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.gray)
                            Text("Start timing in the Home tab")
                                .font(.system(size: 14))
                                .foregroundColor(.gray.opacity(0.7))
                        }
                        .frame(maxHeight: .infinity)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(sessions) { session in
                                    SessionRowView(session: session, onTap: {
                                        selectedSession = session
                                    })
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 20)
                        }
                    }
                } else {
                    if isLoading {
                        ProgressView()
                            .frame(maxHeight: .infinity)
                    } else if multipleSessions.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "doc.text")
                                .font(.system(size: 56))
                                .foregroundColor(.gray.opacity(0.5))
                            Text("No Multiple Sessions Yet")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.gray)
                            Text("Start timing in the Multiple tab")
                                .font(.system(size: 14))
                                .foregroundColor(.gray.opacity(0.7))
                        }
                        .frame(maxHeight: .infinity)
                    } else {
                        ScrollView {
                            VStack(spacing: 12) {
                                ForEach(multipleSessions) { session in
                                    VStack(alignment: .leading, spacing: 12) {
                                        ForEach(session.drivers) { driver in
                                            Button(action: { selectedMultipleSession = session }) {
                                                VStack(alignment: .leading, spacing: 8) {
                                                    HStack {
                                                        Text("\(driver.driverName) - Kart \(driver.kartNumber)")
                                                            .font(.system(size: 16, weight: .semibold))
                                                            .foregroundColor(.white)
                                                        
                                                        Spacer()
                                                        
                                                        Button(action: { deleteDriver(driver.id, from: session.id) }) {
                                                            Image(systemName: "xmark.circle.fill")
                                                                .font(.system(size: 18))
                                                                .foregroundColor(.red)
                                                        }
                                                    }
                                                    
                                                    Text(session.sessionName)
                                                        .font(.system(size: 13))
                                                        .foregroundColor(.red)
                                                    
                                                    VStack(alignment: .leading, spacing: 4) {
                                                        ForEach(Array(driver.laps.enumerated()), id: \.offset) { index, lap in
                                                            HStack {
                                                                Text("Lap \(index + 1):")
                                                                    .font(.system(size: 13, weight: .regular))
                                                                    .foregroundColor(.white)
                                                                
                                                                Spacer()
                                                                
                                                                Text(formatLapTime(lap.lapTime))
                                                                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                                                                    .foregroundColor(isFastestLap(lap.lapTime, in: driver.laps) ? .purple : .red)
                                                            }
                                                        }
                                                    }
                                                }
                                                .padding(12)
                                                .background(Color.white.opacity(0.05))
                                                .cornerRadius(10)
                                            }
                                        }
                                    }
                                    .padding(12)
                                    .background(Color.white.opacity(0.08))
                                    .cornerRadius(12)
                                }
                            }
                            .padding(16)
                        }
                        
                        VStack(spacing: 12) {
                            Divider()
                                .background(Color.white.opacity(0.1))
                            
                            Button(action: { deleteAllSessions() }) {
                                Text("DELETE ALL")
                                    .font(.system(size: 14, weight: .bold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(Color.red)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                            .padding(16)
                        }
                    }
                }
            }
        }
        .onAppear {
            loadData()
        }
        .onChange(of: logType) { _ in
            loadData()
        }
        .sheet(item: $selectedSession) { session in
            SessionDetailView(session: session, onDismiss: {
                selectedSession = nil
                loadData()
            })
        }
        .sheet(item: $selectedMultipleSession) { session in
            MultipleSessionDetailView(session: session, onDismiss: {
                selectedMultipleSession = nil
                loadData()
            })
        }
    }
    
    private func loadData() {
        isLoading = true
        if logType == .single {
            DispatchQueue.global(qos: .userInitiated).async {
                let loadedSessions = KartTimerDatabaseManager.shared.fetchAllSessions()
                DispatchQueue.main.async {
                    sessions = loadedSessions
                    isLoading = false
                }
            }
        } else {
            DispatchQueue.global(qos: .userInitiated).async {
                let loadedSessions = KartTimerDatabaseManager.shared.fetchAllMultipleSessions()
                DispatchQueue.main.async {
                    multipleSessions = loadedSessions
                    isLoading = false
                }
            }
        }
    }
    
    private func deleteDriver(_ driverId: Int64, from sessionId: Int64) {
        if let sessionIndex = multipleSessions.firstIndex(where: { $0.id == sessionId }) {
            var updatedDrivers = multipleSessions[sessionIndex].drivers
            updatedDrivers.removeAll { $0.id == driverId }
            
            if updatedDrivers.isEmpty {
                KartTimerDatabaseManager.shared.deleteMultipleSession(id: sessionId)
                multipleSessions.removeAll { $0.id == sessionId }
            } else {
                multipleSessions[sessionIndex] = MultipleSessionData(
                    id: multipleSessions[sessionIndex].id,
                    sessionName: multipleSessions[sessionIndex].sessionName,
                    drivers: updatedDrivers,
                    createdAt: multipleSessions[sessionIndex].createdAt
                )
            }
        }
    }
    
    private func deleteAllSessions() {
        for session in multipleSessions {
            KartTimerDatabaseManager.shared.deleteMultipleSession(id: session.id)
        }
        multipleSessions = []
    }
    
    private func isFastestLap(_ lapTime: TimeInterval, in laps: [MultipleLapData]) -> Bool {
        guard let fastestLap = laps.min(by: { $0.lapTime < $1.lapTime }) else { return false }
        return lapTime == fastestLap.lapTime
    }
    
    private func formatLapTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        let milliseconds = Int((time.truncatingRemainder(dividingBy: 1)) * 1000)
        return String(format: "%d:%02d.%03d", minutes, seconds, milliseconds)
    }
}

struct MultipleLogsView: View {
    @State private var multipleSessions: [MultipleSessionData] = []
    @State private var selectedSession: MultipleSessionData?
    
    var body: some View {
        VStack(spacing: 0) {
            if multipleSessions.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 56))
                        .foregroundColor(.gray.opacity(0.5))
                    Text("No Multiple Sessions Yet")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.gray)
                    Text("Start timing in the Multiple tab")
                        .font(.system(size: 14))
                        .foregroundColor(.gray.opacity(0.7))
                }
                .frame(maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(multipleSessions) { session in
                            VStack(alignment: .leading, spacing: 12) {
                                ForEach(session.drivers) { driver in
                                    Button(action: { selectedSession = session }) {
                                        VStack(alignment: .leading, spacing: 8) {
                                            HStack {
                                                Text("\(driver.driverName) - Kart \(driver.kartNumber)")
                                                    .font(.system(size: 16, weight: .semibold))
                                                    .foregroundColor(.white)
                                                
                                                Spacer()
                                                
                                                Button(action: { deleteDriver(driver.id, from: session.id) }) {
                                                    Image(systemName: "xmark.circle.fill")
                                                        .font(.system(size: 18))
                                                        .foregroundColor(.red)
                                                }
                                            }
                                            
                                            Text(session.sessionName)
                                                .font(.system(size: 13))
                                                .foregroundColor(.red)
                                            
                                            VStack(alignment: .leading, spacing: 4) {
                                                ForEach(Array(driver.laps.enumerated()), id: \.offset) { index, lap in
                                                    HStack {
                                                        Text("Lap \(index + 1):")
                                                            .font(.system(size: 13, weight: .regular))
                                                            .foregroundColor(.white)
                                                        
                                                        Spacer()
                                                        
                                                        Text(formatLapTime(lap.lapTime))
                                                            .font(.system(size: 13, weight: .semibold, design: .monospaced))
                                                            .foregroundColor(isFastestLap(lap.lapTime, in: driver.laps) ? .purple : .red)
                                                    }
                                                }
                                            }
                                        }
                                        .padding(12)
                                        .background(Color.white.opacity(0.05))
                                        .cornerRadius(10)
                                    }
                                }
                            }
                            .padding(12)
                            .background(Color.white.opacity(0.08))
                            .cornerRadius(12)
                        }
                    }
                    .padding(16)
                }
                
                VStack(spacing: 12) {
                    Divider()
                        .background(Color.white.opacity(0.1))
                    
                    Button(action: { deleteAllSessions() }) {
                        Text("DELETE ALL")
                            .font(.system(size: 14, weight: .bold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .padding(16)
                }
            }
        }
        .onAppear {
            loadMultipleSessions()
        }
        .sheet(item: $selectedSession) { session in
            MultipleSessionDetailView(session: session, onDismiss: {
                selectedSession = nil
                loadMultipleSessions()
            })
        }
    }
    
    private func loadMultipleSessions() {
        multipleSessions = KartTimerDatabaseManager.shared.fetchAllMultipleSessions()
    }
    
    private func deleteDriver(_ driverId: Int64, from sessionId: Int64) {
        if let sessionIndex = multipleSessions.firstIndex(where: { $0.id == sessionId }) {
            var updatedDrivers = multipleSessions[sessionIndex].drivers
            updatedDrivers.removeAll { $0.id == driverId }
            
            if updatedDrivers.isEmpty {
                KartTimerDatabaseManager.shared.deleteMultipleSession(id: sessionId)
                multipleSessions.removeAll { $0.id == sessionId }
            } else {
                multipleSessions[sessionIndex] = MultipleSessionData(
                    id: multipleSessions[sessionIndex].id,
                    sessionName: multipleSessions[sessionIndex].sessionName,
                    drivers: updatedDrivers,
                    createdAt: multipleSessions[sessionIndex].createdAt
                )
            }
        }
    }
    
    private func deleteAllSessions() {
        for session in multipleSessions {
            KartTimerDatabaseManager.shared.deleteMultipleSession(id: session.id)
        }
        multipleSessions = []
    }
    
    private func isFastestLap(_ lapTime: TimeInterval, in laps: [MultipleLapData]) -> Bool {
        guard let fastestLap = laps.min(by: { $0.lapTime < $1.lapTime }) else { return false }
        return lapTime == fastestLap.lapTime
    }
    
    private func formatLapTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        let milliseconds = Int((time.truncatingRemainder(dividingBy: 1)) * 100)
        return String(format: "%02d:%02d.%02d", minutes, seconds, milliseconds)
    }
}

struct MultipleSessionDetailView: View {
    let session: MultipleSessionData
    let onDismiss: () -> Void
    
    var body: some View {
        ZStack {
            Color(red: 0.153, green: 0.149, blue: 0.149)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                HStack {
                    Button(action: onDismiss) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.red)
                    }
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .padding(.horizontal, 16)
                .background(Color.black.opacity(0.3))
                
                Divider()
                    .background(Color.white.opacity(0.1))
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(session.sessionName.uppercased())
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.red)
                        }
                        
                        VStack(alignment: .leading, spacing: 16) {
                            ForEach(session.drivers) { driver in
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("\(driver.driverName) - Kart \(driver.kartNumber)")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.white)
                                    
                                    VStack(alignment: .leading, spacing: 8) {
                                        ForEach(Array(driver.laps.enumerated()), id: \.offset) { index, lap in
                                            HStack {
                                                Text("Lap \(index + 1):")
                                                    .font(.system(size: 14, weight: .regular))
                                                    .foregroundColor(.white)
                                                
                                                Spacer()
                                                
                                                Text(formatLapTime(lap.lapTime))
                                                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                                                    .foregroundColor(isFastestLap(lap.lapTime, in: driver.laps) ? .purple : .red)
                                            }
                                        }
                                    }
                                }
                                .padding(16)
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(12)
                            }
                        }
                    }
                    .padding(20)
                }
            }
        }
    }
    
    private func isFastestLap(_ lapTime: TimeInterval, in laps: [MultipleLapData]) -> Bool {
        guard let fastestLap = laps.min(by: { $0.lapTime < $1.lapTime }) else { return false }
        return lapTime == fastestLap.lapTime
    }
    
    private func formatLapTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        let milliseconds = Int((time.truncatingRemainder(dividingBy: 1)) * 100)
        return String(format: "%02d:%02d.%02d", minutes, seconds, milliseconds)
    }
}

struct SessionRowView: View {
    let session: SessionData
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(session.sessionName.uppercased())
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.red)
                        
                        HStack(spacing: 12) {
                            Text(session.driverName)
                                .font(.system(size: 13))
                                .foregroundColor(.white)
                            
                            Text("•")
                                .foregroundColor(.gray)
                            
                            Text("KART \(session.kartNumber)")
                                .font(.system(size: 13))
                                .foregroundColor(.white)
                            
                            Text("•")
                                .foregroundColor(.gray)
                            
                            HStack(spacing: 4) {
                                let (icon, label, color) = getWeatherDisplay(session.isWet)
                                Image(systemName: icon)
                                    .font(.system(size: 11))
                                    .foregroundColor(color)
                                Text(label)
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(color)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(session.laps.count)")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.green)
                        Text("laps")
                            .font(.system(size: 11))
                            .foregroundColor(.gray)
                    }
                }
                
                if !session.laps.isEmpty {
                    let bestLap = session.laps.min(by: { $0.lapTime < $1.lapTime })?.lapTime ?? 0
                    HStack {
                        Text("Best: \(formatLapTime(bestLap))")
                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
                            .foregroundColor(.green)
                        Spacer()
                        Text(formatDate(session.createdAt))
                            .font(.system(size: 11))
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.cyan.opacity(0.2), lineWidth: 1)
                    )
            )
        }
    }
    
    private func formatLapTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        let milliseconds = Int((time.truncatingRemainder(dividingBy: 1)) * 100)
        return String(format: "%02d:%02d.%02d", minutes, seconds, milliseconds)
    }
    
    private func formatDate(_ dateString: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        if let date = dateFormatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "MMM d, h:mm a"
            return displayFormatter.string(from: date)
        }
        return dateString
    }
}

struct SessionDetailView: View {
    let session: SessionData
    let onDismiss: () -> Void
    @State private var showDeleteAlert = false
    
    private func isFastestLap(_ lapTime: TimeInterval, in laps: [LapData]) -> Bool {
        guard let fastestLap = laps.min(by: { $0.lapTime < $1.lapTime }) else { return false }
        return lapTime == fastestLap.lapTime
    }
    
    var body: some View {
        ZStack {
            Color(red: 0.153, green: 0.149, blue: 0.149)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                HStack {
                    Button(action: onDismiss) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.red)
                    }
                    
                    Spacer()
                    
                    Button(action: { showDeleteAlert = true }) {
                        Image(systemName: "trash.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.red)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color.black.opacity(0.3))
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(session.sessionName.uppercased())
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.red)
                            
                            HStack(spacing: 12) {
                                Text(session.driverName)
                                    .font(.system(size: 14))
                                    .foregroundColor(.white)
                                Text("•")
                                    .foregroundColor(.gray)
                                Text("KART \(session.kartNumber)")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white)
                            }
                            
                            HStack(spacing: 8) {
                                let (icon, label, color) = getWeatherDisplay(session.isWet)
                                Image(systemName: icon)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(color)
                                Text(label)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(color)
                            }
                            
                            Text(formatDate(session.createdAt))
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                        }
                        .padding(.horizontal, 20)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("LAP TIMES")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.red)
                                .tracking(1.2)
                                .padding(.horizontal, 20)
                            
                            VStack(spacing: 8) {
                                ForEach(session.laps) { lap in
                                    HStack {
                                        Text("Lap \(lap.lapNumber)")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.white)
                                        
                                        Spacer()
                                        
                                        Text(formatLapTime(lap.lapTime))
                                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                                            .foregroundColor(isFastestLap(lap.lapTime, in: session.laps) ? .purple : .red)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.white.opacity(0.05))
                                    )
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        if !session.laps.isEmpty {
                            let bestLap = session.laps.min(by: { $0.lapTime < $1.lapTime })?.lapTime ?? 0
                            VStack(alignment: .leading, spacing: 8) {
                                Text("BEST LAP")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.cyan)
                                    .tracking(1.2)
                                
                                Text(formatLapTime(bestLap))
                                    .font(.system(size: 32, weight: .bold, design: .monospaced))
                                    .foregroundColor(.green)
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    .padding(.vertical, 24)
                }
                
                Button(action: { showDeleteAlert = true }) {
                    Text("DELETE SESSION")
                        .font(.system(size: 16, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.red.opacity(0.8))
                        )
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
                .alert("Delete Session", isPresented: $showDeleteAlert) {
                    Button("Delete", role: .destructive) {
                        KartTimerDatabaseManager.shared.deleteSession(id: session.id)
                        onDismiss()
                    }
                    Button("Cancel", role: .cancel) { }
                } message: {
                    Text("Are you sure you want to delete this session? This cannot be undone.")
                }
            }
        }
    }
    
    private func formatLapTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        let milliseconds = Int((time.truncatingRemainder(dividingBy: 1)) * 100)
        return String(format: "%02d:%02d.%02d", minutes, seconds, milliseconds)
    }
    
    private func formatDate(_ dateString: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        if let date = dateFormatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "MMM d, yyyy h:mm a"
            return displayFormatter.string(from: date)
        }
        return dateString
    }
}


#Preview {
    LogsView()
}

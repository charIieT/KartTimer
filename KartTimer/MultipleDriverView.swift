//
//  MultipleDriverView.swift
//  KartTimer
//
//  Created by Charlie Taylor on 13/12/2025.
//

import SwiftUI

struct MultipleView: View {
    @State private var drivers: [DriverTimer] = [
        DriverTimer(id: 1, name: "Kart 1", kartNumber: ""),
        DriverTimer(id: 2, name: "Kart 2", kartNumber: ""),
        DriverTimer(id: 3, name: "Kart 3", kartNumber: ""),
        DriverTimer(id: 4, name: "Kart 4", kartNumber: "")
    ]
    
    var body: some View {
        ZStack {
            Color(red: 0.153, green: 0.149, blue: 0.149)
                .ignoresSafeArea()
            
            VStack(spacing: 12) {
                HStack {
                    Text("4X LAP TIMING")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.red)
                        .tracking(1.2)
                    
                    Spacer()
                    
                    Button(action: {
                        // Stop all running timers first
                        for i in 0..<drivers.count {
                            if drivers[i].timer != nil {
                                drivers[i].timer?.invalidate()
                                drivers[i].timer = nil
                            }
                            drivers[i].isRunning = false
                            drivers[i].elapsedTime = 0
                            drivers[i].laps = []
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.red)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        KartBox(driver: $drivers[0])
                        KartBox(driver: $drivers[1])
                    }
                    
                    HStack(spacing: 12) {
                        KartBox(driver: $drivers[2])
                        KartBox(driver: $drivers[3])
                    }
                }
                .padding(.horizontal, 12)
                
                Button(action: { saveMultipleSession() }) {
                    Text("SAVE SESSION")
                        .font(.system(size: 16, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal, 12)
                
                Spacer()
            }
        }
    }
    
    private func saveMultipleSession() {
        let driversToSave = drivers.filter { !$0.laps.isEmpty }
        
        if driversToSave.isEmpty {
            return
        }
        
        let sessionName = "Practice Session"
        KartTimerDatabaseManager.shared.saveMultipleSession(sessionName: sessionName, drivers: driversToSave)
        
        // Stop all timers before resetting
        for i in 0..<drivers.count {
            drivers[i].timer?.invalidate()
            drivers[i].timer = nil
            drivers[i].isRunning = false
        }
        
        drivers = [
            DriverTimer(id: 1, name: "Kart 1", kartNumber: ""),
            DriverTimer(id: 2, name: "Kart 2", kartNumber: ""),
            DriverTimer(id: 3, name: "Kart 3", kartNumber: ""),
            DriverTimer(id: 4, name: "Kart 4", kartNumber: "")
        ]
    }
}

struct KartBox: View {
    @Binding var driver: DriverTimer
    
    var formattedTime: String {
        let minutes = Int(driver.elapsedTime) / 60
        let seconds = Int(driver.elapsedTime) % 60
        let milliseconds = Int((driver.elapsedTime.truncatingRemainder(dividingBy: 1)) * 100)
        return String(format: "%02d:%02d.%02d", minutes, seconds, milliseconds)
    }
    
    var lastLapTimeString: String {
        guard let lastLap = driver.laps.last else { return "---" }
        let minutes = Int(lastLap) / 60
        let seconds = Int(lastLap) % 60
        let milliseconds = Int((lastLap.truncatingRemainder(dividingBy: 1)) * 100)
        return String(format: "%02d:%02d.%02d", minutes, seconds, milliseconds)
    }
    
    var body: some View {
        VStack(spacing: 12) {
            Text(driver.name)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
            
            Text(formattedTime)
                .font(.system(size: 24, design: .monospaced))
                .fontWeight(.semibold)
                .foregroundColor(.red)
                .frame(maxWidth: .infinity)
                .padding(12)
                .background(Color.white.opacity(0.03))
                .cornerRadius(8)
            
            if driver.isRunning {
                Button(action: { recordLap() }) {
                    Text("LAP")
                        .font(.system(size: 18, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            } else {
                Button(action: { toggleTimer() }) {
                    Text("START")
                        .font(.system(size: 18, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("LAPS")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.gray)
                    
                    Text("(\(driver.laps.count))")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.gray)
                }
                
                Text(lastLapTimeString)
                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                    .foregroundColor(.red)
            }
            .padding(10)
            .background(Color.white.opacity(0.03))
            .cornerRadius(8)
        }
        .padding(12)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
    
    private func toggleTimer() {
        if driver.isRunning {
            driver.timer?.invalidate()
            driver.timer = nil
            driver.isRunning = false
        } else {
            driver.isRunning = true
            driver.timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { _ in
                driver.elapsedTime += 0.01
            }
        }
    }
    
    private func recordLap() {
        driver.laps.append(driver.elapsedTime)
        driver.elapsedTime = 0
    }
}

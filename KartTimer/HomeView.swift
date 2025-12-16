//
//  HomeView.swift
//  KartTimer
//
//  Created by Charlie Taylor on 13/12/2025.
//

import SwiftUI

enum WeatherCondition: Int, Hashable {
    case dry = 0
    case wet = 1
    case greasy = 2
}

struct HomeView: View {
    @ObservedObject var driverManager = DriverManager.shared
    @State private var sessionName = ""
    @State private var selectedDriver: Driver?
    @State private var elapsedTime: TimeInterval = 0
    @State private var isRunning = false
    @State private var timer: Timer?
    @State private var laps: [TimeInterval] = []
    @State private var showMenu = false
    @State private var showAbout = false
    @State private var showHelp = false
    @State private var showTerms = false
    @State private var isViewLoaded = false
    @State private var weatherCondition: WeatherCondition = .dry
    
    var isFormValid: Bool {
        !sessionName.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    var formattedTime: String {
        let minutes = Int(elapsedTime) / 60
        let seconds = Int(elapsedTime) % 60
        let milliseconds = Int((elapsedTime.truncatingRemainder(dividingBy: 1)) * 100)
        return String(format: "%02d:%02d.%02d", minutes, seconds, milliseconds)
    }
    
    func startStopwatch() {
        isRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            elapsedTime += 0.05
        }
    }
    
    func stopStopwatch() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }
    
    func recordLap() {
        laps.append(elapsedTime)
        elapsedTime = 0
    }
    
    func resetSession() {
        stopStopwatch()
        elapsedTime = 0
        laps = []
        sessionName = ""
        selectedDriver = nil
    }
    
    func saveSession() {
        guard let driver = selectedDriver else { return }
        KartTimerDatabaseManager.shared.saveSession(
            sessionName: sessionName,
            driverName: driver.name,
            kartNumber: driver.kartNumber,
            laps: laps,
            weatherCondition: weatherCondition.rawValue
        )
        resetSession()
    }
    
    var body: some View {
        ZStack {
            Color(red: 0.153, green: 0.149, blue: 0.149)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    Button(action: { withAnimation(.easeInOut(duration: 0.3)) { showMenu.toggle() } }) {
                        Image(systemName: "line.3.horizontal")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(10)
                            .background(.ultraThinMaterial)
                            .cornerRadius(8)
                    }
                    
                    Spacer()
                    
                    Image("Logo")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 28)
                    
                    Spacer()
                    
                    Spacer()
                        .frame(width: 44)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                
                Divider()
                    .background(Color.white.opacity(0.1))
                
                VStack(spacing: 0) {
                    if !isRunning && laps.isEmpty {
                        SessionFormView(sessionName: $sessionName, selectedDriver: $selectedDriver, weatherCondition: $weatherCondition, driverManager: driverManager)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 16)
                    } else {
                        VStack(spacing: 8) {
                            Text(sessionName.uppercased())
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.red)
                            if let driver = selectedDriver {
                                Text("\(driver.name) • KART \(driver.kartNumber)")
                                    .font(.system(size: 13))
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.vertical, 16)
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 16) {
                        VStack(alignment: .center, spacing: 8) {
                            Text("TIME")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.red)
                                .tracking(1.2)
                            
                            Text(formattedTime)
                                .font(.system(size: 56, weight: .bold, design: .monospaced))
                                .foregroundColor(.red)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.horizontal, 24)
                        
                        if isRunning && !laps.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("LAST LAP")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.gray)
                                    .tracking(1.0)
                                
                                Text(formatLapTime(laps.last ?? 0))
                                    .font(.system(size: 18, weight: .semibold, design: .monospaced))
                                    .foregroundColor(.red)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 24)
                        }
                    }
                    
                    Button(action: {
                        if isRunning {
                            recordLap()
                        } else if isFormValid {
                            startStopwatch()
                        }
                    }) {
                        Text(isRunning ? "LAP" : "START")
                            .font(.system(size: 36, weight: .bold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 120)
                            .background(
                                RoundedRectangle(cornerRadius: 24)
                                    .fill(Color.green)
                                    .shadow(color: Color.green.opacity(0.4), radius: 12, x: 0, y: 8)
                            )
                            .foregroundColor(.white)
                    }
                    .disabled(!isFormValid && !isRunning)
                    .opacity((!isFormValid && !isRunning) ? 0.5 : 1.0)
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    
                    if isRunning {
                        Button(action: {
                            stopStopwatch()
                            saveSession()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 44))
                                .foregroundColor(.red)
                        }
                        .padding(.top, 12)
                    }
                    
                    Spacer()
                }
            }
            
            if showMenu {
                VStack(spacing: 0) {
                    GlassToolbar {
                        HStack(spacing: 16) {
                            Button(action: { withAnimation(.easeInOut(duration: 0.3)) { showMenu = false } }) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                            
                            Spacer()
                            
                            Text("Menu")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.clear)
                        }
                    }
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            Button(action: { showAbout = true }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "info.circle.fill")
                                        .font(.system(size: 18))
                                        .foregroundColor(.red)
                                    
                                    Text("About")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                }
                                .padding(12)
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(10)
                            }
                            
                            Button(action: { showHelp = true }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "questionmark.circle.fill")
                                        .font(.system(size: 18))
                                        .foregroundColor(.red)
                                    
                                    Text("Help & Support")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                }
                                .padding(12)
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(10)
                            }
                            
                            Button(action: { showTerms = true }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "doc.text.fill")
                                        .font(.system(size: 18))
                                        .foregroundColor(.red)
                                    
                                    Text("Terms & Conditions")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                }
                                .padding(12)
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(10)
                            }
                        }
                        .padding(20)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("KartTimer v1.0")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.gray)
                        
                        Text("© 2025 KartTimer. All rights reserved.")
                            .font(.system(size: 11))
                            .foregroundColor(.gray.opacity(0.7))
                    }
                    .padding(20)
                }
                .frame(maxHeight: .infinity, alignment: .top)
                .background(Color(red: 0.153, green: 0.149, blue: 0.149))
                .transition(.move(edge: .leading))
                .zIndex(1)
            }
        }
        .sheet(isPresented: $showAbout) {
            AboutView()
        }
        .sheet(isPresented: $showHelp) {
            HelpView()
        }
        .sheet(isPresented: $showTerms) {
            TermsView()
        }
        .onAppear {
            driverManager.loadDriversSync()
        }
    }
    
    private func formatLapTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        let milliseconds = Int((time.truncatingRemainder(dividingBy: 1)) * 100)
        return String(format: "%02d:%02d.%02d", minutes, seconds, milliseconds)
    }
}

struct AboutView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color(red: 0.153, green: 0.149, blue: 0.149)
                .ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Text("About KartTimer")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.red)
                    
                    Spacer()
                    
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                    }
                }
                .padding(20)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("KartTimer is a professional lap timing application designed for kart racing enthusiasts. Track your sessions, monitor lap times, and improve your performance on the track.")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                            .lineSpacing(4)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Features")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.red)
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text("• Real-time lap timing")
                                Text("• Multiple driver profiles")
                                Text("• Session history tracking")
                                Text("• Detailed lap analytics")
                                Text("• Dark mode interface")
                            }
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Version")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.gray)
                            
                            Text("1.0.0")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(20)
                }
                
                Spacer()
            }
        }
    }
}

struct HelpView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color(red: 0.153, green: 0.149, blue: 0.149)
                .ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Text("Help & Support")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.red)
                    
                    Spacer()
                    
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                    }
                }
                .padding(20)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Getting Started")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.red)
                            
                            Text("1. Add your driver profile in the Drivers tab\n2. Enter a session name\n3. Select your driver\n4. Tap START to begin timing\n5. Tap LAP to record each lap")
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                                .lineSpacing(4)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Frequently Asked Questions")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.red)
                            
                            VStack(alignment: .leading, spacing: 12) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("How do I add a driver?")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.white)
                                    
                                    Text("Go to the Drivers tab and tap the + button to add a new driver profile.")
                                        .font(.system(size: 13))
                                        .foregroundColor(.gray)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Can I export my data?")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.white)
                                    
                                    Text("Session data is stored locally on your device. You can view all sessions in the Logs tab.")
                                        .font(.system(size: 13))
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Contact Support")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.red)
                            
                            Text("Email: support@karttimer.app\nWebsite: www.karttimer.app")
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                                .lineSpacing(4)
                        }
                    }
                    .padding(20)
                }
                
                Spacer()
            }
        }
    }
}

struct TermsView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color(red: 0.153, green: 0.149, blue: 0.149)
                .ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Text("Terms & Conditions")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.red)
                    
                    Spacer()
                    
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                    }
                }
                .padding(20)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("1. Acceptance of Terms")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.red)
                            
                            Text("By using KartTimer, you agree to comply with these terms and conditions. If you do not agree, please do not use this application.")
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                                .lineSpacing(3)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("2. Use License")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.red)
                            
                            Text("Permission is granted to download and use KartTimer for personal, non-commercial purposes only.")
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                                .lineSpacing(3)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("3. Disclaimer")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.red)
                            
                            Text("KartTimer is provided 'as is' without warranties. We are not responsible for any data loss or inaccuracies in timing.")
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                                .lineSpacing(3)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("4. Limitation of Liability")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.red)
                            
                            Text("In no event shall KartTimer be liable for any indirect, incidental, special, or consequential damages arising from your use of the application.")
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                                .lineSpacing(3)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("5. Changes to Terms")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.red)
                            
                            Text("We reserve the right to modify these terms at any time. Continued use of the application constitutes acceptance of updated terms.")
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                                .lineSpacing(3)
                        }
                    }
                    .padding(20)
                }
                
                Spacer()
            }
        }
    }
}

struct WeatherButtonView: View {
    let condition: WeatherCondition
    let isSelected: Bool
    let action: () -> Void
    
    private var icon: String {
        switch condition {
        case .dry:
            return "sun.max.fill"
        case .wet:
            return "cloud.rain.fill"
        case .greasy:
            return "cloud.sun.rain.fill"
        }
    }
    
    private var label: String {
        switch condition {
        case .dry:
            return "DRY"
        case .wet:
            return "WET"
        case .greasy:
            return "GREASY"
        }
    }
    
    private var color: Color {
        switch condition {
        case .dry:
            return .yellow
        case .wet:
            return .blue
        case .greasy:
            return .orange
        }
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(color)
                
                Text(label)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(color)
            }
            .frame(maxWidth: .infinity)
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(color.opacity(isSelected ? 0.6 : 0.3), lineWidth: 1)
                    )
            )
        }
    }
}

struct SessionFormView: View {
    @Binding var sessionName: String
    @Binding var selectedDriver: Driver?
    @Binding var weatherCondition: WeatherCondition
    @ObservedObject var driverManager: DriverManager
    
    var body: some View {
        VStack(spacing: 16) {
            SessionNameFieldView(sessionName: $sessionName)
            DriverSelectionView(selectedDriver: $selectedDriver, driverManager: driverManager)
                .id(driverManager.drivers.count)
            WeatherSelectionView(weatherCondition: $weatherCondition)
        }
        .padding(20)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
    }
}

struct SessionNameFieldView: View {
    @Binding var sessionName: String
    
    var body: some View {
        VStack(spacing: 12) {
            Text("SESSION NAME")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.red)
                .tracking(1.2)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            TextField("Enter session name", text: $sessionName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.red.opacity(0.3), lineWidth: 1)
                        )
                )
        }
    }
}

struct DriverSelectionView: View {
    @Binding var selectedDriver: Driver?
    @ObservedObject var driverManager: DriverManager
    
    var body: some View {
        VStack(spacing: 12) {
            Text("SELECT DRIVER")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.red)
                .tracking(1.2)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if driverManager.drivers.isEmpty {
                Text("Add drivers in the Drivers tab")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.red.opacity(0.3), lineWidth: 1)
                            )
                    )
            } else {
                Picker("Select Driver", selection: $selectedDriver) {
                    Text("Select Driver").font(.system(size: 14)).tag(nil as Driver?)
                    ForEach(driverManager.drivers) { driver in
                        Text("\(driver.name) - Kart \(driver.kartNumber)").font(.system(size: 14)).tag(driver as Driver?)
                    }
                }
                .pickerStyle(.automatic)
                .tint(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.red.opacity(0.3), lineWidth: 1)
                        )
                )
                .id(driverManager.drivers.count)
            }
        }
    }
}

struct WeatherSelectionView: View {
    @Binding var weatherCondition: WeatherCondition
    
    var body: some View {
        VStack(spacing: 12) {
            Text("WEATHER CONDITION")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.red)
                .tracking(1.2)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 8) {
                WeatherButtonView(condition: .dry, isSelected: weatherCondition == .dry, action: { weatherCondition = .dry })
                WeatherButtonView(condition: .wet, isSelected: weatherCondition == .wet, action: { weatherCondition = .wet })
                WeatherButtonView(condition: .greasy, isSelected: weatherCondition == .greasy, action: { weatherCondition = .greasy })
            }
        }
    }
}

#Preview {
    HomeView()
}

//
//  ProfileView.swift
//  KartTimer
//
//  Created by Charlie Taylor on 13/12/2025.
//

import SwiftUI
import Combine

struct Driver: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var kartNumber: String
    
    init(id: UUID = UUID(), name: String, kartNumber: String) {
        self.id = id
        self.name = name
        self.kartNumber = kartNumber
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Driver, rhs: Driver) -> Bool {
        lhs.id == rhs.id
    }
}

class DriverManager: NSObject, ObservableObject {
    static let shared = DriverManager()
    static let maxDrivers = 10
    
    @Published var drivers: [Driver] = []
    
    private let userDefaults = UserDefaults.standard
    private let driversKey = "savedDrivers"
    private var isLoaded = false
    
    override init() {
        super.init()
        loadDriversSync()
    }
    
    func loadDriversSync() {
        if let data = userDefaults.data(forKey: driversKey),
           let decoded = try? JSONDecoder().decode([Driver].self, from: data) {
            drivers = decoded
        }
    }
    
    func loadDrivers() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            if let data = self?.userDefaults.data(forKey: self?.driversKey ?? ""),
               let decoded = try? JSONDecoder().decode([Driver].self, from: data) {
                DispatchQueue.main.async {
                    self?.drivers = decoded
                }
            }
        }
    }
    
    func saveDrivers() {
        if let encoded = try? JSONEncoder().encode(drivers) {
            userDefaults.set(encoded, forKey: driversKey)
        }
    }
    
    func canAddDriver() -> Bool {
        return drivers.count < DriverManager.maxDrivers
    }
    
    func addDriver(name: String, kartNumber: String) {
        guard canAddDriver() else { return }
        let newDriver = Driver(name: name, kartNumber: kartNumber)
        drivers.append(newDriver)
        saveDrivers()
    }
    
    func deleteDriver(id: UUID) {
        drivers.removeAll { $0.id == id }
        saveDrivers()
    }
    
    func updateDriver(id: UUID, name: String, kartNumber: String) {
        if let index = drivers.firstIndex(where: { $0.id == id }) {
            drivers[index].name = name
            drivers[index].kartNumber = kartNumber
            saveDrivers()
        }
    }
}

struct ProfileView: View {
    @ObservedObject var driverManager = DriverManager.shared
    @State private var showAddDriver = false
    @State private var newDriverName = ""
    @State private var newKartNumber = ""
    @State private var editingDriver: Driver?
    @State private var editName = ""
    @State private var editKartNumber = ""
    @State private var isViewLoaded = false
    
    var body: some View {
        ZStack {
            Color(red: 0.153, green: 0.149, blue: 0.149)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                HStack {
                    Text("DRIVERS")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.red)
                        .tracking(1.2)
                    
                    Spacer()
                    
                    if driverManager.canAddDriver() {
                        Button(action: { showAddDriver = true }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.green)
                        }
                    } else {
                        Text("Limit: 10 drivers")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                
                Divider()
                    .background(Color.white.opacity(0.1))
                
                if driverManager.drivers.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "person.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.gray.opacity(0.5))
                        Text("No Drivers Yet")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.gray)
                        Text("Add a driver to get started")
                            .font(.system(size: 14))
                            .foregroundColor(.gray.opacity(0.7))
                    }
                    .frame(maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(driverManager.drivers) { driver in
                                DriverRowView(
                                    driver: driver,
                                    onEdit: {
                                        editingDriver = driver
                                        editName = driver.name
                                        editKartNumber = driver.kartNumber
                                    },
                                    onDelete: {
                                        driverManager.deleteDriver(id: driver.id)
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                    }
                }
            }
        }
        .sheet(isPresented: $showAddDriver) {
            AddDriverSheet(
                isPresented: $showAddDriver,
                driverManager: driverManager,
                driverName: $newDriverName,
                kartNumber: $newKartNumber
            )
        }
        .sheet(item: $editingDriver) { driver in
            EditDriverSheet(
                isPresented: Binding(
                    get: { editingDriver != nil },
                    set: { if !$0 { editingDriver = nil } }
                ),
                driverManager: driverManager,
                driver: driver,
                driverName: $editName,
                kartNumber: $editKartNumber
            )
        }
        .onAppear {
            if !isViewLoaded {
                isViewLoaded = true
                driverManager.loadDrivers()
            }
        }
    }
}

struct DriverRowView: View {
    let driver: Driver
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text(driver.name.uppercased())
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.red)
                
                Text("KART \(driver.kartNumber)")
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                Button(action: onEdit) {
                    Image(systemName: "pencil.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.blue)
                }
                
                Button(action: onDelete) {
                    Image(systemName: "trash.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.red)
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
                        .stroke(Color.red.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

struct AddDriverSheet: View {
    @Binding var isPresented: Bool
    let driverManager: DriverManager
    @Binding var driverName: String
    @Binding var kartNumber: String
    
    var body: some View {
        ZStack {
            Color(red: 0.153, green: 0.149, blue: 0.149)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                HStack {
                    Text("ADD DRIVER")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.red)
                    
                    Spacer()
                    
                    Button(action: { isPresented = false }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                VStack(spacing: 20) {
                    VStack(spacing: 12) {
                        Text("DRIVER NAME")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.red)
                            .tracking(1.2)
                        
                        TextField("", text: $driverName)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.bottom, 12)
                            .background(
                                VStack {
                                    Spacer()
                                    LinearGradient(
                                        gradient: Gradient(colors: [.red, .red.opacity(0.5)]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                    .frame(height: 1)
                                }
                            )
                    }
                    
                    VStack(spacing: 12) {
                        Text("KART NUMBER")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.red)
                            .tracking(1.2)
                        
                        TextField("", text: $kartNumber)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.bottom, 12)
                            .background(
                                VStack {
                                    Spacer()
                                    LinearGradient(
                                        gradient: Gradient(colors: [.red, .red.opacity(0.5)]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                    .frame(height: 1)
                                }
                            )
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                Button(action: {
                    if !driverName.isEmpty && !kartNumber.isEmpty {
                        driverManager.addDriver(name: driverName, kartNumber: kartNumber)
                        driverName = ""
                        kartNumber = ""
                        isPresented = false
                    }
                }) {
                    Text("ADD DRIVER")
                        .font(.system(size: 16, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.green)
                        )
                        .foregroundColor(.white)
                }
                .disabled(driverName.isEmpty || kartNumber.isEmpty)
                .opacity((driverName.isEmpty || kartNumber.isEmpty) ? 0.5 : 1.0)
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
        }
    }
}

struct EditDriverSheet: View {
    @Binding var isPresented: Bool
    let driverManager: DriverManager
    let driver: Driver
    @Binding var driverName: String
    @Binding var kartNumber: String
    
    var body: some View {
        ZStack {
            Color(red: 0.153, green: 0.149, blue: 0.149)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                HStack {
                    Text("EDIT DRIVER")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.red)
                    
                    Spacer()
                    
                    Button(action: { isPresented = false }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                VStack(spacing: 20) {
                    VStack(spacing: 12) {
                        Text("DRIVER NAME")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.red)
                            .tracking(1.2)
                        
                        TextField("", text: $driverName)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.bottom, 12)
                            .background(
                                VStack {
                                    Spacer()
                                    LinearGradient(
                                        gradient: Gradient(colors: [.red, .red.opacity(0.5)]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                    .frame(height: 1)
                                }
                            )
                    }
                    
                    VStack(spacing: 12) {
                        Text("KART NUMBER")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.red)
                            .tracking(1.2)
                        
                        TextField("", text: $kartNumber)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.bottom, 12)
                            .background(
                                VStack {
                                    Spacer()
                                    LinearGradient(
                                        gradient: Gradient(colors: [.red, .red.opacity(0.5)]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                    .frame(height: 1)
                                }
                            )
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                Button(action: {
                    if !driverName.isEmpty && !kartNumber.isEmpty {
                        driverManager.updateDriver(id: driver.id, name: driverName, kartNumber: kartNumber)
                        isPresented = false
                    }
                }) {
                    Text("SAVE CHANGES")
                        .font(.system(size: 16, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.blue)
                        )
                        .foregroundColor(.white)
                }
                .disabled(driverName.isEmpty || kartNumber.isEmpty)
                .opacity((driverName.isEmpty || kartNumber.isEmpty) ? 0.5 : 1.0)
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
        }
    }
}

#Preview {
    ProfileView()
}

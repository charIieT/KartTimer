//
//  ContentView.swift
//  KartTimer
//
//  Created by Charlie Taylor on 13/12/2025.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var showSplash = true
    
    var body: some View {
        ZStack {
            Color(red: 0.153, green: 0.149, blue: 0.149)
                .ignoresSafeArea()
            
            if showSplash {
                VStack {
                    Spacer()
                    Image("Logo")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 80)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(red: 0.153, green: 0.149, blue: 0.149))
                .transition(.opacity)
            } else {
                TabView(selection: $selectedTab) {
                    HomeView()
                        .tag(0)
                        .tabItem {
                            Label("Home", systemImage: "house.fill")
                        }
                     
                    MultipleView()
                        .tag(1)
                        .tabItem {
                            Label("Multiple", systemImage: "list.bullet")
                        }
                    
                    LogsView()
                        .tag(2)
                        .tabItem {
                            Label("Logs", systemImage: "doc.text.fill")
                        }
                    
                    ProfileView()
                        .tag(3)
                        .tabItem {
                            Label("Drivers", systemImage: "person.fill")
                        }
                }
                .tint(.white)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showSplash = false
                }
            }
        }
    }
}

#Preview {
    ContentView()
}

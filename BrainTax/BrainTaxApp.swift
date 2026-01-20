//
//  BrainTaxApp.swift
//  BrainTax
//
//  Created by Samantha Lee on 1/13/26.
//

import SwiftUI

@main
struct BrainTaxApp: App {
    var body: some Scene {
        WindowGroup {
            TabView {
                HomeView()
                    .tabItem {
                        Label("Apps", systemImage: "square.grid.2x2.fill")
                    }

                ContentView()
                    .tabItem {
                        Label("Practice", systemImage: "puzzlepiece.fill")
                    }

                NavigationView {
                    DNSSettingsView()
                }
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
            }
        }
    }
}

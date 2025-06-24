//
//  ContentView.swift
//  miniGPTdesktop
//
//  Created by El Gato on 20.06.2025.
//

import SwiftUI

struct ContentView: View {
    init() {
            let _ = ChatStorage.shared
        }
    var body: some View {
        TabView {
            ChatView()
                .tabItem {
                    Label("Chat", systemImage: "bubble.left.and.bubble.right")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }

            AboutView()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .frame(minWidth: 700, minHeight: 750)
    }
}

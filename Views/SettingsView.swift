//
//  SettingsView.swift
//  miniGPTdesktop
//
//  Created by El Gato on 23.06.2025.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("apiKey") private var apiKey: String = ""
    @AppStorage("openRouterKey") private var openRouterKey: String = ""

    var body: some View {
        Form {
            Section(header: Text("OpenAI API Key")) {
                SecureField("Enter your API key", text: $apiKey)
                Link("Get an API key", destination: URL(string: "https://platform.openai.com/account/api-keys")!)
            }
            Section(header: Text("OpenRouter API Key")) {
                SecureField("Enter your OpenRouter key", text: $openRouterKey)
                Link("Get an OpenRouter key", destination: URL(string: "https://openrouter.ai/keys")!)
            }

            // Here we can later add HuggingFace, OpenRouter, etc.
        }
        .padding()
    }
}

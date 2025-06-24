//
//  ChatView.swift
//  miniGPTdesktop
//
//  Created by El Gato on 23.06.2025.
//

import SwiftUI

enum Provider: String, CaseIterable, Identifiable {
    case openai = "OpenAI"
    case openrouter = "OpenRouter"

    var id: String { self.rawValue }
}

enum AIProvider: String, CaseIterable, Identifiable {
    case openai = "OpenAI"
    case openrouter = "OpenRouter"
    
    var id: String { self.rawValue }
}

struct ChatView: View {
    @AppStorage("apiKey") private var apiKey: String = ""
    @AppStorage("openRouterKey") private var openRouterKey: String = ""

    @State private var prompt: String = ""
    @State private var response: String = ""
    @State private var error: String = ""

    @State private var selectedProvider: AIProvider = .openai

    let modelOptions: [AIProvider: [String]] = [
        .openai: ["gpt-3.5-turbo", "gpt-4", "gpt-4o"],
        .openrouter: [
            "mistralai/mistral-small-3.2", "mistralai/devstral-small",
            "microsoft/phi-4-reasoning-plus", "google/gemma-3b",
            "deepseek/deepseek-8b", "deepseek/deepseek-52b",
            "sarvamai/sarvam-mistral", "openchat/openchat-3.5",
            "meta-llama/llama-3-8b-instruct", "moonshot/moonshot-72b-chat"
        ]
    ]

    
    @State private var selectedModel: String = "gpt-3.5-turbo"

    let openAIModels = ["gpt-3.5-turbo", "gpt-4", "gpt-4o"]
    let openRouterModels = [
       // "openchat/openchat-3.5",
        "mistralai/mistral-7b-instruct",
        "meta-llama/llama-3-8b-instruct"
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("Provider", selection: $selectedProvider) {
                ForEach(AIProvider.allCases) { provider in
                    Text(provider.rawValue).tag(provider)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .onChange(of: selectedProvider) { newProvider in
                selectedModel = modelOptions[newProvider]?.first ?? ""
            }


            Picker("Model", selection: $selectedModel) {
                ForEach(selectedProvider == .openai ? openAIModels : openRouterModels, id: \.self) { model in
                    Text(model).tag(model)
                }
            }
            .pickerStyle(MenuPickerStyle())

            Button("Test connection") {
                testConnection()
            }

            Text("Prompt:")
            TextEditor(text: $prompt)
                .frame(height: 150)
                .border(Color.gray)

            Button("Send") {
                sendPrompt()
            }

            Text("Response:")
            ScrollView {
                TextEditor(text: Binding(
                    get: { response },
                    set: { _ in }
                ))
                .font(.body)
                .frame(height: 200)
                .border(Color.green)
            }

            Text("Errors:")
            ScrollView {
                TextEditor(text: Binding(
                    get: { error },
                    set: { _ in }
                ))
                .font(.body)
                .foregroundColor(.red)
                .frame(height: 100)
                .border(Color.red)
            }
        }
        .padding()
    }

    func testConnection() {
        let (url, authHeader) = makeURLAndHeader()

        var request = URLRequest(url: url)
        request.setValue(authHeader, forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"

        URLSession.shared.dataTask(with: request) { data, _, err in
            DispatchQueue.main.async {
                if let err = err {
                    error = err.localizedDescription
                } else if let data = data {
                    error = ""
                    response = String(data: data, encoding: .utf8) ?? "Unable to read response"
                }
            }
        }.resume()
    }

    func sendPrompt() {
        let (url, authHeader) = makeURLAndHeader()

        guard !authHeader.isEmpty else {
            error = "Missing API key"
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(authHeader, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": selectedModel,
            "messages": [["role": "user", "content": prompt]]
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, _, err in
            DispatchQueue.main.async {
                if let err = err {
                    error = err.localizedDescription
                    return
                }

                guard let data = data else {
                    error = "No data received"
                    return
                }

                do {
                    let result = try JSONDecoder().decode(OpenAIResponse.self, from: data)
                    response = result.choices.first?.message.content ?? "No response"
                    error = ""
                    // 💾 Сохраняем оба сообщения
                    ChatStorage.shared.saveMessage(role: "user", content: prompt, model: selectedModel)
                    ChatStorage.shared.saveMessage(role: "assistant", content: response, model: selectedModel)

                } catch {
                    self.error = "Error: \(error.localizedDescription)\n\(String(data: data, encoding: .utf8) ?? "")"
                }
            }
        }.resume()
    }

    func makeURLAndHeader() -> (URL, String) {
        switch selectedProvider {
        case .openai:
            return (URL(string: "https://api.openai.com/v1/chat/completions")!, "Bearer \(apiKey)")
        case .openrouter:
            return (URL(string: "https://openrouter.ai/api/v1/chat/completions")!, "Bearer \(openRouterKey)")
        }
    }
}

struct OpenAIResponse: Codable {
    struct Choice: Codable {
        struct Message: Codable {
            let role: String
            let content: String
        }
        let message: Message
    }
    let choices: [Choice]
}

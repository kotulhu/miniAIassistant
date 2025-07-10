//
//  ChatView.swift
//  miniGPTdesktop
//
//  Created by El Gato on 23.06.2025.
//
import SwiftUI

struct ChatView: View {
    //@AppStorage("providerId") private var selectedProviderId: String = "openai"
    //@AppStorage("apiKey") private var apiKey: String = ""
    
    @State private var selectedModel: String = ""
    @State private var prompt: String = ""
    @State private var response: String = ""
    @State private var error: String = ""
    
    // Храним выбранного провайдера как строку (id)
    @AppStorage("selectedProviderId") private var selectedProviderId: String = "openai"
    
    // Получаем список провайдеров из реестра
    let providers = AIProviderRegistry.shared.providers // сделай providers публичным или добавь публичный геттер
    
    
    var body: some View {
        let currentProvider = AIProviderRegistry.shared.getConfig(for: selectedProviderId)
        
        VStack(alignment: .leading, spacing: 12) {
            Picker("Provider", selection: $selectedProviderId) {
                ForEach(AIProviderRegistry.shared.providers, id: \.id) { provider in
                    Text(provider.name).tag(provider.id)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            
            if let provider = currentProvider {
                Picker("Model", selection: $selectedModel) {
                    ForEach(provider.supportedModels, id: \.self) { model in
                        Text(model).tag(model)
                    }
                }
                .pickerStyle(MenuPickerStyle())
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
                TextEditor(text: Binding(get: { response }, set: { _ in }))
                    .font(.body)
                    .frame(height: 200)
                    .border(Color.green)
            }
            
            Text("Errors:")
            ScrollView {
                TextEditor(text: Binding(get: { error }, set: { _ in }))
                    .font(.body)
                    .foregroundColor(.red)
                    .frame(height: 100)
                    .border(Color.red)
            }
        }
        .padding()
        .onAppear {
            if let provider = currentProvider {
                selectedModel = provider.defaultModel
            }
        }
        .onChange(of: selectedProviderId) { newValue in
            if let provider = AIProviderRegistry.shared.getConfig(for: newValue) {
                selectedModel = provider.defaultModel
            }
        }
    }
    
    
    
    func sendPrompt() {
        guard let providerConfig = AIProviderRegistry.shared.getConfig(for: selectedProviderId) else {
            error = "Provider config not found"
            return
        }

        let chatId: Int64 = 1
        // Загружаем историю сообщений из базы
        let messages = ChatStorage.shared.loadMessages(forChatId: chatId)
        
        // Генерируем массив сообщений с учётом истории и сжатия
        let finalMessages = ChatUtils.generateContextualMessages(
            messages: messages,
            currentPrompt: prompt,
            providerConfig: providerConfig,
            model: selectedModel,
            apiKey: providerConfig.apiKey
        )

        
        let url = providerConfig.apiURL
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(providerConfig.apiKey)", forHTTPHeaderField: "Authorization")

        let body: [String: Any] = [
            "model": selectedModel,
            "messages": finalMessages
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

                    // Сохраняем сообщения в базу
                    ChatStorage.shared.saveMessage(role: "user", content: prompt, model: selectedModel)
                    ChatStorage.shared.saveMessage(role: "assistant", content: response, model: selectedModel)

                } catch {
                    DispatchQueue.main.async {
                        self.error = "Error: \(error.localizedDescription)\n\(String(data: data, encoding: .utf8) ?? "")"
                    }
                }

            }
        }.resume()
    }


    
}

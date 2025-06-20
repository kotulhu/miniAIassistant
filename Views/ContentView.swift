//
//  ContentView.swift
//  miniGPTdesktop
//
//  Created by El Gato on 20.06.2025.
//

import SQLite3
import SwiftUI

struct ContentView: View {
    @AppStorage("apiKey") private var apiKey: String = ""
    @State private var prompt: String = ""
    @State private var response: String = ""
    @State private var error: String = ""
    @State private var balance: String = ""
    @State private var generatedImage: NSImage? = nil
    
    @State private var selectedModel = "gpt-3.5-turbo"
    let models = ["gpt-3.5-turbo", "gpt-4", "gpt-4o"]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SecureField("API Key", text: $apiKey)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button("Сохранить") {}
            }

            Button("Тест соединения") {
                testConnection()
            }

            Picker("Модель", selection: $selectedModel) {
                ForEach(models, id: \ .self) { model in
                    Text(model).tag(model)
                }
            }.pickerStyle(SegmentedPickerStyle())

            Text("Запрос:")
            TextEditor(text: $prompt)
                .frame(height: 150)
                .border(Color.gray)

            Button("Отправить запрос") {
                sendPrompt()
            }

            Text("Ответ:")
            ScrollView {
                TextEditor(text: Binding(
                    get: { response },
                    set: { _ in } // игнорируем попытки редактирования
                ))
                .font(.body)
                .frame(height: 200)
                .border(Color.green)
            }
            .frame(height: 200)
            .border(Color.green)

            Text("Ошибки:")
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
            .frame(height: 100)
            .border(Color.red)
        }
        .padding()
        .frame(minWidth: 700, minHeight: 750)
    }

    func testConnection() {
        guard !apiKey.isEmpty else {
            error = "Введите API ключ"
            return
        }

        var request = URLRequest(url: URL(string: "https://api.openai.com/v1/models")!)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"

        URLSession.shared.dataTask(with: request) { data, _, err in
            DispatchQueue.main.async {
                if let err = err {
                    error = err.localizedDescription
                } else if let data = data {
                    error = ""
                    response = String(data: data, encoding: .utf8) ?? "Не удалось прочитать ответ"
                }
            }
        }.resume()

        
    }




    func sendPrompt() {
        guard !apiKey.isEmpty else {
            error = "Введите API ключ"
            return
        }

        var messages = ChatStorage.shared.loadMessages()
        var summary: String? = nil

        // Если сообщений больше 20 — сжимаем историю
        if messages.count > 20 {
            let toSummarize = Array(messages.prefix(messages.count - 10))

            // Превращаем в string
            let textToSummarize = toSummarize.map {
                "\($0["role"] ?? ""): \($0["content"] ?? "")"
            }.joined(separator: "\n")

            summary = generateSummary(from: textToSummarize)
        }

        // Берем последние 10 сообщений
        var limitedMessages = Array(messages.suffix(10))

        // Добавляем сжатую историю как system
        if let summary = summary {
            limitedMessages.insert(["role": "system", "content": "Контекст предыдущего диалога: \(summary)"], at: 0)
        }

        // Добавляем текущий вопрос
        limitedMessages.append(["role": "user", "content": prompt])

        // Готовим запрос
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": selectedModel,
            "messages": limitedMessages
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, _, err in
            DispatchQueue.main.async {
                if let err = err {
                    error = err.localizedDescription
                    return
                }

                guard let data = data else {
                    error = "Нет данных"
                    return
                }

                do {
                    let result = try JSONDecoder().decode(OpenAIResponse.self, from: data)
                    response = result.choices.first?.message.content ?? "Нет ответа"
                    error = ""

                    // Сохраняем оба сообщения
                    ChatStorage.shared.saveMessage(role: "user", content: prompt, model: selectedModel)
                    ChatStorage.shared.saveMessage(role: "assistant", content: response, model: selectedModel)

                } catch {
                    self.error = "Ошибка: \(error.localizedDescription)\n\(String(data: data, encoding: .utf8) ?? "")"
                }
            }
        }.resume()
    }

    func generateSummary(from text: String) -> String? {
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let summaryPrompt = [
            ["role": "system", "content": "Ты помощник, который умеет сжимать переписку в краткое содержание."],
            ["role": "user", "content": "Сожми следующую переписку в краткий абзац для подстановки в system-промт:\n\n\(text)"]
        ]

        let body: [String: Any] = [
            "model": selectedModel,
            "messages": summaryPrompt
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        var resultSummary: String? = nil
        let group = DispatchGroup()
        group.enter()

        URLSession.shared.dataTask(with: request) { data, _, err in
            defer { group.leave() }

            if let data = data,
               let result = try? JSONDecoder().decode(OpenAIResponse.self, from: data),
               let summary = result.choices.first?.message.content {
                resultSummary = summary
            } else {
                print("❌ Не удалось получить summary")
            }
        }.resume()

        group.wait()
        return resultSummary
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


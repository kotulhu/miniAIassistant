//
//  ProviderConfig.swift
//  miniGPTdesktop
//
//  Created by El Gato on 24.06.2025.
//

import Foundation

struct ProviderConfig {
    let id: String
    let name: String
    let apiKey: String
    let apiURL: URL
    let summarizationURL: URL?
    let supportsSummarization: Bool
    let defaultModel: String
    let supportedModels: [String]

    // 🔹 Добавляем alias, чтобы не переписывать sendPrompt()
    var chatURL: URL {
        return apiURL
    }

    // 🔹 Добавим флаг (можно объединить с supportsSummarization, если хочешь)
    var supportsContext: Bool {
        return supportsSummarization && summarizationURL != nil
    }

    // 🔹 Метод генерации summary
    func generateSummary(text: String, apiKey: String) -> String? {
        guard supportsSummarization, let summaryURL = summarizationURL else {
            return nil
        }

        var request = URLRequest(url: summaryURL)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let summaryPrompt: [[String: String]] = [
            ["role": "system", "content": "You are a helpful assistant that summarizes conversation history."],
            ["role": "user", "content": "Summarize the following conversation into a concise context paragraph:\n\n\(text)"]
        ]

        let body: [String: Any] = [
            "model": defaultModel,
            "messages": summaryPrompt
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        var resultSummary: String? = nil
        let group = DispatchGroup()
        group.enter()

        URLSession.shared.dataTask(with: request) { data, _, error in
            defer { group.leave() }

            guard
                error == nil,
                let data = data,
                let decoded = try? JSONDecoder().decode(OpenAIResponse.self, from: data),
                let summary = decoded.choices.first?.message.content
            else {
                return
            }

            resultSummary = summary
            
            print("📌 Summary text:\n\(summary)")

        }.resume()

        group.wait()
        return resultSummary
    }
}

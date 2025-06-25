//
//  ChatUtils.swift
//  miniGPTdesktop
//
//  Created by El Gato on 24.06.2025.
//

import Foundation

struct ChatUtils {
    
    static func generateContextualMessages(
        messages: [[String: String]],
        currentPrompt: String,
        providerConfig: ProviderConfig,
        model: String,
        apiKey: String
    ) -> [[String: String]] {
        var finalMessages = messages
        var summaryText: String? = nil
        
        // Провайдер поддерживает контекст и есть достаточно сообщений
        if providerConfig.supportsContext && messages.count > 10 {
            let toSummarize = Array(messages.prefix(messages.count - 10))
            let recent = Array(messages.suffix(10))

            let textToSummarize = toSummarize.map {
                "\($0["role"] ?? ""): \($0["content"] ?? "")"
            }.joined(separator: "\n")

            summaryText = providerConfig.generateSummary(text: textToSummarize, apiKey: apiKey)

            finalMessages = recent
        } else {
            // Если не поддерживает контекст или сообщений мало — оставляем последние
            finalMessages = Array(messages.suffix(10))
        }

        // Если есть summary — вставляем system-сообщение
        if let summary = summaryText {
            finalMessages.insert([
                "role": "system",
                "content": "Context summary: \(summary)"
            ], at: 0)
        }

        // Добавляем текущий prompt
        finalMessages.append([
            "role": "user",
            "content": currentPrompt
        ])

        return finalMessages
    }
}

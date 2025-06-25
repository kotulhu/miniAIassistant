//
//  AIProviderRegistry.swift
//  miniGPTdesktop
//
//  Created by El Gato on 24.06.2025.
//

import Foundation

class AIProviderRegistry {
    static let shared = AIProviderRegistry()

    var providers: [String: ProviderConfig] = [:]

    private init() {
        // OpenAI
        if let key = UserDefaults.standard.string(forKey: "apiKey") {
            providers["openai"] = ProviderConfig(
                id: "openai",
                name: "OpenAI",
                apiKey: key,
                apiURL: URL(string: "https://api.openai.com/v1/chat/completions")!,
                summarizationURL: URL(string: "https://api.openai.com/v1/chat/completions"),
                supportsSummarization: true,
                defaultModel: "gpt-3.5-turbo",
                supportedModels: ["gpt-3.5-turbo", "gpt-4", "gpt-4o"]
            )
        }

        // OpenRouter
        if let key = UserDefaults.standard.string(forKey: "openRouterKey") {
            providers["openrouter"] = ProviderConfig(
                id: "openrouter",
                name: "OpenRouter",
                apiKey: key,
                apiURL: URL(string: "https://openrouter.ai/api/v1/chat/completions")!,
                summarizationURL: nil,
                supportsSummarization: false,
                defaultModel: "mistralai/mistral-small-3.2",
                supportedModels: [
                    "mistralai/mistral-small-3.2",
                    "mistralai/devstral-small",
                    "meta-llama/llama-3-8b-instruct",
                    "moonshot/moonshot-72b-chat",
                    "deepseek/deepseek-8b"
                ]
            )
        }
    }

    func getConfig(for id: String) -> ProviderConfig? {
        return providers[id]
    }
    
    // Добавляем публичный массив значений для ForEach
    var providersList: [ProviderConfig] {
        return Array(providers.values)
    }
}

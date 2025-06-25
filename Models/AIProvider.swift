//
//  AIProvider.swift
//  miniGPTdesktop
//
//  Created by El Gato on 24.06.2025.
//

import Foundation

struct AIProviderConfig {
    let id: String
    let displayName: String
    let apiURL: URL
    let authURL: URL
    let models: [String]
    let defaultModel: String
    let supportsContext: Bool
    let customHeaderName: String // Authorization, HTTP-Authorization, etc.
    let requiresAuthHeader: Bool
}

class AIProviderRegistry {
    static let shared = AIProviderRegistry()

    let providers: [AIProviderConfig] = [
        AIProviderConfig(
            id: "openai",
            displayName: "OpenAI",
            apiURL: URL(string: "https://api.openai.com/v1/chat/completions")!,
            authURL: URL(string: "https://platform.openai.com/account/api-keys")!,
            models: ["gpt-3.5-turbo", "gpt-4", "gpt-4o"],
            defaultModel: "gpt-3.5-turbo",
            supportsContext: true,
            customHeaderName: "Authorization",
            requiresAuthHeader: true
        ),
        AIProviderConfig(
            id: "openrouter",
            displayName: "OpenRouter",
            apiURL: URL(string: "https://openrouter.ai/api/v1/chat/completions")!,
            authURL: URL(string: "https://openrouter.ai/keys")!,
            models: [
                "mistralai/mistral-7b-instruct",
                "openchat/openchat-3.5-1210",
                "mistralai/mixtral-8x7b",
                "meta-llama/llama-3-8b-instruct"
            ],
            defaultModel: "openchat/openchat-3.5-1210",
            supportsContext: true,
            customHeaderName: "HTTP-Authorization",
            requiresAuthHeader: true
        )
    ]

    func getConfig(for id: String) -> AIProviderConfig? {
        providers.first { $0.id == id }
    }
}

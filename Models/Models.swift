//
//  Models.swift
//  miniGPTdesktop
//
//  Created by El Gato on 24.06.2025.
//

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

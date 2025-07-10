//
//  AIProviderRegistry.swift
//  miniGPTdesktop
//
//  Created by El Gato on 24.06.2025.
//

import Foundation

class AIProviderRegistry {
    static let shared = AIProviderRegistry()
    
    private(set) var providers: [ProviderConfig] = []
    

    private init() {
        loadProvidersFromJSON()
    }

    private func loadProvidersFromJSON() {
        guard let url = Bundle.main.url(forResource: "providers", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let parsed = try? JSONDecoder().decode(ProviderList.self, from: data) else {
            print("⚠️ Failed to load or parse providers.json")
            return
        }
        self.providers = parsed.providers
    }

    func getConfig(for id: String) -> ProviderConfig? {
        return providers.first { $0.id == id }
    }

    struct ProviderList: Codable {
        let providers: [ProviderConfig]
    }
}


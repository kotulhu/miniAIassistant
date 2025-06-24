//
//  AboutView.swift
//  miniGPTdesktop
//
//  Created by El Gato on 23.06.2025.
//

import SwiftUI

struct AboutView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("GPT Assistant")
                .font(.largeTitle)
                .bold()

            Text("A minimalist macOS app for working with GPT-based APIs, including OpenAI and OpenRouter.")
                .font(.body)

            Divider()

            if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
               let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
                Text("Version \(version) (Build \(build))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Text("khtulhu.org.ua")
                .font(.footnote)
                .padding(.top, 8)

            Spacer()
        }
        .padding()
    }
}

#Preview {
    AboutView()
}

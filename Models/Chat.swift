//
//  Chat.swift
//  miniGPTdesktop
//
//  Created by El Gato on 21.06.2025.
//

import Foundation

struct Chat: Identifiable {
    let id: Int64
    var title: String
    var model: String
    var systemPrompt: String
    var createdAt: Date
}

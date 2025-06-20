//
//  Message.swift
//  miniGPTdesktop
//
//  Created by El Gato on 21.06.2025.
//

import Foundation

struct Message: Identifiable {
    let id: Int64
    var chatId: Int64
    var role: String // "user", "assistant", "system"
    var content: String
    var timestamp: Date
}

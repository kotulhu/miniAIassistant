//
//  ChatStorage.swift
//  miniGPTdesktop
//
//  Created by El Gato on 21.06.2025.
//

import Foundation
import SQLite3

class ChatStorage {
    static let shared = ChatStorage()
    
    private let dbURL: URL
    private var db: OpaquePointer?
    
    private init() {
        let fm = FileManager.default
        let supportDir = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = supportDir.appendingPathComponent("miniGPTdesktop", isDirectory: true)

        try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        dbURL = dir.appendingPathComponent("chats.sqlite3")

        openDatabase()
        createTables()
    }

    private func openDatabase() {
        if sqlite3_open(dbURL.path, &db) != SQLITE_OK {
            print("❌ Не удалось открыть базу данных")
        }
    }

    private func createTables() {
        let createChatTable = """
        CREATE TABLE IF NOT EXISTS chats (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP
        );
        """
        let createMessagesTable = """
        CREATE TABLE IF NOT EXISTS messages (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            chat_id INTEGER NOT NULL,
            role TEXT NOT NULL,
            content TEXT NOT NULL,
            model TEXT NOT NULL,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY(chat_id) REFERENCES chats(id)
        );
        """

        if sqlite3_exec(db, createChatTable, nil, nil, nil) != SQLITE_OK {
            print("❌ Ошибка создания таблицы чатов")
        }

        if sqlite3_exec(db, createMessagesTable, nil, nil, nil) != SQLITE_OK {
            print("❌ Ошибка создания таблицы сообщений")
        }
    }

    // Пока один чат по умолчанию (id = 1), потом сделаем выбор
    func saveMessage(role: String, content: String, model: String) {
        let chatId: Int64 = 1

        let insert = """
        INSERT INTO messages (chat_id, role, content, model)
        VALUES (?, ?, ?, ?);
        """

        var stmt: OpaquePointer?
        if sqlite3_prepare_v2(db, insert, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_int64(stmt, 1, chatId)
            sqlite3_bind_text(stmt, 2, (role as NSString).utf8String, -1, nil)
            sqlite3_bind_text(stmt, 3, (content as NSString).utf8String, -1, nil)
            sqlite3_bind_text(stmt, 4, (model as NSString).utf8String, -1, nil)

            if sqlite3_step(stmt) != SQLITE_DONE {
                print("❌ Ошибка вставки сообщения")
            }
        } else {
            print("❌ Ошибка подготовки запроса")
        }

        sqlite3_finalize(stmt)
    }

    func loadMessages(forChatId chatId: Int64 = 1) -> [[String: String]] {
        let query = """
        SELECT role, content FROM messages
        WHERE chat_id = ?
        ORDER BY id ASC;
        """

        var stmt: OpaquePointer?
        var result: [[String: String]] = []

        if sqlite3_prepare_v2(db, query, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_int64(stmt, 1, chatId)

            while sqlite3_step(stmt) == SQLITE_ROW {
                if let roleCStr = sqlite3_column_text(stmt, 0),
                   let contentCStr = sqlite3_column_text(stmt, 1) {
                    let role = String(cString: roleCStr)
                    let content = String(cString: contentCStr)
                    result.append(["role": role, "content": content])
                }
            }
        } else {
            print("❌ Ошибка выборки сообщений")
        }

        sqlite3_finalize(stmt)
        return result
    }

    
}

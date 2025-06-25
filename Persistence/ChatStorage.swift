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
        let fileManager = FileManager.default
        let supportDir = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appSupportDir = supportDir.appendingPathComponent("miniGPTdesktop", isDirectory: true)
        
        do {
            try fileManager.createDirectory(at: appSupportDir, withIntermediateDirectories: true)
        } catch {
            print("❌ Не удалось создать директорию: \(error)")
        }
        
        dbURL = appSupportDir.appendingPathComponent("chats.sqlite3")
        print("📁 База данных будет по пути:", dbURL.path)
        
        openDatabase()
        createTables()
        testInsert()
    }

    private func openDatabase() {
        if sqlite3_open(dbURL.path, &db) != SQLITE_OK {
            print("❌ Не удалось открыть базу данных")
        } else {
            print("✅ База данных открыта")
        }
    }

    private func createTables() {
        let createChats = """
        CREATE TABLE IF NOT EXISTS chats (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP
        );
        """

        let createMessages = """
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

        if sqlite3_exec(db, createChats, nil, nil, nil) != SQLITE_OK {
            print("❌ Ошибка при создании таблицы chats")
        }

        if sqlite3_exec(db, createMessages, nil, nil, nil) != SQLITE_OK {
            print("❌ Ошибка при создании таблицы messages")
        }

        print("✅ Таблицы созданы или уже существуют")
    }

    private func testInsert() {
        let insertSQL = """
        INSERT INTO messages (chat_id, role, content, model)
        VALUES (1, 'system', 'Привет из теста', 'gpt-3.5-turbo');
        """

        if sqlite3_exec(db, insertSQL, nil, nil, nil) != SQLITE_OK {
            print("❌ Ошибка вставки тестового сообщения")
        } else {
            print("✅ Тестовое сообщение вставлено")
        }
    }
    func saveMessage(role: String, content: String, model: String, chatId: Int64 = 1) {
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
                print("❌ Failed to insert message")
            }
        } else {
            print("❌ Failed to prepare insert statement")
        }

        sqlite3_finalize(stmt)
    }
    
    func loadMessages(forChatId chatId: Int64) -> [[String: String]] {
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
            print("❌ Failed to prepare message query")
        }

        sqlite3_finalize(stmt)
        return result
    }


}

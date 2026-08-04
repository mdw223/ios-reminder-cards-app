import Foundation
import GRDB
import SwiftUI

class DatabaseManager: ObservableObject {
    static let shared = DatabaseManager()
    
    @Published var isInitialized = false
    private var dbQueue: DatabaseQueue?
    
    private init() {}
    
    func initializeDatabase() {
        do {
            let fileManager = FileManager.default
            let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let databasePath = documentsPath.appendingPathComponent("ReminderCards.sqlite")
            
            var config = Configuration()
            config.foreignKeys = true
            
            dbQueue = try DatabaseQueue(path: databasePath.path, configuration: config)
            
            try dbQueue?.write { db in
                try createTables(db: db)
                try createDefaultFolders(db: db)
            }
            
            isInitialized = true
        } catch {
            print("Database initialization error: \(error)")
        }
    }
    
    private func createTables(db: Database) throws {
        // Create Notification table first (referenced by other tables)
        try db.execute(sql: """
            CREATE TABLE IF NOT EXISTS Notification (
                notificationId INTEGER PRIMARY KEY AUTOINCREMENT,
                message TEXT NOT NULL,
                recurrenceRule TEXT,
                timeOfDay TEXT NOT NULL,
                isEnabled INTEGER DEFAULT 1,
                createdDateTime TEXT NOT NULL
            )
        """)
        
        // Create Card table
        try db.execute(sql: """
            CREATE TABLE IF NOT EXISTS Card (
                cardId INTEGER PRIMARY KEY AUTOINCREMENT,
                text TEXT NOT NULL,
                isFavorite INTEGER DEFAULT 0,
                notificationId INTEGER,
                createdDateTime TEXT NOT NULL,
                FOREIGN KEY (notificationId) REFERENCES Notification(notificationId)
            )
        """)
        
        // Create Folder table
        try db.execute(sql: """
            CREATE TABLE IF NOT EXISTS Folder (
                folderId INTEGER PRIMARY KEY AUTOINCREMENT,
                title TEXT NOT NULL,
                isDefault INTEGER DEFAULT 0,
                isFavorites INTEGER DEFAULT 0,
                isActiveFolder INTEGER DEFAULT 0,
                notificationId INTEGER,
                createdDateTime TEXT NOT NULL,
                FOREIGN KEY (notificationId) REFERENCES Notification(notificationId)
            )
        """)
        
        // Create FolderCard junction table
        try db.execute(sql: """
            CREATE TABLE IF NOT EXISTS FolderCard (
                folderCardId INTEGER PRIMARY KEY AUTOINCREMENT,
                cardId INTEGER NOT NULL,
                folderId INTEGER NOT NULL,
                addedDateTime TEXT NOT NULL,
                FOREIGN KEY (cardId) REFERENCES Card(cardId) ON DELETE CASCADE,
                FOREIGN KEY (folderId) REFERENCES Folder(folderId) ON DELETE CASCADE,
                UNIQUE(cardId, folderId)
            )
        """)
    }
    
    private func createDefaultFolders(db: Database) throws {
        // Check if default folders already exist
        let existingFolders = try Folder.fetchCount(db)
        
        if existingFolders == 0 {
            // Create Default folder
            let defaultFolder = Folder(
                title: "Default",
                isDefault: true,
                isFavorites: false,
                isActiveFolder: true
            )
            try defaultFolder.insert(db)
            
            // Create Favorites folder
            let favoritesFolder = Folder(
                title: "Favorites",
                isDefault: false,
                isFavorites: true,
                isActiveFolder: false
            )
            try favoritesFolder.insert(db)
        }
    }
    
    func getDatabaseQueue() -> DatabaseQueue? {
        return dbQueue
    }
}


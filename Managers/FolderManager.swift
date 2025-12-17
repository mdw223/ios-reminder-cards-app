import Foundation
import GRDB
import SwiftUI

class FolderManager: ObservableObject {
    @Published var folders: [Folder] = []
    @Published var activeFolder: Folder?
    
    private let databaseManager = DatabaseManager.shared
    
    init() {
        loadFolders()
    }
    
    func loadFolders() {
        folders = getAllFolders()
        activeFolder = getActiveFolder()
    }
    
    func getAllFolders() -> [Folder] {
        guard let dbQueue = databaseManager.getDatabaseQueue() else { return [] }
        
        do {
            return try dbQueue.read { db in
                return try Folder
                    .order(Column("createdDateTime").asc)
                    .fetchAll(db)
            }
        } catch {
            print("Error fetching folders: \(error)")
            return []
        }
    }
    
    func getActiveFolder() -> Folder? {
        guard let dbQueue = databaseManager.getDatabaseQueue() else { return nil }
        
        do {
            return try dbQueue.read { db in
                return try Folder
                    .filter(Column("isActiveFolder") == 1)
                    .fetchOne(db)
            }
        } catch {
            print("Error fetching active folder: \(error)")
            return nil
        }
    }
    
    func createFolder(title: String) -> Folder? {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return nil }
        guard let dbQueue = databaseManager.getDatabaseQueue() else { return nil }
        
        do {
            var newFolder: Folder?
            try dbQueue.write { db in
                let folder = Folder(title: trimmedTitle)
                try folder.insert(db)
                newFolder = folder
            }
            
            if newFolder != nil {
                loadFolders()
            }
            
            return newFolder
        } catch {
            print("Error creating folder: \(error)")
            return nil
        }
    }
    
    func deleteFolder(folderId: Int64) -> Bool {
        guard let dbQueue = databaseManager.getDatabaseQueue() else { return false }
        
        do {
            // Check if it's Default or Favorites folder - prevent deletion
            let folder = try dbQueue.read { db in
                return try Folder.fetchOne(db, key: folderId)
            }
            
            guard let folder = folder else { return false }
            
            if folder.isDefault || folder.isFavorites {
                print("Cannot delete Default or Favorites folder")
                return false
            }
            
            try dbQueue.write { db in
                // Delete folder (FolderCard associations will be deleted via CASCADE)
                try Folder.deleteOne(db, key: folderId)
            }
            
            loadFolders()
            return true
        } catch {
            print("Error deleting folder: \(error)")
            return false
        }
    }
    
    func setActiveFolder(folderId: Int64) -> Bool {
        guard let dbQueue = databaseManager.getDatabaseQueue() else { return false }
        
        do {
            try dbQueue.write { db in
                // Set all folders to inactive
                let allFolders = try Folder.fetchAll(db)
                for var folder in allFolders {
                    folder.isActiveFolder = false
                    try folder.update(db)
                }
                
                // Set selected folder to active
                if var folder = try Folder.fetchOne(db, key: folderId) {
                    folder.isActiveFolder = true
                    try folder.update(db)
                }
            }
            
            loadFolders()
            return true
        } catch {
            print("Error setting active folder: \(error)")
            return false
        }
    }
    
    func addCardToFolder(cardId: Int64, folderId: Int64) -> Bool {
        guard let dbQueue = databaseManager.getDatabaseQueue() else { return false }
        
        do {
            try dbQueue.write { db in
                // Check if association already exists
                let existing = try FolderCard
                    .filter(Column("cardId") == cardId && Column("folderId") == folderId)
                    .fetchOne(db)
                
                if existing == nil {
                    let folderCard = FolderCard(cardId: cardId, folderId: folderId)
                    try folderCard.insert(db)
                }
            }
            
            return true
        } catch {
            print("Error adding card to folder: \(error)")
            return false
        }
    }
    
    func removeCardFromFolder(cardId: Int64, folderId: Int64) -> Bool {
        guard let dbQueue = databaseManager.getDatabaseQueue() else { return false }
        
        do {
            try dbQueue.write { db in
                try FolderCard
                    .filter(Column("cardId") == cardId && Column("folderId") == folderId)
                    .deleteAll(db)
            }
            
            return true
        } catch {
            print("Error removing card from folder: \(error)")
            return false
        }
    }
    
    func getCardsInFolder(folderId: Int64) -> [Card] {
        guard let dbQueue = databaseManager.getDatabaseQueue() else { return [] }
        
        do {
            return try dbQueue.read { db in
                let sql = """
                    SELECT Card.* FROM Card
                    INNER JOIN FolderCard ON Card.cardId = FolderCard.cardId
                    WHERE FolderCard.folderId = ?
                    ORDER BY Card.createdDateTime DESC
                """
                
                return try Card.fetchAll(db, sql: sql, arguments: [folderId])
            }
        } catch {
            print("Error fetching cards in folder: \(error)")
            return []
        }
    }
    
    func getFavoritesFolder() -> Folder? {
        guard let dbQueue = databaseManager.getDatabaseQueue() else { return nil }
        
        do {
            return try dbQueue.read { db in
                return try Folder
                    .filter(Column("isFavorites") == 1)
                    .fetchOne(db)
            }
        } catch {
            print("Error fetching favorites folder: \(error)")
            return nil
        }
    }
    
    func getCardCount(for folderId: Int64) -> Int {
        guard let dbQueue = databaseManager.getDatabaseQueue() else { return 0 }
        
        do {
            return try dbQueue.read { db in
                return try FolderCard
                    .filter(Column("folderId") == folderId)
                    .fetchCount(db)
            }
        } catch {
            print("Error counting cards in folder: \(error)")
            return 0
        }
    }
    
    func getFoldersForCard(cardId: Int64) -> [Int64] {
        guard let dbQueue = databaseManager.getDatabaseQueue() else { return [] }
        
        do {
            return try dbQueue.read { db in
                let folderCards = try FolderCard
                    .filter(Column("cardId") == cardId)
                    .fetchAll(db)
                
                return folderCards.map { $0.folderId }
            }
        } catch {
            print("Error fetching folders for card: \(error)")
            return []
        }
    }
}


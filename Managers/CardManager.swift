import Foundation
import GRDB
import SwiftUI

class CardManager: ObservableObject {
    @Published var cards: [Card] = []
    @Published var currentIndex: Int = 0
    
    private let databaseManager = DatabaseManager.shared
    
    var currentCard: Card? {
        guard currentIndex >= 0 && currentIndex < cards.count else { return nil }
        return cards[currentIndex]
    }
    
    init() {
        loadCards()
    }
    
    func loadCards() {
        cards = getCardsFromActiveFolder()
        if currentIndex >= cards.count {
            currentIndex = max(0, cards.count - 1)
        }
    }
    
    func getAllCards(from folderId: Int64) -> [Card] {
        guard let dbQueue = databaseManager.getDatabaseQueue() else { return [] }
        
        do {
            return try dbQueue.read { db in
                // Use SQL join to get cards from folder
                let sql = """
                    SELECT Card.* FROM Card
                    INNER JOIN FolderCard ON Card.cardId = FolderCard.cardId
                    WHERE FolderCard.folderId = ?
                    ORDER BY Card.createdDateTime DESC
                """
                
                return try Card.fetchAll(db, sql: sql, arguments: [folderId])
            }
        } catch {
            print("Error fetching cards from folder: \(error)")
            return []
        }
    }
    
    func getCardsFromActiveFolder() -> [Card] {
        guard let dbQueue = databaseManager.getDatabaseQueue() else { return [] }
        
        do {
            return try dbQueue.read { db in
                // Find the active folder
                guard let activeFolder = try Folder
                    .filter(Column("isActiveFolder") == 1)
                    .fetchOne(db) else {
                    // Fallback to default folder
                    guard let defaultFolder = try Folder
                        .filter(Column("isDefault") == 1)
                        .fetchOne(db) else {
                        return []
                    }
                    return getAllCards(from: defaultFolder.folderId!)
                }
                
                return getAllCards(from: activeFolder.folderId!)
            }
        } catch {
            print("Error fetching cards from active folder: \(error)")
            return []
        }
    }
    
    func createCard(text: String, folderId: Int64) -> Card? {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        guard let dbQueue = databaseManager.getDatabaseQueue() else { return nil }
        
        do {
            var newCard: Card?
            try dbQueue.write { db in
                let card = Card(text: text.trimmingCharacters(in: .whitespacesAndNewlines))
                try card.insert(db)
                
                // Associate card with folder
                let folderCard = FolderCard(cardId: card.cardId!, folderId: folderId)
                try folderCard.insert(db)
                
                newCard = card
            }
            
            if newCard != nil {
                loadCards()
            }
            
            return newCard
        } catch {
            print("Error creating card: \(error)")
            return nil
        }
    }
    
    func updateCard(cardId: Int64, text: String) -> Bool {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
        guard let dbQueue = databaseManager.getDatabaseQueue() else { return false }
        
        do {
            try dbQueue.write { db in
                if var card = try Card.fetchOne(db, key: cardId) {
                    card.text = text.trimmingCharacters(in: .whitespacesAndNewlines)
                    try card.update(db)
                }
            }
            
            loadCards()
            return true
        } catch {
            print("Error updating card: \(error)")
            return false
        }
    }
    
    func deleteCard(cardId: Int64) -> Bool {
        guard let dbQueue = databaseManager.getDatabaseQueue() else { return false }
        
        do {
            try dbQueue.write { db in
                try Card.deleteOne(db, key: cardId)
            }
            
            loadCards()
            
            // Adjust current index if needed
            if currentIndex >= cards.count && cards.count > 0 {
                currentIndex = cards.count - 1
            } else if cards.isEmpty {
                currentIndex = 0
            }
            
            return true
        } catch {
            print("Error deleting card: \(error)")
            return false
        }
    }
    
    func toggleFavorite(cardId: Int64) -> Bool {
        guard let dbQueue = databaseManager.getDatabaseQueue() else { return false }
        
        do {
            var newFavoriteStatus = false
            try dbQueue.write { db in
                if var card = try Card.fetchOne(db, key: cardId) {
                    card.isFavorite.toggle()
                    newFavoriteStatus = card.isFavorite
                    try card.update(db)
                }
            }
            
            loadCards()
            return newFavoriteStatus
        } catch {
            print("Error toggling favorite: \(error)")
            return false
        }
    }
    
    func nextCard() {
        guard !cards.isEmpty else { return }
        
        if currentIndex < cards.count - 1 {
            currentIndex += 1
        } else {
            // Wrap around to first card
            currentIndex = 0
        }
    }
    
    func previousCard() {
        guard !cards.isEmpty else { return }
        
        if currentIndex > 0 {
            currentIndex -= 1
        } else {
            // Wrap around to last card
            currentIndex = cards.count - 1
        }
    }
    
    func getDefaultFolderId() -> Int64? {
        guard let dbQueue = databaseManager.getDatabaseQueue() else { return nil }
        
        do {
            return try dbQueue.read { db in
                guard let defaultFolder = try Folder
                    .filter(Column("isDefault") == 1)
                    .fetchOne(db) else {
                    return nil
                }
                return defaultFolder.folderId
            }
        } catch {
            print("Error fetching default folder: \(error)")
            return nil
        }
    }
}


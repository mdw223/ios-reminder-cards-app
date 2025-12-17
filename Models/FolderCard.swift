import Foundation
import GRDB

struct FolderCard: Codable {
    var folderCardId: Int64?
    var cardId: Int64
    var folderId: Int64
    var addedDateTime: String
    
    init(folderCardId: Int64? = nil, cardId: Int64, folderId: Int64, addedDateTime: String? = nil) {
        self.folderCardId = folderCardId
        self.cardId = cardId
        self.folderId = folderId
        self.addedDateTime = addedDateTime ?? ISO8601DateFormatter().string(from: Date())
    }
}

extension FolderCard: TableRecord, FetchableRecord, PersistableRecord {
    static var databaseTableName: String { "FolderCard" }
    
    enum Columns {
        static let folderCardId = Column(CodingKeys.folderCardId)
        static let cardId = Column(CodingKeys.cardId)
        static let folderId = Column(CodingKeys.folderId)
        static let addedDateTime = Column(CodingKeys.addedDateTime)
    }
}


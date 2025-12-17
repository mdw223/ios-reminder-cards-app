import Foundation
import GRDB

struct Card: Codable {
    var cardId: Int64?
    var text: String
    var isFavorite: Bool
    var notificationId: Int64?
    var createdDateTime: String
    
    init(cardId: Int64? = nil, text: String, isFavorite: Bool = false, notificationId: Int64? = nil, createdDateTime: String? = nil) {
        self.cardId = cardId
        self.text = text
        self.isFavorite = isFavorite
        self.notificationId = notificationId
        self.createdDateTime = createdDateTime ?? ISO8601DateFormatter().string(from: Date())
    }
    
    enum CodingKeys: String, CodingKey {
        case cardId, text, isFavorite, notificationId, createdDateTime
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        cardId = try container.decodeIfPresent(Int64.self, forKey: .cardId)
        text = try container.decode(String.self, forKey: .text)
        if let favoriteInt = try? container.decode(Int64.self, forKey: .isFavorite) {
            isFavorite = favoriteInt != 0
        } else {
            isFavorite = try container.decode(Bool.self, forKey: .isFavorite)
        }
        notificationId = try container.decodeIfPresent(Int64.self, forKey: .notificationId)
        createdDateTime = try container.decode(String.self, forKey: .createdDateTime)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(cardId, forKey: .cardId)
        try container.encode(text, forKey: .text)
        try container.encode(isFavorite ? 1 : 0, forKey: .isFavorite)
        try container.encodeIfPresent(notificationId, forKey: .notificationId)
        try container.encode(createdDateTime, forKey: .createdDateTime)
    }
}

extension Card: TableRecord, FetchableRecord, PersistableRecord {
    static var databaseTableName: String { "Card" }
    
    enum Columns {
        static let cardId = Column(CodingKeys.cardId)
        static let text = Column(CodingKeys.text)
        static let isFavorite = Column(CodingKeys.isFavorite)
        static let notificationId = Column(CodingKeys.notificationId)
        static let createdDateTime = Column(CodingKeys.createdDateTime)
    }
}


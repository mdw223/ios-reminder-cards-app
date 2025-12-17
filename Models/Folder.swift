import Foundation
import GRDB

struct Folder: Codable {
    var folderId: Int64?
    var title: String
    var isDefault: Bool
    var isFavorites: Bool
    var isActiveFolder: Bool
    var notificationId: Int64?
    var createdDateTime: String
    
    init(folderId: Int64? = nil, title: String, isDefault: Bool = false, isFavorites: Bool = false, isActiveFolder: Bool = false, notificationId: Int64? = nil, createdDateTime: String? = nil) {
        self.folderId = folderId
        self.title = title
        self.isDefault = isDefault
        self.isFavorites = isFavorites
        self.isActiveFolder = isActiveFolder
        self.notificationId = notificationId
        self.createdDateTime = createdDateTime ?? ISO8601DateFormatter().string(from: Date())
    }
    
    enum CodingKeys: String, CodingKey {
        case folderId, title, isDefault, isFavorites, isActiveFolder, notificationId, createdDateTime
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        folderId = try container.decodeIfPresent(Int64.self, forKey: .folderId)
        title = try container.decode(String.self, forKey: .title)
        if let defaultInt = try? container.decode(Int64.self, forKey: .isDefault) {
            isDefault = defaultInt != 0
        } else {
            isDefault = try container.decode(Bool.self, forKey: .isDefault)
        }
        if let favoritesInt = try? container.decode(Int64.self, forKey: .isFavorites) {
            isFavorites = favoritesInt != 0
        } else {
            isFavorites = try container.decode(Bool.self, forKey: .isFavorites)
        }
        if let activeInt = try? container.decode(Int64.self, forKey: .isActiveFolder) {
            isActiveFolder = activeInt != 0
        } else {
            isActiveFolder = try container.decode(Bool.self, forKey: .isActiveFolder)
        }
        notificationId = try container.decodeIfPresent(Int64.self, forKey: .notificationId)
        createdDateTime = try container.decode(String.self, forKey: .createdDateTime)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(folderId, forKey: .folderId)
        try container.encode(title, forKey: .title)
        try container.encode(isDefault ? 1 : 0, forKey: .isDefault)
        try container.encode(isFavorites ? 1 : 0, forKey: .isFavorites)
        try container.encode(isActiveFolder ? 1 : 0, forKey: .isActiveFolder)
        try container.encodeIfPresent(notificationId, forKey: .notificationId)
        try container.encode(createdDateTime, forKey: .createdDateTime)
    }
}

extension Folder: TableRecord, FetchableRecord, PersistableRecord {
    static var databaseTableName: String { "Folder" }
    
    enum Columns {
        static let folderId = Column(CodingKeys.folderId)
        static let title = Column(CodingKeys.title)
        static let isDefault = Column(CodingKeys.isDefault)
        static let isFavorites = Column(CodingKeys.isFavorites)
        static let isActiveFolder = Column(CodingKeys.isActiveFolder)
        static let notificationId = Column(CodingKeys.notificationId)
        static let createdDateTime = Column(CodingKeys.createdDateTime)
    }
}


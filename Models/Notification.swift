import Foundation
import GRDB

struct ReminderNotification: Codable {
    var notificationId: Int64?
    var message: String
    var recurrenceRule: String?
    var timeOfDay: String
    var isEnabled: Bool
    var createdDateTime: String
    
    init(notificationId: Int64? = nil, message: String, recurrenceRule: String? = nil, timeOfDay: String, isEnabled: Bool = true, createdDateTime: String? = nil) {
        self.notificationId = notificationId
        self.message = message
        self.recurrenceRule = recurrenceRule
        self.timeOfDay = timeOfDay
        self.isEnabled = isEnabled
        self.createdDateTime = createdDateTime ?? ISO8601DateFormatter().string(from: Date())
    }
    
    enum CodingKeys: String, CodingKey {
        case notificationId, message, recurrenceRule, timeOfDay, isEnabled, createdDateTime
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        notificationId = try container.decodeIfPresent(Int64.self, forKey: .notificationId)
        message = try container.decode(String.self, forKey: .message)
        recurrenceRule = try container.decodeIfPresent(String.self, forKey: .recurrenceRule)
        timeOfDay = try container.decode(String.self, forKey: .timeOfDay)
        if let enabledInt = try? container.decode(Int64.self, forKey: .isEnabled) {
            isEnabled = enabledInt != 0
        } else {
            isEnabled = try container.decode(Bool.self, forKey: .isEnabled)
        }
        createdDateTime = try container.decode(String.self, forKey: .createdDateTime)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(notificationId, forKey: .notificationId)
        try container.encode(message, forKey: .message)
        try container.encodeIfPresent(recurrenceRule, forKey: .recurrenceRule)
        try container.encode(timeOfDay, forKey: .timeOfDay)
        try container.encode(isEnabled ? 1 : 0, forKey: .isEnabled)
        try container.encode(createdDateTime, forKey: .createdDateTime)
    }
}

extension ReminderNotification: TableRecord, FetchableRecord, PersistableRecord {
    static var databaseTableName: String { "Notification" }
    
    enum Columns {
        static let notificationId = Column(CodingKeys.notificationId)
        static let message = Column(CodingKeys.message)
        static let recurrenceRule = Column(CodingKeys.recurrenceRule)
        static let timeOfDay = Column(CodingKeys.timeOfDay)
        static let isEnabled = Column(CodingKeys.isEnabled)
        static let createdDateTime = Column(CodingKeys.createdDateTime)
    }
}


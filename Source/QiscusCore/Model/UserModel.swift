//
//  Auth.swift
//  QiscusCore
//
//  Created by Qiscus on 19/07/18.
//  Copyright © 2018 Qiscus. All rights reserved.
//

import SwiftyJSON

public enum SortType: String {
    case asc = "asc"
    case desc = "desc"
}

public struct QAccount {
    public var avatarUrl        : URL       = URL(string: "http://")!
    public var id               : String    = ""
    public var rtKey            : String    = ""
    public var token            : String    = ""
    public var name             : String    = ""
    public var extras           : String    = ""
    public var lastMessageId    : String    = ""
    public var lastSyncEventId  : String    = ""
    
    init() { }
    
    init(json: JSON) {
        avatarUrl       = json["avatar_url"].url ?? URL(string: "http://")!
        id              = json["email"].stringValue
        rtKey           = json["rtKey"].stringValue
        token           = json["token"].stringValue
        name            = json["username"].stringValue
        extras          = json["extras"].rawString() ?? ""
        lastMessageId   = json["last_comment_id_str"].stringValue
        lastSyncEventId = json["last_sync_event_id"].stringValue
    }
}

open class QParticipant {
    public var avatarUrl : URL?             = nil
    public var id : String                  = ""
    public var lastMessageReadId : Int      = -1
    public var lastMessageDeliveredId : Int = -1
    public var name : String                = ""
    public var extras: [String:Any]?        = nil
    private let userKey                     = "CoreMemKey_"
    
    init() { }
    
    init(json: JSON) {
        self.id                         = json["email"].stringValue
        self.name                       = json["username"].stringValue
        self.avatarUrl                  = json["avatar_url"].url ?? nil
        self.lastMessageReadId          = json["last_comment_read_id"].intValue
        self.lastMessageDeliveredId     = json["last_comment_received_id"].intValue
        self.extras                     = json["extras"].dictionaryObject
    }
}

open class QUser {
    public var avatarUrl : URL?             = nil
    public var id : String                  = ""
    public var name : String                = ""
    public var extras : [String:Any]?       = nil
    
    init() { }
    
    init(json: JSON) {
        self.id                         = json["email"].stringValue
        self.name                       = json["username"].stringValue
        self.avatarUrl                  = json["avatar_url"].url ?? nil
        self.extras                     = json["extras"].dictionaryObject
    }
}

extension QParticipant {
    internal func saveLastOnline(_ time: Date) {
        let db = UserDefaults.standard
        db.set(time, forKey: self.userKey + "lastSeen")
    }
    
    func lastSeen() -> Date? {
        let db = UserDefaults.standard
        return db.object(forKey: self.userKey + "lastSeen") as? Date
        // MARK: TODO get alternative when null
    }
}

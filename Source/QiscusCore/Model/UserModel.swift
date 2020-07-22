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

public struct UserModel {
    public var avatarUrl        : URL       = URL(string: "http://")!
    public var email            : String    = ""
    public var id               : String    = ""
    public var rtKey            : String    = ""
    public var token            : String    = ""
    public var username         : String    = ""
    public var extras           : String    = ""
    
    init() { }
    
    init(json: JSON) {
        avatarUrl       = json["avatar_url"].url ?? URL(string: "http://")!
        email           = json["email"].stringValue
        id              = json["id_str"].stringValue
        rtKey           = json["rtKey"].stringValue
        token           = json["token"].stringValue
        username        = json["username"].stringValue
        extras          = json["extras"].rawString() ?? ""
    }
}

open class MemberModel {
    public var avatarUrl : URL? = nil
    public var email : String   = ""
    public var id : String      = ""
    public var lastCommentReadId : Int  = -1
    public var lastCommentReceivedId : Int  = -1
    public var username : String    = ""
    public var extras : [String:Any]? = nil
    private let userKey = "CoreMemKey_"
    
    init() { }
    
    init(json: JSON) {
        self.id         = json["email"].stringValue
        self.username   = json["username"].stringValue
        self.avatarUrl  = json["avatar_url"].url ?? nil
        self.email      = json["email"].stringValue
        self.lastCommentReadId      = json["last_comment_read_id"].intValue
        self.lastCommentReceivedId  = json["last_comment_received_id"].intValue
        self.extras                 = json["extras"].dictionaryObject
    }
}

extension MemberModel {
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

//
//  CommentModel.swift
//  QiscusCore
//
//  Created by Rahardyan Bisma on 26/07/18.
//  Copyright © 2018 Qiscus. All rights reserved.
//

import Foundation
import SwiftyJSON

public class SyncMeta {
    public let last_received_comment_id : Int? = nil
    public let need_clear : Bool? = nil
}

open class CommentModel {
    //public var onChange : (CommentModel) -> Void = { _ in} // data binding
    public internal(set) var commentBeforeId      : String        = ""
    public internal(set) var id                   : String        = ""
    public internal(set) var isDeleted            : Bool          = false
    public internal(set) var isPublicChannel      : Bool          = false
    public var status               : CommentStatus = .sending
    public var message              : String        = ""
    /// Comment payload, to describe comment type.
    public var payload              : [String:Any]? = nil
    /// Extra data, set after comment is complate.
    public var extras               : [String:Any]? = nil
    public var userExtras           : [String:Any]? = nil
    public var roomId               : String        = ""
    public internal(set) var timestamp            : String        = ""
    public var type                 : String        = "text"
    public internal(set) var uniqId               : String        = ""
    public internal(set) var unixTimestamp        : Int64         = 0
    public internal(set) var userAvatarUrl        : URL?          = nil
    public internal(set) var userId               : String        = ""
    public internal(set) var username             : String        = ""
    public internal(set) var userEmail            : String        = ""
    /// automatic set when comment initiated
    public var date                 : Date {
        get {
            return self.getDate()
        }
    }
    
    public init() {
        guard let user = QiscusCore.getProfile() else { return }
        DispatchQueue.global(qos: .background).sync {
            self.userId         = String(user.id)
            self.username       = user.username
            self.userAvatarUrl  = user.avatarUrl
            self.userEmail      = user.email
            let now             = Int64(NSDate().timeIntervalSince1970 * 1000000000.0) // nano sec
            self.uniqId         = "ios_\(now)"
            self.id             = "ios_\(now)"
            self.unixTimestamp  = now
            self.timestamp      = CommentModel.getTimestamp()
        }
    }
    
    init(json: JSON) {
        self.id                 = json["id_str"].stringValue
        self.roomId             = json["room_id_str"].string ?? json["Room_id_str"].string ?? ""
        self.uniqId             = json["unique_temp_id"].stringValue
        self.commentBeforeId    = json["comment_before_id_str"].stringValue
        self.userEmail          = json["email"].stringValue
        self.isDeleted          = json["is_deleted"].boolValue
        self.isPublicChannel    = json["is_public_channel"].boolValue
        self.message            = json["message"].stringValue
        self.payload            = json["payload"].dictionaryObject
        self.timestamp          = json["timestamp"].stringValue
        self.unixTimestamp      = json["unix_nano_timestamp"].int64Value
        self.userAvatarUrl      = json["user_avatar_url"].url ?? json["user_avatar"].url ?? URL(string: "http://")
        self.username           = json["username"].stringValue
        self.userId             = json["user_id_str"].stringValue
        let _status             = json["status"].stringValue
        for s in CommentStatus.all {
            if s.rawValue == _status {
                self.status = s
            }
        }
        if isDeleted {
            self.status = .deleted // maping status deleted, backend not provide
        }
        let _type   = json["type"].stringValue
        if _type.lowercased() != "custom" {
            self.type = _type
        }else {
            self.type = getType(fromPayload: self.payload)
            // parsing payload
            if let _payload = self.payload {
                self.payload?.removeAll()
                self.payload = getPayload(fromPayload: _payload)
            }
        }
        
        self.extras             = json["extras"].dictionaryObject
        self.userExtras         = json["user_extras"].dictionaryObject
    }
}

extension CommentModel {
    private func getType(fromPayload data: [String:Any]?) -> String {
        guard let payload = data else { return "custom"}
        let type = payload["type"] as! String
        return type
    }
    
    private func getPayload(fromPayload data: [String:Any]) -> [String:Any]? {
        if let payload = data["content"] as? [String:Any]{
            if !payload.isEmpty {
                return payload
            }else { return nil }
        }else {
            return nil
        }
    }
    
    func getDate() -> Date {
        //let timezone = TimeZone.current.identifier
        let formatter = DateFormatter()
        formatter.dateFormat    = "yyyy-MM-dd'T'HH:mm:ssZ"
        //formatter.timeZone      = TimeZone(secondsFromGMT: 0)
        formatter.timeZone      = TimeZone(abbreviation: "UTC")
        formatter.locale = Locale(identifier: "en_US_POSIX")
        let date = formatter.date(from: self.timestamp)
        return date ?? Date()
    }
    
    static func getTimestamp() -> String {
        let timezone = TimeZone.current.identifier
        let formatter = DateFormatter()
        formatter.dateFormat    = "yyyy-MM-dd'T'HH:mm:ssZ"
        //formatter.timeZone      = TimeZone(secondsFromGMT: 0)
        formatter.timeZone      = TimeZone(abbreviation: "UTC")
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: Date())
    }
    
    func isQiscustype() -> Bool {
        var result = false
        for t in CommentType.all {
            if self.type == t.rawValue {
                result = true
            }
        }
        return result
    }
}

public enum CommentStatus : String, CaseIterable {
    case sending    = "sending"
    case pending    = "pending"
    case failed     = "failed"
    case sent       = "sent"
    case delivered  = "delivered"
    case read       = "read"
    case deleting   = "deleting" // because delete process not only in device
    case deleted    = "deleted"
    
    static let all = [sending, pending, failed, sent, delivered, read, deleted]
    
    var intValue : Int {
        get {
            return self.asInt()
        }
    }
    private func asInt() -> Int {
        for (index,s) in CommentStatus.all.enumerated() {
            if self == s {
                return index
            }
        }
        return 0
    }
}

enum CommentType: String {
    case text                       = "text"
    case fileAttachment             = "file_attachment"
    case accountLink                = "account_linking"
    case buttons                    = "buttons"
    case buttonPostbackResponse     = "button_postback_response"
    case reply                      = "reply"
    case systemEvent                = "system_event"
    case card                       = "card"
    case custom                     = "custom"
    case location                   = "location"
    case contactPerson              = "contact_person"
    case carousel                   = "carousel"
    
    static let all = [text,fileAttachment,accountLink,buttons,buttonPostbackResponse,reply,systemEvent,card,custom,location,contactPerson,carousel]
}

//
//  CommentModel.swift
//  QiscusCore
//
//  Created by Arief Nur Putranto on 26/07/18.
//  Copyright © 2018 Qiscus. All rights reserved.
//

import Foundation
import SwiftyJSON

public class SyncMeta {
    public let last_received_comment_id : Int? = nil
    public let need_clear : Bool? = nil
}

open class QMessage {
    //public var onChange : (QMessage) -> Void = { _ in} // data binding
    public var previousMessageId                    : String        = ""
    public internal(set) var id                     : String        = ""
    public internal(set) var isDeleted              : Bool          = false
    public internal(set) var isPublicChannel        : Bool          = false
    public var status                               : QMessageStatus = .sending
    public var message                              : String        = ""
    /// Comment payload, to describe comment type.
    public var payload                              : [String:Any]? = nil
    /// Extra data, set after comment is complate.
    public var extras                               : [String:Any]? = nil
    public var userExtras                           : [String:Any]? = nil
    public var chatRoomId                           : String        = ""
    public internal(set) var timestampString        : String        = ""
    public var type                                 : String        = "text"
    public var uniqueId               : String        = ""
    public internal(set) var unixTimestamp          : Int64         = 0
    public var userAvatarUrl          : URL?          = nil
    public internal(set) var userId                 : String        = ""
    public var name                   : String        = ""
    public var userEmail              : String        = ""
    /// automatic set when comment initiated
    public var timestamp                 : Date {
        get {
            return self.getDate()
        }
    }
    
    public var sender      : QUser{
        get{
            let user = QUser.init()
            user.avatarUrl  = self.userAvatarUrl
            user.id         = self.userId
            user.extras     = self.userExtras
            user.name       = self.name
            return user
        }
    }
    
    public init() {
       // guard let user = QiscusCore.getProfile() else { return }
        DispatchQueue.global(qos: .background).sync {
//            self.name               = user.name
//            self.userAvatarUrl      = user.avatarUrl
//            self.userEmail          = user.id
            let now                 = Int64(NSDate().timeIntervalSince1970 * 1000000000.0) // nano sec
            self.uniqueId           = "ios_\(now)"
            self.id                 = "ios_\(now)"
            self.unixTimestamp      = now
            self.timestampString    = QMessage.getTimestamp()
        }
    }
    
    init(json: JSON, qiscusCore : QiscusCore? = nil) {
        self.id                 = json["id_str"].stringValue
        self.chatRoomId         = json["room_id_str"].stringValue
        self.uniqueId           = json["unique_temp_id"].stringValue
        self.previousMessageId  = json["comment_before_id_str"].stringValue
        self.userEmail          = json["email"].stringValue
        self.isDeleted          = json["is_deleted"].boolValue
        self.isPublicChannel    = json["is_public_channel"].boolValue
        self.message            = json["message"].stringValue
        self.payload            = json["payload"].dictionaryObject
        self.timestampString    = json["timestamp"].stringValue
        self.unixTimestamp      = json["unix_nano_timestamp"].int64Value
        self.userAvatarUrl      = json["user_avatar_url"].url ?? json["user_avatar"].url ?? URL(string: "http://")
        self.name               = json["username"].stringValue
        self.userId             = json["user_id_str"].stringValue
        let _status             = json["status"].stringValue
        for s in QMessageStatus.all {
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
        
        let roomName = json["room_name"].string ?? ""
        
        if !roomName.isEmpty && qiscusCore != nil {
            if let room = qiscusCore?.database.room.find(id: self.chatRoomId) {
                if room.type != .single {
                    room.name = roomName
                    qiscusCore?.database.room.save([room])
                }else{
                    if self.name.lowercased() == "System".lowercased(){
                        //ignored
                    }else{
                        room.name = roomName
                        qiscusCore?.database.room.save([room])
                    }
                }
            }
        }
    }
    
    public func generateMessage(roomId : String, text : String) -> QMessage {
        var message = QMessage.init()
        message.type = "text"
        message.message = text
        message.chatRoomId = roomId
        
        return message
    }
    
    public func generateFileAttachmentMessage(roomId : String, caption: String, name : String) -> QMessage {
        var message = QMessage.init()
        message.chatRoomId = roomId
        message.type = "file_attachment"
        message.payload = [
            "file_name" : name,
            "caption"   : caption
        ]
        
        return message
    }
    
    public func generateCustomMessage(roomId : String, text : String, type: String, payoad : [String:Any]) -> QMessage {
        var message = QMessage.init()
        message.chatRoomId = roomId
        message.type = "custom"
        message.payload = payload
        message.payload?["type"] = type
        message.message = text
        
        return message
    }
    
    public func generateReplyMessage(roomId: String, text: String, repliedMessage: QMessage) -> QMessage {
        var message = QMessage.init()
        message.chatRoomId = roomId
        message.type = "reply"
        message.message = text
        message.payload = [
            "replied_comment_sender_email"       : repliedMessage.userEmail,
            "replied_comment_id" : Int(repliedMessage.id),
            "text"      : text,
            "replied_comment_message"   : repliedMessage.message,
            "replied_comment_sender_username" : repliedMessage.name,
            "replied_comment_payload" : repliedMessage.payload,
            "replied_comment_type" : repliedMessage.type
        ]
        return message
    }
}

extension QMessage {
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
        let date = formatter.date(from: self.timestampString)
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

public enum QMessageStatus : String, CaseIterable {
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
        for (index,s) in QMessageStatus.all.enumerated() {
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

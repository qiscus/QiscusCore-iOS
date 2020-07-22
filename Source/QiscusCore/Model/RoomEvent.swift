//
//  RoomEvent.swift
//  QiscusCore
//
//  Created by Qiscus on 29/10/18.
//

import Foundation
import SwiftyJSON

public struct RoomEvent {
    public let sender  : String
    public let data    : [String:Any]
}

public struct RoomTyping {
    public let roomID  : String
    public let user    : MemberModel
    public let typing  : Bool
}

enum SyncEventTopic : String {
    case noActionTopic  = ""
    case deletedMessage = "delete_message"
    case clearRoom      = "clear_room"
    case delivered      = "delivered"
    case read           = "read"
    case sent           = "sent"
}

struct SyncEvent {
    let id          : String
    let timestamp   : Int64
    let actionTopic : SyncEventTopic
    let payload     : [String:Any]
    
    init(json: JSON) {
        let id = json["id"].int64 ?? 0
        self.id = "\(id)"
        self.timestamp  = json["timestamp"].int64 ?? 0
        self.actionTopic  = SyncEventTopic(rawValue: json["action_topic"].string ?? "") ?? .noActionTopic
        self.payload    = json["payload"].dictionaryObject ?? [:]
    }
}

extension SyncEvent {
    func getDeletedMessageUniqId() -> [String] {
        var result : [String] = [String]()
        guard let data = payload["data"] as? [String:Any] else {
            return result
        }
        guard let messages = data["deleted_messages"] as? [[String:Any]] else {
            return result
        }
        
        messages.forEach { (message) in
            if let _message = message["message_unique_ids"] as? [String] {
                _message.forEach({ (id) in
                    result.append(id)
                })
            }
        }
        
        return result
    }
    
    func getClearRoomUniqId() -> [String] {
        var result : [String] = [String]()
        guard let data = payload["data"] as? [String:Any] else {
            return result
        }
        guard let rooms = data["deleted_rooms"] as? [[String:Any]] else {
            return result
        }
        
        rooms.forEach { (room) in
            if let id = room["unique_id"] as? String {
                result.append(id)
            }
        }
        
        return result
    }
    
    func updatetStatusMessage(){
        guard let data = payload["data"] as? [String:Any] else {
           return
        }
        let jsonPayload = JSON(arrayLiteral: data)[0]
        let commentId = jsonPayload["comment_id"].stringValue
        let email = jsonPayload["email"].stringValue
        guard let commentDB = QiscusCore.database.comment.find(id: commentId) else {
            return
        }
        if actionTopic == .delivered {
            RealtimeManager.shared.updateMessageStatus(roomId: commentDB.roomId, commentId: commentDB.id, commentUniqueId: commentDB.uniqId, Status: .delivered, userEmail: email, sourceMqtt: false)
        }else if actionTopic == .read {
            RealtimeManager.shared.updateMessageStatus(roomId: commentDB.roomId, commentId: commentDB.id, commentUniqueId: commentDB.uniqId, Status: .read, userEmail: email, sourceMqtt: false)
        }
    }
}

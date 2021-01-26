//
//  ApiResponse.swift
//  QiscusCore
//
//  Created by Arief Nur Putranto on 26/07/18.
//  Copyright © 2018 Qiscus. All rights reserved.
//

import Foundation
import SwiftyJSON

class ApiResponse {
    static func decode(from data: Data) -> JSON {
        let json = JSON(data)
        let result = json["results"]
        return result
    }
    
    static func decodeWithoutResult(from data: Data) -> JSON {
        let json = JSON(data)
        return json
    }
    
    static func decode(string data: String) -> JSON {
        let json = JSON.init(parseJSON: data)
        return json
    }
    
    static func decode(unread data: Data) -> Int {
        let json = JSON(data)
        let unread = json["results"]["total_unread_count"].intValue
        return unread
    }
    
    static func decode(syncEvent event: Data, qiscusCore :  QiscusCore) -> [SyncEvent] {
        let json = JSON(event)
        var results = [SyncEvent]()
        if let result = json["events"].array {
            result.forEach { (data) in
                let event = SyncEvent(json: data, qiscusCore: qiscusCore)
                results.append(event)
            }
            return results
        }else {
            return results
        }
    }
    
    static func decodeError(from data: Data) -> String{
        let json = JSON(data)
        let errorMessage = json["error"]["detailed_messages"].arrayObject ?? ["Error"]
        errorMessage.description
        let string = errorMessage.description
        return string
    }
}

class FileApiResponse {
    static func upload(from json: JSON) -> FileModel {
        let i = json["file"]
        return FileModel(json: i)
    }
}

class UserApiResponse {
    static func blockedUsers(from json: JSON) -> [QUser]? {
        if let rooms = json["blocked_user"].array {
            var results = [QUser]()
            for room in rooms {
                let data = QUser(json: room)
                results.append(data)
            }
            return results
        }else {
            return nil
        }
    }
    
    static func user(from json: JSON) -> QAccount {
        let comment = json["user"]
        return QAccount(json: comment)
    }
    
    static func successRegisterDeviceToken(from json: JSON) -> Bool {
        let changed = json["changed"].bool ?? false
        return changed
    }
    
    static func successRemoveDeviceToken(from json: JSON) -> Bool {
        let success = json["success"].bool ?? false
        return success
    }

    static func allUser(from json: JSON) -> [QUser]?  {
        if let rooms = json["users"].array {
            var results = [QUser]()
            for room in rooms {
                let data = QUser(json: room)
                results.append(data)
            }
            return results
        }else {
            return nil
        }
    }
    
    static func blockUser(from json: JSON) -> QUser {
        let user = json["user"]
        return QUser(json: user)
    }
    
    static func meta(from json: JSON) -> Meta {
        let meta = json["meta"]
        return Meta(json: meta)
    }
}

class RoomApiResponse {
    static func rooms(from json: JSON) -> [QChatRoom]? {
        if let rooms = json["rooms_info"].array {
            var results = [QChatRoom]()
            for room in rooms {
                let data = QChatRoom(json: room)
                results.append(data)
            }
            return results
        }else {
            return nil
        }
    }
    
    static func room(from json: JSON) -> QChatRoom {
        let comment = json["room"]
        return QChatRoom(json: comment)
    }
    
    static func channels(from json: JSON) -> [QiscusChannels]? {
        if let channels = json["channels"].array {
            var results = [QiscusChannels]()
            for channel in channels {
                let data = QiscusChannels(json: channel)
                results.append(data)
            }
            return results
        }else {
            return nil
        }
    }
    
    static func getRoomUnreadCount(from json: JSON) -> Int {
        let unreadCount = json["total_unread_count"].int ?? 0
        return unreadCount
    }
    
    static func usersPresence(from json: JSON) -> [QUserPresence]? {
        if let usersStatus = json["user_status"].array {
            var results = [QUserPresence]()
            for userStatus in usersStatus {
                let data = QUserPresence(json: userStatus)
                results.append(data)
            }
            return results
        }else {
            return nil
        }
    }


    
    static func meta(from json: JSON) -> Meta {
        let meta = json["meta"]
        return Meta(json: meta)
    }
    
    static func metaRoomParticipant(from json: JSON) -> MetaRoomParticipant {
        let meta = json["meta"]
        return MetaRoomParticipant(json: meta)
    }
    
    static func addParticipants(from json: JSON) -> [QParticipant]? {
        if let members = json["participants_added"].array {
            var results = [QParticipant]()
            for member in members {
                let data = QParticipant(json: member)
                results.append(data)
            }
            return results
        }else {
            return nil
        }
    }
    
    static func participants(from json: JSON) -> [QParticipant]? {
        if let members = json["participants"].array {
            var results = [QParticipant]()
            for member in members {
                let data = QParticipant(json: member)
                results.append(data)
            }
            return results
        }else {
            return nil
        }
    }

}

class CommentApiResponse {
    static func comments(from json: JSON, qiscusCore : QiscusCore? = nil) -> [QMessage]? {
        if let comments = json["comments"].array {
            var results = [QMessage]()
            for comment in comments {
                let data = QMessage(json: comment, qiscusCore: qiscusCore)
                results.append(data)
            }
            return results
        }else {
            return nil
        }
    }
    
    static func comment(from json: JSON, qiscusCore : QiscusCore? = nil) -> QMessage {
        let comment = json["comment"]
        return QMessage(json: comment, qiscusCore: qiscusCore)
    }
    
    static func commentDeliveredUser(from json: JSON) -> [QParticipant]? {
        if let members = json["delivered_to"].array {
            var results = [QParticipant]()
            for member in members {
                let user = member["user"]
                let data = QParticipant(json: user)
                
                results.append(data)
            }
            return results
        }else {
            return nil
        }
    }
    
    static func commentReadUser(from json: JSON) -> [QParticipant]? {
        if let members = json["read_by"].array {
            var results = [QParticipant]()
            for member in members {
                let user = member["user"]
                let data = QParticipant(json: user)
                
                results.append(data)
            }
            return results
        }else {
            return nil
        }
    }
    
    static func commentPendingUser(from json: JSON) -> [QParticipant]? {
        if let members = json["pending"].array {
            var results = [QParticipant]()
            for member in members {
                let user = member["user"]
                let data = QParticipant(json: user)
                results.append(data)
            }
            return results
        }else {
            return nil
        }
    }
    
}

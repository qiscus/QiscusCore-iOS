//
//  ApiResponse.swift
//  QiscusCore
//
//  Created by Rahardyan Bisma on 26/07/18.
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
    
    static func decode(syncEvent event: Data) -> [SyncEvent] {
        let json = JSON(event)
        var results = [SyncEvent]()
        if let result = json["events"].array {
            result.forEach { (data) in
                let event = SyncEvent(json: data)
                results.append(event)
            }
            return results
        }else {
            return results
        }
    }
    
    static func decodeError(from data: Data){
        let json = JSON(data)
        let error = json["error"]["detailed_messages"].arrayObject
    }
}

class FileApiResponse {
    static func upload(from json: JSON) -> FileModel {
        let i = json["file"]
        return FileModel(json: i)
    }
}

class UserApiResponse {
    static func blockedUsers(from json: JSON) -> [MemberModel]? {
        if let rooms = json["blocked_user"].array {
            var results = [MemberModel]()
            for room in rooms {
                let data = MemberModel(json: room)
                results.append(data)
            }
            return results
        }else {
            return nil
        }
    }
    
    static func user(from json: JSON) -> UserModel {
        let comment = json["user"]
        return UserModel(json: comment)
    }
    
    static func successRegisterDeviceToken(from json: JSON) -> Bool {
        let changed = json["changed"].bool ?? false
        return changed
    }
    
    static func successRemoveDeviceToken(from json: JSON) -> Bool {
        let success = json["success"].bool ?? false
        return success
    }
    
    static func allUser(from json: JSON) -> [MemberModel]?  {
        if let rooms = json["users"].array {
            var results = [MemberModel]()
            for room in rooms {
                let data = MemberModel(json: room)
                results.append(data)
            }
            return results
        }else {
            return nil
        }
    }
    
    static func blockUser(from json: JSON) -> MemberModel {
        let comment = json["user"]
        return MemberModel(json: comment)
    }
    
    static func meta(from json: JSON) -> Meta {
        let meta = json["meta"]
        return Meta(json: meta)
    }
}

class RoomApiResponse {
    static func rooms(from json: JSON) -> [RoomModel]? {
        if let rooms = json["rooms_info"].array {
            var results = [RoomModel]()
            for room in rooms {
                let data = RoomModel(json: room)
                results.append(data)
            }
            return results
        }else {
            return nil
        }
    }
    
    static func room(from json: JSON) -> RoomModel {
        let comment = json["room"]
        return RoomModel(json: comment)
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
    
    static func addParticipants(from json: JSON) -> [MemberModel]? {
        if let members = json["participants_added"].array {
            var results = [MemberModel]()
            for member in members {
                let data = MemberModel(json: member)
                results.append(data)
            }
            return results
        }else {
            return nil
        }
    }
    
    static func participants(from json: JSON) -> [MemberModel]? {
        if let members = json["participants"].array {
            var results = [MemberModel]()
            for member in members {
                let data = MemberModel(json: member)
                results.append(data)
            }
            return results
        }else {
            return nil
        }
    }

}

class CommentApiResponse {
    static func comments(from json: JSON) -> [CommentModel]? {
        if let comments = json["comments"].array {
            var results = [CommentModel]()
            for comment in comments {
                let data = CommentModel(json: comment)
                results.append(data)
            }
            return results
        }else {
            return nil
        }
    }
    
    static func comment(from json: JSON) -> CommentModel {
        let comment = json["comment"]
        return CommentModel(json: comment)
    }
    
    static func commentDeliveredUser(from json: JSON) -> [MemberModel]? {
        if let members = json["delivered_to"].array {
            var results = [MemberModel]()
            for member in members {
                let user = member["user"]
                let data = MemberModel(json: user)
                
                results.append(data)
            }
            return results
        }else {
            return nil
        }
    }
    
    static func commentReadUser(from json: JSON) -> [MemberModel]? {
        if let members = json["read_by"].array {
            var results = [MemberModel]()
            for member in members {
                let user = member["user"]
                let data = MemberModel(json: user)
                
                results.append(data)
            }
            return results
        }else {
            return nil
        }
    }
    
    static func commentPendingUser(from json: JSON) -> [MemberModel]? {
        if let members = json["pending"].array {
            var results = [MemberModel]()
            for member in members {
                let user = member["user"]
                let data = MemberModel(json: user)
                results.append(data)
            }
            return results
        }else {
            return nil
        }
    }
    
}

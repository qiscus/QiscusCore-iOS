//
//  EndpointRoom.swift
//  QiscusCore
//
//  Created by Qiscus on 13/08/18.
//

import Foundation

// MARK: Room API
internal enum APIRoom {
    case roomList(showParticipants: Bool, limit: Int?, page: Int?, roomType: RoomType? , showRemoved: Bool, showEmpty: Bool)
    case roomInfo(roomId: [String]?, roomUniqueId: [String]?, showParticipants: Bool, showRemoved: Bool)
    case createNewRoom(name: String,participants: [String],avatarUrl: URL?, options: String?)
    case updateRoom(roomId: String, roomName: String?, avatarUrl: URL?, options: String?)
    case roomWithTarget(email: [String], options: String?)
    case channelWithUniqueId(uniqueId: String,name: String?, avatarUrl: URL?, options: String?)
    case getChannels
    case getChannelsInfo(uniqueId : [String])
    case joinChannels(uniqueId : [String])
    case leaveChannels(uniqueId : [String])
    case addParticipant(roomId: String, emails: [String])
    case removeParticipant(roomId: String, emails: [String])
    case getParticipant(roomId: String, page:Int?, limit: Int?, offset: Int?, sorting : SortType?)
    case getRoomById(roomId: String)
    case usersPresence(userIds : [String])
}

extension APIRoom : EndPoint {
    var baseURL: URL {
        return BASEURL
    }
    
    var path: String {
        switch self {
        case .roomList( _, _, _, _, _, _):
            return "/user_rooms"
        case .roomInfo( _, _, _, _):
            return "/rooms_info"
        case .createNewRoom( _, _, _, _):
            return "/create_room"
        case .updateRoom( _, _, _, _):
            return "/update_room"
        case .roomWithTarget( _, _):
            return "/get_or_create_room_with_target"
        case .channelWithUniqueId( _, _, _, _):
            return "/get_or_create_room_with_unique_id"
        case .addParticipant( _, _):
            return "/add_room_participants"
        case .removeParticipant( _, _):
            return "/remove_room_participants"
        case .getRoomById( _):
            return "/get_room_by_id"
        case .getParticipant(_):
            return "/room_participants"
        case .getChannels:
            return "/channels"
        case .getChannelsInfo( _):
            return "channels/info"
        case .joinChannels( _):
            return "channels/join"
        case .leaveChannels( _):
            return "channels/leave"
        case .usersPresence( _):
            return "users/status"
        }
    }
    
    var httpMethod: HTTPMethod {
        switch self {
        case .roomList, .getRoomById, .getParticipant, .getChannels:
            return .get
        case .roomInfo, .createNewRoom, .updateRoom, .roomWithTarget, .channelWithUniqueId, .addParticipant, .removeParticipant, .getChannelsInfo, .joinChannels, .leaveChannels, .usersPresence:
            return .post
        }
    }
    
    var header: HTTPHeaders? {
        return HEADERS
    }
    
    var task: HTTPTask {
        switch self {
        case .roomList(let showParticipants,let limit, let page, let roomType, let showRemoved, let showEmpty):
            var params = [
                "show_participants"          : showParticipants,
                "show_removed"               : showRemoved,
                "show_empty"                 : showEmpty
                
                ] as [String : Any]
            
            if let pages = page {
                params["page"] = pages
            }
            
            if let l = limit {
                params["limit"] = l
            }
            
            if let roomTypeParams = roomType {
                params["room_type"] = roomTypeParams
            }
            return .requestParameters(bodyParameters: nil, bodyEncoding: .jsonUrlEncoding, urlParameters: params)
        case .roomInfo(let roomId, let roomUniqueId ,let showParticipants, let showRemoved):
            var params = [
                "show_participants"          : showParticipants,
                "show_removed"               : showRemoved
                ]as [String : Any]
            
            if let id = roomId {
                params["room_id"] = id
            }
            
            if let uniqueId = roomUniqueId{
                params["room_unique_id"] = uniqueId
            }
            return .requestParameters(bodyParameters: params, bodyEncoding: .jsonEncoding, urlParameters: nil)
        case .createNewRoom(let name,let participants,let avatarUrl, let options):
            var params = [
                "name"                       : name,
                "participants"               : participants
                ]as [String : Any]
            
            if let avatarurl = avatarUrl?.absoluteString {
                params["avatar_url"] = avatarurl
            }
            
            if let optionsParam = options {
                params["options"] = optionsParam
            }
            
            return .requestParameters(bodyParameters: params, bodyEncoding: .jsonEncoding, urlParameters: nil)
        case .updateRoom(let id,let roomName,let avatarUrl, let options) :
            var params = [
                "id"                         : id,
                ]as [String : Any]
            
            if let roomname = roomName {
                params["room_name"] = roomname
            }
            
            if let avatarurl = avatarUrl?.absoluteString {
                params["avatar_url"] = avatarurl
            }
            
            if let optionsParam = options {
                params["options"] = optionsParam
            }
            
            return .requestParameters(bodyParameters: params, bodyEncoding: .jsonEncoding, urlParameters: nil)
        case .roomWithTarget(let email, let options) :
            var params = [
                "emails"                      : email
                ] as [String : Any]
            
            if let optionsParams = options {
                params["options"] = optionsParams
            }
            return .requestParameters(bodyParameters: params, bodyEncoding: .jsonEncoding, urlParameters: nil)
        case .channelWithUniqueId(let uniqueId, let name, let avatarUrl, let options):
            var params = [
                "unique_id"                  : uniqueId
            ]
            
            if let nm = name {
                params["name"] = nm
            }
            
            if let avatarurl = avatarUrl?.absoluteString {
                params["avatar_url"] = avatarurl
            }
            
            if let optionsParams = options {
                params["options"] = optionsParams
            }
            
            return .requestParameters(bodyParameters: params, bodyEncoding: .jsonEncoding, urlParameters: nil)
            
        case .addParticipant(let roomId,let emails) :
            let params = [
                "room_id"                    : roomId,
                "emails"                     : emails
                ] as [String : Any]
            return .requestParameters(bodyParameters: params, bodyEncoding: .jsonEncoding, urlParameters: nil)
        case .removeParticipant(let roomId,let emails) :
            let params = [
                "room_id"                    : roomId,
                "emails"                   : emails
                ] as [String : Any]
            return .requestParameters(bodyParameters: params, bodyEncoding: .jsonEncoding, urlParameters: nil)
        case .getRoomById(let roomId):
            let params = [
                "id"                         : roomId ?? ""
                ] as [String : Any]
            
            return .requestParameters(bodyParameters: nil, bodyEncoding: .jsonUrlEncoding, urlParameters: params)
        case .getParticipant(let roomId, let page, let limit, let offset, let sorting):
            var params = [
                "room_unique_id"                    : roomId
                ] as [String : Any]
            
            if let offset = offset {
                params["offset"] = offset
            }
            
            if let sorting = sorting {
                params["sorting"] = sorting
            }
            
            if let page = page {
                params["page"] = page
            }
            
            if let limit = limit {
                params["limit"] = limit
            }
            
            return .requestParameters(bodyParameters: nil, bodyEncoding: .jsonUrlEncoding, urlParameters: params)
            
        case .getChannels:
            return .requestParameters(bodyParameters: nil, bodyEncoding: .jsonUrlEncoding, urlParameters: nil)
            
        case .getChannelsInfo(let uniqueId):
            let params = [
                "unique_ids"  : uniqueId
                ] as [String : Any]
            return .requestParameters(bodyParameters: params, bodyEncoding: .jsonEncoding, urlParameters: nil)
            
        case .joinChannels(let uniqueId):
            let params = [
                "unique_ids"  : uniqueId
                ] as [String : Any]
            return .requestParameters(bodyParameters: params, bodyEncoding: .jsonEncoding, urlParameters: nil)
       
        case .leaveChannels(let uniqueId):
            let params = [
                "unique_ids"  : uniqueId
                ] as [String : Any]
            return .requestParameters(bodyParameters: params, bodyEncoding: .jsonEncoding, urlParameters: nil)
        
        case .usersPresence(let userIds):
            let params = [
                "user_ids"  : userIds
                ] as [String : Any]
            return .requestParameters(bodyParameters: params, bodyEncoding: .jsonEncoding, urlParameters: nil)
        }
    }
}

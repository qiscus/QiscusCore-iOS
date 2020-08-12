//
//  EndpointComment.swift
//  QiscusCore
//
//  Created by Qiscus on 13/08/18.
//

import Foundation

// MARK: Comment API
internal enum APIComment {
    case postComment(topicId: String, type: String, message: String, payload: [String:Any]?, extras: [String:Any]?, uniqueTempId: String?)
    case loadComment(topicId: String, lastCommentId: String?, after: Bool?, limit: Int?)
    case delete(commentUniqueId: [String])
    case updateStatus(roomId: String,lastCommentReadId: String?, lastCommentReceivedId: String?)
    case clear(roomChannelIds: [String])
    /// Search comment on server
    case search(keyword: String, roomID: String?, lastCommentID: Int?)
    case searchMessage(query: String, roomIds: [String]?, userId : String? = nil, type: [String]?, roomType : RoomType?, page: Int, limit : Int)
    case statusComment(id: String)
    case getFileList(roomIds: [String], fileType : String, page: Int, limit : Int)
}

extension APIComment : EndPoint {
    var baseURL: URL {
        return BASEURL
    }
    
    var path: String {
        switch self {
        case .postComment:
            return "/post_comment"
        case .loadComment:
            return "/load_comments"
        case .delete( _):
            return "/delete_messages"
        case .updateStatus( _, _, _):
            return "/update_comment_status"
        case .clear( _):
            return "/clear_room_messages"
        case .search:
            return "/search_messages"
        case .searchMessage:
            return "/search"
        case .statusComment(_):
            return "/comment_receipt"
        case .getFileList:
            return "/file_list"
        }
    }
    
    var httpMethod: HTTPMethod {
        switch self {
        case .loadComment, .statusComment(_):
            return .get
        case .postComment, .updateStatus, .search( _, _, _), .searchMessage( _, _, _, _, _, _, _), .getFileList( _, _, _, _):
            return .post
        case .delete, .clear( _):
            return .delete
        }
    }
    
    var header: HTTPHeaders? {
        return HEADERS
    }
    
    var task: HTTPTask {
        switch self {
        case .postComment(let topicId, let type, let message, let payload, let extras, let uniqueTempId):
            var params = [
                "topic_id"                   : topicId,
                "type"                       : type,
                "comment"                    : message
                ] as [String : Any]
            if let payloadParams = payload {
                params["payload"] = payloadParams
            }
            if let extrasParams = extras {
                params["extras"] = extrasParams
            }
            if let uniquetempid = uniqueTempId {
                params["unique_temp_id"] = uniquetempid
            }
            return .requestParameters(bodyParameters: params, bodyEncoding: .jsonEncoding, urlParameters: nil)
        case .loadComment(let topicId, let lastCommentId,let after,let limit):
            var params = [
                "topic_id"                   : topicId
                ] as [String : Any]
            
            if let lastcommentid = lastCommentId {
                if !lastcommentid.isEmpty {
                    let intValue = Int(lastcommentid)
                    if intValue != 0 {
                        params["last_comment_id"] = lastcommentid
                    }
                    
                }
            }
            if let aftr = after {
                params["after"] = aftr
            }
            if let limt = limit {
                params["limit"] = limt
            }
            return .requestParameters(bodyParameters: nil, bodyEncoding: .jsonUrlEncoding, urlParameters: params)
        case .delete(let id):
            var params = [
                "unique_ids"                : id,
                "is_hard_delete"            : true,
                "is_delete_for_everyone"    : true
                ] as [String : Any]
            return .requestParameters(bodyParameters: params, bodyEncoding: .jsonEncoding, urlParameters: nil)
        case .updateStatus(let roomId,let lastCommentReadId,let lastCommentReceivedId):
            var params = [
                "room_id"                   : roomId
                ] as [String : Any]
            
            if let lastcommentreadid = lastCommentReadId {
                params["last_comment_read_id"] = lastcommentreadid
            }
            
            if let lastcommentreceivedid = lastCommentReceivedId {
                params["last_comment_received_id"] = lastcommentreceivedid
            }
            
            return .requestParameters(bodyParameters: params, bodyEncoding: .jsonEncoding, urlParameters: nil)
        case .clear(let roomChannelIds):
            let params = [
                "room_channel_ids"           : roomChannelIds
                ] as [String : Any]
            return .requestParameters(bodyParameters: params, bodyEncoding: .jsonEncoding, urlParameters: nil)
        case .search(let keyword, let roomID, let lastCommentID):
            var params = [
                "query"                     : keyword,
            ] as [String : Any]
            if let id = roomID {
                params["room_id"] = id
            }
            if let commentID = lastCommentID {
                params["last_comment_id"] = commentID
            }
            return .requestParameters(bodyParameters: params, bodyEncoding: .jsonEncoding, urlParameters: nil)
        case .searchMessage(let query, let roomIds, let userId, let type, let roomType, let page, let limit):
            var params = [
                "query"             : query,
                "page"              : page,
                "limit"             : limit
                ] as [String : Any]
            
            if let roomIds = roomIds {
                params["room_ids"] = roomIds
            }
            
            if let userId = userId {
                params["sender"] = userId
            }
            
            if let type = type {
                params["type"] = type
            }
            
            if let roomType = roomType {
                if roomType == .group {
                    params["room_type"] = "group"
                    params["is_public"] = false
                    
                } else if roomType == .single {
                    params["room_type"] = "single"
                    params["is_public"] = false
                    
                } else {
                    params["room_type"] = "group"
                    params["is_public"] = true
                }
            }
            
            return .requestParameters(bodyParameters: params, bodyEncoding: .jsonEncoding, urlParameters: nil)
        case .statusComment(let id):
            let params = [
                "comment_id"                : id,
                ] as [String : Any]
            return .requestParameters(bodyParameters: nil, bodyEncoding: .jsonUrlEncoding, urlParameters: params)
        case .getFileList(let roomIds, let fileTye, let page, let limit) :
            var param = [
                "room_ids"       : roomIds,
                "file_type"      : fileTye,
                "page"           : page,
                "limit"          : limit
                ] as [String : Any]
            
            return .requestParameters(bodyParameters: param, bodyEncoding: .jsonEncoding, urlParameters: nil)
        
        }
    }
}

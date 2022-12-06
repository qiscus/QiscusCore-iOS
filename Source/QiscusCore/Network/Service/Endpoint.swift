//
//  Endpoint.swift
//  QiscusCore
//
//  Created by Qiscus on 17/07/18.
//  Copyright © 2018 Qiscus. All rights reserved.
//

import Foundation
import UIKit

protocol EndPoint {
    //var baseURL     : URL { get set}
    var path        : String { get }
    var httpMethod  : HTTPMethod { get }
    //var header      : HTTPHeaders? { get set}
    var task        : HTTPTask { get }
}


// MARK: General API
internal enum APIClient {
    case sync(lastReceivedCommentId: String)
    case syncEvent(startEventId : String)
    case search(keyword: String, roomId: String?, lastCommentId: Int?)
    case registerDeviceToken(token: String, isDevelopment: Bool) //
    case removeDeviceToken(token: String, isDevelopment: Bool) //
    case loginRegister(user: String, password: String , username: String?, avatarUrl: String?, extras: [String:Any]?) //
    case loginRegisterJWT(identityToken: String) //
    case nonce //
    case unread
    case myProfile //
    case updateMyProfile(name: String?, avatarUrl: String?, extras: [String : Any]?) //
    case upload
    case eventReport(moduleName: String, event: String, message: String)
    case appConfig
}
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      
extension APIClient : EndPoint {
    
    var path: String {
        switch self {
        case .sync( _):
            return "/sync"
        case .syncEvent( _):
            return "/sync_event"
        case .search( _, _, _):
            return "/search_messages"
        case .registerDeviceToken( _, _):
            return "/set_user_device_token"
        case .removeDeviceToken( _, _):
            return "/remove_user_device_token"
        case .loginRegister( _, _, _, _, _):
            return "/login_or_register"
        case .loginRegisterJWT( _):
            return "/auth/verify_identity_token"
        case .nonce :
            return "/auth/nonce"
        case .unread:
            return "/total_unread_count"
        case .myProfile:
            return "/my_profile"
        case .updateMyProfile( _, _, _):
            return "/my_profile"
        case .upload:
            return "/upload"
        case .eventReport( _, _, _):
            return "/event_report"
        case .appConfig:
            return "/config"
        }
    }
    
    var httpMethod: HTTPMethod {
        switch self {
        case .sync, .syncEvent, .unread, .myProfile, .appConfig:
            return .get
        case .search, .registerDeviceToken, .removeDeviceToken, .loginRegister, .loginRegisterJWT, .upload, .nonce, .eventReport:
            return .post
        case .updateMyProfile :
            return .patch
        }
    }
    
    var task: HTTPTask {
        switch self {
        case .sync(let lastReceivedCommentId) :
            let param = [
                "last_received_comment_id"    : lastReceivedCommentId
                ] as [String : Any]
            return .requestParameters(bodyParameters: nil, bodyEncoding: .jsonUrlEncoding, urlParameters: param)
        case .syncEvent(let startEventId):
            let param = [
                "start_event_id"              : startEventId
                ] as [String : Any]
            return .requestParameters(bodyParameters: nil, bodyEncoding: .jsonUrlEncoding, urlParameters: param)
        case .search(let keyword,let roomId,let lastCommentId) :
            var param = [
                "query"                       : keyword
                ] as [String : Any]
            
            if let roomid = roomId {
                param["room_id"] = roomid
            }
            
            if let lastcommentid = lastCommentId {
                param["last_comment_id"] = lastcommentid
            }
            
            return .requestParameters(bodyParameters: param, bodyEncoding: .jsonEncoding, urlParameters: nil)
        case .registerDeviceToken(let token, let isDevelopment):
            let param = [
                "device_token"                : token,
                "device_platform"             : "ios",
                "is_development"              : isDevelopment
                ] as [String : Any]
            return .requestParameters(bodyParameters: param, bodyEncoding: .jsonEncoding, urlParameters: nil)
        case .removeDeviceToken(let token, let isDevelopment):
            let param = [
                "device_token"                : token,
                "device_platform"             : "ios",
                "is_development"              : isDevelopment
                ] as [String : Any]
            return .requestParameters(bodyParameters: param, bodyEncoding: .jsonEncoding, urlParameters: nil)
        case .loginRegister(let user, let password, let username, let avatarUrl, let extras):
            var param = [
                "email"                       : user,
                "password"                    : password,
            ] as [String : Any]
            
            if let usernm = username {
                param["username"] = usernm
            }
            if let avatarurl = avatarUrl{
                param["avatar_url"] = avatarurl
            }
            if let extra = extras {
                param["extras"] = extra
            }
            return .requestParameters(bodyParameters: param, bodyEncoding: .jsonEncoding, urlParameters: nil)
        case .loginRegisterJWT(let identityToken):
            let param = [
                "identity_token"                       : identityToken
                ]
            
            return .requestParameters(bodyParameters: param, bodyEncoding: .jsonEncoding, urlParameters: nil)
        case .nonce :
            return .requestParameters(bodyParameters: nil, bodyEncoding: .jsonEncoding, urlParameters: nil)
        case .unread :
            return .requestParameters(bodyParameters: nil, bodyEncoding: .jsonUrlEncoding, urlParameters: nil)
        case .myProfile :
               return .requestParameters(bodyParameters: nil, bodyEncoding: .jsonUrlEncoding, urlParameters: nil)
        case .updateMyProfile(let name, let avatarUrl, let extras) :
            var param = [String : Any]()
            
            if let newName = name {
                param["name"] = newName
            }
            
            if let newAvatarUrl = avatarUrl {
                param["avatar_url"] = newAvatarUrl
            }
            
            if let _extras = extras {
                param["extras"] = _extras
            }
            
            return .requestParameters(bodyParameters: param, bodyEncoding: .jsonEncoding, urlParameters: nil)
        case .upload :
            return .requestParameters(bodyParameters: nil, bodyEncoding: .jsonEncoding, urlParameters: nil)
            
        case .eventReport(let moduleName, let event, let message) :
            let param = [
                "module_name"                 : moduleName,
                "event"                       : event,
                "message"                     : message,
                ] as [String : Any]
            return .requestParameters(bodyParameters: param, bodyEncoding: .jsonEncoding, urlParameters: nil)
            
        case .appConfig :
            return .requestParameters(bodyParameters: nil, bodyEncoding: .jsonUrlEncoding, urlParameters: nil)
        }
    }
}

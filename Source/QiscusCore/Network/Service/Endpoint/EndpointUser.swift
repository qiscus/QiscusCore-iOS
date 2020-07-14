//
//  EndpointUser.swift
//  QiscusCore
//
//  Created by Qiscus on 13/08/18.
//

import Foundation

// MARK: User API
internal enum APIUser {
    case block(email: String)
    case unblock(email: String)
    case listBloked(page: Int?, limit: Int?)
    case unread
    case getUsers(page: Int?, limit: Int?, querySearch: String?)
}

extension APIUser : EndPoint {
    var baseURL: URL {
        return BASEURL
    }
    
    var path: String {
        switch self {
        case .block( _):
            return "/block_user"
        case .unblock( _):
            return "/unblock_user"
        case .listBloked( _, _):
            return "/get_blocked_users"
        case .unread:
            return "/total_unread_count"
        case .getUsers( _, _, _):
            return "/get_user_list"
        }
    }
    
    var httpMethod: HTTPMethod {
        switch self {
        case .block, .unblock :
            return .post
        case .listBloked, .unread, .getUsers:
            return .get
        }
    }
    var header: HTTPHeaders? {
        return HEADERS
    }
    
    var task: HTTPTask {
        switch self {
        case .block(let email):
            let param = [
                "user_email"                  : email
            ]
            return .requestParameters(bodyParameters: param, bodyEncoding: .jsonEncoding, urlParameters: nil)
        case .unblock(let email):
            let param = [
                "user_email"                  : email
            ]
            return .requestParameters(bodyParameters: param, bodyEncoding: .jsonEncoding, urlParameters: nil)
        case .listBloked(let page,let limit):
            var params = [String : Any]()
            if let p = page {
                params["page"] = p
            }
            if let l = limit {
                params["limit"] = l
            }
            return .requestParameters(bodyParameters: nil, bodyEncoding: .jsonUrlEncoding, urlParameters: params)
        case .unread:
            return .requestParameters(bodyParameters: nil, bodyEncoding: .jsonUrlEncoding, urlParameters: nil)
        case .getUsers(let page,let limit, let querySearch):
        var params = [
            "order_query"                 : "username asc",
            ] as [String : Any]
        if let p = page {
            params["page"] = p
        }
        if let l = limit {
            params["limit"] = l
        }
        
        if let s = querySearch {
            params["query"] = s
        }
        
        return .requestParameters(bodyParameters: nil, bodyEncoding: .jsonUrlEncoding, urlParameters: params)
        }
    }
}

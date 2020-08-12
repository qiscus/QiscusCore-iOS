//
//  NetworkMessage.swift
//  QiscusCore
//
//  Created by Qiscus on 14/08/18.
//

import Foundation

// MARK: Comment
extension NetworkManager {
    
    /// load comments on a room or channel
    ///
    /// - Parameters:
    ///   - roomId: room id or unique id
    ///   - lastCommentId: last recieved comment id before loadmore
    ///   - after: if true returns comments with id >= last_comment_id. if false and last_comment_id is specified, returns last 20 comments with id < last_comment_id. if false and last_comment_id is not specified, returns last 20 comments
    ///   - limit: limit for the result default value is 20, max value is 100
    ///   - completion: @escaping when success load comments, return Optional([CommentModel]) and Optional(String error message)
    func loadComments(roomId: String, lastCommentId: String? = nil, after: Bool? = nil, limit: Int? = 20, completion: @escaping ([CommentModel]?, QError?) -> Void) {
        commentRouter.request(.loadComment(topicId: roomId, lastCommentId: lastCommentId, after: after, limit: limit)) { (data, response, error) in
            if error != nil {
                completion(nil, QError(message: error?.localizedDescription ?? "Please check your network connection."))
            }
            if let response = response as? HTTPURLResponse {
                let result = self.handleNetworkResponse(response)
                switch result {
                case .success:
                    guard let responseData = data else {
                        completion(nil, QError(message: NetworkResponse.noData.rawValue))
                        return
                    }
                    let response = ApiResponse.decode(from: responseData)
                    let comments = CommentApiResponse.comments(from: response)
                    completion(comments, nil)
                case .failure(let errorMessage):
                    do {
                        let jsondata = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers)
                        QiscusLogger.errorPrint("json: \(jsondata)")
                    } catch {
                        
                    }
                    completion(nil, QError(message: errorMessage))
                }
            }
        }
    }
    
    
    /// post comment
    ///
    /// - Parameters:
    ///   - roomId: chat room id
    ///   - type: comment type
    ///   - comment: comment text (required when type == text)
    ///   - payload: comment payload (string on json format)
    ///   - extras: comment extras (string on json format)
    ///   - uniqueTempId: -
    ///   - completion: @escaping when success post comment, return Optional(CommentModel) and Optional(String error message)
    func postComment(roomId: String, type: String = "text", message: String, payload: [String:Any]? = nil, extras: [String:Any]? = nil, uniqueTempId: String = "", completion: @escaping(CommentModel?, String?) -> Void) {
        commentRouter.request(.postComment(topicId: roomId, type: type, message: message, payload: payload, extras: extras, uniqueTempId: uniqueTempId)) { (data, response, error) in
            if error != nil {
                completion(nil, error?.localizedDescription ?? "Please check your network connection.")
            }
            if let response = response as? HTTPURLResponse {
                let result = self.handleNetworkResponse(response)
                switch result {
                case .success:
                    guard let responseData = data else {
                        completion(nil, NetworkResponse.noData.rawValue)
                        return
                    }
                    let response = ApiResponse.decode(from: responseData)
                    let comment = CommentApiResponse.comment(from: response)
                    completion(comment, nil)
                case .failure(let errorMessage):
                    if data != nil {
                        do {
                            let jsondata = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers)
                            QiscusLogger.errorPrint("json: \(jsondata)")
                            
                            let data = "json: \(jsondata)"
                            if data.range(of:"comment already exist") != nil {
                                if let comment = QiscusCore.database.comment.find(uniqueId: uniqueTempId){
                                    let sent = comment
                                    sent.status  = .sent
                                    QiscusCore.database.comment.save([sent])
                                    
                                    QiscusCore.shared.getRoom(withID: roomId, onSuccess: { (roomModel, comment) in
                                        
                                    }, onError: { (error) in
                                        
                                    })
                                }
                                
                                 completion(nil, "json: \(jsondata)")

                            }else{
                                switch response.statusCode {
                                case 400...599:
                                    if let comment = QiscusCore.database.comment.find(uniqueId: uniqueTempId){
                                        let failed = comment
                                        failed.status  = .failed
                                        QiscusCore.database.comment.save([failed])
                                    }
                                    completion(nil, "json: \(jsondata)")
                                default:
                                    completion(nil, "json: \(jsondata)")
                                    break
                                }
                            }
                        } catch {
                            QiscusLogger.errorPrint("Error postComment Code =\(response.statusCode)\(errorMessage)")
                            completion(nil, NetworkResponse.unableToDecode.rawValue)
                        }
                    }else{
                        QiscusLogger.errorPrint("Error postComment Code =\(response.statusCode)\(errorMessage)")
                        completion(nil, NetworkResponse.unableToDecode.rawValue)
                    }
                }
            }
        }
    }
    
    
    /// delete comments
    ///
    /// - Parameters:
    ///   - commentUniqueId: comment unique id or you can use comment.uniqueTempId
    ///   - completion: @escaping when success delete comments, return deleted comment Optional([CommentModel]) and Optional(String error message)
    func deleteComment(commentUniqueId: [String], completion: @escaping ([CommentModel]?, QError?) -> Void) {
        commentRouter.request(.delete(commentUniqueId: commentUniqueId)) { (data, response, error) in
            if error != nil {
                completion(nil, QError(message: error?.localizedDescription ?? "Please check your network connection."))
            }
            if let response = response as? HTTPURLResponse {
                let result = self.handleNetworkResponse(response)
                switch result {
                case .success:
                    guard let responseData = data else {
                        completion(nil, QError(message: NetworkResponse.noData.rawValue))
                        return
                    }
                    let response = ApiResponse.decode(from: responseData)
                    let comments = CommentApiResponse.comments(from: response)
                    completion(comments, nil)
                case .failure(let errorMessage):
                    do {
                        let jsondata = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers)
                        QiscusLogger.errorPrint("json: \(jsondata)")
                    } catch {
                        
                    }
                    
                    completion(nil, QError(message: errorMessage))
                }
            }
        }
    }
    
    // todo: add more documentation
    func updateCommentStatus(roomId: String, lastCommentReadId: String? = nil, lastCommentReceivedId: String? = nil) {
        commentRouter.request(.updateStatus(roomId: roomId, lastCommentReadId: lastCommentReadId, lastCommentReceivedId: lastCommentReceivedId)) { (data, response, error) in
            
            var commentReceivedId = "0"
            var commentReadId = "0"
            
            if let readID = lastCommentReadId {
                commentReadId = readID
            }
            
            if let receivedID = lastCommentReceivedId {
                commentReceivedId = receivedID
            }
            
            if let response = response as? HTTPURLResponse {
                let result = self.handleNetworkResponse(response)
                switch result {
                case .success:
                   return
                case .failure(let errorMessage):
                    do {
                        if let data = data{
                            let jsondata = try JSONSerialization.jsonObject(with: data, options: .mutableContainers)
                            QiscusLogger.errorPrint("json: \(jsondata)")
                        }else{
                            
                            QiscusLogger.errorPrint("Error updateCommentStatus Code =\(response.statusCode), \(errorMessage)")
                        }
                       
                    } catch {
                        var message = errorMessage
                        if error != nil {
                            message = error.localizedDescription
                        }
                        
                        QiscusLogger.errorPrint("Error updateCommentStatus Code =\(response.statusCode), \(message)")
                        
                    }
                }
            }
            
        }
    }
    
    /// Get total unread message
    ///
    /// - Parameter completion: result as Int
    func unreadCount(completion: @escaping(Int, QError?) -> Void) {
        userRouter.request(.unread) { (data, response, error) in
            if error != nil {
                completion(0, QError(message: error?.localizedDescription ?? "Please check your network connection."))
            }
            if let response = response as? HTTPURLResponse {
                let result = self.handleNetworkResponse(response)
                switch result {
                case .success:
                    guard let responseData = data else {
                        completion(0, QError(message: NetworkResponse.noData.rawValue))
                        return
                    }
                    let unread = ApiResponse.decode(unread: responseData)
                    completion(unread,nil)
                case .failure(let errorMessage):
                    completion(0, QError(message: "Can't parse error, when request unread count."))
                }
            }
        }
    }
    
//    /// Search message from server
//    ///
//    /// - Parameters:
//    ///   - keyword: required, keyword to search
//    ///   - roomID: optional, search on specific room by room id
//    ///   - lastCommentId: optional, will get comments aafter this id
//    func searchMessage(keyword: String, roomID: String?, lastCommentId: Int?, completion: @escaping ([CommentModel]?, QError?) -> Void) {
//        commentRouter.request(.search(keyword: keyword, roomID: roomID, lastCommentID: lastCommentId)) { (data, response, error) in
//            if error != nil {
//                completion(nil, QError(message: error?.localizedDescription ?? "Please check your network connection."))
//            }
//            if let response = response as? HTTPURLResponse {
//                let result = self.handleNetworkResponse(response)
//                switch result {
//                case .success:
//                    guard let responseData = data else {
//                        completion(nil, QError(message: NetworkResponse.noData.rawValue))
//                        return
//                    }
//                    let response = ApiResponse.decode(from: responseData)
//                    let comments = CommentApiResponse.comments(from: response)
//                    completion(comments, nil)
//                case .failure(let errorMessage):
//                    do {
//                        let jsondata = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers)
//                        QiscusLogger.errorPrint("json: \(jsondata)")
//                    } catch {
//                        
//                    }
//                    completion(nil, QError(message: errorMessage))
//                }
//            }
//        }
//    }
    
    /// Clear message from
    ///
    /// - Parameters:
    ///   - roomsUniqueID: room unique id where you want to clear
    ///   - completion: got error if exist
    func clearMessage(roomsUniqueID: [String], completion: @escaping (QError?) -> Void) {
        if roomsUniqueID.isEmpty {
            completion(QError.init(message: "Parameter can't be empty"))
        }
        commentRouter.request(.clear(roomChannelIds: roomsUniqueID)) { (data, response, error) in
            if error != nil {
                completion(QError(message: error?.localizedDescription ?? "Please check your network connection."))
            }
            if let response = response as? HTTPURLResponse {
                let result = self.handleNetworkResponse(response)
                switch result {
                case .success:
                    completion(nil)
                case .failure(let errorMessage):
                    do {
                        let jsondata = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers)
                        QiscusLogger.errorPrint("json: \(jsondata)")
                    } catch {
                        
                    }
                    completion(QError(message: errorMessage))
                }
            }
        }
    }
    
    /// readReceiptStatus
    ///
    /// - Parameters:
    ///   - commentId: comment id
    ///   - completion: commentInfo
    func readReceiptStatus(commentId id: String, completion: @escaping (CommentInfo?, QError?) -> Void) {
        commentRouter.request(.statusComment(id: id)) { (data, response, error) in
            if error != nil {
                completion(nil, QError(message: error?.localizedDescription ?? "Please check your network connection."))
            }
            if let response = response as? HTTPURLResponse {
                let result = self.handleNetworkResponse(response)
                switch result {
                case .success:
                    guard let responseData = data else {
                        completion(nil, QError(message: NetworkResponse.noData.rawValue))
                        return
                    }
                    let response = ApiResponse.decode(from: responseData)
                    let comment = CommentApiResponse.comment(from: response)
                    
                    
                    var commentInfo = CommentInfo()
                    commentInfo.comment = comment
                    
                    if let commentDeliveredUser = CommentApiResponse.commentDeliveredUser(from: response){
                        commentInfo.deliveredUser = commentDeliveredUser
                    }
                    if let commentPendingUser = CommentApiResponse.commentPendingUser(from: response){
                        commentInfo.sentUser = commentPendingUser
                    }
                    if let commentReadUser = CommentApiResponse.commentReadUser(from: response){
                        commentInfo.readUser = commentReadUser
                    }
                    
                    completion(commentInfo, nil)
                case .failure(let errorMessage):
                    do {
                        let jsondata = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers)
                        QiscusLogger.errorPrint("json: \(jsondata)")
                    } catch {
                        
                    }
                    
                    completion(nil, QError(message: errorMessage))
                }
            }
        }
        
    }
    
    /// Search message from server
    ///
    /// - Parameters:
    ///   - query: required, query to search
    ///   - roomIds:array  room id
    ///   - type: "text", "custom", "buttons", "button_postback_response", "reply", "card", "location", "contact_person", "file_attachment", "carousel", otther
    ///   - roomType : single, group, channel
    ///   - userId : emailSender
    ///   - page : page
    ///   - limit : limit
    func searchMessage(query: String, roomIds: [String]? = nil, userId : String? = nil, type: [String]? = nil, roomType : RoomType? = nil, page: Int, limit : Int, completion: @escaping ([CommentModel]?, QError?) -> Void) {
        commentRouter.request(.searchMessage(query: query, roomIds: roomIds, userId: userId, type: type, roomType : roomType, page: page, limit: limit)) { (data, response, error) in
            if error != nil {
                completion(nil, QError(message: error?.localizedDescription ?? "Please check your network connection."))
            }
            if let response = response as? HTTPURLResponse {
                let result = self.handleNetworkResponse(response)
                switch result {
                case .success:
                    guard let responseData = data else {
                        completion(nil, QError(message: NetworkResponse.noData.rawValue))
                        return
                    }
                    let response = ApiResponse.decode(from: responseData)
                    let comments = CommentApiResponse.comments(from: response)
                    completion(comments, nil)
                case .failure(let errorMessage):
                    do {
                        let jsondata = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers)
                        QiscusLogger.errorPrint("json: \(jsondata)")
                    } catch {
                        
                    }
                    completion(nil, QError(message: errorMessage))
                }
            }
        }
    }
    
    /// get fileList message from server
    ///
    /// - Parameters:
    ///   - roomIds:array  room id
    ///   - page: page
    ///   - limit : limit
    func getFileList(roomIds: [String], fileType : String, page: Int, limit : Int, completion: @escaping ([CommentModel]?, QError?) -> Void) {
        commentRouter.request(.getFileList(roomIds: roomIds, fileType : fileType, page: page, limit: limit)) { (data, response, error) in
            if error != nil {
                completion(nil, QError(message: error?.localizedDescription ?? "Please check your network connection."))
            }
            if let response = response as? HTTPURLResponse {
                let result = self.handleNetworkResponse(response)
                switch result {
                case .success:
                    guard let responseData = data else {
                        completion(nil, QError(message: NetworkResponse.noData.rawValue))
                        return
                    }
                    let response = ApiResponse.decode(from: responseData)
                    let comments = CommentApiResponse.comments(from: response)
                    completion(comments, nil)
                case .failure(let errorMessage):
                    do {
                        let jsondata = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers)
                        QiscusLogger.errorPrint("json: \(jsondata)")
                    } catch {
                        
                    }
                    completion(nil, QError(message: errorMessage))
                }
            }
        }
    }
}

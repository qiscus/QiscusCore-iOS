//
//  QiscusComment.swift
//  QiscusCore
//
//  Created by Qiscus on 25/07/18.
//  Copyright © 2018 Qiscus. All rights reserved.
//

import Foundation

// MARK: Comment Management
extension QiscusCore {
    @available(*, deprecated, message: "will soon become unavailable.")
    public func sendMessage(roomID id: String, comment: CommentModel, onSuccess: @escaping (CommentModel) -> Void, onError: @escaping (QError) -> Void) {
        // update comment
        let _comment            = comment
        _comment.roomId         = id
        _comment.status         = .sending
        _comment.timestamp      = CommentModel.getTimestamp()
        // check comment type, if not Qiscus Comment set as custom type
        if !_comment.isQiscustype() {
            let _payload    = _comment.payload
            let _type       = _comment.type
            _comment.type = "custom"
            _comment.payload?.removeAll() // clear last payload then recreate
            _comment.payload = ["type" : _type]
            if let payload = _payload {
                _comment.payload!["content"] = payload
            }else {
                _comment.payload!["content"] = ["":""]
            }
        }
        
        if (comment.type == "reply"){
            if (comment.payload != nil) {
                if let messageTypeReply = comment.payload?["replied_comment_type"] as? String {
                    if messageTypeReply == "system_event" {
                        let failed = comment
                        failed.status  = .failed
                        QiscusCore.database.comment.save([failed])
                        onError(QError.init(message: "can't reply on system_event type"))
                        return
                    }
                }
            }
        }

        // send message to server
        QiscusCore.network.postComment(roomId: comment.roomId, type: comment.type, message: comment.message, payload: comment.payload, extras: comment.extras, uniqueTempId: comment.uniqId) { (result, error) in
            
            if error != nil {
                //save in local comment pending
                QiscusCore.database.comment.save([_comment])
            }
            
            if let commentResult = result {
                // save in local
                commentResult.status = .sent
                QiscusCore.database.comment.save([commentResult])
                
                if let roomData = QiscusCore.database.room.find(id: commentResult.roomId){
                    roomData.lastComment = commentResult
                    QiscusCore.database.room.save([roomData])
                }
                //comment.onChange(commentResult) // view data binding
                onSuccess(commentResult)
            }else {
                let _pending = comment
                _pending.status  = .pending
                QiscusCore.database.comment.save([_pending])
                //comment.onChange(_pending) // view data binding
                onError(QError.init(message: error ?? "Pending to send message"))
            }
        }
    }
    
    /// Send Message
    ///
    /// - Parameters:
    ///   - id: Room ID
    ///   - message: CommentModel()
    ///   - completion: Response commentModel Object and error if exist.
    public func sendMessage(message: CommentModel, onSuccess: @escaping (CommentModel) -> Void, onError: @escaping (QError) -> Void) {
        // update comment
        let _comment            = message
        _comment.roomId         = message.roomId
        _comment.status         = .sending
        _comment.timestamp      = CommentModel.getTimestamp()
        // check comment type, if not Qiscus Comment set as custom type
        if !_comment.isQiscustype() {
            let _payload    = _comment.payload
            let _type       = _comment.type
            _comment.type = "custom"
            _comment.payload?.removeAll() // clear last payload then recreate
            _comment.payload = ["type" : _type]
            if let payload = _payload {
                _comment.payload!["content"] = payload
            }else {
                _comment.payload!["content"] = ["":""]
            }
        }
        
        if (message.type == "reply"){
            if (message.payload != nil) {
                if let messageTypeReply = message.payload?["replied_comment_type"] as? String {
                    if messageTypeReply == "system_event" {
                        let failed = message
                        failed.status  = .failed
                        QiscusCore.database.comment.save([failed])
                        onError(QError.init(message: "can't reply on system_event type"))
                        return
                    }
                }
            }
        }
        
        // send message to server
        QiscusCore.network.postComment(roomId: message.roomId, type: message.type, message: message.message, payload: message.payload, extras: message.extras, uniqueTempId: message.uniqId) { (result, error) in
            
            if error != nil {
                //save in local comment pending
                QiscusCore.database.comment.save([_comment])
            }
            
            if let commentResult = result {
                // save in local
                commentResult.status = .sent
                QiscusCore.database.comment.save([commentResult])
                
                if let roomData = QiscusCore.database.room.find(id: commentResult.roomId){
                    roomData.lastComment = commentResult
                    QiscusCore.database.room.save([roomData])
                }
                //comment.onChange(commentResult) // view data binding
                onSuccess(commentResult)
            }else {
                let _pending = message
                _pending.status  = .pending
                QiscusCore.database.comment.save([_pending])
                //comment.onChange(_pending) // view data binding
                onError(QError.init(message: error ?? "Pending to send message"))
            }
        }
    }
    
    /// Send FileMessage
    ///
    /// - Parameters:
    ///   - roomID: Room ID
    ///   - message: CommentModel()
    ///   - file : FileUploadModel()
    ///   - completion: Response commentModel Object and error if exist.
    public func sendFileMessage(message: CommentModel, file: FileUploadModel, progressUploadListener:  @escaping (Double) -> Void, onSuccess: @escaping (CommentModel) -> Void, onError: @escaping (QError) -> Void){
        
        guard let data = file.data else {
            onError(QError(message: "file data can't be empty"))
            return
        }
        
        if file.name.isEmpty {
            onError(QError(message: "file name can't be empty"))
            return
        }
        
        QiscusCore.shared.upload(file: file, onSuccess: { (fileModel) in
            
            let messageData = message
            message.payload = [
                "url"       : fileModel.url.absoluteString,
                "file_name" : fileModel.name,
                "size"      : fileModel.size,
                "caption"   : file.caption
            ]
            self.sendMessage(message: messageData, onSuccess: { (commentModel) in
                onSuccess(commentModel)
            }, onError: { (error) in
                onError(error)
            })
        }, onError: { (error) in
            onError(error)
        }) { (progress) in
            progressUploadListener(progress)
        }
    
    }
    
    /// Load Comment by room
    ///
    /// - Parameters:
    ///   - id: Room ID
    ///   - lastCommentId: last recieved comment id before loadmore
    ///   - after: if true returns comments with id >= last_comment_id. if false and last_comment_id is specified, returns last 20 comments with id < last_comment_id. if false and last_comment_id is not specified, returns last 20 comments
    ///   - limit: by default set 20, min 0 and max 100
    ///   - completion: Response new Qiscus Array of Comment Object and error if exist.
    @available(*, deprecated, message: "will soon become unavailable.")
    public func loadComments(roomID id: String, lastCommentId: String? = nil, after: Bool? = nil, limit: Int? = 20, onSuccess: @escaping ([CommentModel]) -> Void, onError: @escaping (QError) -> Void) {
        // Load message by default 20
        QiscusCore.network.loadComments(roomId: id, lastCommentId: lastCommentId, after: after, limit: limit) { (comments, error) in
            if let c = comments {
                // save comment in local
                QiscusCore.database.comment.save(c, publishEvent: false)
                onSuccess(c)
            }else {
                onError(error ?? QError(message: "Unexpected error"))
            }
        }
    }
    
    
    /// Load Comment by room
    ///
    /// - Parameters:
    ///   - roomId: Room ID
    ///   - messageId: last recieved comment id before loadmore
    ///   - limit: min 0 and max 100
    ///   - completion: Response new Qiscus Array of Comment Object and error if exist.
    public func getPreviousMessagesById(roomID id: String, limit: Int, messageId: String? = nil, onSuccess: @escaping ([CommentModel]) -> Void, onError: @escaping (QError) -> Void) {
        // Load message by default 20
        QiscusCore.network.loadComments(roomId: id, lastCommentId: messageId, after: false, limit: limit) { (comments, error) in
            if let c = comments {
                // save comment in local
                QiscusCore.database.comment.save(c, publishEvent: false)
                onSuccess(c)
            }else {
                onError(error ?? QError(message: "Unexpected error"))
            }
        }
    }
    
    /// Load Comment by room
    ///
    /// - Parameters:
    ///   - roomId: Room ID
    ///   - messageId: last recieved comment id before loadmore
    ///   - limit: min 0 and max 100
    ///   - completion: Response new Qiscus Array of Comment Object and error if exist.
    public func getNextMessagesById(roomId: String, limit: Int, messageId: String? = nil, onSuccess: @escaping ([CommentModel]) -> Void, onError: @escaping (QError) -> Void) {
        // Load message by default 20
        QiscusCore.network.loadComments(roomId: roomId, lastCommentId: messageId, after: true, limit: limit) { (comments, error) in
            if let c = comments {
                // save comment in local
                QiscusCore.database.comment.save(c, publishEvent: false)
                onSuccess(c)
            }else {
                onError(error ?? QError(message: "Unexpected error"))
            }
        }
    }
    
    /// Load More Message in room
    ///
    /// - Parameters:
    ///   - roomID: Room ID
    ///   - lastCommentID: last comment id want to load
    ///   - after: if true returns comments with id >= last_comment_id. if false and last_comment_id is specified, returns last 20 comments with id < last_comment_id. if false and last_comment_id is not specified, returns last 20 comments
    ///   - limit: min 0 and max 100
    ///   - completion: Response new Qiscus Array of Comment Object and error if exist.
    public func loadMore(roomID id: String, lastCommentID commentID: String, after: Bool? = nil, limit: Int, onSuccess: @escaping ([CommentModel]) -> Void, onError: @escaping (QError) -> Void) {
        // Load message from server
        QiscusCore.network.loadComments(roomId: id, lastCommentId: commentID, after: after, limit: limit) { (comments, error) in
            if let c = comments {
                // save comment in local
                QiscusCore.database.comment.save(c, publishEvent: false)
                onSuccess(c)
            }else {
                onError(error ?? QError(message: "Unexpected error"))
            }
        }
    }
    
    /// Delete message by id
    ///
    /// - Parameters:
    ///   - uniqueID: comment unique id
    ///   - completion: Response Comments your deleted
    @available(*, deprecated, message: "will soon become unavailable.")
    public func deleteMessage(uniqueIDs id: [String], onSuccess: @escaping ([CommentModel]) -> Void, onError: @escaping (QError) -> Void) {
        QiscusCore.network.deleteComment(commentUniqueId: id) { (results, error) in
            if let c = results {
                // MARK : delete comment in local
                for comment in c {
                    // delete
                    _ = QiscusCore.database.comment.delete(comment)
                    onSuccess(c)
                }
            }else {
                onError(error ?? QError(message: "Unexpected error"))
            }
        }
    }
    
    /// Delete message by id
    ///
    /// - Parameters:
    ///   - messageUniqueIds: comment unique id
    ///   - completion: Response Comments your deleted
    public func deleteMessages(messageUniqueIds: [String], onSuccess: @escaping ([CommentModel]) -> Void, onError: @escaping (QError) -> Void) {
        QiscusCore.network.deleteComment(commentUniqueId: messageUniqueIds) { (results, error) in
            if let c = results {
                // MARK : delete comment in local
                for comment in c {
                    // delete
                    _ = QiscusCore.database.comment.delete(comment)
                    onSuccess(c)
                }
            }else {
                onError(error ?? QError(message: "Unexpected error"))
            }
        }
    }
    
    /// Delete all message in room
    ///
    /// - Parameters:
    ///   - roomID: array of room id
    ///   - completion: Response error if exist
    @available(*, deprecated, message: "will soon become unavailable.")
    public func deleteAllMessage(roomID ids: [String], completion: @escaping (QError?) -> Void) {
        if ids.isEmpty {
            completion(QError.init(message: "Parameter can't be empty"))
            return
        }
        var uniqueID : [String] = [String]()
        ids.forEach { (id) in
            if let room = QiscusCore.database.room.find(id: id) {
                uniqueID.append(room.uniqueId)
            }
        }
        
        QiscusCore.shared.deleteAllMessage(roomUniqID: uniqueID, completion: completion)
    }
    
    /// Delete all message in room
    ///
    /// - Parameters:
    ///   - roomIds: array of room id
    ///   - completion: Response error if exist
    public func clearMessagesByChatRoomId(roomIds: [String], completion: @escaping (QError?) -> Void) {
        if roomIds.isEmpty {
            completion(QError.init(message: "Parameter can't be empty"))
            return
        }
        var uniqueID : [String] = [String]()
        roomIds.forEach { (id) in
            if let room = QiscusCore.database.room.find(id: id) {
                uniqueID.append(room.uniqueId)
            }
        }
        
        QiscusCore.shared.deleteAllMessage(roomUniqID: uniqueID, completion: completion)
    }
    
    /// Delete all message in room
    ///
    /// - Parameters:
    ///   - roomUniqID: array of room uniq id
    ///   - completion: Response error if exist
    @available(*, deprecated, message: "will soon become unavailable.")
    public func deleteAllMessage(roomUniqID roomIDs: [String], completion: @escaping (QError?) -> Void) {
        QiscusCore.network.clearMessage(roomsUniqueID: roomIDs) { (error) in
            if error == nil {
                // delete comment on local
                roomIDs.forEach({ (id) in
                    if let room = QiscusCore.database.room.find(uniqID: id) {
                        QiscusCore.database.comment.clear(inRoom: room.id)
                        room.lastComment    = nil
                        room.unreadCount    = 0
                        QiscusCore.database.room.save([room])
                        QiscusEventManager.shared.roomUpdate(room: room)
                    }
                })
            }
            completion(error)
        }
    }
    
    /// Delete all message in room
    ///
    /// - Parameters:
    ///   - roomUniqIds: array of room uniq id
    ///   - completion: Response error if exist
    public func clearMessagesByChatRoomId(roomUniqIds: [String], completion: @escaping (QError?) -> Void) {
        QiscusCore.network.clearMessage(roomsUniqueID: roomUniqIds) { (error) in
            if error == nil {
                // delete comment on local
                roomUniqIds.forEach({ (id) in
                    if let room = QiscusCore.database.room.find(uniqID: id) {
                        QiscusCore.database.comment.clear(inRoom: room.id)
                        room.lastComment    = nil
                        room.unreadCount    = 0
                        QiscusCore.database.room.save([room])
                        QiscusEventManager.shared.roomUpdate(room: room)
                    }
                })
            }
            completion(error)
        }
    }
    
    /// Search message
    ///
    /// - Parameters:
    ///   - keyword: required, keyword to search
    ///   - roomID: optional, search on specific room by room id
    ///   - lastCommentId: optional, will get comments aafter this id
//    public func searchMessage(keyword: String, roomID: String?, lastCommentId: Int?, onSuccess: @escaping ([CommentModel]) -> Void, onError: @escaping (QError) -> Void) {
//        QiscusCore.network.searchMessage(keyword: keyword, roomID: roomID, lastCommentId: lastCommentId) { (results, error) in
//            if let c = results {
//                onSuccess(c)
//            }else {
//                onError(error ?? QError(message: "Unexpected error"))
//            }
//        }
//    }
    
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
    public func searchMessage(query: String, roomIds: [String]? = nil, userId : String? = nil, type: [String]? = nil, roomType : RoomType? = nil, page: Int, limit : Int, onSuccess: @escaping ([CommentModel]) -> Void, onError: @escaping (QError) -> Void) {
        QiscusCore.network.searchMessage(query: query, roomIds: roomIds, userId: userId, type: type, roomType : roomType, page: page, limit: limit) { (results, error) in
            if let c = results {
                onSuccess(c)
            }else {
                onError(error ?? QError(message: "Unexpected error"))
            }
        }
    }
    
    /// get fileList message from server
    ///
    /// - Parameters:
    ///   - roomIds:array  room id
    ///   - fileType  type of file that want to search for: "media", "doc", "link" and "others"
    ///   - page: page
    ///   - limit : limit (maximum limit is 10)
    public func getFileList(roomIds: [String], fileType : String, page: Int, limit : Int, onSuccess: @escaping ([CommentModel]) -> Void, onError: @escaping (QError) -> Void) {
        QiscusCore.network.getFileList(roomIds: roomIds, fileType : fileType, page: page, limit: limit) { (results, error) in
            if let c = results {
                onSuccess(c)
            }else {
                onError(error ?? QError(message: "Unexpected error"))
            }
        }
    }
    
    /// Mark Comment as read, include comment before
    ///
    /// - Parameters:
    ///   - roomId: room id, where comment cooming
    ///   - lastCommentReadId: comment id
    @available(*, deprecated, message: "will soon become unavailable.")
    public func updateCommentRead(roomId: String, lastCommentReadId commentID: String) {
        // update unread comment
        if let comment = QiscusCore.database.comment.find(id: commentID) {
            _ = QiscusCore.database.room.updateReadComment(comment)
        }
         QiscusCore.network.updateCommentStatus(roomId: roomId, lastCommentReadId: commentID, lastCommentReceivedId: nil)
    }
    
    /// Mark Comment as read
    ///
    /// - Parameters:
    ///   - roomId: room id, where comment cooming
    ///   - commentId: commentId you want to read
    public func markAsRead(roomId: String, commentId: String) {
        // update unread comment
        if let comment = QiscusCore.database.comment.find(id: commentId) {
            _ = QiscusCore.database.room.updateReadComment(comment)
        }
        QiscusCore.network.updateCommentStatus(roomId: roomId, lastCommentReadId: commentId, lastCommentReceivedId: nil)
    }
    
    /// Mark Comment as received or deliverd, include comment before
    ///
    /// - Parameters:
    ///   - roomId: room id, where comment cooming
    ///   - lastCommentReceivedId: comment id
    @available(*, deprecated, message: "will soon become unavailable.")
    public func updateCommentReceive(roomId: String, lastCommentReceivedId commentID: String) {
        QiscusCore.network.updateCommentStatus(roomId: roomId, lastCommentReadId: nil, lastCommentReceivedId: commentID)
        
        guard let comment = QiscusCore.database.comment.find(id: commentID) else{
            return
        }
        let new = comment
        // update comment
        new.status = .delivered
        QiscusCore.database.comment.save([new])
    }
    
    /// Mark Comment as received or deliverd, include comment before
    ///
    /// - Parameters:
    ///   - roomId: room id, where comment cooming
    ///   - commentId: commentId you want to read
    public func markAsDelivered(roomId: String, commentId: String) {
        QiscusCore.network.updateCommentStatus(roomId: roomId, lastCommentReadId: nil, lastCommentReceivedId: commentId)
        
        guard let comment = QiscusCore.database.comment.find(id: commentId) else{
            return
        }
        
        let new = comment
        // update comment
        new.status = .delivered
        QiscusCore.database.comment.save([new])
       
    }
    
    /// Get comment status is read or received
    ///
    /// - Parameters:
    ///   - id: comment id
    ///   - completion: return object commentInfo
    public func readReceiptStatus(commentId id: String, onSuccess: @escaping (CommentInfo) -> Void, onError: @escaping (QError) -> Void) {
        
        if let comment = QiscusCore.database.comment.find(id: id){
            if let room = QiscusCore.database.room.find(id: comment.roomId){
                var commentInfo = CommentInfo()
                commentInfo.comment = comment
                
                var readUser = [MemberModel]()
                var deliveredUser = [MemberModel]()
                var sentUser = [MemberModel]()
                
                for participant in room.participants!{
                    if participant.lastCommentReadId >= Int(comment.id)!{
                        readUser.append(participant)
                    }else if (participant.lastCommentReceivedId >= Int(comment.id)!){
                        deliveredUser.append(participant)
                    }else{
                        sentUser.append(participant)
                    }
                }
                
                commentInfo.deliveredUser = deliveredUser
                commentInfo.readUser = readUser
                commentInfo.sentUser = sentUser
                
                onSuccess(commentInfo)
                
            }else{
                onError(QError(message: "Failed get room from local db"))
            }
        }else{
            onError(QError(message: "Failed get comment from local db"))
        }
    }
    
}

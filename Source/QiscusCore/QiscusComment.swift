//
//  QiscusComment.swift
//  QiscusCore
//
//  Created by Qiscus on 25/07/18.
//  Copyright © 2018 Qiscus. All rights reserved.
//

import Foundation

// MARK: Comment Management
extension NewQiscusCore {
    /// Update Message
    ///
    /// - Parameters:
    ///   - message: CommentModel()
    ///   - completion: Response commentModel Object and error if exist.
    public func updateMessage(message: QMessage, onSuccess: @escaping (QMessage) -> Void, onError: @escaping (QError) -> Void) {
        // update comment
        let _comment                = message
        _comment.chatRoomId         = message.chatRoomId
        _comment.status             = message.status
        _comment.timestampString    = message.timestampString
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
                        self.qiscusCore?.database.message.save([failed])
                        onError(QError.init(message: "can't reply on system_event type"))
                        return
                    }
                }
            }
        }
        
        // send message to server
        self.qiscusCore?.network.updateComment(message: message.message, payload: message.payload, extras: message.extras, uniqueTempId: message.uniqueId) { (result, error) in
            
            if let commentResult = result {
                // save in local
                self.qiscusCore?.database.message.save([commentResult], publishEvent: true, isUpdateMessage: true)
                
                onSuccess(commentResult)
            }else {
                onError(QError.init(message:"\(error)"))
            }
        }
    }
    

    
    @available(*, deprecated, message: "will soon become unavailable.")
    public func sendMessage(roomID id: String, comment: QMessage, onSuccess: @escaping (QMessage) -> Void, onError: @escaping (QError) -> Void) {
       
        guard let user = self.qiscusCore?.getProfile() else { return }
        
        if comment.name.isEmpty{
            comment.name = user.name
        }
        
        if comment.userAvatarUrl == nil{
            comment.userAvatarUrl      = user.avatarUrl
        }
        
        if comment.userEmail.isEmpty{
            comment.userEmail = user.id
        }
        
        // update comment
        let _comment            = comment
        _comment.chatRoomId         = id
        _comment.status         = .sending
        _comment.timestampString      = QMessage.getTimestamp()
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
                        self.qiscusCore?.database.message.save([failed])
                        onError(QError.init(message: "can't reply on system_event type"))
                        return
                    }
                }
            }
        }

        // send message to server
        self.qiscusCore?.network.postComment(roomId: comment.chatRoomId, type: comment.type, message: comment.message, payload: comment.payload, extras: comment.extras, uniqueTempId: comment.uniqueId) { (result, error) in
            
            if error != nil {
                //save in local comment pending
                _comment.status = .pending
                self.qiscusCore?.database.message.save([_comment])
            }
            
            if let commentResult = result {
                // save in local
                commentResult.status = .sent
                self.qiscusCore?.database.message.save([commentResult])
                DispatchQueue.global(qos: .background).sync{
                    if let roomData = self.qiscusCore?.database.room.find(id: commentResult.chatRoomId){
                        roomData.lastComment = commentResult
                        self.qiscusCore?.database.room.save([roomData])
                    }
                }
                
                //comment.onChange(commentResult) // view data binding
                onSuccess(commentResult)
            }else {
                if let comment = self.qiscusCore?.database.message.find(uniqueId: comment.uniqueId){
                    if comment.status == .failed{
                        onError(QError.init(message: error ?? "Failed to send message"))
                    }else{
                        let _pending = _comment
                        _pending.status  = .pending
                        self.qiscusCore?.database.message.save([_pending])
                        onError(QError.init(message: error ?? "Pending to send message"))
                    }
                }else if error?.contains("failed send message") == true{
                    let _failed = _comment
                    _failed.status  = .failed
                    self.qiscusCore?.database.message.save([_failed])
                    onError(QError.init(message: error ?? "Failed to send message"))
                }else{
                    let _pending = _comment
                    _pending.status  = .pending
                    self.qiscusCore?.database.message.save([_pending])
                    onError(QError.init(message: error ?? "Pending to send message"))
                }
            }
        }
    }
    
    /// Send Message
    ///
    /// - Parameters:
    ///   - id: Room ID
    ///   - message: CommentModel()
    ///   - completion: Response commentModel Object and error if exist.
    public func sendMessage(message: QMessage, onSuccess: @escaping (QMessage) -> Void, onError: @escaping (QError) -> Void) {
        guard let user = self.qiscusCore?.getProfile() else { return }
        
        if message.name.isEmpty{
            message.name = user.name
        }
        
        if message.userAvatarUrl == nil{
            message.userAvatarUrl      = user.avatarUrl
        }
        
        if message.userEmail.isEmpty{
            message.userEmail = user.id
        }
        
        // update comment
        let _comment                = message
        _comment.chatRoomId         = message.chatRoomId
        _comment.status             = .sending
        _comment.timestampString    = QMessage.getTimestamp()
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
                        self.qiscusCore?.database.message.save([failed])
                        onError(QError.init(message: "can't reply on system_event type"))
                        return
                    }
                }
            }
        }
        
        // send message to server
        self.qiscusCore?.network.postComment(roomId: message.chatRoomId, type: message.type, message: message.message, payload: message.payload, extras: message.extras, uniqueTempId: message.uniqueId) { (result, error) in
            
            if error != nil {
                //save in local comment pending
                _comment.status = .pending
                self.qiscusCore?.database.message.save([_comment])
            }
            
            if let commentResult = result {
                // save in local
                commentResult.status = .sent
                self.qiscusCore?.database.message.save([commentResult])
                DispatchQueue.global(qos: .background).sync{
                    if let roomData = self.qiscusCore?.database.room.find(id: commentResult.chatRoomId){
                        roomData.lastComment = commentResult
                        self.qiscusCore?.database.room.save([roomData])
                    }
                }
                
                //comment.onChange(commentResult) // view data binding
                onSuccess(commentResult)
            }else {
                if let comment = self.qiscusCore?.database.message.find(uniqueId: message.uniqueId){
                    if comment.status == .failed{
                        onError(QError.init(message: error ?? "Failed to send message"))
                    }else{
                        let _pending = _comment
                        _pending.status  = .pending
                        self.qiscusCore?.database.message.save([_pending])
                        onError(QError.init(message: error ?? "Pending to send message"))
                    }
                }else if error?.contains("failed send message") == true{
                    let _failed = _comment
                    _failed.status  = .failed
                    self.qiscusCore?.database.message.save([_failed])
                    onError(QError.init(message: error ?? "Failed to send message"))
                }else{
                    let _pending = _comment
                    _pending.status  = .pending
                    self.qiscusCore?.database.message.save([_pending])
                    onError(QError.init(message: error ?? "Pending to send message"))
                }
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
    public func sendFileMessage(message: QMessage, file: FileUploadModel, progressUploadListener:  @escaping (Double) -> Void, onSuccess: @escaping (QMessage) -> Void, onError: @escaping (QError) -> Void){
        
        guard let data = file.data else {
            onError(QError(message: "file data can't be empty"))
            return
        }
        
        if file.name.isEmpty {
            onError(QError(message: "file name can't be empty"))
            return
        }
        
        self.qiscusCore?.shared.upload(file: file, onSuccess: { (fileModel) in
            
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
    public func loadComments(roomID id: String, lastCommentId: String? = nil, after: Bool? = nil, limit: Int? = 20, onSuccess: @escaping ([QMessage]) -> Void, onError: @escaping (QError) -> Void) {
        // Load message by default 20
        self.qiscusCore?.network.loadComments(roomId: id, lastCommentId: lastCommentId, after: after, limit: limit) { (comments, error) in
            if let c = comments {
                // save comment in local
                self.qiscusCore?.database.message.save(c, publishEvent: false)
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
    public func getPreviousMessagesById(roomID id: String, limit: Int, messageId: String? = nil, onSuccess: @escaping ([QMessage]) -> Void, onError: @escaping (QError) -> Void) {
        // Load message by default 20
        self.qiscusCore?.network.loadComments(roomId: id, lastCommentId: messageId, after: false, limit: limit) { (comments, error) in
            if let c = comments {
                // save comment in local
                self.qiscusCore?.database.message.save(c, publishEvent: false)
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
    public func getNextMessagesById(roomId: String, limit: Int, messageId: String? = nil, onSuccess: @escaping ([QMessage]) -> Void, onError: @escaping (QError) -> Void) {
        // Load message by default 20
        self.qiscusCore?.network.loadComments(roomId: roomId, lastCommentId: messageId, after: true, limit: limit) { (comments, error) in
            if let c = comments {
                // save comment in local
                self.qiscusCore?.database.message.save(c, publishEvent: false)
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
    public func loadMore(roomID id: String, lastCommentID commentID: String, after: Bool? = nil, limit: Int, onSuccess: @escaping ([QMessage]) -> Void, onError: @escaping (QError) -> Void) {
        // Load message from server
        self.qiscusCore?.network.loadComments(roomId: id, lastCommentId: commentID, after: after, limit: limit) { (comments, error) in
            if let c = comments {
                // save comment in local
                self.qiscusCore?.database.message.save(c, publishEvent: false)
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
    public func deleteMessage(uniqueIDs id: [String], onSuccess: @escaping ([QMessage]) -> Void, onError: @escaping (QError) -> Void) {
        self.qiscusCore?.network.deleteComment(commentUniqueId: id) { (results, error) in
            if let c = results {
                // MARK : delete comment in local
                for comment in c {
                    // delete
                    _ = self.qiscusCore?.database.message.delete(comment)
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
    public func deleteMessages(messageUniqueIds: [String], onSuccess: @escaping ([QMessage]) -> Void, onError: @escaping (QError) -> Void) {
        self.qiscusCore?.network.deleteComment(commentUniqueId: messageUniqueIds) { (results, error) in
            if let c = results {
                // MARK : delete comment in local
                for comment in c {
                    // delete
                    _ = self.qiscusCore?.database.message.delete(comment)
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
            if let room = self.qiscusCore?.database.room.find(id: id) {
                uniqueID.append(room.uniqueId)
            }
        }
        
        self.deleteAllMessage(roomUniqID: uniqueID, completion: completion)
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
            if let room = self.qiscusCore?.database.room.find(id: id) {
                uniqueID.append(room.uniqueId)
            }
        }
        
        self.deleteAllMessage(roomUniqID: uniqueID, completion: completion)
    }
    
    /// Delete all message in room
    ///
    /// - Parameters:
    ///   - roomUniqID: array of room uniq id
    ///   - completion: Response error if exist
    @available(*, deprecated, message: "will soon become unavailable.")
    public func deleteAllMessage(roomUniqID roomIDs: [String], completion: @escaping (QError?) -> Void) {
        self.qiscusCore?.network.clearMessage(roomsUniqueID: roomIDs) { (error) in
            if error == nil {
                // delete comment on local
                roomIDs.forEach({ (id) in
                    if let room = self.qiscusCore?.database.room.find(uniqID: id) {
                        self.qiscusCore?.database.message.clear(inRoom: room.id)
                        room.lastComment    = nil
                        room.unreadCount    = 0
                        self.qiscusCore?.database.room.save([room])
                        self.qiscusCore?.eventManager.roomUpdate(room: room)
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
        self.qiscusCore?.network.clearMessage(roomsUniqueID: roomUniqIds) { (error) in
            if error == nil {
                // delete comment on local
                roomUniqIds.forEach({ (id) in
                    if let room = self.qiscusCore?.database.room.find(uniqID: id) {
                        self.qiscusCore?.database.message.clear(inRoom: room.id)
                        room.lastComment    = nil
                        room.unreadCount    = 0
                        self.qiscusCore?.database.room.save([room])
                        self.qiscusCore?.eventManager.roomUpdate(room: room)
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
//        self.qiscusCore?.network.searchMessage(keyword: keyword, roomID: roomID, lastCommentId: lastCommentId) { (results, error) in
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
    public func searchMessage(query: String, roomIds: [String]? = nil, userId : String? = nil, type: [String]? = nil, roomType : RoomType? = nil, page: Int, limit : Int, onSuccess: @escaping ([QMessage]) -> Void, onError: @escaping (QError) -> Void) {
        self.qiscusCore?.network.searchMessage(query: query, roomIds: roomIds, userId: userId, type: type, roomType : roomType, page: page, limit: limit) { (results, error) in
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
    ///   - userId : Sender userId
    ///   - includeExtensions : example ["jpg", ''png']
    ///   - excludeExtensions : example ["gif"]
    ///   - page: page
    ///   - limit : limit (maximum limit is 10)
    public func getFileList(roomIds: [String]? = nil, fileType : String? = nil , userId: String? = nil, includeExtensions : [String]? = nil, excludeExtensions : [String]? = nil, page: Int, limit : Int, onSuccess: @escaping ([QMessage]) -> Void, onError: @escaping (QError) -> Void) {
        self.qiscusCore?.network.getFileList(roomIds: roomIds, fileType : fileType,userId: userId, includeExtensions: includeExtensions, excludeExtensions: excludeExtensions, page: page, limit: limit) { (results, error) in
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
        if let comment = self.qiscusCore?.database.message.find(id: commentID) {
            _ = self.qiscusCore?.database.room.updateReadComment(comment)
        }
         self.qiscusCore?.network.updateCommentStatus(roomId: roomId, lastCommentReadId: commentID, lastCommentReceivedId: nil)
    }
    
    /// Mark Comment as read
    ///
    /// - Parameters:
    ///   - roomId: room id, where comment cooming
    ///   - commentId: commentId you want to read
    public func markAsRead(roomId: String, commentId: String) {
        // update unread comment
        if let comment = self.qiscusCore?.database.message.find(id: commentId) {
            _ = self.qiscusCore?.database.room.updateReadComment(comment)
        }
        self.qiscusCore?.network.updateCommentStatus(roomId: roomId, lastCommentReadId: commentId, lastCommentReceivedId: nil)
    }
    
    /// Mark Comment as received or deliverd, include comment before
    ///
    /// - Parameters:
    ///   - roomId: room id, where comment cooming
    ///   - lastCommentReceivedId: comment id
    @available(*, deprecated, message: "will soon become unavailable.")
    public func updateCommentReceive(roomId: String, lastCommentReceivedId commentID: String) {
        self.qiscusCore?.network.updateCommentStatus(roomId: roomId, lastCommentReadId: nil, lastCommentReceivedId: commentID)
        
        
        guard let comment =  self.qiscusCore?.database.message.find(id: commentID) else{
            return
        }
        let new = comment
        // update comment
        new.status = .delivered
        self.qiscusCore?.database.message.save([new])

    }
    
    /// Mark Comment as received or deliverd, include comment before
    ///
    /// - Parameters:
    ///   - roomId: room id, where comment cooming
    ///   - commentId: commentId you want to read
    public func markAsDelivered(roomId: String, commentId: String) {
        self.qiscusCore?.network.updateCommentStatus(roomId: roomId, lastCommentReadId: nil, lastCommentReceivedId: commentId)
        
        guard let comment = self.qiscusCore?.database.message.find(id: commentId) else{
            return
        }
        
        let new = comment
        // update comment
        new.status = .delivered
        self.qiscusCore?.database.message.save([new])

    }
    
    /// Get comment status is read or received
    ///
    /// - Parameters:
    ///   - id: comment id
    ///   - completion: return object commentInfo
    public func readReceiptStatus(commentId id: String, onSuccess: @escaping (CommentInfo) -> Void, onError: @escaping (QError) -> Void) {
        
        if let comment = self.qiscusCore?.database.message.find(id: id){
            if let room = self.qiscusCore?.database.room.find(id: comment.chatRoomId){
                var commentInfo = CommentInfo()
                commentInfo.comment = comment
                
                var readUser = [QParticipant]()
                var deliveredUser = [QParticipant]()
                var sentUser = [QParticipant]()
                
                for participant in room.participants!{
                    if participant.lastMessageReadId >= Int(comment.id)!{
                        readUser.append(participant)
                    }else if (participant.lastMessageDeliveredId >= Int(comment.id)!){
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

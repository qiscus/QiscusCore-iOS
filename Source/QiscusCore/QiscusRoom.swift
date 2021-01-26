//
//  QiscusRoom.swift
//  QiscusCore
//
//  Created by Qiscus on 17/07/18.
//  Copyright © 2018 Qiscus. All rights reserved.
//

import Foundation

// MARK: Room Management
extension NewQiscusCore {
    /// Get or create room with participant
    ///
    /// - Parameters:
    ///   - withUsers: Qiscus user email.
    ///   - completion: Qiscus Room Object and error if exist.
    @available(*, deprecated, message: "will soon become unavailable.")
    public func getRoom(withUser user: String, options: String? = nil, onSuccess: @escaping (QChatRoom, [QMessage]) -> Void, onError: @escaping (QError) -> Void) {
        // call api get_or_create_room_with_target
        self.qiscusCore?.network.getOrCreateRoomWithTarget(targetSdkEmail: user, options: options, onSuccess: { (room, comments) in
            self.qiscusCore?.database.room.save([room])
            var c = [QMessage]()
            if let _comments = comments {
                // save comments
                self.qiscusCore?.database.message.save(_comments,publishEvent: false)
                c = _comments
            }
            onSuccess(room,c)
        }) { (error) in
            onError(error)
        }
    }
    
    /// Get or create room with participant
    ///
    /// - Parameters:
    ///   - userId: Qiscus user Id.
    ///   - extras : extras (valid Json String)
    ///   - completion: Qiscus Room Object and error if exist.
    public func chatUser(userId: String, extras: String? = nil, onSuccess: @escaping (QChatRoom, [QMessage]) -> Void, onError: @escaping (QError) -> Void) {
        // call api get_or_create_room_with_target
        self.qiscusCore?.network.getOrCreateRoomWithTarget(targetSdkEmail: userId, options: extras, onSuccess: { (room, comments) in
            self.qiscusCore?.database.room.save([room])
            var c = [QMessage]()
            if let _comments = comments {
                // save comments
                self.qiscusCore?.database.message.save(_comments,publishEvent: false)
                c = _comments
            }
            onSuccess(room,c)
        }) { (error) in
            onError(error)
        }
    }
    
    /// Get or create room by channel name
    /// If room with predefined unique id is not exist then it will create a new one with requester as the only one participant. Otherwise, if room with predefined unique id is already exist, it will return that room and add requester as a participant.
    /// When first call (room is not exist), if requester did not send avatar_url and/or room name it will use default value. But, after the second call (room is exist) and user (requester) send avatar_url and/or room name, it will be updated to that value. Object changed will be true in first call and when avatar_url or room name is updated.
    
    /// - Parameters:
    ///   - channel: channel name or channel id
    ///   - name: channel name
    ///   - avatarUrl: url avatar
    ///   - options: option
    ///   - onSuccess: return object room
    ///   - onError: return object QError
    @available(*, deprecated, message: "will soon become unavailable.")
    public func getRoom(withChannel channel: String, name: String? = nil, avatarUrl: URL? = nil, options: String? = nil, onSuccess: @escaping (QChatRoom) -> Void, onError: @escaping (QError) -> Void) {
        // call api get_room_by_id
        self.qiscusCore?.network.getOrCreateChannel(uniqueId: channel, name: name, avatarUrl: avatarUrl, options: options) { (rooms, comments, error) in
            if let room = rooms {
                // save room
                self.qiscusCore?.database.room.save([room])
                var c = [QMessage]()
                if let _comments = comments {
                    // save comments
                    self.qiscusCore?.database.message.save(_comments)
                    c = _comments
                }
                onSuccess(room)
            }else {
                onError(QError(message: error ?? "Unexpected error"))
            }
        }
    }
    
    public func createChannel(uniqueId: String, name: String? = nil, avatarURL: URL? = nil, extras: String? = nil, onSuccess: @escaping (QChatRoom) -> Void, onError: @escaping (QError) -> Void) {
        // call api get_room_by_id
        self.qiscusCore?.network.getOrCreateChannel(uniqueId: uniqueId, name: name, avatarUrl: avatarURL, options: extras) { (rooms, comments, error) in
            if let room = rooms {
                // save room
                self.qiscusCore?.database.room.save([room])
                var c = [QMessage]()
                if let _comments = comments {
                    // save comments
                    self.qiscusCore?.database.message.save(_comments)
                    c = _comments
                }
                onSuccess(room)
            }else {
                onError(QError(message: error ?? "Unexpected error"))
            }
        }
    }
    
    // getChannels
    ///
    ///   - completion: Response array of QiscusChannels
    public func getChannels(onSuccess: @escaping ([QiscusChannels]) -> Void, onError: @escaping (QError) -> Void ) {
        self.qiscusCore?.network.getChannels() { (channels, error) in
            if let _channels = channels {
               onSuccess(_channels)
            }else{
                if let _error = error {
                   onError(QError(message: _error))
                }else {
                    onError(QError(message: "Unexpected Error"))
                }
            }
        }
    }
    
    // getChannelsInfo
    /// - Parameters:
    ///   - uniqueIds: array uniqueId
    ///   - completion: Response array of QiscusChannels
    public func getChannelsInfo(uniqueIds : [String], onSuccess: @escaping ([QiscusChannels]) -> Void, onError: @escaping (QError) -> Void ) {
        self.qiscusCore?.network.getChannelsInfo(uniqueIds: uniqueIds) { (channels, error) in
            if let _channels = channels {
               onSuccess(_channels)
            }else{
                if let _error = error {
                   onError(QError(message: _error))
                }else {
                    onError(QError(message: "Unexpected Error"))
                }
            }
        }
    }
    
    // joinChannels
    /// - Parameters:
    ///   - uniqueIds: array uniqueId
    ///   - completion: Response array of QiscusChannels
    public func joinChannels(uniqueIds : [String], onSuccess: @escaping ([QiscusChannels]) -> Void, onError: @escaping (QError) -> Void ) {
        self.qiscusCore?.network.joinChannels(uniqueIds: uniqueIds) { (channels, error) in
            if let _channels = channels {
               onSuccess(_channels)
            }else{
                if let _error = error {
                   onError(QError(message: _error))
                }else {
                    onError(QError(message: "Unexpected Error"))
                }
            }
        }
    }
    
    // leaveChannels
    /// - Parameters:
    ///   - uniqueIds: array uniqueId
    ///   - completion: Response array of QiscusChannels
    public func leaveChannels(uniqueIds : [String], onSuccess: @escaping ([QiscusChannels]) -> Void, onError: @escaping (QError) -> Void ) {
        self.qiscusCore?.network.leaveChannels(uniqueIds: uniqueIds) { (channels, error) in
            if let _channels = channels {
                onSuccess(_channels)
            }else{
                if let _error = error {
                    onError(QError(message: _error))
                }else {
                    onError(QError(message: "Unexpected Error"))
                }
            }
        }
    }
    
    /// Get room with room id
    ///
    /// - Parameters:
    ///   - withID: existing roomID from server or local db.
    ///   - completion: Response Qiscus Room Object and error if exist.
    @available(*, deprecated, message: "will soon become unavailable.")
    public func getRoom(withID id: String, onSuccess: @escaping (QChatRoom, [QMessage]) -> Void, onError: @escaping (QError) -> Void) {
        if id == "0"{
            onError(QError(message:"Please check your roomID, now your roomID is =\(id)"))
        }else{
            // call api get_room_by_id
            self.qiscusCore?.network.getRoomById(roomId: id, onSuccess: { (room, comments) in
                // save room
                if let comments = comments {
                    room.lastComment = comments.first
                }
                
                self.qiscusCore?.database.room.save([room])
                
                // save comments
                var c = [QMessage]()
                if let _comments = comments {
                    // save comments
                    self.qiscusCore?.database.message.save(_comments,publishEvent: false)
                    c = _comments
                }
                onSuccess(room,c)
            }) { (error) in
                onError(error)
            }
        }
    }
    
    /// Get Chat Room with room id
    ///
    /// - Parameters:
    ///   - roomId: existing roomID from server or local db.
    ///   - completion: Response Qiscus Room Object and error if exist.
    public func getChatRoomWithMessages(roomId: String, onSuccess: @escaping (QChatRoom, [QMessage]) -> Void, onError: @escaping (QError) -> Void) {
        if roomId == "0"{
            onError(QError(message:"Please check your roomID, now your roomID is =\(roomId)"))
        }else{
            // call api get_room_by_id
            self.qiscusCore?.network.getRoomById(roomId: roomId, onSuccess: { (room, comments) in
                // save room
                if let comments = comments {
                    room.lastComment = comments.first
                }
                
                self.qiscusCore?.database.room.save([room])
                
                // save comments
                var c = [QMessage]()
                if let _comments = comments {
                    // save comments
                    self.qiscusCore?.database.message.save(_comments,publishEvent: false)
                    c = _comments
                }
                onSuccess(room,c)
            }) { (error) in
                onError(error)
            }
        }
    }
    
    
    /// Get Room info
    ///
    /// - Parameters:
    ///   - withId: array of room id
    ///   - showParticipant : default is false
    ///   - showRemoved : default is false
    ///   - completion: Response new Qiscus Room Object and error if exist.
    @available(*, deprecated, message: "will soon become unavailable.")
    public func getRooms(withId ids: [String], showParticipant: Bool = true, showRemoved: Bool = false, onSuccess: @escaping ([QChatRoom]) -> Void, onError: @escaping (QError) -> Void) {
        if self.qiscusCore?.config.appID != nil {
            if self.qiscusCore?.isLogined ?? false {
                self.qiscusCore?.network.getRoomInfo(roomIds: ids, roomUniqueIds: nil, showParticipant: showParticipant, showRemoved: showRemoved){ (rooms, error) in
                    if let data = rooms {
                        // save room
                        self.qiscusCore?.database.room.save(data)
                        onSuccess(data)
                    }else {
                        onError(error ?? QError(message: "Unexpected error"))
                    }
                }
            }else{
                onError(QError(message: "please login Qiscus first before register deviceToken"))
            }
        }else{
            onError(QError(message: "please setupAPPID first before call api"))
        }
    }
    
    
    /// Get getChatRoom
    ///
    /// - Parameters:
    ///   - roomIds: array of room id
    ///   - showParticipant : default is false
    ///   - showRemoved : default is false
    ///   - completion: Response new Qiscus Room Object and error if exist.
    public func getChatRooms(roomIds: [String], showRemoved: Bool = false, showParticipant: Bool = true, onSuccess: @escaping ([QChatRoom]) -> Void, onError: @escaping (QError) -> Void) {
        if self.qiscusCore?.config.appID != nil {
            if self.qiscusCore?.isLogined ?? false{
                self.qiscusCore?.network.getRoomInfo(roomIds: roomIds, roomUniqueIds: nil, showParticipant: showParticipant, showRemoved: showRemoved){ (rooms, error) in
                    if let data = rooms {
                        // save room
                        self.qiscusCore?.database.room.save(data)
                        onSuccess(data)
                    }else {
                        onError(error ?? QError(message: "Unexpected error"))
                    }
                }
            }else{
                onError(QError(message: "please login Qiscus first before register deviceToken"))
            }
        }else{
            onError(QError(message: "please setupAPPID first before call api"))
        }
    }
    
    
    /// Get Room info
    ///
    /// - Parameters:
    ///   - ids: Unique room id
    ///   - showParticipant : default is false
    ///   - showRemoved : default is false
    ///   - completion: Response new Qiscus Room Object and error if exist.
    @available(*, deprecated, message: "will soon become unavailable.")
    public func getRooms(withUniqueId ids: [String],showParticipant: Bool = true, showRemoved: Bool = false, onSuccess: @escaping ([QChatRoom]) -> Void, onError: @escaping (QError) -> Void) {
        if self.qiscusCore?.config.appID != nil {
            if self.qiscusCore?.isLogined ?? false {
                self.qiscusCore?.network.getRoomInfo(roomIds: nil, roomUniqueIds: ids, showParticipant: showParticipant, showRemoved: showRemoved){ (rooms, error) in
                    if let data = rooms {
                        // save room
                        self.qiscusCore?.database.room.save(data)
                        onSuccess(data)
                    }else {
                        onError(error ?? QError(message: "Unexpected error"))
                    }
                }
            }else{
                onError(QError(message: "please login Qiscus first before register deviceToken"))
            }
        }else{
            onError(QError(message: "please setupAPPID first before call api"))
        }
    }
    
    /// Get Room info
    ///
    /// - Parameters:
    ///   - uniqueIds: Unique room id
    ///   - showParticipant : default is false
    ///   - showRemoved : default is false
    ///   - completion: Response new Qiscus Room Object and error if exist.
    public func getChatRooms(uniqueIds: [String],showParticipant: Bool = true, showRemoved: Bool = false, onSuccess: @escaping ([QChatRoom]) -> Void, onError: @escaping (QError) -> Void) {
        if self.qiscusCore?.config.appID != nil {
            if self.qiscusCore?.isLogined ?? false {
                self.qiscusCore?.network.getRoomInfo(roomIds: nil, roomUniqueIds: uniqueIds, showParticipant: showParticipant, showRemoved: showRemoved){ (rooms, error) in
                    if let data = rooms {
                        // save room
                        self.qiscusCore?.database.room.save(data)
                        onSuccess(data)
                    }else {
                        onError(error ?? QError(message: "Unexpected error"))
                    }
                }
            }else{
                onError(QError(message: "please login Qiscus first before register deviceToken"))
            }
        }else{
            onError(QError(message: "please setupAPPID first before call api"))
        }
    }
    
    /// getAllRoom
    ///
    /// - Parameter completion: First Completion will return data from local if exis, then return from server with meta data(totalpage,current). Response new Qiscus Room Object and error if exist.
    @available(*, deprecated, message: "will soon become unavailable.")
    public func getAllRoom(limit: Int? = 20, page: Int? = 1, showRemoved: Bool = false, showEmpty: Bool = false,onSuccess: @escaping ([QChatRoom],Meta?) -> Void, onError: @escaping (QError) -> Void) {
        // api get room lists
      
        self.qiscusCore?.network.getRoomList(limit: limit, page: page, showRemoved: showRemoved, showEmpty: showEmpty) { (data, meta, error) in
            if let rooms = data {
                if rooms.count != 0{
                    // save room
                    self.qiscusCore?.database.room.save(rooms)
                    rooms.forEach({ (_room) in
                        if let _comment = _room.lastComment {
                            if _comment.id.contains("0"){
                                //ignored
                            }else{
                                // save last comment
                                self.qiscusCore?.database.message.save([_comment])
                            }
                        }
                    })

                }
               
                onSuccess(rooms,meta)
            }else {
                onError(QError(message: error ?? "Something Wrong"))
            }
        }
    }
    
    /// getAllRoom
    /// - Parameters:
    ///   - showParticipant: Bool (true = include participants obj to the room, false = participants obj nil)
    ///   - showRemoved: Bool (true = include room that has been removed, false = exclude room that has been removed)
    ///   - showEmpty: Bool (true = it will show all rooms that have been created event there are no messages, default is false where only room that have at least one message will be shown)
    ///   - roomType: (single, group, public_channel) by default returning all type
    ///   - page: page
    ///   - limit: limit room per page
    ///   - completion: @escaping when success get room list returning Optional([RoomModel]), Optional(Meta) contain page, total_room per page, Optional(String error message)
    public func getAllChatRooms(showParticipant:Bool = true,showRemoved: Bool = false, showEmpty: Bool = false, roomType : RoomType? = nil, page: Int, limit: Int ,onSuccess: @escaping ([QChatRoom],Meta?) -> Void, onError: @escaping (QError) -> Void) {
        // api get room lists
        
        self.qiscusCore?.network.getRoomList(showParticipant: showParticipant, limit: limit, page: page, roomType: roomType, showRemoved: showRemoved, showEmpty: showEmpty) { (data, meta, error) in
            if let rooms = data {
                // save room
                if rooms.count != 0{
                    self.qiscusCore?.database.room.save(rooms)
                    rooms.forEach({ (_room) in
                        if let _comment = _room.lastComment {
                            if _comment.id.contains("0"){
                                //ignored
                            }else{
                                // save last comment
                                self.qiscusCore?.database.message.save([_comment])
                            }
                        }
                    })
                }
                onSuccess(rooms,meta)
            }else {
                onError(QError(message: error ?? "Something Wrong"))
            }
        }
    }
    
    /// Create new Group room
    ///
    /// - Parameters:
    ///   - withName: Name of group
    ///   - participants: arrau of user id/qiscus email
    ///   - completion: Response Qiscus Room Object and error if exist.
    @available(*, deprecated, message: "will soon become unavailable.")
    public func createGroup(withName name: String, participants: [String], avatarUrl url: URL?, onSuccess: @escaping (QChatRoom) -> Void, onError: @escaping (QError) -> Void) {
        // call api create_room
        self.qiscusCore?.network.createRoom(name: name, participants: participants, avatarUrl: url) { (room, error) in
            // save room
            if let data = room {
                self.qiscusCore?.database.room.save([data])
                onSuccess(data)
            }else {
                guard let message = error else {
                    onError(QError(message: "Something Wrong"))
                    return
                }
               onError(QError(message: message))
            }
        }
    }
    
    /// Create new Group room
    ///
    /// - Parameters:
    ///   - name: Name of group
    ///   - userIds: array of user id/qiscus email
    ///   - avatarURL : avatar group
    ///   = extras : String json
    ///   - completion: Response Qiscus Room Object and error if exist.
    public func createGroupChat(name: String, userIds: [String], avatarURL: URL? = nil, extras: String? = nil, onSuccess: @escaping (QChatRoom) -> Void, onError: @escaping (QError) -> Void){
        self.qiscusCore?.network.createRoom(name: name, participants: userIds, avatarUrl: avatarURL, options : extras) { (room, error) in
            // save room
            if let data = room {
                self.qiscusCore?.database.room.save([data])
                onSuccess(data)
            }else {
                guard let message = error else {
                    onError(QError(message: "Something Wrong"))
                    return
                }
                onError(QError(message: message))
            }
        }
    }
    
    /// update Group or channel
    ///
    /// - Parameters:
    ///   - id: room id, where room type not single. group and channel is approved
    ///   - name: new room name optional
    ///   - avatarURL: new room Avatar
    ///   - options: String, and JSON string is approved
    ///   - completion: Response new Qiscus Room Object and error if exist.
    @available(*, deprecated, message: "will soon become unavailable.")
    public func updateRoom(withID id: String, name: String?, avatarURL url: URL?, options: String?, onSuccess: @escaping (QChatRoom) -> Void, onError: @escaping (QError) -> Void) {
        // call api update_room
        self.qiscusCore?.network.updateRoom(roomId: id, roomName: name, avatarUrl: url, options: options) { (room, error) in
            if let data = room {
                self.qiscusCore?.database.room.save([data])
                onSuccess(data)
            }else {
                guard let message = error else {
                    onError(QError(message: "Something Wrong"))
                    return
                }
                onError(message)
            }
        }
    }
    
    /// update Group or channel
    ///
    /// - Parameters:
    ///   - roomId: room id, where room type not single. group and channel is approved
    ///   - name: new room name optional
    ///   - avatarURL: new room Avatar
    ///   - extras: String, and JSON string is approved
    ///   - completion: Response new Qiscus Room Object and error if exist.
    public func updateChatRoom(roomId: String, name: String?, avatarURL url: URL?, extras: String?, onSuccess: @escaping (QChatRoom) -> Void, onError: @escaping (QError) -> Void) {
        // call api update_room
        self.qiscusCore?.network.updateRoom(roomId: roomId, roomName: name, avatarUrl: url, options: extras) { (room, error) in
            if let data = room {
                self.qiscusCore?.database.room.save([data])
                onSuccess(data)
            }else {
                guard let message = error else {
                    onError(QError(message: "Something Wrong"))
                    return
                }
                onError(message)
            }
        }
    }
    
    /// Add new participant in room(Group)
    ///
    /// - Parameters:
    ///   - userEmails: qiscus user email
    ///   - roomId: room id
    ///   - completion:  Response new Qiscus Participant Object and error if exist.
    @available(*, deprecated, message: "will soon become unavailable.")
    public func addParticipant(userEmails emails: [String], roomId: String, onSuccess: @escaping ([QParticipant]) -> Void, onError: @escaping (QError) -> Void) {
        
        self.qiscusCore?.network.addParticipants(roomId: roomId, userSdkEmail: emails) { (members, error) in
            if let _members = members {
                // Save participant in local
                self.qiscusCore?.database.participant.save(_members, roomID: roomId)
                onSuccess(_members)
            }else{
                if let _error = error {
                    onError(_error)
                }else {
                    onError(QError(message: "Unexpected Error"))
                }
            }
        }
    }
    
    /// Add new participant in room (group & channel)
    ///
    /// - Parameters:
    ///   - roomId: room id
    ///   - userIds: array of qiscus user userIds
    ///   - completion:  Response new Qiscus Participant Object and error if exist.
    public func addParticipants(roomId: String, userIds: [String], onSuccess: @escaping ([QParticipant]) -> Void, onError: @escaping (QError) -> Void) {
        
        self.qiscusCore?.network.addParticipants(roomId: roomId, userSdkEmail: userIds) { (members, error) in
            if let _members = members {
                // Save participant in local
                self.qiscusCore?.database.participant.save(_members, roomID: roomId)
                onSuccess(_members)
            }else{
                if let _error = error {
                    onError(_error)
                }else {
                    onError(QError(message: "Unexpected Error"))
                }
            }
        }
    }
    
    /// remove users from room(Group)
    ///
    /// - Parameters:
    ///   - emails: array qiscus email
    ///   - roomId: room id (group)
    ///   - completion: Response true if success and error if exist
    @available(*, deprecated, message: "will soon become unavailable.")
    public func removeParticipant(userEmails emails: [String], roomId: String, onSuccess: @escaping (Bool) -> Void, onError: @escaping (QError) -> Void) {
        self.qiscusCore?.network.removeParticipants(roomId: roomId, userSdkEmail: emails) { (result, error) in
            if result {
                onSuccess(result)
            }else {
                if let _error = error {
                    onError(_error)
                }else {
                    onError(QError(message: "Unexpected Error"))
                }
            }
        }
    }
    
    /// remove users from room(Group & Channel)
    ///
    /// - Parameters:
    ///   - roomId: room id (group)
    ///   - userIds: array qiscus userIds
    ///   - completion: Response true if success and error if exist
    public func removeParticipants(roomId: String, userIds: [String], onSuccess: @escaping (Bool) -> Void, onError: @escaping (QError) -> Void) {
        self.qiscusCore?.network.removeParticipants(roomId: roomId, userSdkEmail: userIds) { (result, error) in
            if result {
                onSuccess(result)
            }else {
                if let _error = error {
                    onError(_error)
                }else {
                    onError(QError(message: "Unexpected Error"))
                }
            }
        }
    }
    
    /// get participant by room id
    ///
    /// - Parameters:
    ///   - roomUniqeId: room id (group)
    ///   - offset : default is 0
    ///   - sorting : default is asc
    ///   - completion: Response new Qiscus Participant Object and error if exist.
    @available(*, deprecated, message: "will soon become unavailable.")
    public func getParticipant(roomUniqeId id: String, offset: Int? = 0, sorting: SortType? = nil, onSuccess: @escaping ([QParticipant]) -> Void, onError: @escaping (QError) -> Void ) {
        self.qiscusCore?.network.getParticipants(roomUniqeId: id, page:0, limit: 0, offset: offset, sorting: sorting) { (members, meta, error) in
            if let _members = members {
                onSuccess(_members)
            }else{
                if let _error = error {
                    onError(_error)
                }else {
                    onError(QError(message: "Unexpected Error"))
                }
            }
        }
    }
    
    // get participant by room uniqueId
    ///
    /// - Parameters:
    ///   - roomId: room uniqueId
    ///   - offset : default is nil
    ///   - sorting : default is asc
    ///   - completion: Response new Qiscus Participant Object, Meta and error if exist.
    public func getParticipants(roomUniqueId: String, page: Int? = 1, limit : Int? = 100, sorting: SortType? = nil, onSuccess: @escaping ([QParticipant], MetaRoomParticipant) -> Void, onError: @escaping (QError) -> Void ) {
        self.qiscusCore?.network.getParticipants(roomUniqeId: roomUniqueId, page: page, limit: limit, offset: 0, sorting: sorting) { (members, meta, error) in
            if let _members = members {
                if let meta = meta {
                     onSuccess(_members, meta)
                }
            }else{
                if let _error = error {
                    onError(_error)
                }else {
                    onError(QError(message: "Unexpected Error"))
                }
            }
        }
    }
    
    public func leaveRoom(by roomId:String, onSuccess: @escaping (Bool) -> Void, onError: @escaping (QError) -> Void) {
        guard let user = self.qiscusCore?.getProfile() else {
            onError(QError(message: "User not found, please login to continue"))
            return
        }
        guard let room = self.qiscusCore?.database.room.find(id: roomId) else {
            onError(QError(message: "Room not Found"))
            return
        }
        _ = self.qiscusCore?.database.room.delete(room)
        self.removeParticipant(userEmails: [user.id], roomId: roomId, onSuccess: onSuccess, onError: onError)
    }
    
    // userPresence
    /// - Parameters:
    ///   - userIds: array userIds
    ///   - completion: Response array of QUserPresence
    public func getUserPresence(userIds : [String], onSuccess: @escaping ([QUserPresence]) -> Void, onError: @escaping (QError) -> Void ) {
        self.qiscusCore?.network.getUserPresence(userIds: userIds) { (channels, error) in
            if let _channels = channels {
                onSuccess(_channels)
            }else{
                if let _error = error {
                    onError(QError(message: _error))
                }else {
                    onError(QError(message: "Unexpected Error"))
                }
            }
        }
    }
    
    /// getRoomUnreadCount
    /// - Parameters:
    ///   - completion: Response unreadCount (int)
    public func getRoomUnreadCount(onSuccess: @escaping (Int) -> Void, onError: @escaping (QError) -> Void ) {
        self.qiscusCore?.network.getRoomUnreadCount(token: self.qiscusCore?.getUserData()?.token ?? "") { (unreadCount, error) in
            if let _unreadCount = unreadCount {
                onSuccess(_unreadCount)
            }else{
                if let _error = error {
                    onError(QError(message: _error))
                }else {
                    onError(QError(message: "Unexpected Error"))
                }
            }
        }
    }

    
    
    @available(*, deprecated, message: "will soon become unavailable.")
    public func subscribeEvent(roomID: String, onEvent: @escaping (RoomEvent) -> Void) {
        return (self.qiscusCore?.realtime.subscribeEvent(roomID: roomID, onEvent: onEvent))!
    }
    
    public func subscribeCustomEvent(roomId: String, onEvent: @escaping (RoomEvent) -> Void) {
        return (self.qiscusCore?.realtime.subscribeEvent(roomID: roomId, onEvent: onEvent))!
    }
    
    @available(*, deprecated, message: "will soon become unavailable.")
    public func unsubscribeEvent(roomID: String) {
        self.qiscusCore?.realtime.unsubscribeEvent(roomID: roomID)
    }
    
    public func unsubscribeCustomEvent(roomId: String) {
        self.qiscusCore?.realtime.unsubscribeEvent(roomID: roomId)
    }
    
    @available(*, deprecated, message: "will soon become unavailable.")
    public func publishEvent(roomID: String, payload: [String : Any]) -> Bool {
        return (self.qiscusCore?.realtime.publishEvent(roomID: roomID, payload: payload))!
    }
    
    public func publishCustomEvent(roomId: String, data: [String : Any]) -> Bool {
        return (self.qiscusCore?.realtime.publishEvent(roomID: roomId, payload: data))!
    }
    
    public func subscribeTyping(roomID: String, onTyping: @escaping (RoomTyping) -> Void) {
        if let roomUser = self.qiscusCore?.database.room.find(id: roomID){
            if roomUser.type == RoomType.channel {
                return
            }
        }
    
        return (self.qiscusCore?.realtime.subscribeTyping(roomID:roomID, onTyping: onTyping))!
    }
    
    public func unsubscribeTyping(roomID: String) {
        if let roomUser = self.qiscusCore?.database.room.find(id: roomID){
            if roomUser.type == RoomType.channel {
                return
            }
        }

        self.qiscusCore?.realtime.unsubscribeTyping(roomID: roomID)
    }
}

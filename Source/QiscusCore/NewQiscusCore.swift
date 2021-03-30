//
//  NewQiscusCore.swift
//  QiscusCore
//
//  Created by Qiscus on 15/01/20.
//  Copyright © 2020 Qiscus. All rights reserved.
//

import Foundation

public class NewQiscusCore: NSObject {
    
    var qiscusCore : QiscusCore? = nil
    
    /// Register device token Apns or Pushkit
    ///
    /// - Parameters:
    ///   - deviceToken: device token
    ///   - completion: The code to be executed once the request has finished
    @available(*, deprecated, message: "will soon become unavailable.")
    public func register(deviceToken : String, isDevelopment:Bool = false, onSuccess: @escaping (Bool) -> Void, onError: @escaping (QError) -> Void) {
        if self.qiscusCore?.isLogined ?? false{
            self.qiscusCore?.network.registerDeviceToken(deviceToken: deviceToken, isDevelopment: isDevelopment, onSuccess: { (success) in
                self.qiscusCore?.config.deviceToken = deviceToken
                onSuccess(success)
            }) { (error) in
                onError(error)
            }
        }else{
            onError(QError(message: "please login Qiscus first before register deviceToken"))
        }
    }
    
    /// Register device token Apns or Pushkit
    ///
    /// - Parameters:
    ///   - token: device token
    ///   - isDevelopment : default is false / using production
    ///   - completion: The code to be executed once the request has finished
    public func registerDeviceToken(token : String, isDevelopment:Bool = false, onSuccess: @escaping (Bool) -> Void, onError: @escaping (QError) -> Void) {
        if self.qiscusCore?.isLogined ?? false {
            self.qiscusCore?.network.registerDeviceToken(deviceToken: token, isDevelopment: isDevelopment, onSuccess: { (success) in
                onSuccess(success)
            }) { (error) in
                onError(error)
            }
        }else{
            onError(QError(message: "please login Qiscus first before register deviceToken"))
        }
    }
    
    /// Remove device token
    ///
    /// - Parameters:
    ///   - deviceToken: device token
    ///   - isDevelopment : default is false / using production
    ///   - completion: The code to be executed once the request has finished
    @available(*, deprecated, message: "will soon become unavailable.")
    public func remove(deviceToken : String,  isDevelopment:Bool = false, onSuccess: @escaping (Bool) -> Void, onError: @escaping (QError) -> Void) {
        self.qiscusCore?.network.removeDeviceToken(deviceToken: deviceToken, isDevelopment: isDevelopment, onSuccess: onSuccess, onError: onError)
    }
    
    /// Remove device token
    ///
    /// - Parameters:
    ///   - token: device token
    ///   - isDevelopment : default is false / using production
    ///   - completion: The code to be executed once the request has finished
    public func removeDeviceToken(token : String, isDevelopment:Bool = false, onSuccess: @escaping (Bool) -> Void, onError: @escaping (QError) -> Void) {
        self.qiscusCore?.network.removeDeviceToken(deviceToken: token, isDevelopment: isDevelopment, onSuccess: onSuccess, onError: onError)
    }
    
    /// Update user profile
    ///
    /// - Parameters:
    ///   - displayName: nick name
    ///   - url: user avatar url
    ///   - completion: The code to be executed once the request has finished
    @available(*, deprecated, message: "will soon become unavailable.")
    public func updateProfile(username: String = "", avatarUrl url: URL? = nil, extras: [String : Any]? = nil, onSuccess: @escaping (QAccount) -> Void, onError: @escaping (QError) -> Void) {
        if self.qiscusCore?.config.appID != nil {
            if self.qiscusCore?.isLogined ?? false{
                self.qiscusCore?.network.updateProfile(displayName: username, avatarUrl: url, extras: extras, onSuccess: { (userModel) in
                    self.qiscusCore?.config.user = userModel
                    onSuccess(userModel)
                }) { (error) in
                    onError(error)
                }
            }else{
                onError(QError(message: "please login Qiscus first before register deviceToken"))
            }
        }else{
            onError(QError(message: "please setupAppID first"))
        }
    }
    
    /// Update user profile
    ///
    /// - Parameters:
    ///   - name: nick name
    ///   - avatarURL: user avatar url
    ///   - extras : extrasData
    ///   - completion: The code to be executed once the request has finished
    public func updateUser(name: String = "", avatarURL: URL? = nil, extras: [String : Any]? = nil, onSuccess: @escaping (QAccount) -> Void, onError: @escaping (QError) -> Void) {
        if self.qiscusCore?.config.appID != nil {
            if self.qiscusCore?.isLogined ?? false {
                self.qiscusCore?.network.updateProfile(displayName: name, avatarUrl: avatarURL, extras: extras, onSuccess: { (userModel) in
                    self.qiscusCore?.config.user = userModel
                    onSuccess(userModel)
                }) { (error) in
                    onError(error)
                }
            }else{
                onError(QError(message: "please login Qiscus first before register deviceToken"))
            }
        }else{
            onError(QError(message: "please setupAppID first"))
        }
    }
    
    /// Get total unread count by user
    ///
    /// - Parameter completion: number of unread cout for all room
    @available(*, deprecated, message: "will soon become unavailable.")
    public func unreadCount(completion: @escaping (Int, QError?) -> Void) {
        self.qiscusCore?.network.unreadCount(completion: completion)
    }
    
    /// Get total unread count by user
    ///
    /// - Parameter completion: number of unread cout for all room
    public func getTotalUnreadCount(completion: @escaping (Int, QError?) -> Void) {
        self.qiscusCore?.network.unreadCount(completion: completion)
    }
    
    /// Block Qiscus User
    ///
    /// - Parameters:
    ///   - email: qiscus email user
    ///   - completion: Response object user and error if exist
    @available(*, deprecated, message: "will soon become unavailable.")
    public func blockUser(email: String, onSuccess: @escaping (QUser) -> Void, onError: @escaping (QError) -> Void) {
        self.qiscusCore?.network.blockUser(email: email, onSuccess: onSuccess, onError: onError)
    }
    
    /// Block Qiscus User
    ///
    /// - Parameters:
    ///   - userId: qiscus userId user
    ///   - completion: Response object user and error if exist
    public func blockUser(userId: String, onSuccess: @escaping (QUser) -> Void, onError: @escaping (QError) -> Void) {
        self.qiscusCore?.network.blockUser(email: userId, onSuccess: onSuccess, onError: onError)
    }
    
    /// Unblock Qiscus User
    ///
    /// - Parameters:
    ///   - email: qiscus email user
    ///   - completion: Response object user and error if exist
    @available(*, deprecated, message: "will soon become unavailable.")
    public func unblockUser(email: String, onSuccess: @escaping (QUser) -> Void, onError: @escaping (QError) -> Void) {
        self.qiscusCore?.network.unblockUser(email: email, onSuccess: onSuccess, onError: onError)
    }
    
    /// Unblock Qiscus User
    ///
    /// - Parameters:
    ///   - userId: qiscus userId user
    ///   - completion: Response object user and error if exist
    public func unblockUser(userId: String, onSuccess: @escaping (QUser) -> Void, onError: @escaping (QError) -> Void) {
        self.qiscusCore?.network.unblockUser(email: userId, onSuccess: onSuccess, onError: onError)
    }
    
    /// Get blocked user
    ///
    /// - Parameters:
    ///   - page: page for pagination
    ///   - limit: limit per page
    ///   - completion: Response array of object user and error if exist
    @available(*, deprecated, message: "will soon become unavailable.")
    public func listBlocked(page: Int?, limit:Int?, onSuccess: @escaping ([QUser]) -> Void, onError: @escaping (QError) -> Void) {
        self.qiscusCore?.network.getBlokedUser(page: page, limit: limit, onSuccess: onSuccess, onError: onError)
    }
    
    
    /// Get blocked user
    ///
    /// - Parameters:
    ///   - page: page for pagination
    ///   - limit: limit per page
    ///   - completion: Response array of object user and error if exist
    public func getBlockedUsers(page: Int?, limit:Int?, onSuccess: @escaping ([QUser]) -> Void, onError: @escaping (QError) -> Void) {
        self.qiscusCore?.network.getBlokedUser(page: page, limit: limit, onSuccess: onSuccess, onError: onError)
    }
    
    /// Upload to qiscus server
    ///
    /// - Parameters:
    ///   - data: data file to upload
    ///   - filename: file Name
    ///   - onSuccess: return object file model when success
    ///   - onError: return QError
    ///   - progress: progress upload
    @available(*, deprecated, message: "will soon become unavailable.")
    public func upload(data : Data, filename: String, onSuccess: @escaping (FileModel) -> Void, onError: @escaping (QError) -> Void, progress: @escaping (Double) -> Void ) {
        self.qiscusCore?.network.upload(data: data, filename: filename, onSuccess: onSuccess, onError: onError, progress: progress)
    }
    
    /// Upload to qiscus server
    ///
    /// - Parameters:
    ///   - file: data file to upload
    ///   - filename: file Name
    ///   - onSuccess: return object file model when success
    ///   - onError: return QError
    ///   - progress: progress upload
    public func upload(file : FileUploadModel, onSuccess: @escaping (FileModel) -> Void, onError: @escaping (QError) -> Void, progressListener: @escaping (Double) -> Void ) {
        
        guard let data = file.data else {
            onError(QError(message: "file data can't be empty"))
            return
        }
        
        if file.name.isEmpty {
            onError(QError(message: "file name can't be empty"))
            return
        }
        
        self.qiscusCore?.network.upload(data: data, filename: file.name, onSuccess: onSuccess, onError: onError, progress: progressListener)
    }
    
    /// get ThumbnailURL
    ///
    /// - Parameters:
    ///   - url: url (support for image, video and pdf)
    ///   - onSuccess: return string url thumbnail when success
    public func getThumbnailURL(url : String, onSuccess: @escaping (String) -> Void, onError: @escaping (QError) -> Void){
        
        if url.isEmpty{
            onError(QError(message: "URL can't be empty"))
        }
        
        var thumbURL = url.replacingOccurrences(of: "/upload/", with: "/upload/w_320,h_320,c_limit/").replacingOccurrences(of: " ", with: "%20")
        let thumbUrlArr = thumbURL.split(separator: ".")
        
        var newThumbURL = ""
        var i = 0
        for thumbComponent in thumbUrlArr{
            if i == 0{
                newThumbURL += String(thumbComponent)
            }else if i < (thumbUrlArr.count - 1){
                newThumbURL += ".\(String(thumbComponent))"
            }else{
                newThumbURL += ".png"
            }
            i += 1
        }
        thumbURL = newThumbURL
        onSuccess(thumbURL)
    }
    
    /// getBlurryThumbnailURL
    ///
    /// - Parameters:
    ///   - url: url
    ///   - onSuccess: return string url thumbnail when success
    public func getBlurryThumbnailURL(url : String, onSuccess: @escaping (String) -> Void, onError: @escaping (QError) -> Void){
        
        if url.isEmpty{
            onError(QError(message: "URL can't be empty"))
        }
        
        var thumbURL = url.replacingOccurrences(of: "/upload/", with: "/upload/w_320,h_320,c_limit,e_blur:300/").replacingOccurrences(of: " ", with: "%20")
        let thumbUrlArr = thumbURL.split(separator: ".")
        
        var newThumbURL = ""
        var i = 0
        for thumbComponent in thumbUrlArr{
            if i == 0{
                newThumbURL += String(thumbComponent)
            }else if i < (thumbUrlArr.count - 1){
                newThumbURL += ".\(String(thumbComponent))"
            }else{
                newThumbURL += ".png"
            }
            i += 1
        }
        thumbURL = newThumbURL
        onSuccess(thumbURL)
    }
    
    
    
    /// Download
    ///
    /// - Parameters:
    ///   - url: url you want to download
    ///   - onSuccess: resturn local url after success download
    ///   - onProgress: progress download
    public func download(url: URL, onSuccess: @escaping (URL) -> Void, onProgress: @escaping (Float) -> Void) {
        self.qiscusCore?.network.download(url: url, onSuccess: onSuccess, onProgress: onProgress)
    }
    
    /// getUsers
    ///
    /// - Parameters:
    ///   - limit: default 20
    ///   - page: default 1
    ///   - querySearch: default nil
    ///   - onSuccess: array of users and metaData
    ///   - onError: error when failed call api
    @available(*, deprecated, message: "will soon become unavailable.")
    public func getUsers(limit : Int? = 100, page: Int? = 1, querySearch: String? = nil,onSuccess: @escaping ([QUser], Meta) -> Void, onError: @escaping (QError) -> Void){
        self.qiscusCore?.network.getUsers(limit: limit, page: page, querySearch: querySearch, onSuccess: onSuccess, onError: onError)
    }
    
    /// getUsers
    ///
    /// - Parameters:
    ///   - searchUsername: default nil
    ///   - page: page
    ///   - limit: limit min 0 max 100
    ///   - onSuccess: array of users and metaData
    ///   - onError: error when failed call api
    public func getUsers(searchUsername: String? = nil, page: Int, limit : Int,onSuccess: @escaping ([QUser], Meta) -> Void, onError: @escaping (QError) -> Void){
        self.qiscusCore?.network.getUsers(limit: limit, page: page, querySearch: searchUsername, onSuccess: onSuccess, onError: onError)
    }
    
    /// Get Profile from server
    ///
    /// - Parameter completion: The code to be executed once the request has finished
    @available(*, deprecated, message: "will soon become unavailable.")
    public func getProfile(onSuccess: @escaping (QAccount) -> Void, onError: @escaping (QError) -> Void) {
        if self.qiscusCore?.config.appID != nil {
            if self.qiscusCore?.isLogined ?? false {
                self.qiscusCore?.network.getProfile(onSuccess: { (userModel) in
                    self.qiscusCore?.config.user = userModel
                    onSuccess(userModel)
                }) { (error) in
                    onError(error)
                }
            }else{
                onError(QError(message: "please login Qiscus first before register deviceToken"))
            }
        }else{
            onError(QError(message: "please setupAPPID first before call api"))
        }
        
    }
    
    /// Get Profile from server
    ///
    /// - Parameter completion: The code to be executed once the request has finished
    public func getUserData(onSuccess: @escaping (QAccount) -> Void, onError: @escaping (QError) -> Void) {
        if self.qiscusCore?.config.appID != nil {
            if self.qiscusCore?.isLogined ?? false {
                self.qiscusCore?.network.getProfile(onSuccess: { (userModel) in
                    self.qiscusCore?.config.user = userModel
                    onSuccess(userModel)
                }) { (error) in
                    onError(error)
                }
            }else{
                onError(QError(message: "please login Qiscus first before register deviceToken"))
            }
        }else{
            onError(QError(message: "please setupAPPID first before call api"))
        }
        
    }
    
    /// Start or stop typing in room,
    ///
    /// - Parameters:
    ///   - value: set true if user start typing, and false when finish
    ///   - roomID: room id where you typing
    @available(*, deprecated, message: "will soon become unavailable.")
    public func isTyping(_ value: Bool, roomID: String) {
        self.qiscusCore?.realtime.isTyping(value, roomID: roomID)
    }
    
    /// Start or stop typing in room,
    ///
    /// - Parameters:
    ///   - value: set true if user start typing, and false when finish
    ///   - roomID: room id where you typing
    public func publishTyping(roomID: String, isTyping: Bool) {
        self.qiscusCore?.realtime.isTyping(isTyping, roomID: roomID)
    }
    
    /// Set Online or offline
    ///
    /// - Parameter value: true if user online and false if offline
    @available(*, deprecated, message: "will soon become unavailable.")
    public func isOnline(_ value: Bool) {
        self.qiscusCore?.realtime.isOnline(value)
    }
    
    /// publish Online or offline
    ///
    /// - Parameter value: true if user online and false if offline
    public func publishOnlinePresence(isOnline: Bool) {
        self.qiscusCore?.realtime.isOnline(isOnline)
    }
    
    /// Set subscribe rooms
    ///
    /// - Parameter value: RoomModel
    @available(*, deprecated, message: "will soon become unavailable.")
    public func subcribeRooms(_ rooms: [QChatRoom]) {
        self.qiscusCore?.realtime.subscribeRoomsWithoutOnlineStatus(rooms: rooms)
    }
    
    /// Set subscribe subscribeChatRoom
    ///
    /// - Parameter value: array RoomModel
    public func subscribeChatRooms(_ rooms: [QChatRoom]) {
        self.qiscusCore?.realtime.subscribeRoomsWithoutOnlineStatus(rooms: rooms)
    }
    
    /// Set subscribe subscribeChatRoom
    ///
    /// - Parameter value: RoomModel
    public func subscribeChatRoom(_ room: QChatRoom) {
        self.qiscusCore?.realtime.subscribeRoomsWithoutOnlineStatus(rooms: [room])
    }
    
    /// Set unSubcribeRoom rooms
    ///
    /// - Parameter value: array of RoomModel
    @available(*, deprecated, message: "will soon become unavailable.")
    public func unSubcribeRooms(_ rooms: [QChatRoom]) {
        self.qiscusCore?.realtime.unsubscribeRoomsWithoutOnlineStatus(rooms: rooms)
    }
    
    /// Set unSubcribeChatRoom rooms
    ///
    /// - Parameter value: array RoomModel
    public func unSubcribeChatRooms(_ rooms: [QChatRoom]) {
        self.qiscusCore?.realtime.unsubscribeRoomsWithoutOnlineStatus(rooms: rooms)
    }
    
    /// Set unSubcribeChatRoom rooms
    ///
    /// - Parameter value: RoomModel
    public func unSubcribeChatRoom(_ room: QChatRoom) {
        self.qiscusCore?.realtime.unsubscribeRoomsWithoutOnlineStatus(rooms: [room])
    }
    
    
    /// subscribe user online presence / online status
    ///
    /// - Parameter userId: userId
    public func subscribeUserOnlinePresence(userId : String){
        self.qiscusCore?.realtime.subscribeUserOnlinePresence(userId: userId)
    }
    
    /// subscribe user online presence / online status
    ///
    /// - Parameter userIds: array of userId
    public func subscribeUserOnlinePresence(userIds : [String]){
        self.qiscusCore?.realtime.subscribeUserOnlinePresence(userIds: userIds)
    }
    
    /// unSubscribe user online presence / online status
    ///
    /// - Parameter userId: userId
    public func unsubscribeUserOnlinePresence(userId : String){
        self.qiscusCore?.realtime.unsubscribeUserOnlinePresence(userId: userId)
    }
    
    /// unSubscribe user online presence / online status
    ///
    /// - Parameter userIds: array of userId
    public func unsubscribeUserOnlinePresence(userIds : [String]){
        self.qiscusCore?.realtime.unsubscribeUserOnlinePresence(userIds: userIds)
    }
    
    /// Set unSubcribeChatRoomChannel room
    ///
    /// - Parameter value: RoomModel
    public func unSubcribeChatRoomChannel(_ room: QChatRoom) {
        self.qiscusCore?.realtime.unsubscribeRoomsChannel(rooms: [room])
    }
    
    /// Set unSubcribeChatRoomChannels rooms
    ///
    /// - Parameter value: [RoomModel]
    public func unSubcribeChatRoomsChannel(_ room: [QChatRoom]) {
        self.qiscusCore?.realtime.unsubscribeRoomsChannel(rooms: room)
    }

    
}

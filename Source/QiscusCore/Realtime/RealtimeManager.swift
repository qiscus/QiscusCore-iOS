 //
//  RealtimeManager.swift
//  QiscusCore
//
//  Created by Qiscus on 09/08/18.
//

import Foundation
import UIKit
import QiscusRealtime

typealias _roomEvent = (RoomEvent) -> Void
typealias _roomTyping = (RoomTyping) -> Void
 
class RealtimeManager {
    static var shared : RealtimeManager = RealtimeManager()
    private var client : QiscusRealtime? = nil
    private var pendingSubscribeTopic : [RealtimeSubscribeEndpoint] = [RealtimeSubscribeEndpoint]()
    var state : QiscusRealtimeConnectionState = QiscusRealtimeConnectionState.disconnected
    private var roomEvents : [String : _roomEvent] = [String : _roomEvent]()
    
    private var roomTypings : [String : _roomTyping] = [String : _roomTyping]()
    func setup(appName: String) {
        // make sure realtime client still single object
       // if client != nil { return }
        
        var bundle = "0"
        if let bundleData = Bundle.main.infoDictionary?[kCFBundleNameKey as String] as? String{
            bundle = bundleData
        }
        
        let now = Int64(NSDate().timeIntervalSince1970 * 1000000000.0) // nano sec
        
        let clientID = "iosMQTT-\(bundle)-\(appName)-\(randomString(10))-\(now)"
        
        var config = QiscusRealtimeConfig(appName: appName, clientID: clientID)
        if let customServer = ConfigManager.shared.server?.realtimeURL {
            config.hostRealtimeServer = customServer
        }
        if let customPort = ConfigManager.shared.server?.realtimePort {
            config.port = customPort
        }
        
        client = QiscusRealtime.init(withConfig: config)
        QiscusRealtime.enableDebugPrint = QiscusCore.enableDebugPrint
    }
    
    func randomString(_ n: Int) -> String {
        let digits = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890"
        return String(Array(0..<n).map { _ in digits.randomElement()! })
    }
    
    func disconnect() {
        guard let c = client else {
            return
        }
        c.disconnect()
        self.pendingSubscribeTopic.removeAll()
    }
    
    func connect(username: String, password: String) {
        guard let c = client else {
            DispatchQueue.main.asyncAfter(deadline: .now()) {
                self.connect(username: username, password: password)
                return
            }
            return
        }
        
        if QiscusCore.enableRealtime == true{
            self.pendingSubscribeTopic.append(.comment(token: password))
            self.pendingSubscribeTopic.append(.updateComment(token: password))
            self.pendingSubscribeTopic.append(.notification(token: password))
            
            if  ConfigManager.shared.isEnableDisableRealtimeManually == true && c.isConnect == false {
                c.connect(username: username, password: password, delegate: self)
            }
        } else {
            ConfigManager.shared.isConnectedMqtt = false
        }
        
    }
    
    /// Subscribe comment(deliverd and read), typing by member in the room, and online status
    ///
    /// - Parameter rooms: array of rooms
    // MARK: TODO optimize, check already subscribe?
    func subscribeRooms(rooms: [RoomModel]) {
        guard let c = client else {
            return
        }
        
        if ConfigManager.shared.isEnableDisableRealtimeManually == true {
            for room in rooms {
                if room.type == .channel{
                    if let appId = ConfigManager.shared.appID {
                        if !c.subscribe(endpoint: .roomChannel(AppId: appId, roomUniqueId: room.uniqueId)){
                             self.pendingSubscribeTopic.append(.roomChannel(AppId: appId, roomUniqueId: room.uniqueId))
                             QiscusLogger.errorPrint("failed to subscribe room channel \(room.name), then queue in pending")
                        }
                    }
                }else{
                    // subscribe comment deliverd receipt
                    if !c.subscribe(endpoint: .delivery(roomID: room.id)){
                        self.pendingSubscribeTopic.append(.delivery(roomID: room.id))
                        QiscusLogger.errorPrint("failed to subscribe event deliver event from room \(room.name), then queue in pending")
                    }
                    // subscribe comment read
                    if !c.subscribe(endpoint: .read(roomID: room.id)) {
                        self.pendingSubscribeTopic.append(.read(roomID: room.id))
                        QiscusLogger.errorPrint("failed to subscribe event read from room \(room.name), then queue in pending")
                    }
                    if !c.subscribe(endpoint: .typing(roomID: room.id)) {
                        self.pendingSubscribeTopic.append(.typing(roomID: room.id))
                        QiscusLogger.errorPrint("failed to subscribe event typing from room \(room.name), then queue in pending")
                    }
                    
                    if !c.subscribe(endpoint: .typingAI(roomID: room.id)) {
                        self.pendingSubscribeTopic.append(.typingAI(roomID: room.id))
                        QiscusLogger.errorPrint("failed to subscribe event typingAI from room \(room.name), then queue in pending")
                    }
                    
                    guard let participants = room.participants else { return }
                    for u in participants {
                        if !c.subscribe(endpoint: .onlineStatus(user: u.email)) {
                            self.pendingSubscribeTopic.append(.onlineStatus(user: u.email))
                            QiscusLogger.errorPrint("failed to subscribe online status user \(u.email), then queue in pending")
                        }
                    }
                }
                
               
            }
            
            self.resumePendingSubscribeTopic()
        }
    }
    
    /// subscribe user online presence / online status
    ///
    /// - Parameter userId: userId
    func subscribeUserOnlinePresence(userId : String){
        guard let c = client else {
            return
        }
        
        if ConfigManager.shared.isEnableDisableRealtimeManually == true {
            if !c.subscribe(endpoint: .onlineStatus(user: userId)) {
                self.pendingSubscribeTopic.append(.onlineStatus(user: userId))
                QiscusLogger.errorPrint("failed to subscribe online status user \(userId), then queue in pending")
            }
        }
    }
    
    /// subscribe user online presence / online status
    ///
    /// - Parameter userIds: array of userIds
    func subscribeUserOnlinePresence(userIds : [String]){
        guard let c = client else {
            return
        }
        
        if ConfigManager.shared.isEnableDisableRealtimeManually == true {
            for userId in userIds {
                if !c.subscribe(endpoint: .onlineStatus(user: userId)) {
                    self.pendingSubscribeTopic.append(.onlineStatus(user: userId))
                    QiscusLogger.errorPrint("failed to subscribe online status user \(userId), then queue in pending")
                }
            }
        }
    }
    
    func unsubscribeUserOnlinePresence(userId : String){
        guard let c = client else {
            return
        }
        
        if ConfigManager.shared.isEnableDisableRealtimeManually == true {
            c.unsubscribe(endpoint: .onlineStatus(user: userId))
        }
    }
    
    func unsubscribeUserOnlinePresence(userIds : [String]){
        guard let c = client else {
            return
        }
        
        if ConfigManager.shared.isEnableDisableRealtimeManually == true {
            for userId in userIds {
                c.unsubscribe(endpoint: .onlineStatus(user: userId))
            }
        }
    }
    
    /// Subscribe comment(deliverd and read), typing by member in the room, and online status
    ///
    /// - Parameter rooms: array of rooms
    // MARK: TODO optimize, check already subscribe?
    func subscribeRoomsWithoutOnlineStatus(rooms: [RoomModel]) {
        guard let c = client else {
            return
        }
        
        if ConfigManager.shared.isEnableDisableRealtimeManually == true {
            for room in rooms {
                if room.type == .channel{
                    if let appId = ConfigManager.shared.appID {
                        if !c.subscribe(endpoint: .roomChannel(AppId: appId, roomUniqueId: room.uniqueId)){
                            self.pendingSubscribeTopic.append(.roomChannel(AppId: appId, roomUniqueId: room.uniqueId))
                            QiscusLogger.errorPrint("failed to subscribe room channel \(room.name), then queue in pending")
                        }
                    }
                }else{
                    // subscribe comment deliverd receipt
                    if !c.subscribe(endpoint: .delivery(roomID: room.id)){
                        self.pendingSubscribeTopic.append(.delivery(roomID: room.id))
                        QiscusLogger.errorPrint("failed to subscribe event deliver event from room \(room.name), then queue in pending")
                    }
                    // subscribe comment read
                    if !c.subscribe(endpoint: .read(roomID: room.id)) {
                        self.pendingSubscribeTopic.append(.read(roomID: room.id))
                        QiscusLogger.errorPrint("failed to subscribe event read from room \(room.name), then queue in pending")
                    }
                    if !c.subscribe(endpoint: .typing(roomID: room.id)) {
                        self.pendingSubscribeTopic.append(.typing(roomID: room.id))
                        QiscusLogger.errorPrint("failed to subscribe event typing from room \(room.name), then queue in pending")
                    }
                    
                    if !c.subscribe(endpoint: .typingAI(roomID: room.id)) {
                        self.pendingSubscribeTopic.append(.typingAI(roomID: room.id))
                        QiscusLogger.errorPrint("failed to subscribe event typingAI from room \(room.name), then queue in pending")
                    }
                }
            }
            
            self.resumePendingSubscribeTopic()
        }
    }
    
    func unsubscribeRooms(rooms: [RoomModel]) {
        guard let c = client else {
            return
        }
        
        if ConfigManager.shared.isEnableDisableRealtimeManually == true {
            for room in rooms {
                if room.type != .channel {
                    // unsubcribe room event
                    c.unsubscribe(endpoint: .delivery(roomID: room.id))
                    c.unsubscribe(endpoint: .read(roomID: room.id))
                    c.unsubscribe(endpoint: .typing(roomID: room.id))
                    c.unsubscribe(endpoint: .typingAI(roomID: room.id))
                    guard let participants = room.participants else { return }
                    for u in participants {
                        c.unsubscribe(endpoint: .onlineStatus(user: u.email))
                    }
                }
            }
        }
    }
    
    func unsubscribeRoomsChannel(rooms: [RoomModel]) {
        guard let c = client else {
            return
        }
        
        if ConfigManager.shared.isEnableDisableRealtimeManually == true {
            for room in rooms {
                if room.type == .channel {
                    if let appId = ConfigManager.shared.appID {
                        c.unsubscribe(endpoint: .roomChannel(AppId: appId, roomUniqueId: room.uniqueId))
                    }
                }
            }
        }
        
    }
    
    func unsubscribeRoomsWithoutOnlineStatus(rooms: [RoomModel]) {
        guard let c = client else {
            return
        }
        
        if ConfigManager.shared.isEnableDisableRealtimeManually == true {
            for room in rooms {
                if room.type != .channel {
                    // unsubcribe room event
                    c.unsubscribe(endpoint: .delivery(roomID: room.id))
                    c.unsubscribe(endpoint: .read(roomID: room.id))
                    c.unsubscribe(endpoint: .typing(roomID: room.id))
                    c.unsubscribe(endpoint: .typingAI(roomID: room.id))
                }
            }
        }
    }
    

    func isTyping(_ value: Bool, roomID: String){
        guard let c = client else {
            return
        }
        
        if ConfigManager.shared.isEnableDisableRealtimeManually == true {
            if !c.publish(endpoint: .isTyping(value: value, roomID: roomID)) {
                QiscusLogger.errorPrint("failed to send typing to roomID \(roomID)")
            }
        }
        
    }
    
    func isOnline(_ value: Bool) {
        guard let c = client else {
            return
        }
        
        if ConfigManager.shared.isEnableDisableRealtimeManually == true {
            if !c.publish(endpoint: .onlineStatus(value: value)) {
                if c.isConnect == false {
                    QiscusCore.retryConnect { (success) in
                        if success == true{
                            if let user = QiscusCore.getProfile() {
                                // connect qiscus realtime server
                                QiscusCore.realtime.connect(username: user.email, password: user.token)
                                QiscusLogger.debugPrint("try reconnect Qiscus realtime with server realtime from lb")
                            }
                        }else{
                            QiscusLogger.errorPrint("failed to send Online status")
                        }
                    }
                }
            }
        }
       
    }
    
    func resumePendingSubscribeTopic() {
        guard let client = client else {
            return
        }
        
        if ConfigManager.shared.isEnableDisableRealtimeManually == true {
            QiscusLogger.debugPrint("Resume pending subscribe")
            // resume pending subscribe
            if !pendingSubscribeTopic.isEmpty {
                for (i,t) in pendingSubscribeTopic.enumerated().reversed() {
                    // check if success subscribe
                    if client.subscribe(endpoint: t) {
                        // remove from pending list
                       self.pendingSubscribeTopic.remove(at: i)
                    }
                }
            }
            
            QiscusLogger.debugPrint("pendingSubscribeTopic count = \(pendingSubscribeTopic.count)")
        }
    }
    
    // MARK : Typing event
    func subscribeTyping(roomID: String, onTyping: @escaping (RoomTyping) -> Void) {
        if let roomUser = QiscusCore.database.room.find(id: roomID){
            if roomUser.type == RoomType.channel {
                return
            }
        }
        
        guard let c = client else { return }
        
        if ConfigManager.shared.isEnableDisableRealtimeManually == true {
            if c.isConnect{
                if !c.subscribe(endpoint: .typing(roomID: roomID)) {
                    self.pendingSubscribeTopic.append(.typing(roomID: roomID))
                    QiscusLogger.errorPrint("failed to subscribe event typing from room \(roomID), then queue in pending")
                }else{
                    self.roomTypings[roomID] = onTyping
                }
            }else{
                DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                    self.subscribeTyping(roomID: roomID) { (roomTyping) in
                        self.roomTypings[roomID] = onTyping
                    }
                }
                
            }
        }
       
    }
    
    func unsubscribeTyping(roomID: String) {
        if let roomUser = QiscusCore.database.room.find(id: roomID){
            if roomUser.type == RoomType.channel {
                return
            }
        }
        
        if ConfigManager.shared.isEnableDisableRealtimeManually == true {
            roomTypings.removeValue(forKey: roomID)
            guard let c = client else {
                return
            }
            // unsubcribe room event
            c.unsubscribe(endpoint: .typing(roomID: roomID))
        }
       
    }
    
    // MARK : Custom Event
    func subscribeEvent(roomID: String, onEvent: @escaping (RoomEvent) -> Void) {
        guard let c = client else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.subscribeEvent(roomID: roomID, onEvent: onEvent)
                return
            }
            return
        }
        
        if ConfigManager.shared.isEnableDisableRealtimeManually == true {
            if c.isConnect{
                // subcribe user token to get new comment
                if !c.subscribe(endpoint: .roomEvent(roomID: roomID)) {
                    self.pendingSubscribeTopic.append(.roomEvent(roomID: roomID))
                    QiscusLogger.errorPrint("failed to subscribe room Event, then queue in pending")
                }else {
                    self.roomEvents[roomID] = onEvent
                }
            }else{
                DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                    self.subscribeEvent(roomID: roomID, onEvent: { (roomEvent) in
                        self.roomEvents[roomID] = onEvent
                    })
                }
            }
        }
        
    }
    
    func unsubscribeEvent(roomID: String) {
        if ConfigManager.shared.isEnableDisableRealtimeManually == true {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                if self.roomEvents.count == 0 {
                    return
                }
                
                guard let c = self.client else {
                    return
                }
                
                if self.roomEvents.removeValue(forKey: roomID) != nil{
                    // unsubcribe room event
                    c.unsubscribe(endpoint: .roomEvent(roomID: roomID))
                }
            }
        }
       
    }
    
    func publishEvent(roomID: String, payload: [String : Any]) -> Bool {
        guard let c = client else {
            return false
        }
        
        if ConfigManager.shared.isEnableDisableRealtimeManually == true {
            if c.publish(endpoint: .roomEvent(roomID: roomID, payload: payload.dict2json())) {
                return true //
            }else {
                return false
            }
        }else{
            return false
        }
        
       
    }
    
    // util
    func toDictionary(text : String) -> [String: Any]? {
        if let data = text.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            } catch {
                print("error parsing \(error.localizedDescription)")
            }
        }
        return nil
    }
}

extension RealtimeManager: QiscusRealtimeDelegate {
    func didReceiveRoomDelete(roomID: String, data: String){
        guard let payload = toDictionary(text: data) else { return }
        if let room = QiscusCore.database.room.find(id: roomID) {
            _ = QiscusCore.database.comment.clear(inRoom: room.id, timestamp: nil)
        }
    }
    func didReceiveRoomEvent(roomID: String, data: String) {
        guard let payload = toDictionary(text: data) else { return }
        guard let postEvent = roomEvents[roomID] else { return }
        let event = RoomEvent(sender: payload["sender"] as? String ?? "", data: payload["data"] as? [String : Any] ?? ["":""])
        postEvent(event)
    }
    
    func didReceiveUser(userEmail: String, isOnline: Bool, timestamp: String) {
        QiscusEventManager.shared.gotEvent(email: userEmail, isOnline: isOnline, timestamp: timestamp)
    }

    func didReceiveMessageStatus(roomId: String, commentId: String, commentUniqueId: String, Status: MessageStatus, userEmail: String) {
        self.updateMessageStatus(roomId: roomId, commentId: commentId, commentUniqueId: commentUniqueId, Status: Status, userEmail: userEmail, sourceMqtt: true)
    }
    
    func updateMessageStatus(roomId: String, commentId: String, commentUniqueId: String, Status: MessageStatus, userEmail: String, sourceMqtt: Bool = true) {
        guard let _comment = QiscusCore.database.comment.find(uniqueId: commentUniqueId) else { return }
        var _status : CommentStatus? = nil
        switch Status {
        case .deleted:
            _status  = .deleted
            // delete from local
            _comment.status = .deleted
            _comment.isDeleted  = true
            _ = QiscusCore.database.comment.delete(_comment)
            break
        case .delivered:
            _status  = .delivered
            break
        case .read:
            _status  = .read
            break
        }
        // check convert status
        guard let status = _status else { return }
        if status == .deleted { return }
        if let room = QiscusCore.database.room.find(id: roomId) {
            // very tricky, need to review v3, calculating comment status in backend for group rooms
            if let comments = QiscusCore.database.comment.find(roomId: roomId) {
                guard let user = QiscusCore.getProfile() else {
                    return
                }
                
                guard let comment = QiscusCore.database.comment.find(id: commentId) else{
                    return
                }
                
                if room.type == .single {
                    if user.email.lowercased() == userEmail.lowercased(){
                        return
                    }
                    // compare current status
                    if comment.status.intValue < status.intValue {
                        // update all my comment status
                        comments.forEach { (c) in
                            // check lastStatus and compare
                            if c.status.intValue < status.intValue {
                                let new = c
                                // update comment
                                new.status = status
                                QiscusCore.database.comment.save([new])
                                QiscusCore.eventManager.gotMessageStatus(comment: new) // patch hard update
                            }
                            
                        }
                    }
                }else if room.type == .group {
                    guard let participants = room.participants else {
                        QiscusCore.network.getRoomById(roomId: room.id, onSuccess: { (room, comments) in
                            // save room
                            if let comments = comments {
                                room.lastComment = comments.first
                            }
                            
                            QiscusCore.database.room.save([room])
                            
                            // save comments
                            var c = [CommentModel]()
                            if let _comments = comments {
                                // save comments
                                QiscusCore.database.comment.save(_comments)
                                c = _comments
                            }
                            
                            return
                        }) { (error) in
                            return
                        }
                        
                        return
                    }
                    
                    switch Status {
                    case .delivered:
                        if let commentID = Int(commentId){
                            if userEmail != user.email {
                                // check if userEmail not me, update all
                                for participant in participants{
                                    participant.lastCommentReceivedId = commentID
                                    QiscusCore.database.member.save([participant], roomID: roomId)
                                }
                            }else{
                                // else userEmail is me, just update participant me
                                for participant in participants{
                                    if participant.email == user.email {
                                        participant.lastCommentReceivedId = commentID
                                        QiscusCore.database.member.save([participant], roomID: roomId)
                                    }
                                }
                            }
                        }
                        break
                    case .read:
                        if let commentID = Int(commentId){
                            if sourceMqtt == true {
                                if userEmail != user.email {
                                    // check if userEmail not me, update all
                                    for participant in participants{
                                        participant.lastCommentReadId = commentID
                                        participant.lastCommentReceivedId = commentID
                                        QiscusCore.database.member.save([participant], roomID: roomId)
                                    }
                                }else{
                                   // else userEmail is me, just update participant me
                                    for participant in participants{
                                        if participant.email == user.email {
                                            participant.lastCommentReadId = commentID
                                            participant.lastCommentReceivedId = commentID
                                            QiscusCore.database.member.save([participant], roomID: roomId)
                                        }
                                    }
                                }
                            }else{
                                if userEmail != comment.userEmail {
                                    // check if userEmail not same with sender
                                    for participant in participants{
                                        participant.lastCommentReadId = commentID
                                        participant.lastCommentReceivedId = commentID
                                        QiscusCore.database.member.save([participant], roomID: roomId)
                                    }

                                }else if user.email == comment.userEmail {
                                    // check if sender is me
                                    for participant in participants{
                                        if participant.email == userEmail {
                                            participant.lastCommentReadId = commentID
                                            participant.lastCommentReceivedId = commentID
                                            QiscusCore.database.member.save([participant], roomID: roomId)
                                        }
                                    }
                                } else if userEmail != comment.userEmail {
                                    //check if userEmail not same with comment sender
                                    for participant in participants{
                                        participant.lastCommentReadId = commentID
                                        participant.lastCommentReceivedId = commentID
                                        QiscusCore.database.member.save([participant], roomID: roomId)
                                    }
                                }
                            }
                        }
                        break
                    case .deleted:
                        break
                    }
                    
                    var readUser = [MemberModel]()
                    var deliveredUser = [MemberModel]()
                    var sentUser = [MemberModel]()
                    
                    if let room = QiscusCore.database.room.find(id: roomId){
                        for participant in room.participants!{
                            if let commentID = Int(commentId){
                                if participant.lastCommentReadId == commentID{
                                    readUser.append(participant)
                                }else if (participant.lastCommentReceivedId == commentID){
                                    deliveredUser.append(participant)
                                }else{
                                    sentUser.append(participant)
                                }
                            }
                            
                        }
                    
                        if(readUser.count == room.participants?.count){
                            if comment.status.intValue < status.intValue {
                                // update all my comment status
                                comments.forEach { (c) in
                                    // check lastStatus and compare
                                    if c.status.intValue < status.intValue {
                                        let new = c
                                        // update comment
                                        new.status = .read
                                        QiscusCore.database.comment.save([new])
                                        QiscusCore.eventManager.gotMessageStatus(comment: new)
                                    }
                                    
                                }
                            }

                        }else{
                            if comment.status.intValue < status.intValue && userEmail.lowercased() !=  user.email.lowercased(){
                                // update all my comment status
                                comments.forEach { (c) in
                                    // check lastStatus and compare
                                    if c.status.intValue < status.intValue {
                                        let new = c
                                        // update comment
                                        new.status = .delivered
                                        QiscusCore.database.comment.save([new])
                                        QiscusCore.eventManager.gotMessageStatus(comment: new)
                                    }
                                    
                                }
                            }

                        }
                    }
                }else {
                    // ignore for channel
                }
            }
        }
    }
    
    func didReceiveMessage(data: String) {
        let json = ApiResponse.decode(string: data)
        let comment = CommentModel(json: json)
        
        //check comment in db
        if let commentDB = QiscusCore.database.comment.find(id: comment.roomId){
            //ignored for status sent from my self / after postComment
        }else{
            DispatchQueue.global(qos: .background).sync {
                QiscusCore.database.comment.save([comment])
            }
        }
        
        
    }
    
    func didReceiveUpdatedMessage(data: String) {
        let json = ApiResponse.decode(string: data)
        let comment = CommentModel(json: json)
        
        //check comment in db
        QiscusCore.database.comment.save([comment], publishEvent: true, isUpdateMessage: true)

    }
    
    func didReceiveUser(typing: Bool, roomId: String, userEmail: String) {
        QiscusEventManager.shared.gotTyping(roomID: roomId, user: userEmail, value: typing)
        
       //typing event from outside room
        if let room = QiscusCore.database.room.find(id: roomId) {
            guard let member = QiscusCore.database.member.find(byEmail: userEmail) else { return }
            guard let postTyping = roomTypings[roomId] else { return }
            let typing = RoomTyping(roomID: roomId, user: member, typing: typing)
            postTyping(typing)
        }
        
    }
    
    
    func didReceiveUserAI(roomId: String, data: String) {
        let json = ApiResponse.decode(string: data)
        
        let userID = json["sender_id"].string ?? ""
        let senderName = json["sender_name"].string ?? ""
        let textMessage = json["text"].string ?? ""
        let statusTyping = json["status"].string ?? "0"
        var boolTyping = false
        if statusTyping == "0" {
            boolTyping = false
        }else{
            boolTyping = true
        }
        QiscusEventManager.shared.gotTypingAI(roomID: roomId, user: userID, value: boolTyping, textMessage: textMessage, senderName : senderName)
        
       //typing event from outside room
        if let room = QiscusCore.database.room.find(id: roomId) {
            guard let member = QiscusCore.database.member.find(byEmail: userID) else { return }
            guard let postTyping = roomTypings[roomId] else { return }
            let typing = RoomTyping(roomID: roomId, user: member, typing: boolTyping)
            postTyping(typing)
        }
    }
    
    
    func connectionState(change state: QiscusRealtimeConnectionState) {
        QiscusLogger.debugPrint("Qiscus realtime connection state \(state.rawValue)")
        
        if state == .connecting {
            QiscusEventManager.shared.connectionDelegate?.onReconnecting()
        }
        
        self.state = state
        if let state : QiscusConnectionState = QiscusConnectionState(rawValue: state.rawValue) {
            QiscusEventManager.shared.connectionDelegate?.connectionState(change: state)
        }
        
        switch state {
        case .connected:
            QiscusCore.reconnectCounter = 0
            ConfigManager.shared.isConnectedMqtt = true
            QiscusLogger.debugPrint("Qiscus realtime connected")
            DispatchQueue.main.async {
                let stateApp = UIApplication.value(forKeyPath: #keyPath(UIApplication.shared)) as! UIApplication
                let state = stateApp.applicationState

                
                if state == .active {
                    // foreground
                    QiscusCore.shared.publishOnlinePresence(isOnline: true)
                }
            }
            resumePendingSubscribeTopic()
            QiscusEventManager.shared.connectionDelegate?.onConnected()
            
            break
        case .disconnected:
            QiscusLogger.debugPrint("Qiscus realtime disconnected")
            QiscusCore.heartBeat?.resume()
            break
        default:
            break
        }
    }
    
    
    func disconnect(withError err: Error?){
        ConfigManager.shared.isConnectedMqtt = false
        if let error = err{
            QiscusEventManager.shared.connectionDelegate?.onDisconnected(withError: QError(message: error.localizedDescription))
            if QiscusCore.hasSetupUser(){
                if QiscusCore.enableEventReport == true {
                    QiscusCore.network.event_report(moduleName: "MQTT", event: "DISCONNECTED", message: error.localizedDescription, onSuccess: { (success) in
                        //success send report
                    }) { (error) in
                        QiscusLogger.debugPrint(error.message)
                    }
                }
            }
        }else{
             QiscusEventManager.shared.connectionDelegate?.onDisconnected(withError: nil)
        }
        
        if QiscusCore.hasSetupUser(){
            if QiscusCore.enableRealtime == true && ConfigManager.shared.isEnableDisableRealtimeManually == true{
                
                if QiscusCore.reconnectCounter >= 20 {
                    //stop call reconnect
                    return
                }else{
                    QiscusCore.retryConnect { (success) in
                        if success == true{
                            if let user = QiscusCore.getProfile() {
                                let periode = QiscusCore.reconnectCounter * 10
                               
                                let when = DispatchTime.now() + DispatchTimeInterval.seconds(periode)
                                
                                DispatchQueue.main.asyncAfter(deadline: when, execute: {
                                    // connect qiscus realtime server
                                    QiscusCore.reconnectCounter += 1
                                    QiscusCore.realtime.connect(username: user.email, password: user.token)
                                    QiscusLogger.debugPrint("try reconnect Qiscus realtime with server realtime from lb \(QiscusLogger.getDateTime())")
                
                                })
                            }
                        }
                    }
                }
            }
        }
    }

}


 //
//  RealtimeManager.swift
//  QiscusCore
//
//  Created by Qiscus on 09/08/18.
//

import Foundation
import QiscusRealtime
import UIKit

typealias _roomEvent = (RoomEvent) -> Void
typealias _roomTyping = (RoomTyping) -> Void
 
public class RealtimeManager {
    var qiscusCore : QiscusCore? = nil
   // static var shared : RealtimeManager = RealtimeManager()
   
    private var pendingSubscribeTopic : [RealtimeSubscribeEndpoint] = [RealtimeSubscribeEndpoint]()
    var state : QiscusRealtimeConnectionState = QiscusRealtimeConnectionState.disconnected
    private var roomEvents : [String : _roomEvent] = [String : _roomEvent]()
    
    private var roomTypings : [String : _roomTyping] = [String : _roomTyping]()
    func setup(appName: String) {
        // make sure realtime self.qiscusCore?.client still single object
       // if self.qiscusCore?.client != nil { return }
        var bundle = "0"
        if let bundleData = Bundle.main.infoDictionary?[kCFBundleNameKey as String] as? String{
            bundle = bundleData
        }

        let now = Int64(NSDate().timeIntervalSince1970 * 1000000000.0) // nano sec
        let clientID = "iosMQTT-\(bundle)-\(appName)-\(randomString(10))-\(now)"
        
        var config = QiscusRealtimeConfig(appName: appName, clientID: clientID)
        if let customServer = self.qiscusCore?.config.server?.realtimeURL {
            config.hostRealtimeServer = customServer
        }
        if let customPort = self.qiscusCore?.config.server?.realtimePort {
            config.port = customPort
        }
        self.qiscusCore?.client = QiscusRealtime.init(withConfig: config)
        QiscusRealtime.enableDebugPrint = self.qiscusCore?.enableDebugPrint ?? false
    }
    
    func randomString(_ n: Int) -> String {
        let digits = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890"
        return String(Array(0..<n).map { _ in digits.randomElement()! })
    }

    
    func disconnect() {
        guard let c = self.qiscusCore?.client else {
            return
        }
        c.disconnect()
        self.pendingSubscribeTopic.removeAll()
    }
    
    func connect(username: String, password: String) {
        guard let c = self.qiscusCore?.client else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.connect(username: username, password: password)
                return
            }
            return
        }
        
        if self.qiscusCore?.enableRealtime == true{
            self.pendingSubscribeTopic.append(.comment(token: password))
            self.pendingSubscribeTopic.append(.updateComment(token: password))
            self.pendingSubscribeTopic.append(.notification(token: password))
            
            c.connect(username: username, password: password, delegate: self)
        } else {
            self.qiscusCore?.config.isConnectedMqtt = false
        }

        
    }
    
    /// Subscribe comment(deliverd and read), typing by member in the room, and online status
    ///
    /// - Parameter rooms: array of rooms
    // MARK: TODO optimize, check already subscribe?
    func subscribeRooms(rooms: [QChatRoom]) {
        guard let c = self.qiscusCore?.client else {
            return
        }
        
        if self.qiscusCore?.config.isEnableDisableRealtimeManually == true {
            for room in rooms {
                if room.type == .channel{
                    if let appId = self.qiscusCore?.config.appID {
                        if !c.subscribe(endpoint: .roomChannel(AppId: appId, roomUniqueId: room.uniqueId)){
                             self.pendingSubscribeTopic.append(.roomChannel(AppId: appId, roomUniqueId: room.uniqueId))
                             self.qiscusCore?.qiscusLogger.errorPrint("failed to subscribe room channel \(room.name), then queue in pending")
                        }
                    }
                }else{
                    // subscribe comment deliverd receipt
                    if !c.subscribe(endpoint: .delivery(roomID: room.id)){
                        self.pendingSubscribeTopic.append(.delivery(roomID: room.id))
                        self.qiscusCore?.qiscusLogger.errorPrint("failed to subscribe event deliver event from room \(room.name), then queue in pending")
                    }
                    // subscribe comment read
                    if !c.subscribe(endpoint: .read(roomID: room.id)) {
                        self.pendingSubscribeTopic.append(.read(roomID: room.id))
                        self.qiscusCore?.qiscusLogger.errorPrint("failed to subscribe event read from room \(room.name), then queue in pending")
                    }
                    if !c.subscribe(endpoint: .typing(roomID: room.id)) {
                        self.pendingSubscribeTopic.append(.typing(roomID: room.id))
                        self.qiscusCore?.qiscusLogger.errorPrint("failed to subscribe event typing from room \(room.name), then queue in pending")
                    }
                    guard let participants = room.participants else { return }
                    for u in participants {
                        if !c.subscribe(endpoint: .onlineStatus(user: u.id)) {
                            self.pendingSubscribeTopic.append(.onlineStatus(user: u.id))
                            self.qiscusCore?.qiscusLogger.errorPrint("failed to subscribe online status user \(u.id), then queue in pending")
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
        guard let c = self.qiscusCore?.client else {
            return
        }
        
        if self.qiscusCore?.config.isEnableDisableRealtimeManually == true {
            if !c.subscribe(endpoint: .onlineStatus(user: userId)) {
                self.pendingSubscribeTopic.append(.onlineStatus(user: userId))
                self.qiscusCore?.qiscusLogger.errorPrint("failed to subscribe online status user \(userId), then queue in pending")
            }
        }
    }
    
    /// subscribe user online presence / online status
    ///
    /// - Parameter userIds: array of userIds
    func subscribeUserOnlinePresence(userIds : [String]){
        guard let c = self.qiscusCore?.client else {
            return
        }
        
        if self.qiscusCore?.config.isEnableDisableRealtimeManually == true {
            for userId in userIds {
                if !c.subscribe(endpoint: .onlineStatus(user: userId)) {
                    self.pendingSubscribeTopic.append(.onlineStatus(user: userId))
                    self.qiscusCore?.qiscusLogger.errorPrint("failed to subscribe online status user \(userId), then queue in pending")
                }
            }
        }
        
    }
    
    func unsubscribeUserOnlinePresence(userId : String){
        guard let c = self.qiscusCore?.client else {
            return
        }
        
        if self.qiscusCore?.config.isEnableDisableRealtimeManually == true {
            c.unsubscribe(endpoint: .onlineStatus(user: userId))
        }
    }
    
    func unsubscribeUserOnlinePresence(userIds : [String]){
        guard let c = self.qiscusCore?.client else {
            return
        }
        
        if self.qiscusCore?.config.isEnableDisableRealtimeManually == true {
            for userId in userIds {
                c.unsubscribe(endpoint: .onlineStatus(user: userId))
            }
        }
    }
    
    /// Subscribe comment(deliverd and read), typing by member in the room, and online status
    ///
    /// - Parameter rooms: array of rooms
    // MARK: TODO optimize, check already subscribe?
    func subscribeRoomsWithoutOnlineStatus(rooms: [QChatRoom]) {
        guard let c = self.qiscusCore?.client else {
            return
        }
        
        if self.qiscusCore?.config.isEnableDisableRealtimeManually == true {
            for room in rooms {
                if room.type == .channel{
                    if let appId = self.qiscusCore?.config.appID {
                        if !c.subscribe(endpoint: .roomChannel(AppId: appId, roomUniqueId: room.uniqueId)){
                            self.pendingSubscribeTopic.append(.roomChannel(AppId: appId, roomUniqueId: room.uniqueId))
                            self.qiscusCore?.qiscusLogger.errorPrint("failed to subscribe room channel \(room.name), then queue in pending")
                        }
                    }
                }else{
                    // subscribe comment deliverd receipt
                    if !c.subscribe(endpoint: .delivery(roomID: room.id)){
                        self.pendingSubscribeTopic.append(.delivery(roomID: room.id))
                        self.qiscusCore?.qiscusLogger.errorPrint("failed to subscribe event deliver event from room \(room.name), then queue in pending")
                    }
                    // subscribe comment read
                    if !c.subscribe(endpoint: .read(roomID: room.id)) {
                        self.pendingSubscribeTopic.append(.read(roomID: room.id))
                        self.qiscusCore?.qiscusLogger.errorPrint("failed to subscribe event read from room \(room.name), then queue in pending")
                    }
                    if !c.subscribe(endpoint: .typing(roomID: room.id)) {
                        self.pendingSubscribeTopic.append(.typing(roomID: room.id))
                        self.qiscusCore?.qiscusLogger.errorPrint("failed to subscribe event typing from room \(room.name), then queue in pending")
                    }
                }
            }
            
            self.resumePendingSubscribeTopic()
        }
    }
    
    func unsubscribeRooms(rooms: [QChatRoom]) {
        guard let c = self.qiscusCore?.client else {
            return
        }
        
        if self.qiscusCore?.config.isEnableDisableRealtimeManually == true {
            for room in rooms {
                if room.type != .channel {
                    // unsubcribe room event
                    c.unsubscribe(endpoint: .delivery(roomID: room.id))
                    c.unsubscribe(endpoint: .read(roomID: room.id))
                    c.unsubscribe(endpoint: .typing(roomID: room.id))
                    guard let participants = room.participants else { return }
                    for u in participants {
                        c.unsubscribe(endpoint: .onlineStatus(user: u.id))
                    }
                }
            }
        }
    }
    
    func unsubscribeRoomsChannel(rooms: [QChatRoom]) {
        guard let c = self.qiscusCore?.client else {
            return
        }
        
        if self.qiscusCore?.config.isEnableDisableRealtimeManually == true {
            for room in rooms {
                if room.type == .channel {
                    if let appId = self.qiscusCore?.config.appID {
                        c.unsubscribe(endpoint: .roomChannel(AppId: appId, roomUniqueId: room.uniqueId))
                    }
                }
            }
        }
        
    }
    
    func unsubscribeRoomsWithoutOnlineStatus(rooms: [QChatRoom]) {
        guard let c = self.qiscusCore?.client else {
            return
        }
        
        if self.qiscusCore?.config.isEnableDisableRealtimeManually == true {
            for room in rooms {
                if room.type != .channel {
                    // unsubcribe room event
                    c.unsubscribe(endpoint: .delivery(roomID: room.id))
                    c.unsubscribe(endpoint: .read(roomID: room.id))
                    c.unsubscribe(endpoint: .typing(roomID: room.id))
                }
            }
        }
        
    }
    

    func isTyping(_ value: Bool, roomID: String){
        guard let c = self.qiscusCore?.client else {
            return
        }
        
        if self.qiscusCore?.config.isEnableDisableRealtimeManually == true {
            if !c.publish(endpoint: .isTyping(value: value, roomID: roomID)) {
                self.qiscusCore?.qiscusLogger.errorPrint("failed to send typing to roomID \(roomID)")
            }
        }
    }
    
    func isOnline(_ value: Bool) {
        guard let c = self.qiscusCore?.client else {
            return
        }
        
        if self.qiscusCore?.config.isEnableDisableRealtimeManually == true {
            if !c.publish(endpoint: .onlineStatus(value: value)) {
                self.qiscusCore?.qiscusLogger.errorPrint("failed to send Online status")
            }
        }
    }
    
    func resumePendingSubscribeTopic() {
        guard let client = self.qiscusCore?.client else {
            return
        }
        if self.qiscusCore?.config.isEnableDisableRealtimeManually == true {
            self.qiscusCore?.qiscusLogger.debugPrint("Resume pending subscribe")
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
            
            self.qiscusCore?.qiscusLogger.debugPrint("pendingSubscribeTopic count = \(pendingSubscribeTopic.count)")
        }
    }
    
    // MARK : Typing event
    func subscribeTyping(roomID: String, onTyping: @escaping (RoomTyping) -> Void) {
        guard let c = self.qiscusCore?.client else { return }
        
        if let roomUser = self.qiscusCore?.database.room.find(id: roomID){
            if roomUser.type == RoomType.channel {
                return
            }
        }
        
        if self.qiscusCore?.config.isEnableDisableRealtimeManually == true {
            if c.isConnect{
                if !c.subscribe(endpoint: .typing(roomID: roomID)) {
                    self.pendingSubscribeTopic.append(.typing(roomID: roomID))
                    self.qiscusCore?.qiscusLogger.errorPrint("failed to subscribe event typing from room \(roomID), then queue in pending")
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
        if let roomUser = self.qiscusCore?.database.room.find(id: roomID){
            if roomUser.type == RoomType.channel {
                return
            }
        }
        
        if self.qiscusCore?.config.isEnableDisableRealtimeManually == true {
            guard let c = self.qiscusCore?.client else {
                return
            }
            // unsubcribe room event
            roomTypings.removeValue(forKey: roomID)
            c.unsubscribe(endpoint: .typing(roomID: roomID))
        }
    }
    
    // MARK : Custom Event
    func subscribeEvent(roomID: String, onEvent: @escaping (RoomEvent) -> Void) {
        guard let c = self.qiscusCore?.client else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.subscribeEvent(roomID: roomID, onEvent: onEvent)
                return
            }
            return
        }
        
        if self.qiscusCore?.config.isEnableDisableRealtimeManually == true {
            if c.isConnect{
                // subcribe user token to get new comment
                if !c.subscribe(endpoint: .roomEvent(roomID: roomID)) {
                    self.pendingSubscribeTopic.append(.roomEvent(roomID: roomID))
                    self.qiscusCore?.qiscusLogger.errorPrint("failed to subscribe room Event, then queue in pending")
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
        if self.qiscusCore?.config.isEnableDisableRealtimeManually == true {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                if self.roomEvents.count == 0 {
                    return
                }
                
                guard let c = self.self.qiscusCore?.client else {
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
        guard let c = self.qiscusCore?.client else {
            return false
        }
        
        if self.qiscusCore?.config.isEnableDisableRealtimeManually == true {
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
    public func didReceiveRoomDelete(roomID: String, data: String){
        guard let payload = toDictionary(text: data) else { return }
        if let room = self.qiscusCore?.database.room.find(id: roomID) {
            _ = self.qiscusCore?.database.message.clear(inRoom: room.id, timestamp: nil)
        }
    }

    public func didReceiveRoomEvent(roomID: String, data: String) {
        guard let payload = toDictionary(text: data) else { return }
        guard let postEvent = roomEvents[roomID] else { return }
        let event = RoomEvent(sender: payload["sender"] as? String ?? "", data: payload["data"] as? [String : Any] ?? ["":""])
        postEvent(event)
    }
    
    public func didReceiveUser(userEmail: String, isOnline: Bool, timestamp: String) {
        qiscusCore?.eventManager.gotEvent(email: userEmail, isOnline: isOnline, timestamp: timestamp)
    }

    public func didReceiveMessageStatus(roomId: String, commentId: String, commentUniqueId: String, Status: MessageStatus, userEmail: String) {
        self.updateMessageStatus(roomId: roomId, commentId: commentId, commentUniqueId: commentUniqueId, Status: Status, userEmail: userEmail, sourceMqtt: true)
    }
    
    func updateMessageStatus(roomId: String, commentId: String, commentUniqueId: String, Status: MessageStatus, userEmail: String, sourceMqtt: Bool = true) {
        guard let _comment = self.qiscusCore?.database.message.find(uniqueId: commentUniqueId) else { return }
        var _status : QMessageStatus? = nil
        switch Status {
        case .deleted:
            _status  = .deleted
            // delete from local
            _comment.status = .deleted
            _comment.isDeleted  = true
            _ = self.qiscusCore?.database.message.delete(_comment)
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
        if let room = self.qiscusCore?.database.room.find(id: roomId) {
            // very tricky, need to review v3, calculating comment status in backend for group rooms
            if let comments = self.qiscusCore?.database.message.find(roomId: roomId) {
                guard let user = self.qiscusCore?.getProfile() else {
                    return
                }
                
                guard let comment = self.qiscusCore?.database.message.find(id: commentId) else{
                    return
                }
                
                if room.type == .single {
                    if user.id.lowercased() == userEmail.lowercased(){
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
                                self.qiscusCore?.database.message.save([new])
                                self.qiscusCore?.eventManager.gotMessageStatus(comment: new) // patch hard update
                            }
                            
                        }
                    }
                }else if room.type == .group {
                    guard let participants = room.participants else {
                        self.qiscusCore?.network.getRoomById(roomId: room.id, onSuccess: { (room, comments) in
                            // save room
                            if let comments = comments {
                                room.lastComment = comments.first
                            }
                            
                            self.qiscusCore?.database.room.save([room])
                            
                            // save comments
                            var c = [QMessage]()
                            if let _comments = comments {
                                // save comments
                                self.qiscusCore?.database.message.save(_comments)
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
                            if userEmail != user.id {
                                // check if userEmail not me, update all
                                for participant in participants{
                                    participant.lastMessageDeliveredId = commentID
                                    self.qiscusCore?.database.participant.save([participant], roomID: roomId)
                                }
                            }else{
                                // else userEmail is me, just update participant me
                                for participant in participants{
                                    if participant.id == user.id {
                                        participant.lastMessageDeliveredId = commentID
                                        self.qiscusCore?.database.participant.save([participant], roomID: roomId)
                                    }
                                }
                            }
                        }
                        break
                    case .read:
                        if let commentID = Int(commentId){
                            if sourceMqtt == true {
                                if userEmail != user.id {
                                    // check if userEmail not me, update all
                                    for participant in participants{
                                        participant.lastMessageReadId = commentID
                                        participant.lastMessageDeliveredId = commentID
                                        self.qiscusCore?.database.participant.save([participant], roomID: roomId)
                                    }
                                }else{
                                   // else userEmail is me, just update participant me
                                    for participant in participants{
                                        if participant.id == user.id {
                                            participant.lastMessageReadId = commentID
                                            participant.lastMessageDeliveredId = commentID
                                            self.qiscusCore?.database.participant.save([participant], roomID: roomId)
                                        }
                                    }
                                }
                            }else{
                                if userEmail != comment.userEmail {
                                    // check if userEmail not same with sender
                                    for participant in participants{
                                        participant.lastMessageReadId = commentID
                                        participant.lastMessageDeliveredId = commentID
                                        self.qiscusCore?.database.participant.save([participant], roomID: roomId)
                                    }

                                }else if user.id == comment.userEmail {
                                    // check if sender is me
                                    for participant in participants{
                                        if participant.id == userEmail {
                                            participant.lastMessageReadId = commentID
                                            participant.lastMessageDeliveredId = commentID
                                            self.qiscusCore?.database.participant.save([participant], roomID: roomId)
                                        }
                                    }
                                } else if userEmail != comment.userEmail {
                                    //check if userEmail not same with comment sender
                                    for participant in participants{
                                        participant.lastMessageReadId = commentID
                                        participant.lastMessageDeliveredId = commentID
                                        self.qiscusCore?.database.participant.save([participant], roomID: roomId)
                                    }
                                }
                            }
                        }
                        break
                    case .deleted:
                        break
                    }
                    
                    var readUser = [QParticipant]()
                    var deliveredUser = [QParticipant]()
                    var sentUser = [QParticipant]()
                    
                    if let room = self.qiscusCore?.database.room.find(id: roomId){
                        for participant in room.participants!{
                            if let commentID = Int(commentId){
                                if participant.lastMessageReadId == commentID{
                                    readUser.append(participant)
                                }else if (participant.lastMessageDeliveredId == commentID){
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
                                        self.qiscusCore?.database.message.save([new])
                                        self.qiscusCore?.eventManager.gotMessageStatus(comment: new)
                                    }
                                    
                                }
                            }

                        }else{
                            if comment.status.intValue < status.intValue && userEmail.lowercased() !=  user.id.lowercased(){
                                // update all my comment status
                                comments.forEach { (c) in
                                    // check lastStatus and compare
                                    if c.status.intValue < status.intValue {
                                        let new = c
                                        // update comment
                                        new.status = .delivered
                                        self.qiscusCore?.database.message.save([new])
                                        self.qiscusCore?.eventManager.gotMessageStatus(comment: new)
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
    
    public func didReceiveMessage(data: String) {
        let json = ApiResponse.decode(string: data)
        let comment = QMessage(json: json, qiscusCore: self.qiscusCore)
        
        //check comment in db
        if let commentDB = self.qiscusCore?.database.message.find(id: comment.chatRoomId){
            //ignored for status sent from my self / after postComment
        }else{
            self.qiscusCore?.database.message.save([comment])
        }
        
        
    }
    
    public func didReceiveUpdatedMessage(data: String) {
        let json = ApiResponse.decode(string: data)
        let comment = QMessage(json: json, qiscusCore: self.qiscusCore)
        
        //check comment in db
        qiscusCore?.database.message.save([comment], publishEvent: true, isUpdateMessage: true)

    }
    
    public func didReceiveUser(typing: Bool, roomId: String, userEmail: String) {
        qiscusCore?.eventManager.gotTyping(roomID: roomId, user: userEmail, value: typing)
        
       //typing event from outside room
        if let room = self.qiscusCore?.database.room.find(id: roomId) {
            guard let member = self.qiscusCore?.database.participant.find(byEmail: userEmail) else { return }
            guard let postTyping = roomTypings[roomId] else { return }
            let typing = RoomTyping(roomID: roomId, user: member, typing: typing)
            postTyping(typing)
        }
        
    }
    
    public func connectionState(change state: QiscusRealtimeConnectionState) {
        self.qiscusCore?.qiscusLogger.debugPrint("Qiscus realtime connection state \(state.rawValue)")
        
        if state == .connecting {
            qiscusCore?.connectionDelegate?.onReconnecting()
        }
        
        self.state = state
        if let state : QiscusConnectionState = QiscusConnectionState(rawValue: state.rawValue) {
            qiscusCore?.connectionDelegate?.connectionState(change: state)
        }
        
        switch state {
        case .connected:
            self.qiscusCore?.config.isConnectedMqtt = true
            self.qiscusCore?.qiscusLogger.debugPrint("Qiscus realtime connected")
            DispatchQueue.main.async {
                let stateApp = UIApplication.value(forKeyPath: #keyPath(UIApplication.shared)) as! UIApplication
                let state = stateApp.applicationState
                
                if state == .active {
                    // foreground
                    self.qiscusCore?.shared.publishOnlinePresence(isOnline: true)
                }
            }
            
            if let room = self.qiscusCore?.activeChatRoom{
                self.qiscusCore?.shared.subscribeChatRoom(room)
            }
            
            resumePendingSubscribeTopic()
            qiscusCore?.connectionDelegate?.onConnected()
            
            break
        case .disconnected:
            self.qiscusCore?.qiscusLogger.debugPrint("Qiscus realtime disconnected")
            self.qiscusCore?.heartBeat?.resume()
            break
        default:
            break
        }
    }
    
    
    public func disconnect(withError err: Error?){
        self.qiscusCore?.config.isConnectedMqtt = false
        if let error = err{
            qiscusCore?.connectionDelegate?.onDisconnected(withError: QError(message: error.localizedDescription))
            if self.qiscusCore?.hasSetupUser() ?? true{
                if self.qiscusCore?.enableEventReport == true {
                    self.qiscusCore?.network.event_report(moduleName: "MQTT", event: "DISCONNECTED", message: error.localizedDescription, onSuccess: { (success) in
                        //success send report
                    }) { (error) in
                        self.qiscusCore?.qiscusLogger.debugPrint(error.message)
                    }
                }
            }
        }else{
             qiscusCore?.connectionDelegate?.onDisconnected(withError: nil)
        }
        
        if self.qiscusCore?.hasSetupUser() ?? true{
            if self.qiscusCore?.enableRealtime == true && self.qiscusCore?.config.isEnableDisableRealtimeManually == true{
                self.qiscusCore?.retryConnect { (success) in
                    if success == true{
                        if let user = self.qiscusCore?.getProfile() {
                            // connect qiscus realtime server
                            self.qiscusCore?.realtime.connect(username: user.id, password: user.token)
                            self.qiscusCore?.qiscusLogger.debugPrint("try reconnect Qiscus realtime with server realtime from lb")
                        }
                    }
                }
            }
        }
    }

}


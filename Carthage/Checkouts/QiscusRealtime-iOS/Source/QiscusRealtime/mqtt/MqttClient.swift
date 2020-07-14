//
//  MqttClient.swift
//  QiscusCore
//
//  Created by Qiscus on 09/08/18.
//

import Foundation
import CocoaMQTT

enum QREventType {
    case comment
    case typing // ignore by sender
    case online // ignore by sender
    case read // ignore by sender
    case delivery // ignore by sender
    case notification
    case undefined
    case event // room event
}

class MqttClient {
    var client              : CocoaMQTT
    var delegate            : QiscusRealtimeDelegate? = nil
    var connectionState     : QiscusRealtimeConnectionState = .disconnected
    var isConnect : Bool {
        get {
            if connectionState == .connected {
                return true
            }else {
                return false
            }
        }
    }
    
    init(clientID: String, host: String, port: UInt16) {
        client = CocoaMQTT.init(clientID: clientID, host: host, port: port)
    }
    
    func connect(username: String, password: String,ssl:Bool) -> Bool {
        client.username = username
        client.password = password
        client.willMessage = CocoaMQTTMessage(topic: "u/\(username)/s", string: "0",qos: .qos1, retained:  true)
        client.keepAlive    = 60
        client.autoReconnect    = false
        client.delegate         = self
        client.enableSSL        = ssl
        
        return client.connect()
    }
    
    func publish(_ topic: String, message: String, retained:Bool = true) -> Bool {
        if self.connectionState == .connected {
            client.publish(topic, withString: message, qos: .qos1, retained: retained)
            return true
        }else {
            QRLogger.debugPrint("can't publish \(topic)")
            return false
        }
    }
    
    func subscribe(_ topic: String) -> Bool {
        if self.connectionState == .connected {
            client.subscribe(topic, qos: .qos1)
            return true
        }else {
            // delay subscribe
            QRLogger.debugPrint("delay subscribe \(topic)")
            return false
        }
    }
    
    func unsubscribe(_ topic: String) {
        client.unsubscribe(topic)
    }
    
    func disconnect(){
        self.client.disconnect()
    }
    
    private func getEventType(topic: String) -> QREventType {
        // MARK: TODO check other type
        let word = topic.components(separatedBy: "/")
        // follow this doc https://quip.com/JpRjA0qjmINd
        if word.count == 2 {
            // probably new comment
            if word[1] == "c" || word.last == "c"{
                return QREventType.comment
            }else if word.last == "n" {
                return QREventType.notification
            }
            else {
                return QREventType.undefined
            }
        }else if word.count == 3 {
            if word.first == "u" && word.last == "s" {
                return QREventType.online
            }else if word.last == "c"{
                 return QREventType.comment
            }else {
                return QREventType.undefined
            }
        }else if word.count == 4 {
            if word.first == "r" && word.last == "e" {
                return QREventType.event
            }else {
                return QREventType.undefined
            }
        }else if word.count == 5 {
            // probably deliverd or read or typing
            if word.last == "t" {
                return QREventType.typing
            }else if word.last == "r" {
                return QREventType.read
            }else if word.last == "d" {
                return QREventType.delivery
            }else{
                return QREventType.undefined
            }
        }else {
            return QREventType.undefined
        }
    }
    /// Get room id from topic room event
    private func getEventRoomID(fromTopic topic: String) -> String {
        let r = topic.replacingOccurrences(of: "r/", with: "")
        let t = r.replacingOccurrences(of: "/e", with: "")
        let id = t.components(separatedBy: "/")
        return id.first ?? ""
    }
    /// Get room id from topic typing, read, delivered
    private func getRoomID(fromTopic topic: String) -> String {
        let r = topic.replacingOccurrences(of: "r/", with: "")
        let t = r.replacingOccurrences(of: "/t", with: "")
        let id = t.components(separatedBy: "/")
        return id.first ?? ""
    }
    /// Get email from topic typing, read, delivered
    private func getUser(fromTopic topic: String) -> String {
        // r/959996/959996/hijuju/t /d /r
        var t = topic.components(separatedBy: "/")
        t.removeLast() // remove /t /d /r
        return t.last ?? ""
    }
    
    private func getUserOnline(fromTopic topic: String) -> String {
        // u/hijuju/s
        var t = topic.components(separatedBy: "/")
        t.removeFirst() // remove "u"
        return t.first ?? ""
    }
    
    /// get comment id and unique id from event message status deliverd or read
    ///
    /// - Parameter topic: mqtt payload
    /// - Returns: comment id and unique id
    private func getCommentId(fromPayload payload: String) -> (String,String) {
        // example payload :
        // {commentId}:{commentUniqueId}
        let ids = payload.components(separatedBy: ":")
        return(ids.first ?? "", ids.last ?? "")
    }
    
    private func getCommentsUniqueID(fromPayload payload: String) -> [DeletedMessage]? {
        let data = payload.data(using: .utf8)!
        do {
            let decoder = JSONDecoder()
            let json = try decoder.decode(PayloadNotification.self, from:
                data)
            if json.actionTopic == "delete_message" {
                return json.payload.data.deletedMessages
            }else {
                return nil
            }
        }catch {
            return nil
        }
    }
    
    /// get user is Online and timestampt
    ///
    /// - Parameter payload: mqtt payload
    /// - Returns: isOnline and timestampt in UTC
    private func getIsOnlineAndTime(fromPayload payload: String) -> (Bool,String) {
        // example payload :
        // **{1|0}:timestamp**
        let ids = payload.components(separatedBy: ":")
        let value = Int(ids.first ?? "0") ?? 0 // convert string to int default 0
        let isOnline = value != 0 // convert int to bool, default false
        return(isOnline, ids.last ?? "")
    }
}

extension MqttClient: CocoaMQTTDelegate {
    func mqtt(_ mqtt: CocoaMQTT, didSubscribeTopics success: NSDictionary, failed: [String]) {
        QRLogger.debugPrint("didSubscribeTopic success: \(success)")
        QRLogger.debugPrint("didSubscribeTopic failed: \(failed)")
    }
    
//    func mqtt(_ mqtt: CocoaMQTT, didSubscribeTopic topics: [String]) {
//        QRLogger.debugPrint("didSubscribeTopic: \(topics)")
//    }
    
    // Optional ssl CocoaMQTTDelegate
    func mqtt(_ mqtt: CocoaMQTT, didReceive trust: SecTrust, completionHandler: @escaping (Bool) -> Void) {
        completionHandler(true)
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didConnectAck ack: CocoaMQTTConnAck) {
        //        let state = UIApplication.shared.applicationState
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didStateChangeTo state: CocoaMQTTConnState) {
        self.connectionState = QiscusRealtimeConnectionState(rawValue: state.description)!
        self.delegate?.connectionState(change: QiscusRealtimeConnectionState(rawValue: self.connectionState.rawValue) ?? .disconnected)
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didPublishMessage message: CocoaMQTTMessage, id: UInt16) {
        if let messageData = message.string {
            QRLogger.debugPrint("didPublishMessage \n===== topic: \(message.topic) \n===== data: \(messageData)")
        }
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didPublishAck id: UInt16) {
        
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didReceiveMessage message: CocoaMQTTMessage, id: UInt16 ) {
        if let messageData = message.string {
            QRLogger.debugPrint("didReceiveMessage \n===== topic: \(message.topic) \n===== data: \(messageData)")
            let type = getEventType(topic: message.topic)
            // MARK: 
            switch type {
            case .comment:
                //                let id = getRoomID(fromComment: messageData)
                self.delegate?.didReceiveMessage(data: messageData)
            case .typing:
                let id = getRoomID(fromTopic: message.topic)
                let user = getUser(fromTopic: message.topic)
                if user == client.username { break }
                let value = Int(messageData) ?? 0 // convert string to int default 0
                let istyping = value != 0 // convert int to bool, default false
                self.delegate?.didReceiveUser(typing: istyping, roomId: id, userEmail: user)
                break
            case .online:
                let user = getUserOnline(fromTopic: message.topic)
                if user == client.username { break }
                let (isOnline,time) = getIsOnlineAndTime(fromPayload: messageData)
                self.delegate?.didReceiveUser(userEmail: user, isOnline: isOnline, timestamp: time)
                break
            case .read:
                let user = getUser(fromTopic: message.topic)
                if user == client.username { break }
                let room          = getRoomID(fromTopic: message.topic)
                let (id,uniqueID) = getCommentId(fromPayload: messageData)
                if room.isEmpty || id.isEmpty || uniqueID.isEmpty || user.isEmpty { break }
                self.delegate?.didReceiveMessageStatus(roomId: room, commentId: id, commentUniqueId: uniqueID, Status: .read, userEmail: user)
                break
            case .delivery:
                let user = getUser(fromTopic: message.topic)
                if user == client.username { break }
                let room          = getRoomID(fromTopic: message.topic)
                let (id,uniqueID) = getCommentId(fromPayload: messageData)
                if room.isEmpty || id.isEmpty || uniqueID.isEmpty || user.isEmpty { break }
                self.delegate?.didReceiveMessageStatus(roomId: room, commentId: id, commentUniqueId: uniqueID, Status: .delivered, userEmail: user)
                break
            case .notification:
                guard let response : [DeletedMessage] = self.getCommentsUniqueID(fromPayload: messageData) else { break }
                if response.isEmpty { break }
                for room in response {
                    if !room.messageUniqueIDS.isEmpty {
                        for id in room.messageUniqueIDS {
                            self.delegate?.didReceiveMessageStatus(roomId: room.roomID, commentId: "", commentUniqueId: id, Status: .deleted, userEmail: "")
                        }
                    }
                }
                break
            case .event:
                let room = getEventRoomID(fromTopic: message.topic)
                self.delegate?.didReceiveRoomEvent(roomID: room, data: messageData)
            case .undefined:
                QRLogger.debugPrint("Receive event but topic undefined")
                break
            }
        }
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didSubscribeTopics topics: [String]) {
         QRLogger.debugPrint("didSubscribeTopic: \(topics)")
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didUnsubscribeTopics topics: [String]) {
         QRLogger.debugPrint("didUnsubscribeTopic: \(topics)")
    }

    func mqttDidPing(_ mqtt: CocoaMQTT) {
        QRLogger.debugPrint("PING")
    }
    
    func mqttDidReceivePong(_ mqtt: CocoaMQTT) {
        QRLogger.debugPrint("PONG")
    }
    
    func mqttDidDisconnect(_ mqtt: CocoaMQTT, withError err: Error?) {
         QRLogger.debugPrint("disconnected mqtt =\(err?.localizedDescription)")
        self.delegate?.disconnect(withError: err)
    }
}

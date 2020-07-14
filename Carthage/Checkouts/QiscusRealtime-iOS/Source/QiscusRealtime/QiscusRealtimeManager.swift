//
//  QiscusManager.swift
//  QChat
//
//  Created by asharijuang on 8/24/17.
//  Copyright © 2017 qiscus. All rights reserved.
//

import Foundation

public enum RealtimeSubscribeEndpoint {
    case comment(token: String)
    // publish online status
    case onlineStatus(user: String)
    // get typing inside room
    case typing(roomID: String)
    // delivery or receive comment inside room
    case delivery(roomID: String)
    // read comment inside room
    case read(roomID: String)
    case notification(token: String)
    // subscribe room event
    case roomEvent(roomID: String)
    
    case roomChannel(AppId: String, roomUniqueId: String)
}
public enum RealtimePublishEndpoint {
    // publish online status
    case onlineStatus(value: Bool)
    // publish typing in room, typing by autenticate user
    case isTyping(value: Bool, roomID: String)
    // publish custom room event
    case roomEvent(roomID: String, payload: String)
}

struct RealtimeSubscriber {
    static func topic(endpoint: RealtimeSubscribeEndpoint) -> String {
        switch endpoint {
        case .comment(let token):
            return "\(token)/c"
        case .onlineStatus(let user):
            return "u/\(user)/s"
        case .typing(let roomID):
            return "r/\(roomID)/\(roomID)/+/t"
        case .delivery(let roomID):
            return "r/\(roomID)/\(roomID)/+/d"
        case .read(let roomID):
            return "r/\(roomID)/\(roomID)/+/r"
        case .notification(let token):
            return "\(token)/n"
        case .roomEvent(let roomID):
            return "r/\(roomID)/\(roomID)/e"
        case .roomChannel(let appId, let roomUniqueId):
            return "\(appId)/\(roomUniqueId)/c"
        }
    }
}

struct RealtimePublisher {
    static func topic(endpoint: RealtimePublishEndpoint, user: String) -> String {
        switch endpoint {
        case .onlineStatus(_):
            return "u/\(user)/s"
        case .isTyping(_ , let roomID):
            return "r/\(roomID)/\(roomID)/\(user)/t"
        case .roomEvent(let roomID, _):
            return "r/\(roomID)/\(roomID)/e"
        }
    }
}

// Qiscus wrapper
class QiscusRealtimeManager {
    var delegate            : QiscusRealtimeDelegate? = nil
    var config               : QiscusRealtimeConfig?    = nil
    var user                : QiscusRealtimeUser?   = nil
    var mqttClient          : MqttClient!
    var isConnected         : Bool {
        get {
            return mqttClient.isConnect
        }
    }

    init(withConfig c: QiscusRealtimeConfig) {
        config          = c
        mqttClient     = MqttClient(clientID: c.clientID, host: c.hostRealtimeServer, port: c.port)
    }
    
    func disconnect(){
        mqttClient.disconnect()
    }
    
    func publish(type: RealtimePublishEndpoint) -> Bool {
        if let u = self.user {
            let topic = RealtimePublisher.topic(endpoint: type, user: u.email)
            switch type {
            case .onlineStatus(let value):
                return mqttClient.publish(topic, message: "\(value ? 1 : 0)", retained: true)
            case .isTyping(let value, _):
                return mqttClient.publish(topic, message: "\(value ? 1 : 0)", retained: false)
            case .roomEvent(_, let payload):
                let jsonPayload : String = "{\"sender\":\"\(u.email)\",\"data\":\(payload)}"
                return mqttClient.publish(topic, message: jsonPayload, retained: false)
            }
        }else {
            return false
        }
    }
    
    func subscribe(type: RealtimeSubscribeEndpoint) -> Bool {
        let topic = RealtimeSubscriber.topic(endpoint: type)
        return mqttClient.subscribe(topic)
    }
    
    func unsubscribe(type: RealtimeSubscribeEndpoint) {
        let topic = RealtimeSubscriber.topic(endpoint: type)
        mqttClient.unsubscribe(topic)
    }

    func connect(username: String, password: String, delegate: QiscusRealtimeDelegate? = nil){
        self.delegate = delegate
        mqttClient.delegate = delegate
        let connecting = mqttClient.connect(username: username, password: password, ssl: config?.QiscusClientRealtimeSSL ?? true)
        if connecting {
            self.user   = QiscusRealtimeUser(email: username, token: password, deviceID: "")
        }
    }
    
    private func timenowUTC() -> String {
        let timeInms = NSDate().timeIntervalSince1970 // is UTC
        return String(timeInms)
    }
}

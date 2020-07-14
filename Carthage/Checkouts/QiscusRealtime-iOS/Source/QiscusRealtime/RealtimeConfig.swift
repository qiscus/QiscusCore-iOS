//
//  RealtimeConfig.swift
//  QiscusRealtime
//
//  Created by Qiscus on 09/08/18.
//

import Foundation

public enum MessageStatus:Int{
    case read
    case delivered
    case deleted
}

struct QiscusRealtimeUser {
    let email       : String
    let token       : String
    let deviceID    : String
}

public struct QiscusRealtimeConfig {
    public let appName                    : String
    public var clientID                   : String
    public var hostRealtimeServer         : String = "mqtt.qiscus.com"
    public var port                       : UInt16 = 1885
    public var QiscusClientRealtimeSSL    : Bool = true
    
    public init(appName name: String, clientID id: String) {
        appName = name
        clientID = id
    }
    
    public init(appName name: String, clientID id: String, host h: String, port p: UInt16) {
        appName             = name
        clientID            = id
        hostRealtimeServer  = h
        port                = p
    }
}

//
//  mqttLib.swift
//  mqttLib
//
//  Created by asharijuang on 03/08/18.
//  Copyright © 2018 qiscus. All rights reserved.
//

import Foundation

public class QiscusRealtime {
    private let manager : QiscusRealtimeManager
    public static var enableDebugPrint: Bool = false
    public var isConnect : Bool {
        return manager.isConnected
    }
    class var bundle:Bundle{
        get{
            let podBundle   = Bundle(for: QiscusRealtime.self)
            
            if let bundleURL = podBundle.url(forResource: "QiscusRealtime", withExtension: "bundle") {
                return Bundle(url: bundleURL)!
            }else{
                return podBundle
            }
        }
    }
    
    /// this func to init QiscusRealtime
    ///
    /// - Parameters:
    ///   - config: need to set config QiscusRealtimeConfig
    ///   - delegate
    public init(withConfig config: QiscusRealtimeConfig) {
        manager = QiscusRealtimeManager(withConfig: config)
    }
    
    /// Connect to qiscus realtime server, you can listen protocol when connect to realtime server
    ///
    /// - Parameters:
    ///   - username: qiscus user email
    ///   - password: qiscus token
    ///   - delegate: set delegate to get the event
    public func connect(username: String, password: String, delegate: QiscusRealtimeDelegate? = nil){
        manager.connect(username: username, password: password, delegate: delegate)
    }
    
    public func subscribe(endpoint: RealtimeSubscribeEndpoint) -> Bool {
        return manager.subscribe(type: endpoint)
    }
    
    public func unsubscribe(endpoint: RealtimeSubscribeEndpoint){
        manager.unsubscribe(type: endpoint)
    }
    
    public func publish(endpoint: RealtimePublishEndpoint) -> Bool {
        return manager.publish(type:endpoint)
    }
    
    /// this func to disconnect qiscus realtime
    public func disconnect(){
        return manager.disconnect()
    }
}

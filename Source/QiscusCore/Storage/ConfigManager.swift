//
//  ConfigManager.swift
//  Pods
//
//  Created by Qiscus on 07/08/18.
//

import Foundation

public class ConfigManager : NSObject {
    var qiscusCore : QiscusCore? = nil
    //static let shared = ConfigManager()
    var prefix : String {
        get{
            return "qcu_\(qiscusCore?.appID)"
        }
    }
    fileprivate var userCache : QAccount? = nil
    var appID   : String? {
        get {
            let storage = UserDefaults.standard
            return storage.string(forKey: prefix) ?? nil
        }
        set {
            guard let id = newValue else { return }
            let storage = UserDefaults.standard
            storage.set(id, forKey: prefix)
        }
    }
    
    var customHeader : [String : Any]?{
        get{
           return self.getCustomHeader()
        }
        set{
            guard let value = newValue else { return }
            self.setCustomHeader(value)
        }
    }
    
    var deviceToken : String?{
        get{
           return getDeviceToken()
        }
        set{
            guard let value = newValue else { return }
            setDeviceToken(value)
        }
    }
    
    var user    : QAccount? {
        get {
           return loadUser()
        }
        set {
            if let value = newValue {
                saveUser(value)
            }
        }
    }
    var syncEventId : String {
        get {
            return self.getSyncEventId()
        }
        set {
            self.setSyncEventId(newValue)
        }
    }
    var syncId : String {
        get {
            return self.getSyncId()
        }
        set {
            self.setSyncId(newValue)
        }
    }
    
    var lastCommentId : String {
        get {
            return self.getLastCommentId()
        }
        set {
            self.setLastCommentId(newValue)
        }
    }
    
    private func setLastCommentId(_ id: String) {
        // save in file
        let defaults = UserDefaults.standard
        let current = self.getSyncEventId()
        defaults.set(id, forKey: filename("lastMessageId"))
    }
    
    private func getLastCommentId() -> String {
        // save in file
        let defaults = UserDefaults.standard
        return defaults.string(forKey: filename("lastMessageId")) ?? ""
    }

    
    var isConnectedMqtt : Bool {
        get {
            return self.getIsConnectedMQTT()
        }
        set {
            self.setIsConnectedMQTT(newValue)
        }
    }
    
    var server    : QiscusServer? {
           get {
                return loadQiscusServer()
           }
           set {
               if let value = newValue {
                   saveQiscusServer(value)
               }
           }
       }
    
    var syncInterval    : TimeInterval {
           get {
                return loadQiscusSyncInterval()
           }
           set {
               saveQiscusSyncInterval(newValue)
           }
       }
    
    //var syncInterval : TimeInterval     = 5
    
    fileprivate func fileNameQiscusServer(_ name: String) -> String {
        return prefix + name + "qiscusServer"
    }
    
    private func saveQiscusServer(_ data: QiscusServer) {
        // save in file
        let defaults = UserDefaults.standard
        defaults.set(data.brokerLBUrl, forKey: fileNameQiscusServer("brokerLBUrl"))
        defaults.set(data.realtimePort, forKey: fileNameQiscusServer("realtimePort"))
        defaults.set(data.realtimeURL, forKey: fileNameQiscusServer("realtimeURL"))
        defaults.set(data.url.absoluteString, forKey: fileNameQiscusServer("url"))
    }
    
    private func loadQiscusServer() -> QiscusServer? {
        
        // load from cache
        let storage = UserDefaults.standard
        
        
        let defaultBrokerURL = ""
        let defaultRealtimePort = 1885
        let defaultRealtimeURL = ""
        let defaultUrl = "https://"
        
        let realtimePort :Int  = storage.integer(forKey: fileNameQiscusServer("realtimePort")) ?? defaultRealtimePort
        let urlString : String =  storage.string(forKey: fileNameQiscusServer("url")) ?? defaultUrl
        
            
        
        let qiscusServer : QiscusServer = QiscusServer.init(url: URL(string: urlString)!, realtimeURL: storage.string(forKey: fileNameQiscusServer("realtimeURL")) ?? defaultRealtimeURL, realtimePort: UInt16(realtimePort), brokerLBUrl: storage.string(forKey: fileNameQiscusServer("brokerLBUrl")) ?? defaultBrokerURL)
        
        if qiscusServer.url == nil{
            return nil
        }else{
           return qiscusServer
        }
        
        
    }
    
    private func loadQiscusSyncInterval() -> TimeInterval {
        let storage = UserDefaults.standard
        
        let localTimeInterval = storage.integer(forKey: filename("timeInterval"))
        
        return TimeInterval(localTimeInterval)
    }
    
    private func saveQiscusSyncInterval(_ value: TimeInterval) {
        // save in file
        let defaults = UserDefaults.standard
        defaults.set(value, forKey: filename("timeInterval"))
    }
    
    
    fileprivate func filename(_ name: String) -> String {
        return prefix + name + "userdata"
    }
    
    private func saveUser(_ data: QAccount) {
        // save in file
        let defaults = UserDefaults.standard
        defaults.set(data.id, forKey: filename("email"))
        defaults.set(data.name, forKey: filename("username"))
        defaults.set(data.token, forKey: filename("token"))
        defaults.set(data.rtKey, forKey: filename("rtKey"))
//        defaults.set(data.pnIosConfigured, forKey: filename("pnIosConfigured"))
        defaults.set(data.lastSyncEventId, forKey: filename("lastSyncEventId"))
        defaults.set(data.lastMessageId, forKey: filename("lastMessageId"))
        defaults.set(data.avatarUrl, forKey: filename("avatarUrl"))
        defaults.set(data.extras, forKey: filename("extras"))
    }
    
    private func loadUser() -> QAccount? {
        // save in cache
        let storage = UserDefaults.standard
        if let token = storage.string(forKey: filename("token")) {
            if token.isEmpty { return nil }
            var user = QAccount()
            user.token              = token
            user.id                 = storage.string(forKey: filename("email")) ?? ""
            user.name               = storage.string(forKey: filename("username")) ?? ""
            user.extras             = storage.string(forKey: filename("extras")) ?? ""
            user.avatarUrl          = storage.url(forKey: filename("avatarUrl")) ?? URL(string: "http://")!
            user.lastSyncEventId    = storage.string(forKey: filename("lastSyncEventId")) ?? ""
            user.lastMessageId      = storage.string(forKey: filename("lastMessageId")) ?? ""
            self.userCache          = user
            return user
        }else {
            return nil
        }
    }
    
    private func setSyncId(_ id: String) {
        // save in file
        let defaults = UserDefaults.standard
        defaults.set(id, forKey: filename("syncId"))
    }
    
    private func getSyncId() -> String {
        // save in file
        let defaults = UserDefaults.standard
        return defaults.string(forKey: filename("syncId")) ?? ""
    }
    
    private func setCustomHeader(_ value: [String:Any]) {
        // save in file
        let defaults = UserDefaults.standard
        defaults.set(value, forKey: fileNameQiscusServer("customHeader"))
    }
    
    private func getCustomHeader() -> [String:Any]? {
        // save in file
        let defaults = UserDefaults.standard
        return defaults.dictionary(forKey: fileNameQiscusServer("customHeader")) ?? nil
    }
    
    private func setDeviceToken(_ value: String) {
        // save in file
        let defaults = UserDefaults.standard
        defaults.set(value, forKey: filename("deviceToken"))
    }
    
    private func getDeviceToken() -> String? {
        // save in file
        let defaults = UserDefaults.standard
        return defaults.string(forKey: filename("deviceToken")) ?? nil
    }
    
    private func setSyncEventId(_ id: String) {
        // save in file
        let defaults = UserDefaults.standard
        defaults.set(id, forKey: filename("syncEventId"))
    }
    
    private func getSyncEventId() -> String {
        // save in file
        let defaults = UserDefaults.standard
        return defaults.string(forKey: filename("syncEventId")) ?? "0"
    }
    
    private func setIsConnectedMQTT(_ value: Bool) {
        // save in file
        let defaults = UserDefaults.standard
        defaults.set(value, forKey: filename("isConnectedMQTT"))
    }
    
    private func getIsConnectedMQTT() -> Bool {
        // save in file
        let defaults = UserDefaults.standard
        return defaults.bool(forKey: filename("isConnectedMQTT")) ?? true
    }
    
    var isEnableDisableRealtimeManually : Bool {
        get {
            return self.getIsEnableDisableRealtimeManuallly()
        }
        set {
            self.setIsEnableDisableRealtimeManuallly(newValue)
        }
    }

    private func setIsEnableDisableRealtimeManuallly(_ value: Bool) {
        // save in file
        let defaults = UserDefaults.standard
        defaults.set(value, forKey: filename("enableDisableRealtimeManuallly"))
    }
    
    //by default is enable
    private func getIsEnableDisableRealtimeManuallly() -> Bool {
        let defaults = UserDefaults.standard
        let checkFirstTIme = defaults.bool(forKey: filename("firstTime"))
        
        if checkFirstTIme == false {
            defaults.set(true, forKey: filename("firstTime"))
            self.setIsEnableDisableRealtimeManuallly(true)
            return true
        }else{
            // save in file
            return defaults.bool(forKey: filename("enableDisableRealtimeManuallly"))
        }
        
    }
    
    func clearConfig() {
        // remove file user
        let storage = UserDefaults.standard
        storage.removeObject(forKey: filename("id"))
        storage.removeObject(forKey: filename("token"))
        storage.removeObject(forKey: filename("username"))
        storage.removeObject(forKey: filename("email"))
        storage.removeObject(forKey: filename("rtKey"))
        storage.removeObject(forKey: filename("avatarUrl"))
        storage.removeObject(forKey: filename("syncEventId"))
        storage.removeObject(forKey: filename("syncId"))
        storage.removeObject(forKey: filename("isConnectedMQTT"))
        storage.removeObject(forKey: filename("extras"))
        storage.removeObject(forKey: filename("customHeader"))
        storage.removeObject(forKey: filename("deviceToken"))
        storage.removeObject(forKey: filename("lastMessageId"))
        storage.removeObject(forKey: filename("firstTime"))
        storage.removeObject(forKey: filename("enableDisableRealtimeManuallly"))

        self.userCache = nil
    }
}

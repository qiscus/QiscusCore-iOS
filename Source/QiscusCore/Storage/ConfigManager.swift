//
//  ConfigManager.swift
//  Pods
//
//  Created by Qiscus on 07/08/18.
//

import Foundation

public class ConfigManager : NSObject {
    var eventdelegate  : QiscusCoreEventDelegate?
    static let shared = ConfigManager()
    private let prefix = "qcu_"
    fileprivate var userCache : UserModel? = nil
    var appID   : String? {
        get {
            let storage = UserDefaults.standard
            return storage.string(forKey: "qiscuskey") ?? nil
        }
        set {
            guard let id = newValue else { return }
            let storage = UserDefaults.standard
            storage.set(id, forKey: "qiscuskey")
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
    
    var user    : UserModel? {
        get {
            if let user = userCache {
                self.eventdelegate?.onDebugEvent("InitQiscus-isLogined()", message: "finish check QiscusCore.isLogined from userCache \(QiscusLogger.getDateTime())")
                self.eventdelegate = nil // just firstTime when call QiscusCoreWithCustomeServer()
                return user
            }else {
                return loadUser()
            }
        }
        set {
            if let value = newValue {
                self.userCache = nil
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
    
    
    var isConnectedMqtt : Bool {
        get {
            return self.getIsConnectedMQTT()
        }
        set {
            self.setIsConnectedMQTT(newValue)
        }
    }
    
    var isEnableDisableRealtimeManually : Bool {
        get {
            return self.getIsEnableDisableRealtimeManuallly()
        }
        set {
            self.setIsEnableDisableRealtimeManuallly(newValue)
        }
    }
    
    var server      : QiscusServer?     = nil
    var syncInterval : TimeInterval     = 5
    
    fileprivate func filename(_ name: String) -> String {
        return prefix + name + "userdata"
    }
    
    private func saveUser(_ data: UserModel) {
        // save in file
        let defaults = UserDefaults.standard
        defaults.set(data.id, forKey: filename("id"))
        defaults.set(data.username, forKey: filename("username"))
        defaults.set(data.email, forKey: filename("email"))
        defaults.set(data.token, forKey: filename("token"))
        defaults.set(data.rtKey, forKey: filename("rtKey"))
//        defaults.set(data.pnIosConfigured, forKey: filename("pnIosConfigured"))
//        defaults.set(data.lastSyncEventId, forKey: filename("lastSyncEventId"))
//        defaults.set(data.lastCommentId, forKey: filename("lastCommentId"))
        defaults.set(data.avatarUrl, forKey: filename("avatarUrl"))
        defaults.set(data.extras, forKey: filename("extras"))
        defaults.set(data.refreshUserToken, forKey: filename("refreshToken"))
        defaults.set(data.tokenExpiresAt, forKey: filename("tokenExpiresAt"))
    }
    
    private func loadUser() -> UserModel? {
        // save in cache
        let storage = UserDefaults.standard
        if let token = storage.string(forKey: filename("token")) {
            if token.isEmpty { return nil }
            var user = UserModel()
            user.token      = token
            user.id         = storage.string(forKey: filename("id")) ?? ""
            user.email      = storage.string(forKey: filename("email")) ?? ""
            user.username   = storage.string(forKey: filename("username")) ?? ""
            user.extras     = storage.string(forKey: filename("extras")) ?? ""
            user.avatarUrl  = storage.url(forKey: filename("avatarUrl")) ?? URL(string: "http://")!
            user.refreshUserToken = storage.string(forKey: filename("refreshToken")) ?? ""
            user.tokenExpiresAt = storage.string(forKey: filename("tokenExpiresAt")) ?? ""
//            user.lastSyncEventId    = Int64(storage.integer(forKey: filename("username")))
            self.userCache  = user
            
            self.eventdelegate?.onDebugEvent("InitQiscus-isLogined()", message: "finish check QiscusCore.isLogined from loadUser() \(QiscusLogger.getDateTime())")
            self.eventdelegate = nil // just firstTime when call setupWithCustomServer()
            return user
        }else {
            self.eventdelegate?.onDebugEvent("InitQiscus-isLogined()", message: "finish check QiscusCore.isLogined from loadUser() with return nil (not login) \(QiscusLogger.getDateTime())")
            self.eventdelegate = nil // just firstTime when call setupWithCustomServer()
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
        defaults.set(value, forKey: filename("customHeader"))
    }
    
    private func getCustomHeader() -> [String:Any]? {
        // save in file
        let defaults = UserDefaults.standard
        return defaults.dictionary(forKey: filename("customHeader")) ?? nil
    }
    
    private func setDeviceToken(_ value: String) {
        // save in file
        let defaults = UserDefaults.standard
        defaults.set(value, forKey: filename("deviceToken"))
    }
    
    private func getDeviceToken() -> String? {
        // save in file
        let defaults = UserDefaults.standard
        return defaults.string(forKey: "deviceToken") ?? nil
    }
    
    private func setSyncEventId(_ id: String) {
        // save in file
        let defaults = UserDefaults.standard
        let current = self.getSyncEventId()
        defaults.set(id, forKey: filename("syncEventId"))
    }
    
    private func getSyncEventId() -> String {
        // save in file
        let defaults = UserDefaults.standard
        return defaults.string(forKey: filename("syncEventId")) ?? "0"
    }
    
    private func setLastCommentId(_ id: String) {
        // save in file
        let defaults = UserDefaults.standard
        let current = self.getSyncEventId()
        defaults.set(id, forKey: filename("lastCommentId"))
    }
    
    private func getLastCommentId() -> String {
        // save in file
        let defaults = UserDefaults.standard
        return defaults.string(forKey: filename("lastCommentId")) ?? ""
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
    
    var lastClearDB : String?{
        get{
           return getLastClearDB()
        }
        set{
            guard let value = newValue else { return }
            setLastClearDB(value)
        }
    }
    
    private func setLastClearDB(_ value: String) {
        // save in file
        let defaults = UserDefaults.standard
        defaults.set(value, forKey: filename("lastClearDB"))
    }
    
    private func getLastClearDB() -> String? {
        // save in file
        let defaults = UserDefaults.standard
        return defaults.string(forKey: filename("lastClearDB")) ?? nil
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
        storage.removeObject(forKey: filename("lastCommentId"))
        storage.removeObject(forKey: filename("firstTime"))
        storage.removeObject(forKey: filename("enableDisableRealtimeManuallly"))
        storage.removeObject(forKey: filename("refreshToken"))
        storage.removeObject(forKey: filename("tokenExpiresAt"))
        storage.removeObject(forKey: filename("lastClearDB"))
        self.userCache = nil
    }
}

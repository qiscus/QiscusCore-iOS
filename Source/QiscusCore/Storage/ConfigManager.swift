//
//  ConfigManager.swift
//  Pods
//
//  Created by Qiscus on 07/08/18.
//

import Foundation

class ConfigManager : NSObject {
    static let shared = ConfigManager()
    private let prefixOLD = "qcu_"
    private let prefix = "qcuNew_"
    private let iv = "-iv-QiscusJogja-" // fixed 16 chars.
    private var cryptoKeyString : String {
        get {
            if let key = KeychainWrapper.standard.string(forKey: "rtKey") {
                return key
            }else{
                return ""
            }
        }
    }
    
    var appID   : String? {
        get {
            let storage = UserDefaults.standard
            if let appID = storage.string(forKey: "qiscuskey"){
                //save to keychain
                KeychainWrapper.standard.set(appID, forKey: "qiscuskey")
                
                //remove from storage
                storage.removeObject(forKey: "qiscuskey")
                
                return appID
            }else{
                //check in keychain
                if let key = KeychainWrapper.standard.string(forKey: "qiscuskey") {
                    return key
                }else{
                    return nil
                }
            }
        }
        set {
            guard let id = newValue else { return }
            //save to keychain
            KeychainWrapper.standard.set(id, forKey: "qiscuskey")
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
    
    
    var isConnectedMqtt : Bool {
        get {
            return self.getIsConnectedMQTT()
        }
        set {
            self.setIsConnectedMQTT(newValue)
        }
    }
    
    var server      : QiscusServer?     = nil
    var syncInterval : TimeInterval     = 5
    
    func migrationEncrypDescrypt(){
        let storage = UserDefaults.standard
        if let token = storage.string(forKey: filenameOLD("token")) {
            if token.isEmpty {
                //not login or was migration
                print("arief check not login or was migration")
            }else{
                //go migration
                let storage = UserDefaults.standard
                
                //migration user
                if let token = storage.string(forKey: filenameOLD("token")) {
                    if !token.isEmpty {
                        var userOLD = UserModel()
                        userOLD.token      = token
                        userOLD.id         = storage.string(forKey: filenameOLD("id")) ?? ""
                        userOLD.email      = storage.string(forKey: filenameOLD("email")) ?? ""
                        userOLD.username   = storage.string(forKey: filenameOLD("username")) ?? ""
                        userOLD.extras     = storage.string(forKey: filenameOLD("extras")) ?? ""
                        userOLD.avatarUrl  = storage.url(forKey: filenameOLD("avatarUrl")) ?? URL(string: "http://")!
                        userOLD.rtKey      = storage.string(forKey: filenameOLD("rtKey")) ?? ""
                        
                        
                        KeychainWrapper.standard.set(userOLD.rtKey, forKey: "rtKey")
                        
                        self.user = userOLD
                    }
                }
                
                //migration syncId
                if let oldSyncId = storage.string(forKey: filenameOLD("syncId")){
                    self.syncId = oldSyncId
                }
                
                //migration custom header
                if let customHeaderOLD = storage.dictionary(forKey: filenameOLD("customHeader")){
                    self.customHeader = customHeaderOLD
                }
                
                //migration syncEventId
                if let syncEventIdOLD = storage.string(forKey: filenameOLD("syncEventId")) {
                    self.syncEventId = syncEventIdOLD
                }
                
                //migration lastCommentId
                if let lastCommentIdOLD = storage.string(forKey: filenameOLD("lastCommentId")){
                    self.lastCommentId = lastCommentIdOLD
                }
                
                //migration isConnectMQTT
                let isConnectedMqttOLD = storage.bool(forKey: filename("isConnectedMQTT")) ?? true
                self.isConnectedMqtt = isConnectedMqttOLD
                
                
                //remove oldData after save to new encrypt
                self.clearOldData()
                
            }
        } else {
            //not login or was migration
        }
    }
    
    fileprivate func filename(_ name: String) -> String {
        return prefix + name + "userdata"
    }
    
    fileprivate func filenameOLD(_ name: String) -> String {
        return prefixOLD + name + "userdata"
    }
    
    private func saveUser(_ data: UserModel) {
        let defaults = UserDefaults.standard
        
        // save in file
        if let encodedDataId = data.id.aesEncrypt(key: cryptoKeyString, iv: iv){
            defaults.set(encodedDataId, forKey: filename("id"))
        }
        
        if let encodedDataUsername = data.username.aesEncrypt(key: cryptoKeyString, iv: iv){
            defaults.set(encodedDataUsername, forKey: filename("username"))
        }
        
        if let encodedDataEmail = data.email.aesEncrypt(key: cryptoKeyString, iv: iv){
            defaults.set(encodedDataEmail, forKey: filename("email"))
        }
        
        if let encodedDataToken = data.token.aesEncrypt(key: cryptoKeyString, iv: iv){
            defaults.set(encodedDataToken, forKey: filename("token"))
        }
        
        if let encodedDataAvatarUrl = data.avatarUrl.absoluteString.aesEncrypt(key: cryptoKeyString, iv: iv){
            defaults.set(encodedDataAvatarUrl, forKey: filename("avatarUrl"))
        }
        
        if let encodedDataExtras = data.extras.aesEncrypt(key: cryptoKeyString, iv: iv){
            defaults.set(encodedDataExtras, forKey: filename("extras"))
        }
        
    }
    
    private func loadUser() -> UserModel? {
        let storage = UserDefaults.standard
        
        if let token = storage.string(forKey: filename("token")) {
            if token.isEmpty { return nil }
            var user = UserModel()
            if let decryptedToken = token.aesDecrypt(key: cryptoKeyString, iv: iv){
                user.token      = decryptedToken
            }
            
            if let decryptedId = storage.string(forKey: filename("id")){
                if let decryptedId = decryptedId.aesDecrypt(key: cryptoKeyString, iv: iv){
                    user.id      = decryptedId
                }else{
                    user.id = ""
                }
            }else{
                user.id = ""
            }
            
            if let decryptedEmail = storage.string(forKey: filename("email")){
                if let decryptedEmail = decryptedEmail.aesDecrypt(key: cryptoKeyString, iv: iv){
                    user.email      = decryptedEmail
                }else{
                    user.email = ""
                }
            }else{
                user.email = ""
            }
            
            if let decryptedUsername = storage.string(forKey: filename("username")){
                if let decryptedUsername = decryptedUsername.aesDecrypt(key: cryptoKeyString, iv: iv){
                    user.username      = decryptedUsername
                }else{
                    user.username = ""
                }
            }else{
                user.username = ""
            }
            
            if let decryptedExtras = storage.string(forKey: filename("extras")){
                if let decryptedExtras = decryptedExtras.aesDecrypt(key: cryptoKeyString, iv: iv){
                    user.extras      = decryptedExtras
                }else{
                    user.extras = ""
                }
            }else{
                user.extras = ""
            }
            
            if let decryptedAvatarUrl = storage.string(forKey: filename("avatarUrl")){
                if let decryptedAvatarUrl = decryptedAvatarUrl.aesDecrypt(key: cryptoKeyString, iv: iv){
                    user.avatarUrl      = URL(string: decryptedAvatarUrl)!
                }else{
                    user.avatarUrl = URL(string: "http://")!
                }
            }else{
                user.avatarUrl = URL(string: "http://")!
            }
            
            return user
            
            
        } else {
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
        return defaults.set(value, forKey: filename("customHeader"))
        
    }
    
    private func getCustomHeader() -> [String:Any]? {
        // save in file
        let defaults = UserDefaults.standard
        if let customHeader = defaults.dictionary(forKey: filename("customHeader")){
            return customHeader
        }else{
            return nil
        }
    }
    
    private func setDeviceToken(_ value: String) {
        // save in file
        let defaults = UserDefaults.standard
        
        if let encodedDeviceToken = value.aesEncrypt(key: cryptoKeyString, iv: iv){
            defaults.set(encodedDeviceToken, forKey: "deviceToken")
        }
    }
    
    private func getDeviceToken() -> String? {
        // save in file
        let defaults = UserDefaults.standard
        
        if let decryptedDeviceToken = defaults.string(forKey: "deviceToken"){
            if let decryptedDeviceToken = decryptedDeviceToken.aesDecrypt(key: cryptoKeyString, iv: iv){
                return decryptedDeviceToken
            }else{
                return nil
            }
        }else{
            return nil
        }
    }
    
    private func setSyncEventId(_ id: String) {
        // save in file
        let defaults = UserDefaults.standard
        if let encodedSyncEventId = id.aesEncrypt(key: cryptoKeyString, iv: iv){
            defaults.set(encodedSyncEventId, forKey: filename("syncEventId"))
        }
    }
    
    private func getSyncEventId() -> String {
        // save in file
        let defaults = UserDefaults.standard
        
        if let decryptedSyncEventId = defaults.string(forKey: filename("syncEventId")){
            if let decryptedSyncEventId = decryptedSyncEventId.aesDecrypt(key: cryptoKeyString, iv: iv){
                return decryptedSyncEventId
            }else{
                return "0"
            }
        }else{
            return "0"
        }
    }
    
    private func setLastCommentId(_ id: String) {
        // save in file
        let defaults = UserDefaults.standard
        if let encodedLastCommentId = id.aesEncrypt(key: cryptoKeyString, iv: iv){
            defaults.set(encodedLastCommentId, forKey: filename("lastCommentId"))
        }
    }
    
    private func getLastCommentId() -> String {
        // save in file
        let defaults = UserDefaults.standard
        if let decryptedLastCommentId = defaults.string(forKey: filename("lastCommentId")){
            if let decryptedLastCommentId = decryptedLastCommentId.aesDecrypt(key: cryptoKeyString, iv: iv){
                return decryptedLastCommentId
            }else{
                return ""
            }
        }else{
            return ""
        }
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
        storage.removeObject(forKey: filename("lastCommentId"))
    }
    
    func clearOldData(){
        let storage = UserDefaults.standard
        storage.removeObject(forKey: filenameOLD("id"))
        storage.removeObject(forKey: filenameOLD("token"))
        storage.removeObject(forKey: filenameOLD("username"))
        storage.removeObject(forKey: filenameOLD("email"))
        storage.removeObject(forKey: filenameOLD("rtKey"))
        storage.removeObject(forKey: filenameOLD("avatarUrl"))
        storage.removeObject(forKey: filenameOLD("syncEventId"))
        storage.removeObject(forKey: filenameOLD("syncId"))
        storage.removeObject(forKey: filenameOLD("isConnectedMQTT"))
        storage.removeObject(forKey: filenameOLD("extras"))
        storage.removeObject(forKey: filenameOLD("customHeader"))
        storage.removeObject(forKey: filenameOLD("lastCommentId"))
    }
}

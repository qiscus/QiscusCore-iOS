//
//  QiscusCore.swift
//  QiscusCore
//
//  Created by Qiscus on 16/07/18.
//  Copyright © 2018 Qiscus. All rights reserved.
//

import Foundation
import QiscusRealtime
import CoreData
import UIKit
public class QiscusCore: NSObject {
    public static let qiscusCoreVersionNumber:String = "3.0.0-beta.17"
    class var bundle:Bundle{
        get{
            let podBundle = Bundle(for: QiscusCore.self)
            if let bundleURL = podBundle.url(forResource: "QiscusCore", withExtension: "bundle") {
                return Bundle(url: bundleURL)!
            }else{
                return podBundle
            }
        }
    }
    
    
    
    public var defaultBrokerUrl : String  = "https://realtime-lb.qiscus.com"
    public var defaultRealtimeURL: String = "realtime-jogja.qiscus.com"
    public var appID : String = ""
    public var enableEventReport : Bool = false
    public var enableRealtime : Bool = true
    
    //MQTT
    var client : QiscusRealtime? = nil
    
    //DB
    @available(iOS 10.0, *)
    lazy var _persistentContainer: NSPersistentContainer? = nil
    
    var _initDB : QiscusDatabase? = nil
    var initDB : QiscusDatabase{
        get{
            if _initDB == nil{
                _initDB = QiscusDatabase.init(qiscusCore: self)
                return _initDB!
            }else{
                return _initDB!
            }
        }
    }
    
    
    var _messagePersistens : Message? = nil
    var messagePersistens : Message{
        get{
            if #available(iOS 10.0, *) {
                if _messagePersistens == nil{
                    let message = Message(context: initDB.persistenStore.context)
                    message.qiscusCore = self
                    _messagePersistens = message
                    return _messagePersistens!
                }else{
                   return _messagePersistens!
                }
            } else {
                // Fallback on earlier versions
                if _messagePersistens == nil{
                    let context =  initDB.persistenStore.context
                    let description = NSEntityDescription.entity(forEntityName: "Message", in: context)
                    let message = Message(entity: description!, insertInto: context)
                    message.qiscusCore = self
                    _messagePersistens = message
                    return _messagePersistens!
                }else{
                    return _messagePersistens!
                }
            }
        }
    }
    
    var _participantPersistens : Participant? = nil
    
    var participantPersistens : Participant{
        get{
            if #available(iOS 10.0, *) {
                if _participantPersistens == nil{
                    let participant = Participant(context: initDB.persistenStore.context)
                    participant.qiscusCore = self
                    _participantPersistens = participant
                    return _participantPersistens!
                }else{
                   return _participantPersistens!
                }
            } else {
                // Fallback on earlier versions
                if _participantPersistens == nil{
                    let context =  initDB.persistenStore.context
                    let description = NSEntityDescription.entity(forEntityName: "Participant", in: context)
                    let participant = Participant(entity: description!, insertInto: context)
                    participant.qiscusCore = self
                    _participantPersistens = participant
                    return _participantPersistens!
                }else{
                    return _participantPersistens!
                }
            }
        }
    }
    
    var _roomPersistens : Room? = nil
    
    var roomPersistens : Room{
        get{
            if #available(iOS 10.0, *) {
                if _roomPersistens == nil{
                    let room = Room(context: initDB.persistenStore.context)
                    room.qiscusCore = self
                    _roomPersistens = room
                    return _roomPersistens!
                }else{
                   return _roomPersistens!
                }
            } else {
                // Fallback on earlier versions
                if _roomPersistens == nil{
                    let context =  initDB.persistenStore.context
                    let description = NSEntityDescription.entity(forEntityName: "Room", in: context)
                    let room = Room(entity: description!, insertInto: context)
                    room.qiscusCore = self
                    _roomPersistens = room
                    return _roomPersistens!
                }else{
                    return _roomPersistens!
                }
            }
        }
    }
    
    var dataDBQParticipant : [QParticipant] = [QParticipant]()
    var dataDBQChatRoom : [QChatRoom] = [QChatRoom]()
    var dataDBQMessage : [QMessage] {
        get {
            return _data
        }
        set {
            _data = newValue
        }
    }
    
    var _data : [QMessage] = [QMessage]()
    
    public var shared : NewQiscusCore{
        get {
            let new = NewQiscusCore()
            new.qiscusCore = self
            return new
        }
    }

    public var network : NetworkManager{
        get {
            let new = NetworkManager()
            new.qiscusCore = self
            return new
        }
    }

    public var config : ConfigManager{
        get {
            let new = ConfigManager()
            new.qiscusCore = self
            return new
        }
    }

    public var realtime : RealtimeManager{
        get {
            let new = RealtimeManager()
            new.qiscusCore = self
            return new
        }
    }

    public var eventManager : QiscusEventManager{
        get {
            let new = QiscusEventManager()
            new.qiscusCore = self
            return new
        }
    }

    public var fileManager : QiscusFileManager{
        get {
            let new = QiscusFileManager()
            new.qiscusCore = self
            return new
        }
    }

    public var database : QiscusDatabaseManager{
        get {
            let new = QiscusDatabaseManager()
            new.qiscusCore = self
            return new
        }
    }

    public var worker : QiscusWorkerManager{
        get {
            let new = QiscusWorkerManager()
            new.qiscusCore = self
            return new
        }
    }

    public var qiscusLogger : QiscusLogger{
        get {
            let new = QiscusLogger()
            new.qiscusCore = self
            return new
        }
    }
    
    var heartBeat        : QiscusHeartBeat?      = nil
    var heartBeatSync    : QiscusSyncEventInterval?      = nil
    public var delegate  : QiscusCoreDelegate? = nil
    public var roomDelegate  : QiscusCoreRoomDelegate? = nil
    public var connectionDelegate : QiscusConnectionDelegate? = nil
    public var activeChatRoom : QChatRoom? = nil
    
    public var reachability:QiscusReachability?
    
    func setupReachability(){
        self.reachability = QiscusReachability()
        
        
        self.reachability?.whenReachable = { reachability in
            DispatchQueue.main.async {
                if reachability.isReachableViaWiFi {
                    self.qiscusLogger.debugPrint("connected via wifi")
                } else {
                    self.qiscusLogger.debugPrint("connected via cellular data")
                }
                
                if let reachable = self.reachability {
                    if reachable.isReachable {
                        
                        DispatchQueue.main.asyncAfter(deadline: .now()+3, execute: {
                            if self.hasSetupUser() && self.config.isConnectedMqtt == false {
                               //connection internet = true
                                if let user = self.getProfile() {
                                   // connect qiscus realtime server
                                   self.retryConnect { (success) in
                                       if success == true{
                                        if let user = self.getProfile() {
                                               // connect qiscus realtime server
                                               self.realtime.connect(username: user.id, password: user.token)
                                            self.qiscusLogger.debugPrint("try reconnect Qiscus realtime")
                                           }
                                       }
                                   }
                               }
                           }
                        })
                    }
                }
               
            }
            
        }
        self.reachability?.whenUnreachable = { reachability in
            self.qiscusLogger.debugPrint("no internet connection")
        }
        do {
            try  self.reachability?.startNotifier()
        } catch {
            qiscusLogger.debugPrint("Unable to start network notifier")
        }
    }

    
    
    @available(*, deprecated, message: "will soon become unavailable.")
    public var enableDebugPrint: Bool = false
    public func enableDebugMode(value : Bool = false){
        self.enableDebugPrint = value
    }
    
    public var enableSync : Bool = true
    public var enableSyncEvent : Bool = false
    
    var AUTHTOKEN : String {
        get {
            if let user = self.config.user {
                return user.token
            }else {
                return ""
            }
            
        }
    }

    var BASEURL : URL {
        get {
            if let server = self.config.server {
                return server.url
            }else {
                return URL.init(string: "https://api3.qiscus.com/api/v2/mobile")!
            }
        }
    }

    var HEADERS : [String: String] {
        get {
            var headers = [
                "QISCUS-SDK-PLATFORM": "iOS",
                "QISCUS-SDK-DEVICE-BRAND": "Apple",
                "QISCUS-SDK-VERSION": QiscusCore.qiscusCoreVersionNumber,
                "QISCUS-SDK-DEVICE-MODEL" : UIDevice.modelName,
                "QISCUS-SDK-DEVICE-OS-VERSION" : UIDevice.current.systemVersion
                ]
            if let appID = self.config.appID {
                headers["QISCUS-SDK-APP-ID"] = appID
            }
            
            if let user = self.config.user {
                if let appid = self.config.appID {
                    headers["QISCUS-SDK-APP-ID"] = appid
                }
                if !user.token.isEmpty {
                    headers["QISCUS-SDK-TOKEN"] = user.token
                }
                if !user.id.isEmpty {
                    headers["QISCUS-SDK-USER-ID"] = user.id
                }
            }
            
            if let customHeader = self.config.customHeader {
                headers.merge(customHeader as! [String : String]){(_, new) in new}
            }
            
            return headers
        }
    }

    
    private func heartBeatForSync(timeInterval : Double = 30){
        self.heartBeatSync = QiscusSyncEventInterval.init(timeInterval: timeInterval)
        self.heartBeatSync?.eventHandler = {
            self.worker.resumeSyncEvent()
        }
        self.heartBeatSync?.resume()
    }
    
    private func getBrokerLBUrl(onSuccess: @escaping (String) -> Void, onError:  @escaping (QError) -> Void){
        if let brokerLBUrl = config.server?.brokerLBUrl{
            if brokerLBUrl.isEmpty{
                onError(QError(message: "brokerLBUrl is empty"))
            }else{
                network.getBrokerLBUrl(url: (config.server?.brokerLBUrl)!, onSuccess: { (brokerlLb) in
                    onSuccess(brokerlLb)
                }) { (error) in
                    onError(error)
                }
            }
        }else{
            onError(QError(message: "brokerLBUrl is nil"))
        }
    }
    
    //getAppConfig
    private func getAppConfig(){
        network.getAppConfig(onSuccess: { (appConfig) in
            self.enableEventReport = appConfig.enableEventReport
            self.enableRealtime = appConfig.enableRealtime
            self.enableSync = appConfig.enableSync
            self.enableSyncEvent = appConfig.enableSyncEvent

            
            
            //check old and new appServer
            if let oldConfig = self.config.server {
                var newBaseUrl : URL = oldConfig.url //default using old baseUrl
                var newBrokerLBURL : String? = oldConfig.brokerLBUrl  //default using old brokerLBURL
                var newBrokerURL : String? = oldConfig.realtimeURL  //default using old brokerLBURL
                
                
                //check for baseUrl
                if appConfig.baseURL != ""{
                    if oldConfig.url.absoluteString.range(of: appConfig.baseURL) == nil {
                        //using new baseUrl
                        if let url = URL(string: appConfig.baseURL) {
                            newBaseUrl = url
                        }
                    }
                }
                
                //check for LBURL
                if appConfig.brokerLBURL != "" {
                    if let brokerLB = oldConfig.brokerLBUrl{
                        if brokerLB.range(of: appConfig.brokerLBURL) == nil {
                            //using new brokerLBURL
                            newBrokerLBURL = appConfig.brokerLBURL
                        }
                    }
                }
                
                //check for brokerURL
                if appConfig.brokerURL != "" {
                    if let brokerURL = oldConfig.realtimeURL{
                        if brokerURL.range(of: appConfig.brokerURL) == nil {
                            //using new realtimeURL or brokerURL
                            newBrokerURL = appConfig.brokerURL
                        }
                    }
                }
                
                
                self.config.server = QiscusServer(url: newBaseUrl, realtimeURL: newBrokerURL, realtimePort: 1885, brokerLBUrl: newBrokerLBURL)
                
                if appConfig.enableRealtime == true {
                    if let appID = self.config.appID {
                        self.realtime.setup(appName: appID)
                    }
                }
            }
           
            // Background sync when realtime off
            self.config.syncInterval = (appConfig.syncInterval / 1000)
            self.heartBeat = QiscusHeartBeat.init(timeInterval: self.config.syncInterval)
            self.heartBeat?.eventHandler = {
                self.qiscusLogger.debugPrint("Bip")
                self.worker.resume()
            }
            self.heartBeat?.resume()
            
            self.heartBeatForSync(timeInterval: (appConfig.syncOnConnect / 1000))
            
            self.setupReachability()
            
        }) { (error) in
            if let appID = self.config.appID {
                self.realtime.setup(appName: appID)
            }
            
            self.config.syncInterval = 5
            // Background sync when realtime off
            self.heartBeat = QiscusHeartBeat.init(timeInterval: self.config.syncInterval)
            self.heartBeat?.eventHandler = {
                self.qiscusLogger.debugPrint("Bip")
                self.worker.resume()
            }
            self.heartBeat?.resume()
            
            self.heartBeatForSync()
            
            self.setupReachability()
        }
    }
    
    /// set your app Qiscus APP ID, always set app ID everytime your app lounch. \nAfter login successculy, no need to setup again
    ///
    /// - Parameter WithAppID: Qiscus SDK App ID
    @available(*, deprecated, message: "will soon become unavailable.")
    public func setup(WithAppID id: String, server: QiscusServer? = nil) {
        self.appID = id
        config.appID    = id
        
        if let _server = server {
            config.server = _server
        }else {
            config.server   = QiscusServer(url: URL.init(string: "https://api.qiscus.com")!, realtimeURL: self.defaultRealtimeURL, realtimePort: 1885, brokerLBUrl: self.defaultBrokerUrl)
        }
        
        if self.isLogined{
            // Populate data from db
           self.database.loadData()
        }
        
       getAppConfig()
    }
    
    /// set your app Qiscus APP ID, always set app ID everytime your app lounch. \nAfter login successculy, no need to setup again
    ///
    /// - Parameter WithAppID: Qiscus SDK App ID
    public func setup(AppID: String) {
        self.appID = AppID
        config.appID    = AppID
        config.server   = QiscusServer(url: URL.init(string: "https://api.qiscus.com")!, realtimeURL: self.defaultRealtimeURL, realtimePort: 1885, brokerLBUrl: self.defaultBrokerUrl)
        
        if self.isLogined{
            // Populate data from db
            self.database.loadData()
        }
        
        getAppConfig()
    }
    
    /// set your app Qiscus APP ID, always set app ID everytime your app lounch. \nAfter login successculy, no need to setup again
    ///
    /// - Parameter
    /// AppID: Qiscus SDK App ID
    /// baseUrl: baseUrl
    /// brokerUrl: brokerUrl for example realtime-jogja.qiscus.com
    /// brokerLBUrl: brokerLBUrl is optional, default using urlLB from qiscus
    
    public func setupWithCustomServer(AppID: String, baseUrl: URL, brokerUrl: String, brokerLBUrl: String?) {
        self.appID = AppID
        config.appID    = AppID
        
        if brokerLBUrl != nil{
            config.server   = QiscusServer(url: baseUrl, realtimeURL: brokerUrl, realtimePort: 1885, brokerLBUrl: brokerLBUrl)
        }else{
            self.config.server   = QiscusServer(url: baseUrl, realtimeURL: brokerUrl, realtimePort: 1885, brokerLBUrl: nil)
        }
        
        if self.isLogined{
            // Populate data from db
            self.database.loadData()
        }
        
        getAppConfig()
    }

    public func setCustomHeader(values : [String: Any]){
        self.config.customHeader = values
    }
    
    /// Connect to qiscus server
    ///
    /// - Parameter delegate: qiscuscore delegate to listen the event
    /// - Returns: true if success connect, please make sure you already login before connect.
    public func connect(delegate: QiscusConnectionDelegate? = nil) -> Bool {
        // check user login
        if let user = self.getProfile() {
            // setup configuration
//            if let appid = ConfigManager.shared.appID {
//                QiscusCore.setup(WithAppID: appid)
//            }
            // set delegate
            self.connectionDelegate = delegate
            // connect qiscus realtime server
            self.realtime.connect(username: user.id, password: user.token)
            return true
        }else {
            return false
        }
    }
    
    public func retryConnect(_ onSuccess: @escaping (Bool) -> Void){
        if let appID = config.appID{
            guard let checkConfig = config.server else {
                onSuccess(false)
                return
            }
            if checkConfig.brokerLBUrl != nil{
                getBrokerLBUrl(onSuccess: { (url) in
                    self.config.server   = QiscusServer(url: checkConfig.url, realtimeURL: url, realtimePort: 1885, brokerLBUrl: checkConfig.brokerLBUrl)
                    self.realtime.setup(appName: appID)
                    onSuccess(true)
                }) { (error) in
                    onSuccess(true)
                    self.realtime.setup(appName: appID)
                }
            }else{
                self.realtime.setup(appName: appID)
                onSuccess(true)
            }
            
        }else{
            onSuccess(false)
            qiscusLogger.errorPrint("please setup APPID first")
        }
        
    }
    
    /// Sync Time interval, by default is 5s. every 5 sec will be sync when realtime server is disconnect
    ///
    /// - Parameter interval: time interval, by default is 30s
    @available(*, deprecated, message: "will soon become unavailable.")
    public func setSync(interval: TimeInterval) {
        self.config.syncInterval = interval
    }
    
    /// Sync Time interval, by default is 30s. every 30 sec will be sync when realtime server is disconnect
    ///
    /// - Parameter interval: time interval, by default is 30s
    public func setSyncInterval(interval: TimeInterval) {
        self.config.syncInterval = interval
    }
    
    // MARK: Auth

    /// Get Nonce from SDK server. use when login with JWT
    ///
    /// - Parameter completion: @escaping with Optional(QNonce) and String Optional(error)
    @available(*, deprecated, message: "will soon become unavailable.")
    public func getNonce(onSuccess: @escaping (QNonce) -> Void, onError: @escaping (QError) -> Void) {
        if config.appID == nil {
            fatalError("You need to set App ID")
        }
        self.network.getNonce(onSuccess: onSuccess, onError: onError)
    }
    
    // MARK: Auth
    
    /// Get JWTNonce from SDK server. use when login with JWT
    ///
    /// - Parameter completion: @escaping with Optional(QNonce) and String Optional(error)
    public func getJWTNonce(onSuccess: @escaping (QNonce) -> Void, onError: @escaping (QError) -> Void) {
        if self.config.appID == nil {
            fatalError("You need to set App ID")
        }
        self.network.getNonce(onSuccess: onSuccess, onError: onError)
    }
    
    /// SDK Login or Register with userId and passkey, if new user register you can set username and avatar The handler to be called once the request has finished.
    /// - parameter userID              : must be unique per appid, exm: email, phonenumber, udid.
    /// - userKey                       : user password
    /// - parameter completion          : The code to be executed once the request has finished, also give a user object and error.
    ///
    @available(*, deprecated, message: "will soon become unavailable.")
    public func loginOrRegister(userID: String, userKey: String, username: String? = nil, avatarURL: URL? = nil, extras: [String:Any]? = nil, onSuccess: @escaping (QAccount) -> Void, onError: @escaping (QError) -> Void) {
        if config.appID == nil {
            fatalError("You need to set App ID")
        }
        self.network.login(email: userID, password: userKey, username: username, avatarUrl: avatarURL?.absoluteString, extras: extras, onSuccess: { (user) in
            // save user in local
            self.config.user = user
            self.realtime.connect(username: user.id, password: user.token)
            onSuccess(user)
        }) { (error) in
            onError(error)
        }
    }
    
    /// SDK Login or Register with userId and passkey, if new user register you can set username and avatar The handler to be called once the request has finished.
    /// - parameter userID              : must be unique per appid, exm: email, phonenumber, udid.
    /// - userKey                       : user password
    /// - parameter completion          : The code to be executed once the request has finished, also give a user object and error.
    ///
    public func setUser(userId: String, userKey: String, username: String? = nil, avatarURL: URL? = nil, extras: [String:Any]? = nil, onSuccess: @escaping (QAccount) -> Void, onError: @escaping (QError) -> Void) {
        if config.appID == nil {
            fatalError("You need to set App ID")
        }
        network.login(email: userId, password: userKey, username: username, avatarUrl: avatarURL?.absoluteString, extras: extras, onSuccess: { (user) in
            // save user in local
            self.config.user = user
            self.realtime.connect(username: user.id, password: user.token)
            onSuccess(user)
        }) { (error) in
            onError(error)
        }
    }
    
    
    /// connect with identityToken, after use nonce and JWT
    ///
    /// - Parameters:
    ///   - token: identity token from your server, when you implement Nonce or JWT
    ///   - completion: The code to be executed once the request has finished, also give a user object and error.
    @available(*, deprecated, message: "will soon become unavailable.")
    public func login(withIdentityToken token: String, onSuccess: @escaping (QAccount) -> Void, onError: @escaping (QError) -> Void) {
        if config.appID == nil {
            fatalError("You need to set App ID")
        }
        network.login(identityToken: token, onSuccess: { (user) in
            // save user in local
            self.config.user = user
            onSuccess(user)
        }) { (error) in
            onError(error)
        }
    }
    
    /// connect with identityToken, after use nonce and JWT
    ///
    /// - Parameters:
    ///   - token: identity token from your server, when you implement Nonce or JWT
    ///   - completion: The code to be executed once the request has finished, also give a user object and error.
    public func setUserWithIdentityToken(token: String, onSuccess: @escaping (QAccount) -> Void, onError: @escaping (QError) -> Void) {
        if config.appID == nil {
            fatalError("You need to set App ID")
        }
        network.login(identityToken: token, onSuccess: { (user) in
            // save user in local
            self.config.user = user
            onSuccess(user)
        }) { (error) in
            onError(error)
        }
    }
    
    /// Disconnect or logout
    ///
    /// - Parameter completionHandler: The code to be executed once the request has finished, also give a user object and error.
    @available(*, deprecated, message: "will soon become unavailable.")
    public func logout(completion: @escaping (QError?) -> Void) {
        self.flowLogOut()
        completion(nil)
    }
    
    /// Disconnect or logout
    ///
    /// - Parameter completionHandler: The code to be executed once the request has finished, also give a user object and error.
    public func clearUser(completion: @escaping (QError?) -> Void) {
        self.flowLogOut()
        completion(nil)
    }
    
    private func flowLogOut(){
        let clientRouter    = Router<APIClient>()
        let roomRouter      = Router<APIRoom>()
        let commentRouter   = Router<APIComment>()
        let userRouter      = Router<APIUser>()
        
        clientRouter.cancel()
        roomRouter.cancel()
        commentRouter.cancel()
        userRouter.cancel()
        
        self.shared.publishOnlinePresence(isOnline: false)
        
        // clear room and comment
        self.database.clear()
        // clear config
        self.config.clearConfig()
        // realtime disconnect
        self.realtime.disconnect()
    }
    
    /// check already logined
    ///
    /// - Returns: return true if already login
    @available(*, deprecated, message: "will soon become unavailable.")
    public var isLogined : Bool {
        get {
            if let user = self.getProfile(){
                if !user.token.isEmpty{
                     return true
                }else{
                    return false
                }
            }else{
                return false
            }
        }
    }
    
    /// check already logined
    ///
    /// - Returns: return true if already login
    public func hasSetupUser() -> Bool{
        if let user = self.getProfile(){
            if !user.token.isEmpty{
                return true
            }else{
                return false
            }
        }else{
            return false
        }
    }
    
   
    
    // MARK: User Profile
    /// get qiscus user from local storage
    ///
    /// - Returns: return nil when client not logined, and return object user when already logined
    @available(*, deprecated, message: "will soon become unavailable.")
    public func getProfile() -> QAccount? {
        return self.config.user
    }
    
    // MARK: User Profile
    
    /// get qiscus user from local storage
    ///
    /// - Returns: return nil when client not logined, and return object user when already logined
    public func getUserData() -> QAccount? {
        return self.config.user
    }
    
    /// Sync comment
    ///
    /// - Parameters:
    ///   - lastCommentReceivedId: last comment id, to get id you can call QiscusCore.dataStore.getComments().
    ///   - order: "asc" or "desc" only, lowercase. If other than that, it will assumed to "desc"
    ///   - limit: limit number of comment by default 20
    ///   - completion: return object array of comment and return error if exist
    @available(*, deprecated, message: "will soon become unavailable.")
    public func sync(lastCommentReceivedId id: String = "", onSuccess: @escaping ([QMessage]) -> Void, onError: @escaping (QError) -> Void) {
        if id.isEmpty {
            // get last comment id
            if let comment = self.dataDBQMessage.last {
                self.network.sync(lastCommentReceivedId: comment.id) { (comments, error) in
                    if let message = error {
                        onError(QError(message: message))
                    }else {
                        if let results = comments {
                            // Save comment in local
                            if results.count != 0 {
                                let reversedComments : [QMessage] = Array(results.reversed())
                                self.database.message.save(reversedComments)
                            }
                            onSuccess(results)
                        }
                    }
                }
            }else {
                onError(QError(message: "call sync without parameter is not work, please try to set last comment id. Maybe comment in DB is empty"))
            }
        }else {
            self.network.sync(lastCommentReceivedId: id) { (comments, error) in
                if let message = error {
                    onError(QError(message: message))
                }else {
                    if let results = comments {
                        // Save comment in local
                        if results.count != 0 {
                            let reversedComments : [QMessage] = Array(results.reversed())
                            self.database.message.save(reversedComments)
                        }
                        onSuccess(results)
                    }
                }
            }
        }
    }
    
    /// synchronize comment
    ///
    /// - Parameters:
    ///   - lastMessageId: last comment id, to get id you can call QiscusCore.dataStore.getComments().
    ///   - limit: limit number of comment by default 20
    ///   - completion: return object array of comment and return error if exist
    public func synchronize(lastMessageId id: String = "", onSuccess: @escaping ([QMessage]) -> Void, onError: @escaping (QError) -> Void) {
        if id.isEmpty {
            // get last comment id
            if let comment = self.dataDBQMessage.last {
                self.network.sync(lastCommentReceivedId: comment.id) { (comments, error) in
                    if let message = error {
                        onError(QError(message: message))
                    }else {
                        DispatchQueue.global(qos: .background).sync {
                            if let results = comments {
                                // Save comment in local
                                if results.count != 0 {
                                    let reversedComments : [QMessage] = Array(results.reversed())
                                    self.database.message.save(reversedComments)
                                }
                                onSuccess(results)
                            }
                        }
                    }
                }
            }else {
                self.network.sync(lastCommentReceivedId: id) { (comments, error) in
                    if let message = error {
                        onError(QError(message: message))
                    }else {
                        DispatchQueue.global(qos: .background).sync {
                            if let results = comments {
                                // Save comment in local
                                if results.count != 0 {
                                    let reversedComments : [QMessage] = Array(results.reversed())
                                    self.database.message.save(reversedComments)
                                }
                                onSuccess(results)
                            }
                        }
                    }
                }
            }
        }else {
            self.network.sync(lastCommentReceivedId: id) { (comments, error) in
                if let message = error {
                    onError(QError(message: message))
                }else {
                    DispatchQueue.global(qos: .background).sync {
                        if let results = comments {
                            // Save comment in local
                            if results.count != 0 {
                                let reversedComments : [QMessage] = Array(results.reversed())
                                self.database.message.save(reversedComments)
                            }
                            onSuccess(results)
                        }
                    }
                }
            }
        }
    }
    
    public func openRealtimeConnection() -> Bool{
        if let user = self.getProfile() {
            self.config.isEnableDisableRealtimeManually = true
            if self.config.isConnectedMqtt == false {
                realtime.connect(username: user.id, password: user.token)
            }
            return true
        }else {
            return false
        }
    }
    
    public func closeRealtimeConnection() -> Bool{
        if hasSetupUser(){
            if self.config.isConnectedMqtt == true{
                self.realtime.disconnect()
                self.config.isEnableDisableRealtimeManually = false
                return true
            }else{
                //already disconnect
                return true
            }
        }else{
            return false
        }
    }

    
}

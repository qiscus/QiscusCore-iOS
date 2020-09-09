//
//  QiscusCore.swift
//  QiscusCore
//
//  Created by Qiscus on 16/07/18.
//  Copyright © 2018 Qiscus. All rights reserved.
//

import Foundation

public class QiscusCore: NSObject {
    public static let qiscusCoreVersionNumber:String = "1.5.5"
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
    
    public static var defaultBrokerUrl : String  = "https://realtime-lb.qiscus.com"
    public static var defaultRealtimeURL: String = "realtime-jogja.qiscus.com"
    
    public static let shared    : QiscusCore            = QiscusCore()
    private static var config   : ConfigManager         = ConfigManager.shared
    static var realtime         : RealtimeManager       = RealtimeManager.shared
    static var eventManager     : QiscusEventManager    = QiscusEventManager.shared
    static let fileManager      : QiscusFileManager     = QiscusFileManager.shared
    public static var database  : QiscusDatabaseManager = QiscusDatabaseManager.shared
    static var network          : NetworkManager        = NetworkManager()
    static var worker           : QiscusWorkerManager   = QiscusWorkerManager()
    static var heartBeat        : QiscusHeartBeat?      = nil
    static var heartBeatSync    : QiscusSyncEventInterval?      = nil
    public static var delegate  : QiscusCoreDelegate? {
        get {
            return eventManager.delegate
        }
        set {
            eventManager.delegate = newValue
        }
    }
    
    var reachability:QiscusReachability?
    
    class func setupReachability(){
        QiscusCore.shared.reachability = QiscusReachability()
        
        
        QiscusCore.shared.reachability?.whenReachable = { reachability in
            DispatchQueue.main.async {
                if reachability.isReachableViaWiFi {
                    QiscusLogger.debugPrint("connected via wifi")
                } else {
                    QiscusLogger.debugPrint("connected via cellular data")
                }
                
                if let reachable = QiscusCore.shared.reachability {
                    if reachable.isReachable {
                        
                        DispatchQueue.main.asyncAfter(deadline: .now()+3, execute: {
                            if QiscusCore.hasSetupUser() && ConfigManager.shared.isConnectedMqtt == false && QiscusCore.enableRealtime == true {
                               //connection internet = true
                               if let user = QiscusCore.getProfile() {
                                   // connect qiscus realtime server
                                   QiscusCore.retryConnect { (success) in
                                       if success == true{
                                           if let user = QiscusCore.getProfile() {
                                               // connect qiscus realtime server
                                               QiscusCore.realtime.connect(username: user.email, password: user.token)
                                               QiscusLogger.debugPrint("try reconnect Qiscus realtime")
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
        QiscusCore.shared.reachability?.whenUnreachable = { reachability in
            QiscusLogger.debugPrint("no internet connection")
        }
        do {
            try  QiscusCore.shared.reachability?.startNotifier()
        } catch {
            QiscusLogger.debugPrint("Unable to start network notifier")
        }
    }

    public static var enableEventReport : Bool = false
    public static var enableRealtime : Bool = true
    
    @available(*, deprecated, message: "will soon become unavailable.")
    public static var enableDebugPrint: Bool = false
    public class func enableDebugMode(value : Bool = false){
        QiscusCore.enableDebugPrint = value
    }
    
    private func heartBeatForSync(timeInterval : Double = 30){
        QiscusCore.heartBeatSync = QiscusSyncEventInterval.init(timeInterval: timeInterval)
        QiscusCore.heartBeatSync?.eventHandler = {
            QiscusCore.worker.resumeSyncEvent()
        }
        QiscusCore.heartBeatSync?.resume()
    }
    
    private class func getBrokerLBUrl(onSuccess: @escaping (String) -> Void, onError:  @escaping (QError) -> Void){

        network.getBrokerLBUrl(url: (config.server?.brokerLBUrl)!, onSuccess: { (brokerlLb) in
            onSuccess(brokerlLb)
        }) { (error) in
            onError(error)
        }
    }
    
    /// set your app Qiscus APP ID, always set app ID everytime your app lounch. \nAfter login successculy, no need to setup again
    ///
    /// - Parameter WithAppID: Qiscus SDK App ID
    @available(*, deprecated, message: "will soon become unavailable.")
    public class func setup(WithAppID id: String, server: QiscusServer? = nil) {
        config.appID    = id
        if let _server = server {
            config.server = _server
        }else {
            config.server   = QiscusServer(url: URL.init(string: "https://api.qiscus.com")!, realtimeURL: self.defaultRealtimeURL, realtimePort: 1885, brokerLBUrl: self.defaultBrokerUrl)
        }
        
        if config.server?.brokerLBUrl != nil {
            getBrokerLBUrl(onSuccess: { (realtimeUrl) in
                if server != nil{
                    config.server   = QiscusServer(url: config.server!.url, realtimeURL: realtimeUrl, realtimePort: 1885, brokerLBUrl: config.server!.brokerLBUrl)
                }else{
                    config.server   = QiscusServer(url: config.server!.url, realtimeURL: realtimeUrl, realtimePort: 1885, brokerLBUrl: config.server!.brokerLBUrl)
                }
               
                realtime.setup(appName: id)
            }) { (error) in
                realtime.setup(appName: id)
            }
        }else{
            realtime.setup(appName: id)
        }
        
        if QiscusCore.isLogined{
            // Populate data from db
            QiscusCore.database.loadData()
        }
        
       getAppConfig()
    }
    
    /// set your app Qiscus APP ID, always set app ID everytime your app lounch. \nAfter login successculy, no need to setup again
    ///
    /// - Parameter WithAppID: Qiscus SDK App ID
    public class func setup(AppID: String) {
        config.appID    = AppID
        
        config.server   = QiscusServer(url: URL.init(string: "https://api.qiscus.com")!, realtimeURL: self.defaultRealtimeURL, realtimePort: 1885, brokerLBUrl: self.defaultBrokerUrl)
        
        getBrokerLBUrl(onSuccess: { (realtimeUrl) in
             config.server   = QiscusServer(url: config.server!.url, realtimeURL: realtimeUrl, realtimePort: 1885, brokerLBUrl: config.server!.brokerLBUrl)
             realtime.setup(appName: AppID)
        }) { (error) in
            config.server   = QiscusServer(url: config.server!.url, realtimeURL: config.server!.realtimeURL, realtimePort: 1885, brokerLBUrl: config.server!.brokerLBUrl)
            realtime.setup(appName: AppID)
        }
        
        if QiscusCore.isLogined{
            // Populate data from db
            QiscusCore.database.loadData()
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
    
    public class func setupWithCustomServer(AppID: String, baseUrl: URL, brokerUrl: String, brokerLBUrl: String?) {
        config.appID    = AppID
        
        if brokerLBUrl != nil{
            config.server   = QiscusServer(url: baseUrl, realtimeURL: brokerUrl, realtimePort: 1885, brokerLBUrl: brokerLBUrl)
            
            getBrokerLBUrl(onSuccess: { (url) in
                config.server   = QiscusServer(url: baseUrl, realtimeURL: url, realtimePort: 1885, brokerLBUrl: brokerLBUrl)
                realtime.setup(appName: AppID)
            }) { (error) in
                realtime.setup(appName: AppID)
            }
            
        }else{
            config.server   = QiscusServer(url: baseUrl, realtimeURL: brokerUrl, realtimePort: 1885, brokerLBUrl: nil)
            realtime.setup(appName: AppID)
        }
        
        if QiscusCore.isLogined{
            // Populate data from db
            QiscusCore.database.loadData()
        }
        
        getAppConfig()
    }
    
    private class func getAppConfig(){
        network.getAppConfig(onSuccess: { (appConfig) in
            QiscusCore.enableEventReport = appConfig.enableEventReport
            QiscusCore.enableRealtime = appConfig.enableRealtime
            
            //check old and new appServer
            if let oldConfig = config.server {
                var newBaseUrl : URL = oldConfig.url //default using old baseUrl
                var newBrokerLBURL : String? = oldConfig.brokerLBUrl  //default using old brokerLBURL
                var newBrokerURL : String? = oldConfig.realtimeURL  //default using old brokerLBURL
                var restartRealtime : Bool = false
                
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
                            restartRealtime = true
                        }
                    }
                }
                
                config.server = QiscusServer(url: newBaseUrl, realtimeURL: newBrokerURL, realtimePort: 1885, brokerLBUrl: newBrokerLBURL)
                
                if restartRealtime == true && appConfig.enableRealtime == true {
                    if let appID = config.appID {
                        ConfigManager.shared.isConnectedMqtt = false
                        realtime.disconnect()
                        realtime.setup(appName: appID)
                        restartRealtime = false
                    }
                } else if (appConfig.enableRealtime == false) {
                    restartRealtime = false
                    realtime.disconnect()
                    ConfigManager.shared.isConnectedMqtt = false
                }
            }
           
            // Background sync when realtime off
            self.config.syncInterval = (appConfig.syncInterval / 1000)
            QiscusCore.heartBeat = QiscusHeartBeat.init(timeInterval: config.syncInterval)
            QiscusCore.heartBeat?.eventHandler = {
                QiscusLogger.debugPrint("Bip")
                QiscusCore.worker.resume()
            }
            QiscusCore.heartBeat?.resume()
            
            QiscusCore.shared.heartBeatForSync(timeInterval: (appConfig.syncOnConnect / 1000))
            
            QiscusCore.setupReachability()
            
        }) { (error) in
            // Background sync when realtime off
            QiscusCore.heartBeat = QiscusHeartBeat.init(timeInterval: config.syncInterval)
            QiscusCore.heartBeat?.eventHandler = {
                QiscusLogger.debugPrint("Bip")
                QiscusCore.worker.resume()
            }
            QiscusCore.heartBeat?.resume()
            
            QiscusCore.shared.heartBeatForSync()
            
            QiscusCore.setupReachability()
        }
    }

    public class func setCustomHeader(values : [String: Any]){
        config.customHeader = values
    }
    
    /// Connect to qiscus server
    ///
    /// - Parameter delegate: qiscuscore delegate to listen the event
    /// - Returns: true if success connect, please make sure you already login before connect.
    public class func connect(delegate: QiscusConnectionDelegate? = nil) -> Bool {
        // check user login
        if let user = getProfile() {
            // setup configuration
//            if let appid = ConfigManager.shared.appID {
//                QiscusCore.setup(WithAppID: appid)
//            }
            // set delegate
            eventManager.connectionDelegate = delegate
            // connect qiscus realtime server
            realtime.connect(username: user.email, password: user.token)
            return true
        }else {
            return false
        }
    }
    
    public class func retryConnect(_ onSuccess: @escaping (Bool) -> Void){
        if let appID = config.appID{
            guard let checkConfig = config.server else {
                onSuccess(false)
                return
            }
            if checkConfig.brokerLBUrl != nil{
                getBrokerLBUrl(onSuccess: { (url) in
                    config.server   = QiscusServer(url: checkConfig.url, realtimeURL: url, realtimePort: 1885, brokerLBUrl: checkConfig.brokerLBUrl)
                    realtime.setup(appName: appID)
                    onSuccess(true)
                }) { (error) in
                    onSuccess(true)
                    realtime.setup(appName: appID)
                }
            }else{
                realtime.setup(appName: appID)
                onSuccess(true)
            }
            
        }else{
            onSuccess(false)
            QiscusLogger.errorPrint("please setup APPID first")
        }
        
    }
    
    /// Sync Time interval, by default is 5s. every 5 sec will be sync when realtime server is disconnect
    ///
    /// - Parameter interval: time interval, by default is 30s
    @available(*, deprecated, message: "will soon become unavailable.")
    public class func setSync(interval: TimeInterval) {
        config.syncInterval = interval
    }
    
    /// Sync Time interval, by default is 30s. every 30 sec will be sync when realtime server is disconnect
    ///
    /// - Parameter interval: time interval, by default is 30s
    public class func setSyncInterval(interval: TimeInterval) {
        config.syncInterval = interval
    }
    
    // MARK: Auth

    /// Get Nonce from SDK server. use when login with JWT
    ///
    /// - Parameter completion: @escaping with Optional(QNonce) and String Optional(error)
    @available(*, deprecated, message: "will soon become unavailable.")
    public class func getNonce(onSuccess: @escaping (QNonce) -> Void, onError: @escaping (QError) -> Void) {
        if config.appID == nil {
            fatalError("You need to set App ID")
        }
        network.getNonce(onSuccess: onSuccess, onError: onError)
    }
    
    // MARK: Auth
    
    /// Get JWTNonce from SDK server. use when login with JWT
    ///
    /// - Parameter completion: @escaping with Optional(QNonce) and String Optional(error)
    public class func getJWTNonce(onSuccess: @escaping (QNonce) -> Void, onError: @escaping (QError) -> Void) {
        if config.appID == nil {
            fatalError("You need to set App ID")
        }
        network.getNonce(onSuccess: onSuccess, onError: onError)
    }
    
    /// SDK Login or Register with userId and passkey, if new user register you can set username and avatar The handler to be called once the request has finished.
    /// - parameter userID              : must be unique per appid, exm: email, phonenumber, udid.
    /// - userKey                       : user password
    /// - parameter completion          : The code to be executed once the request has finished, also give a user object and error.
    ///
    @available(*, deprecated, message: "will soon become unavailable.")
    public class func loginOrRegister(userID: String, userKey: String, username: String? = nil, avatarURL: URL? = nil, extras: [String:Any]? = nil, onSuccess: @escaping (UserModel) -> Void, onError: @escaping (QError) -> Void) {
        if config.appID == nil {
            fatalError("You need to set App ID")
        }
        network.login(email: userID, password: userKey, username: username, avatarUrl: avatarURL?.absoluteString, extras: extras, onSuccess: { (user) in
            // save user in local
            ConfigManager.shared.user = user
            realtime.connect(username: user.email, password: user.token)
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
    public class func setUser(userId: String, userKey: String, username: String? = nil, avatarURL: URL? = nil, extras: [String:Any]? = nil, onSuccess: @escaping (UserModel) -> Void, onError: @escaping (QError) -> Void) {
        if config.appID == nil {
            fatalError("You need to set App ID")
        }
        network.login(email: userId, password: userKey, username: username, avatarUrl: avatarURL?.absoluteString, extras: extras, onSuccess: { (user) in
            // save user in local
            ConfigManager.shared.user = user
            realtime.connect(username: user.email, password: user.token)
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
    public class func login(withIdentityToken token: String, onSuccess: @escaping (UserModel) -> Void, onError: @escaping (QError) -> Void) {
        if config.appID == nil {
            fatalError("You need to set App ID")
        }
        network.login(identityToken: token, onSuccess: { (user) in
            // save user in local
            ConfigManager.shared.user = user
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
    public class func setUserWithIdentityToken(token: String, onSuccess: @escaping (UserModel) -> Void, onError: @escaping (QError) -> Void) {
        if config.appID == nil {
            fatalError("You need to set App ID")
        }
        network.login(identityToken: token, onSuccess: { (user) in
            // save user in local
            ConfigManager.shared.user = user
            onSuccess(user)
        }) { (error) in
            onError(error)
        }
    }
    
    /// Disconnect or logout
    ///
    /// - Parameter completionHandler: The code to be executed once the request has finished, also give a user object and error.
    @available(*, deprecated, message: "will soon become unavailable.")
    public static func logout(completion: @escaping (QError?) -> Void) {
        QiscusCore.shared.flowLogOut()
        completion(nil)
    }
    
    /// Disconnect or logout
    ///
    /// - Parameter completionHandler: The code to be executed once the request has finished, also give a user object and error.
    public static func clearUser(completion: @escaping (QError?) -> Void) {
        QiscusCore.shared.flowLogOut()
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
        
        QiscusCore.shared.publishOnlinePresence(isOnline: false)
        
        // clear room and comment
        QiscusCore.database.clear()
        // clear config
        ConfigManager.shared.clearConfig()
        // realtime disconnect
        QiscusCore.realtime.disconnect()
    }
    
    /// check already logined
    ///
    /// - Returns: return true if already login
    @available(*, deprecated, message: "will soon become unavailable.")
    public static var isLogined : Bool {
        get {
            if let user = getProfile(){
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
    public class func hasSetupUser() -> Bool{
        if let user = QiscusCore.getProfile(){
            if !user.token.isEmpty{
                return true
            }else{
                return false
            }
        }else{
            return false
        }
    }
    
    /// Register device token Apns or Pushkit
    ///
    /// - Parameters:
    ///   - deviceToken: device token
    ///   - completion: The code to be executed once the request has finished
    @available(*, deprecated, message: "will soon become unavailable.")
    public func register(deviceToken : String, isDevelopment:Bool = false, onSuccess: @escaping (Bool) -> Void, onError: @escaping (QError) -> Void) {
        if QiscusCore.isLogined {
            QiscusCore.network.registerDeviceToken(deviceToken: deviceToken, isDevelopment: isDevelopment, onSuccess: { (success) in
                QiscusCore.config.deviceToken = deviceToken
                onSuccess(success)
            }) { (error) in
                onError(error)
            }
        }else{
            onError(QError(message: "please login Qiscus first before register deviceToken"))
        }
    }
    
    /// Register device token Apns or Pushkit
    ///
    /// - Parameters:
    ///   - token: device token
    ///   - isDevelopment : default is false / using production
    ///   - completion: The code to be executed once the request has finished
    public func registerDeviceToken(token : String, isDevelopment:Bool = false, onSuccess: @escaping (Bool) -> Void, onError: @escaping (QError) -> Void) {
        if QiscusCore.isLogined {
            QiscusCore.network.registerDeviceToken(deviceToken: token, isDevelopment: isDevelopment, onSuccess: { (success) in
                onSuccess(success)
            }) { (error) in
                onError(error)
            }
        }else{
            onError(QError(message: "please login Qiscus first before register deviceToken"))
        }
    }
    
    /// Remove device token
    ///
    /// - Parameters:
    ///   - deviceToken: device token
    ///   - isDevelopment : default is false / using production
    ///   - completion: The code to be executed once the request has finished
    @available(*, deprecated, message: "will soon become unavailable.")
    public func remove(deviceToken : String,  isDevelopment:Bool = false, onSuccess: @escaping (Bool) -> Void, onError: @escaping (QError) -> Void) {
        QiscusCore.network.removeDeviceToken(deviceToken: deviceToken, isDevelopment: isDevelopment, onSuccess: onSuccess, onError: onError)
    }
    
    /// Remove device token
    ///
    /// - Parameters:
    ///   - token: device token
    ///   - isDevelopment : default is false / using production
    ///   - completion: The code to be executed once the request has finished
    public func removeDeviceToken(token : String, isDevelopment:Bool = false, onSuccess: @escaping (Bool) -> Void, onError: @escaping (QError) -> Void) {
        QiscusCore.network.removeDeviceToken(deviceToken: token, isDevelopment: isDevelopment, onSuccess: onSuccess, onError: onError)
    }
    
    /// Sync comment
    ///
    /// - Parameters:
    ///   - lastCommentReceivedId: last comment id, to get id you can call QiscusCore.dataStore.getComments().
    ///   - order: "asc" or "desc" only, lowercase. If other than that, it will assumed to "desc"
    ///   - limit: limit number of comment by default 20
    ///   - completion: return object array of comment and return error if exist
    @available(*, deprecated, message: "will soon become unavailable.")
    public func sync(lastCommentReceivedId id: String = "", onSuccess: @escaping ([CommentModel]) -> Void, onError: @escaping (QError) -> Void) {
        if id.isEmpty {
            // get last comment id
            if let comment = QiscusCore.database.comment.all().last {
                QiscusCore.network.sync(lastCommentReceivedId: comment.id) { (comments, error) in
                    if let message = error {
                        onError(QError(message: message))
                    }else {
                        if let results = comments {
                            // Save comment in local
                            if results.count != 0 {
                                let reversedComments : [CommentModel] = Array(results.reversed())
                                QiscusCore.database.comment.save(reversedComments)
                            }
                            onSuccess(results)
                        }
                    }
                }
            }else {
                onError(QError(message: "call sync without parameter is not work, please try to set last comment id. Maybe comment in DB is empty"))
            }
        }else {
            QiscusCore.network.sync(lastCommentReceivedId: id) { (comments, error) in
                if let message = error {
                    onError(QError(message: message))
                }else {
                    if let results = comments {
                        // Save comment in local
                        if results.count != 0 {
                            let reversedComments : [CommentModel] = Array(results.reversed())
                            QiscusCore.database.comment.save(reversedComments)
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
    public func synchronize(lastMessageId id: String = "", onSuccess: @escaping ([CommentModel]) -> Void, onError: @escaping (QError) -> Void) {
        if id.isEmpty {
            // get last comment id
            if let comment = QiscusCore.database.comment.all().last {
                QiscusCore.network.sync(lastCommentReceivedId: comment.id) { (comments, error) in
                    if let message = error {
                        onError(QError(message: message))
                    }else {
                        if let results = comments {
                            // Save comment in local
                            if results.count != 0 {
                                let reversedComments : [CommentModel] = Array(results.reversed())
                                QiscusCore.database.comment.save(reversedComments)
                            }
                            onSuccess(results)
                        }
                    }
                }
            }else {
                onError(QError(message: "call sync without parameter is not work, please try to set last comment id. Maybe comment in DB is empty"))
            }
        }else {
            QiscusCore.network.sync(lastCommentReceivedId: id) { (comments, error) in
                if let message = error {
                    onError(QError(message: message))
                }else {
                    if let results = comments {
                        // Save comment in local
                        if results.count != 0 {
                            let reversedComments : [CommentModel] = Array(results.reversed())
                            QiscusCore.database.comment.save(reversedComments)
                        }
                        onSuccess(results)
                    }
                }
            }
        }
    }
    
    // MARK: User Profile
    
    /// get qiscus user from local storage
    ///
    /// - Returns: return nil when client not logined, and return object user when already logined
    @available(*, deprecated, message: "will soon become unavailable.")
    public static func getProfile() -> UserModel? {
        return ConfigManager.shared.user
    }
    
    /// Get Profile from server
    ///
    /// - Parameter completion: The code to be executed once the request has finished
    @available(*, deprecated, message: "will soon become unavailable.")
    public func getProfile(onSuccess: @escaping (UserModel) -> Void, onError: @escaping (QError) -> Void) {
        if ConfigManager.shared.appID != nil {
            if QiscusCore.isLogined {
                QiscusCore.network.getProfile(onSuccess: { (userModel) in
                    ConfigManager.shared.user = userModel
                    onSuccess(userModel)
                }) { (error) in
                    onError(error)
                }
            }else{
                onError(QError(message: "please login Qiscus first before register deviceToken"))
            }
        }else{
            onError(QError(message: "please setupAPPID first before call api"))
        }
        
    }
    
    // MARK: User Profile
    
    /// get qiscus user from local storage
    ///
    /// - Returns: return nil when client not logined, and return object user when already logined
    public static func getUserData() -> UserModel? {
        return ConfigManager.shared.user
    }
    
    /// Get Profile from server
    ///
    /// - Parameter completion: The code to be executed once the request has finished
    public func getUserData(onSuccess: @escaping (UserModel) -> Void, onError: @escaping (QError) -> Void) {
        if ConfigManager.shared.appID != nil {
            if QiscusCore.isLogined {
                QiscusCore.network.getProfile(onSuccess: { (userModel) in
                    ConfigManager.shared.user = userModel
                    onSuccess(userModel)
                }) { (error) in
                    onError(error)
                }
            }else{
                onError(QError(message: "please login Qiscus first before register deviceToken"))
            }
        }else{
            onError(QError(message: "please setupAPPID first before call api"))
        }
        
    }
    
    
    /// Start or stop typing in room,
    ///
    /// - Parameters:
    ///   - value: set true if user start typing, and false when finish
    ///   - roomID: room id where you typing
    @available(*, deprecated, message: "will soon become unavailable.")
    public func isTyping(_ value: Bool, roomID: String) {
        QiscusCore.realtime.isTyping(value, roomID: roomID)
    }
    
    /// Start or stop typing in room,
    ///
    /// - Parameters:
    ///   - value: set true if user start typing, and false when finish
    ///   - roomID: room id where you typing
    public func publishTyping(roomID: String, isTyping: Bool) {
        QiscusCore.realtime.isTyping(isTyping, roomID: roomID)
    }
    
    /// Set Online or offline
    ///
    /// - Parameter value: true if user online and false if offline
    @available(*, deprecated, message: "will soon become unavailable.")
    public func isOnline(_ value: Bool) {
        QiscusCore.realtime.isOnline(value)
    }
    
    /// publish Online or offline
    ///
    /// - Parameter value: true if user online and false if offline
    public func publishOnlinePresence(isOnline: Bool) {
        QiscusCore.realtime.isOnline(isOnline)
    }
    
    /// Set subscribe rooms
    ///
    /// - Parameter value: RoomModel
    @available(*, deprecated, message: "will soon become unavailable.")
    public func subcribeRooms(_ rooms: [RoomModel]) {
        QiscusCore.realtime.subscribeRoomsWithoutOnlineStatus(rooms: rooms)
    }
    
    /// Set subscribe subscribeChatRoom
    ///
    /// - Parameter value: array RoomModel
    public func subscribeChatRooms(_ rooms: [RoomModel]) {
        QiscusCore.realtime.subscribeRoomsWithoutOnlineStatus(rooms: rooms)
    }
    
    /// Set subscribe subscribeChatRoom
    ///
    /// - Parameter value: RoomModel 
    public func subscribeChatRoom(_ room: RoomModel) {
        QiscusCore.realtime.subscribeRoomsWithoutOnlineStatus(rooms: [room])
    }
    
    /// Set unSubcribeRoom rooms
    ///
    /// - Parameter value: array of RoomModel
    @available(*, deprecated, message: "will soon become unavailable.")
    public func unSubcribeRooms(_ rooms: [RoomModel]) {
        QiscusCore.realtime.unsubscribeRoomsWithoutOnlineStatus(rooms: rooms)
    }
    
    /// Set unSubcribeChatRoom rooms
    ///
    /// - Parameter value: array RoomModel
    public func unSubcribeChatRooms(_ rooms: [RoomModel]) {
        QiscusCore.realtime.unsubscribeRoomsWithoutOnlineStatus(rooms: rooms)
    }
    
    /// Set unSubcribeChatRoom rooms
    ///
    /// - Parameter value: RoomModel
    public func unSubcribeChatRoom(_ room: RoomModel) {
        QiscusCore.realtime.unsubscribeRoomsWithoutOnlineStatus(rooms: [room])
    }
    
    
    /// subscribe user online presence / online status
    ///
    /// - Parameter userId: userId
    public func subscribeUserOnlinePresence(userId : String){
        QiscusCore.realtime.subscribeUserOnlinePresence(userId: userId)
    }
    
    /// subscribe user online presence / online status
    ///
    /// - Parameter userIds: array of userId
    public func subscribeUserOnlinePresence(userIds : [String]){
        QiscusCore.realtime.subscribeUserOnlinePresence(userIds: userIds)
    }
    
    /// unSubscribe user online presence / online status
    ///
    /// - Parameter userId: userId
    public func unsubscribeUserOnlinePresence(userId : String){
        QiscusCore.realtime.unsubscribeUserOnlinePresence(userId: userId)
    }
    
    /// unSubscribe user online presence / online status
    ///
    /// - Parameter userIds: array of userId
    public func unsubscribeUserOnlinePresence(userIds : [String]){
        QiscusCore.realtime.unsubscribeUserOnlinePresence(userIds: userIds)
    }
    
    /// Update user profile
    ///
    /// - Parameters:
    ///   - displayName: nick name
    ///   - url: user avatar url
    ///   - completion: The code to be executed once the request has finished
    @available(*, deprecated, message: "will soon become unavailable.")
    public func updateProfile(username: String = "", avatarUrl url: URL? = nil, extras: [String : Any]? = nil, onSuccess: @escaping (UserModel) -> Void, onError: @escaping (QError) -> Void) {
        if ConfigManager.shared.appID != nil {
            if QiscusCore.isLogined {
                QiscusCore.network.updateProfile(displayName: username, avatarUrl: url, extras: extras, onSuccess: { (userModel) in
                    ConfigManager.shared.user = userModel
                    onSuccess(userModel)
                }) { (error) in
                    onError(error)
                }
            }else{
                onError(QError(message: "please login Qiscus first before register deviceToken"))
            }
        }else{
            onError(QError(message: "please setupAppID first"))
        }
    }
    
    /// Update user profile
    ///
    /// - Parameters:
    ///   - name: nick name
    ///   - avatarURL: user avatar url
    ///   - extras : extrasData
    ///   - completion: The code to be executed once the request has finished
    public func updateUser(name: String = "", avatarURL: URL? = nil, extras: [String : Any]? = nil, onSuccess: @escaping (UserModel) -> Void, onError: @escaping (QError) -> Void) {
        if ConfigManager.shared.appID != nil {
            if QiscusCore.isLogined {
                QiscusCore.network.updateProfile(displayName: name, avatarUrl: avatarURL, extras: extras, onSuccess: { (userModel) in
                    ConfigManager.shared.user = userModel
                    onSuccess(userModel)
                }) { (error) in
                    onError(error)
                }
            }else{
                onError(QError(message: "please login Qiscus first before register deviceToken"))
            }
        }else{
            onError(QError(message: "please setupAppID first"))
        }
    }
    
    /// Get total unread count by user
    ///
    /// - Parameter completion: number of unread cout for all room
    @available(*, deprecated, message: "will soon become unavailable.")
    public func unreadCount(completion: @escaping (Int, QError?) -> Void) {
        QiscusCore.network.unreadCount(completion: completion)
    }
    
    /// Get total unread count by user
    ///
    /// - Parameter completion: number of unread cout for all room
    public func getTotalUnreadCount(completion: @escaping (Int, QError?) -> Void) {
        QiscusCore.network.unreadCount(completion: completion)
    }
    
    /// Block Qiscus User
    ///
    /// - Parameters:
    ///   - email: qiscus email user
    ///   - completion: Response object user and error if exist
    @available(*, deprecated, message: "will soon become unavailable.")
    public func blockUser(email: String, onSuccess: @escaping (MemberModel) -> Void, onError: @escaping (QError) -> Void) {
        QiscusCore.network.blockUser(email: email, onSuccess: onSuccess, onError: onError)
    }
    
    /// Block Qiscus User
    ///
    /// - Parameters:
    ///   - userId: qiscus userId user
    ///   - completion: Response object user and error if exist
    public func blockUser(userId: String, onSuccess: @escaping (MemberModel) -> Void, onError: @escaping (QError) -> Void) {
        QiscusCore.network.blockUser(email: userId, onSuccess: onSuccess, onError: onError)
    }
    
    /// Unblock Qiscus User
    ///
    /// - Parameters:
    ///   - email: qiscus email user
    ///   - completion: Response object user and error if exist
    @available(*, deprecated, message: "will soon become unavailable.")
    public func unblockUser(email: String, onSuccess: @escaping (MemberModel) -> Void, onError: @escaping (QError) -> Void) {
        QiscusCore.network.unblockUser(email: email, onSuccess: onSuccess, onError: onError)
    }
    
    /// Unblock Qiscus User
    ///
    /// - Parameters:
    ///   - userId: qiscus userId user
    ///   - completion: Response object user and error if exist
    public func unblockUser(userId: String, onSuccess: @escaping (MemberModel) -> Void, onError: @escaping (QError) -> Void) {
        QiscusCore.network.unblockUser(email: userId, onSuccess: onSuccess, onError: onError)
    }
    
    /// Get blocked user
    ///
    /// - Parameters:
    ///   - page: page for pagination
    ///   - limit: limit per page
    ///   - completion: Response array of object user and error if exist
    @available(*, deprecated, message: "will soon become unavailable.")
    public func listBlocked(page: Int?, limit:Int?, onSuccess: @escaping ([MemberModel]) -> Void, onError: @escaping (QError) -> Void) {
        QiscusCore.network.getBlokedUser(page: page, limit: limit, onSuccess: onSuccess, onError: onError)
    }
    
    
    /// Get blocked user
    ///
    /// - Parameters:
    ///   - page: page for pagination
    ///   - limit: limit per page
    ///   - completion: Response array of object user and error if exist
    public func getBlockedUsers(page: Int?, limit:Int?, onSuccess: @escaping ([MemberModel]) -> Void, onError: @escaping (QError) -> Void) {
        QiscusCore.network.getBlokedUser(page: page, limit: limit, onSuccess: onSuccess, onError: onError)
    }
    
    /// Upload to qiscus server
    ///
    /// - Parameters:
    ///   - data: data file to upload
    ///   - filename: file Name
    ///   - onSuccess: return object file model when success
    ///   - onError: return QError
    ///   - progress: progress upload
    @available(*, deprecated, message: "will soon become unavailable.")
    public func upload(data : Data, filename: String, onSuccess: @escaping (FileModel) -> Void, onError: @escaping (QError) -> Void, progress: @escaping (Double) -> Void ) {
        QiscusCore.network.upload(data: data, filename: filename, onSuccess: onSuccess, onError: onError, progress: progress)
    }
    
    /// Upload to qiscus server
    ///
    /// - Parameters:
    ///   - file: data file to upload
    ///   - filename: file Name
    ///   - onSuccess: return object file model when success
    ///   - onError: return QError
    ///   - progress: progress upload
    public func upload(file : FileUploadModel, onSuccess: @escaping (FileModel) -> Void, onError: @escaping (QError) -> Void, progressListener: @escaping (Double) -> Void ) {
        
        guard let data = file.data else {
            onError(QError(message: "file data can't be empty"))
            return
        }
        
        if file.name.isEmpty {
            onError(QError(message: "file name can't be empty"))
            return
        }
        
        QiscusCore.network.upload(data: data, filename: file.name, onSuccess: onSuccess, onError: onError, progress: progressListener)
    }
    
    /// get ThumbnailURL
    ///
    /// - Parameters:
    ///   - url: url (support for image, video and pdf)
    ///   - onSuccess: return string url thumbnail when success
    public func getThumbnailURL(url : String, onSuccess: @escaping (String) -> Void, onError: @escaping (QError) -> Void){
        
        if url.isEmpty{
            onError(QError(message: "URL can't be empty"))
        }
        
        var thumbURL = url.replacingOccurrences(of: "/upload/", with: "/upload/w_320,h_320,c_limit/").replacingOccurrences(of: " ", with: "%20")
        let thumbUrlArr = thumbURL.split(separator: ".")
        
        var newThumbURL = ""
        var i = 0
        for thumbComponent in thumbUrlArr{
            if i == 0{
                newThumbURL += String(thumbComponent)
            }else if i < (thumbUrlArr.count - 1){
                newThumbURL += ".\(String(thumbComponent))"
            }else{
                newThumbURL += ".png"
            }
            i += 1
        }
        thumbURL = newThumbURL
        onSuccess(thumbURL)
    }
    
    /// getBlurryThumbnailURL
    ///
    /// - Parameters:
    ///   - url: url
    ///   - onSuccess: return string url thumbnail when success
    public func getBlurryThumbnailURL(url : String, onSuccess: @escaping (String) -> Void, onError: @escaping (QError) -> Void){
        
        if url.isEmpty{
            onError(QError(message: "URL can't be empty"))
        }
        
        var thumbURL = url.replacingOccurrences(of: "/upload/", with: "/upload/w_320,h_320,c_limit,e_blur:300/").replacingOccurrences(of: " ", with: "%20")
        let thumbUrlArr = thumbURL.split(separator: ".")
        
        var newThumbURL = ""
        var i = 0
        for thumbComponent in thumbUrlArr{
            if i == 0{
                newThumbURL += String(thumbComponent)
            }else if i < (thumbUrlArr.count - 1){
                newThumbURL += ".\(String(thumbComponent))"
            }else{
                newThumbURL += ".png"
            }
            i += 1
        }
        thumbURL = newThumbURL
        onSuccess(thumbURL)
    }
    

    
    /// Download
    ///
    /// - Parameters:
    ///   - url: url you want to download
    ///   - onSuccess: resturn local url after success download
    ///   - onProgress: progress download
    public func download(url: URL, onSuccess: @escaping (URL) -> Void, onProgress: @escaping (Float) -> Void) {
        QiscusCore.network.download(url: url, onSuccess: onSuccess, onProgress: onProgress)
    }
    
    /// getUsers
    ///
    /// - Parameters:
    ///   - limit: default 20
    ///   - page: default 1
    ///   - querySearch: default nil
    ///   - onSuccess: array of users and metaData
    ///   - onError: error when failed call api
    @available(*, deprecated, message: "will soon become unavailable.")
    public func getUsers(limit : Int? = 100, page: Int? = 1, querySearch: String? = nil,onSuccess: @escaping ([MemberModel], Meta) -> Void, onError: @escaping (QError) -> Void){
        QiscusCore.network.getUsers(limit: limit, page: page, querySearch: querySearch, onSuccess: onSuccess, onError: onError)
    }
    
    /// getUsers
    ///
    /// - Parameters:
    ///   - searchUsername: default nil
    ///   - page: page
    ///   - limit: limit min 0 max 100
    ///   - onSuccess: array of users and metaData
    ///   - onError: error when failed call api
    public func getUsers(searchUsername: String? = nil, page: Int, limit : Int,onSuccess: @escaping ([MemberModel], Meta) -> Void, onError: @escaping (QError) -> Void){
        QiscusCore.network.getUsers(limit: limit, page: page, querySearch: searchUsername, onSuccess: onSuccess, onError: onError)
    }
    
    // userPresence
    /// - Parameters:
    ///   - userIds: array userIds
    ///   - completion: Response array of QUserPresence
    public func getUserPresence(userIds : [String], onSuccess: @escaping ([QUserPresence]) -> Void, onError: @escaping (QError) -> Void ) {
        QiscusCore.network.getUserPresence(userIds: userIds) { (channels, error) in
            if let _channels = channels {
                onSuccess(_channels)
            }else{
                if let _error = error {
                    onError(QError(message: _error))
                }else {
                    onError(QError(message: "Unexpected Error"))
                }
            }
        }
    }
}

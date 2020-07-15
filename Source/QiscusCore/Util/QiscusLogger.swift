//
//  QiscusLogger.swift
//  QiscusCore
//
//  Created by Arief Nur Putranto on 24/07/18.
//  Copyright © 2018 Qiscus. All rights reserved.
//

import Foundation

public class QiscusLogger: NSObject {
    var qiscusCore : QiscusCore? = nil
    func debugPrint(_ text: String) {
        if self.qiscusCore?.enableDebugPrint ?? false{
            if let appId = qiscusCore?.appID{
                 print("[QiscusCore || \(appId)] \(text)")
            }else{
                 print("[QiscusCore] \(text)")
            }
        }
    }
    
    func debugDBPrint(_ text: String) {
        if self.qiscusCore?.enableDebugPrint ?? false {
            if let appId = qiscusCore?.appID{
                 print("[QiscusCoreDB || \(appId)] \(text)")
            }else{
                 print("[QiscusCoreDB] \(text)")
            }
        }
    }
    
    func errorPrint(_ text: String) {
        if self.qiscusCore?.enableDebugPrint ?? false {
            if let appId = qiscusCore?.appID{
                 print("[QiscusCore || \(appId)] Error: \(text)")
            }else{
                 print("[QiscusCore] Error: \(text)")
            }
        }
    }
    
    func networkLogger(request: URLRequest) {
        if self.qiscusCore?.enableDebugPrint ?? false == false {
            return
        }
        
        print("\n ====================> REQUEST <============ \n")
        defer { print("\n ====================> END REQUEST <============ \n") }
        
        let urlAsString = request.url?.absoluteString ?? ""
        let urlComponents = NSURLComponents(string: urlAsString)
        
        let method = request.httpMethod != nil ? "\(request.httpMethod ?? "")" : ""
        let path = "\(urlComponents?.path ?? "")"
        let query = "\(urlComponents?.query ?? "")"
        let host = "\(urlComponents?.host ?? "")"
        
        var logOutput = """
        \(urlAsString) \n\n
        \(method) \(path)?\(query) HTTP/1.1 \n
        HOST: \(host)\n
        """
        for (key,value) in request.allHTTPHeaderFields ?? [:] {
            logOutput += "\(key): \(value) \n"
        }
        if let body = request.httpBody {
            logOutput += "\n \(NSString(data: body, encoding: String.Encoding.utf8.rawValue) ?? "")"
        }
        
        print(logOutput)
    }
    
    func networkLogger(request: URLRequest, response: Data?) {
        if self.qiscusCore?.enableDebugPrint ?? false == false {
            return
        }
        
        print("\n ====================> RESPONSE <============ \n")
        defer { print("\n ====================> END RESPONSE <============ \n") }
        
        let urlAsString = request.url?.absoluteString ?? ""
        var responseMessage = ""
        if let responseData = response {
            responseMessage = responseData.toJsonString()
        }
        
        var logOutput = """
               URL: \(urlAsString) \n
               Response: \(responseMessage)
               """
        
        if let appId = qiscusCore?.appID{
            logOutput = """
                    URL with AppID = \(appId): \(urlAsString) \n
                    Response with AppID = \(appId): \(responseMessage)
                    """
        }
        
        print(logOutput)
    }
}

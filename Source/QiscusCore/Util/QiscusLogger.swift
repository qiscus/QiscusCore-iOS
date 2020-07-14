//
//  QiscusLogger.swift
//  QiscusCore
//
//  Created by Rahardyan Bisma on 24/07/18.
//  Copyright © 2018 Qiscus. All rights reserved.
//

import Foundation

class QiscusLogger {
    static func debugPrint(_ text: String) {
        if QiscusCore.enableDebugPrint {
            print("[QiscusCore] \(text)")
        }
    }
    
    static func debugDBPrint(_ text: String) {
        if QiscusCore.enableDebugPrint {
            print("[QiscusCoreDB] \(text)")
        }
    }
    
    static func errorPrint(_ text: String) {
        if QiscusCore.enableDebugPrint {
            print("[QiscusCore] Error: \(text)")
        }
    }
    
    static func networkLogger(request: URLRequest) {
        if !QiscusCore.enableDebugPrint {
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
    
    static func networkLogger(request: URLRequest, response: Data?) {
        if !QiscusCore.enableDebugPrint {
            return
        }
        
        print("\n ====================> RESPONSE <============ \n")
        defer { print("\n ====================> END RESPONSE <============ \n") }
        
        let urlAsString = request.url?.absoluteString ?? ""
        var responseMessage = ""
        if let responseData = response {
            responseMessage = responseData.toJsonString()
        }
        let logOutput = """
        URL: \(urlAsString) \n
        Response: \(responseMessage)
        """
        print(logOutput)
    }
}

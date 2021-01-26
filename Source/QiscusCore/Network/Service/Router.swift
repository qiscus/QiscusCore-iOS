//
//  Router.swift
//  QiscusCore
//
//  Created by Malcolm Kumwenda on 2018/03/07.
//  Copyright © 2018 Malcolm Kumwenda. All rights reserved.
//

import Foundation
import UIKit

internal typealias NetworkRouterCompletion = (_ data: Data?,_ response: URLResponse?,_ error: Error?)->()

protocol NetworkRouter: class {
    associatedtype  endPoint: EndPoint
    func request(_ route: endPoint, completion: @escaping NetworkRouterCompletion)
    func cancel()
}

class Router<endpoint: EndPoint>: NetworkRouter {
    var qiscusCore : QiscusCore? = nil
    private let session = URLSession(configuration: .default)
    private var task: URLSessionTask?
    
    var AUTHTOKEN : String {
        get {
            if let user = self.qiscusCore?.config.user {
                return user.token
            }else {
                return ""
            }
            
        }
    }

    var BASEURL : URL {
        get {
            if let server = self.qiscusCore?.config.server {
                return server.url
            }else {
                return URL.init(string: "https://api.qiscus.com/api/v2/mobile")!
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
            if let appID = self.qiscusCore?.config.appID {
                headers["QISCUS-SDK-APP-ID"] = appID
            }
            
            if let user = self.qiscusCore?.config.user {
                if let appid = self.qiscusCore?.config.appID {
                    headers["QISCUS-SDK-APP-ID"] = appid
                }
                if !user.token.isEmpty {
                    headers["QISCUS-SDK-TOKEN"] = user.token
                }
                if !user.id.isEmpty {
                    headers["QISCUS-SDK-USER-ID"] = user.id
                }
            }
            
            if let customHeader = self.qiscusCore?.config.customHeader {
                headers.merge(customHeader as! [String : String]){(_, new) in new}
            }
            
            return headers
        }
    }
    
    func request(_ route: endpoint, completion: @escaping NetworkRouterCompletion) {
        DispatchQueue.global(qos: .background).sync {
            do {
                var newRoute = route
                newRoute.baseURL = self.BASEURL
                newRoute.header  = self.HEADERS
                let request = try self.buildRequest(from: route)
                qiscusCore?.qiscusLogger.networkLogger(request: request)
                self.task = self.session.dataTask(with: request, completionHandler: { data, response, error in
                    self.qiscusCore?.qiscusLogger.networkLogger(request: request, response: data)
                    if Thread.isMainThread {
                        completion(data, response, error)
                    }else{
                        if Thread.isMainThread {
                            completion(data, response, error)
                        } else {
                            DispatchQueue.main.sync { completion(data, response, error) }
                        }
                    }
                })
            }catch {
                if Thread.isMainThread {
                    completion(nil, nil, error)
                }else{
                    if Thread.isMainThread {
                        completion(nil, nil, error)
                    } else {
                        DispatchQueue.main.sync { completion(nil, nil, error) }
                    }
                    
                }
            }
            self.task?.resume()
        }
    }
    
    func cancel() {
        self.task?.cancel()
    }
    
    fileprivate func buildRequest(from route: endpoint) throws -> URLRequest {
        
        var request = URLRequest(url: route.baseURL.appendingPathComponent(route.path),
                                 cachePolicy: .reloadIgnoringLocalAndRemoteCacheData,
                                 timeoutInterval: 10.0)
        
        request.httpMethod = route.httpMethod.rawValue
        if let header = route.header {
            self.addAdditionalHeaders(header, request: &request)
        }
        
        do {
            switch route.task {
            case .request:
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            case .requestParameters(let bodyParameters,
                                    let bodyEncoding,
                                    let urlParameters):
                
                try self.configureParameters(bodyParameters: bodyParameters,
                                             bodyEncoding: bodyEncoding,
                                             urlParameters: urlParameters,
                                             request: &request)
                
            case .requestParametersAndHeaders(let bodyParameters,
                                              let bodyEncoding,
                                              let urlParameters,
                                              let additionalHeaders):
                
                self.addAdditionalHeaders(additionalHeaders, request: &request)
                try self.configureParameters(bodyParameters: bodyParameters,
                                             bodyEncoding: bodyEncoding,
                                             urlParameters: urlParameters,
                                             request: &request)
            }
            return request
        } catch {
            throw error
        }
    }
    
    fileprivate func configureParameters(bodyParameters: Parameters?,
                                         bodyEncoding: ParameterEncoding,
                                         urlParameters: Parameters?,
                                         request: inout URLRequest) throws {
        do {
            try bodyEncoding.encode(urlRequest: &request,
                                    bodyParameters: bodyParameters, urlParameters: urlParameters)
        } catch {
            throw error
        }
    }
    
    fileprivate func addAdditionalHeaders(_ additionalHeaders: HTTPHeaders?, request: inout URLRequest) {
        guard let headers = additionalHeaders else { return }
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
    }
    
}

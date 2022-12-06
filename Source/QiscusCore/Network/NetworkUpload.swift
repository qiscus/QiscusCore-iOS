//
//  NetworkUpload.swift
//  QiscusCore
//
//  Created by Qiscus on 05/09/18.
//
import UIKit
import Foundation

class NetworkUpload {
    var qiscusCore : QiscusCore? = nil
    func createRequest(route: EndPoint, data: Data, filename: String) throws -> URLRequest {
        let boundary = "Boundary-\(UUID().uuidString)"
        var request : URLRequest? = nil
        if let url = self.qiscusCore?.BASEURL{
            request = URLRequest(url: url.appendingPathComponent(route.path))
        }
        
        guard var request = request else {
            return URLRequest(url: URL.init(string: "https://api3.qiscus.com/api/v2/mobile")!.appendingPathComponent(route.path))
        }

       
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        //if let header = route.header {
        self.addAdditionalHeaders(self.qiscusCore?.HEADERS, request: &request)
        //}
        guard let user = qiscusCore?.config.user else { return request }
        request.httpBody = NetworkUpload().createBody(
                                      boundary: boundary,
                                      data: data,
                                      mimeType: "image/jpg",
                                      filename: filename)
        
        return request
    }
    
    fileprivate func createBody(
                    boundary: String,
                    data: Data,
                    mimeType: String,
                    filename: String) -> Data {
        let body = NSMutableData()
        
        let boundaryPrefix = "--\(boundary)\r\n"
        body.appendString(boundaryPrefix)
        body.appendString("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n")
        body.appendString("Content-Type: \(mimeType)\r\n\r\n")
        body.append(data)
        body.appendString("\r\n")
        body.appendString("--".appending(boundary.appending("--")))
        
        return body as Data
    }
    
    fileprivate func addAdditionalHeaders(_ additionalHeaders: HTTPHeaders?, request: inout URLRequest) {
        guard let headers = additionalHeaders else { return }
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
    }
}

extension NSMutableData {
    func appendString(_ string: String) {
        let data = string.data(using: String.Encoding.utf8, allowLossyConversion: false)
        append(data!)
    }
}

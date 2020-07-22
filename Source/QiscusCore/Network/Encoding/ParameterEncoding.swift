//
//  ParameterEncoding.swift
//  QiscusCore
//
//  Created by Qiscus on 18/07/18.
//

import Foundation

public typealias Parameters = [String:Any]

public protocol ParameterEncoder {
    func encode(urlRequest: inout URLRequest, with parameters: Parameters) throws
}

public protocol FormUrlEncoder {
    func encode(urlRequest: inout URLRequest, with parameters: Parameters) throws
}

public protocol ParameterNotEncoder{
    func notEncode(urlRequest: inout URLRequest, with parameters: Parameters) throws
}

public enum ParameterEncoding {
    
    case urlEncoding
    case jsonEncoding
    case jsonUrlEncoding
    case formUrlEncode
    
    public func encode(urlRequest: inout URLRequest,
                       bodyParameters: Parameters?,
                       urlParameters: Parameters?) throws {
        do {
            switch self {
            case .formUrlEncode:
                guard let urlParameters = urlParameters else { return }
                try FormUrlEncode().encode(urlRequest: &urlRequest, with: urlParameters)
            case .urlEncoding:
                guard let urlParameters = urlParameters else { return }
                try URLParameterEncoder().encode(urlRequest: &urlRequest, with: urlParameters)
            case .jsonEncoding:
                guard let bodyParameters = bodyParameters else { return }
                try JSONParameterEncoder().encode(urlRequest: &urlRequest, with: bodyParameters)
            case .jsonUrlEncoding:
                //Using method get and using query param
                guard let urlParameters = urlParameters else { return }
                try JSONParameterEncoder().urlEncode(urlRequest: &urlRequest, with: urlParameters)
                
            }
        }catch {
            throw error
        }
    }
}


public enum NetworkError : String, Error {
    case parametersNil = "Parameters were nil."
    case encodingFailed = "Parameter encoding failed."
    case missingURL = "URL is nil."
}

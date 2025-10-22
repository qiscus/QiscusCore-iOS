//
//  HTTPMethod.swift
//  QiscusCore
//
//  Created by Qiscus on 18/07/18.
//  Copyright © 2018 Qiscus. All rights reserved.
//

import UIKit

typealias HTTPHeaders = [String:String]

internal enum HTTPMethod : String {
    case get        = "GET"
    case post       = "POST"
    case put        = "PUT"
    case patch      = "PATCH"
    case delete     = "DELETE"
}

internal enum HTTPTask {
    case request

    case requestParameters(bodyParameters: Parameters?,
        bodyEncoding: ParameterEncoding,
        urlParameters: Parameters?)
    
    case requestParametersAndHeaders(bodyParameters: Parameters?,
        bodyEncoding: ParameterEncoding,
        urlParameters: Parameters?,
        additionHeaders: HTTPHeaders?)
    
    case requestCompositeParameters(bodyParameters: Parameters?, bodyEncoding: ParameterEncoding, urlParameters: Parameters?)
}

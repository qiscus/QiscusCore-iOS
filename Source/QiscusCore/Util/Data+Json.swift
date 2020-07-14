//
//  String+Print.swift
//  CocoaAsyncSocket
//
//  Created by Rahardyan Bisma on 24/07/18.
//

import Foundation

extension Data {
    func toJsonString() -> String {
        guard let jsonString = String(data: self, encoding: .utf8) else {return "invalid json data"}
        
        return jsonString
    }
}

//extension Dictionary {
//    var json: String {
//        let invalidJson = "Not a valid JSON"
//        do {
//            let jsonData = try JSONSerialization.data(withJSONObject: self, options: .prettyPrinted)
//            return String(bytes: jsonData, encoding: String.Encoding.utf8) ?? invalidJson
//        } catch {
//            return invalidJson
//        }
//    }
//    
//    func dict2json() -> String {
//        return json
//    }
//}

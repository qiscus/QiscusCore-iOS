//
//  QRLogger.swift
//  QiscusRealtime
//
//  Created by Qiscus on 15/08/18.
//

import Foundation

class QRLogger {
    static func debugPrint(_ text: String) {
        if QiscusRealtime.enableDebugPrint {
            print("[QiscusRealtime] \(text)")
        }
    }
    
    static func errorPrint(_ text: String) {
        if QiscusRealtime.enableDebugPrint {
            print("[QiscusRealtime] Error: \(text)")
        }
    }
}

//
//  QUserPresence.swift
//  QiscusCore
//
//  Created by Qiscus on 26/07/18.
//  Copyright © 2018 Qiscus. All rights reserved.
//
import Foundation
import SwiftyJSON


open class QUserPresence : NSObject {
    public internal(set) var userId : String = ""
    public internal(set) var timestamp : Int64 = 0
    public internal(set) var status : Bool = false
    
    init(json: JSON) {
        self.userId             = json["email"].stringValue
        let value               = json["status"].intValue
        if value == 0 {
            self.status = false
        } else {
            self.status = true
        }
        
        self.timestamp      = json["timestamp"].int64Value
    }
}



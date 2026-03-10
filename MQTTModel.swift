//
//  MqttModel.swift
//  Pods
//
//  Created by arief nur putranto on 10/03/26.
//

//
//  MQTTModel.swift
//  QiscusCore
//
//  Created by arief nur putranto on 20/01/26.
//

import Foundation
import SwiftyJSON
import UIKit

public struct MQTTModel {
    public var usernameMQTT     : String    = ""
    public var passwordMQTT     : String    = ""
    
    init() { }
    
    init(json: JSON) {
        usernameMQTT       = json["username"].string ?? ""
        passwordMQTT       = json["password"].string ?? ""
        
    }
    

}

//
//  AppConfigModel.swift
//  QiscusCore
//
//  Created by Qiscus on 11/02/20.
//  Copyright © 2020 Qiscus. All rights reserved.
//

import Foundation
import SwiftyJSON

public class AppConfigModel {
    public var baseURL : String = ""
    public var brokerLBURL : String = ""
    public var brokerURL : String = ""
    public var enableEventReport : Bool = false
    public var enableRealtime : Bool = true
    public var syncInterval : Double = 0
    public var syncOnConnect : Double = 0
    public var extras : String = ""
    
    init(json: JSON) {
        self.baseURL  = json["base_url"].string ?? ""
        self.brokerLBURL  = json["broker_lb_url"].string ?? ""
        self.brokerURL  = json["broker_url"].string ?? ""
        self.enableEventReport  = json["enable_event_report"].bool ?? false
        self.enableRealtime  = json["enable_realtime"].bool ?? true
        self.syncInterval  = json["sync_interval"].double ?? 5000
        self.syncOnConnect  = json["sync_on_connect"].double ?? 30000
        self.extras  = json["extras"].string ?? ""
    }
}

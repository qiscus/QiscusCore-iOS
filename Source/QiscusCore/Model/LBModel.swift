//
//  LBModel.swift
//  Alamofire
//
//  Created by Qiscus on 21/10/19.
//

import Foundation
import SwiftyJSON

public class LBModel {
    public let node : String
    
    init(json: JSON) {
        self.node  = json["node"].stringValue
    }
}

//
//  NonceModel.swift
//  QiscusCore
//
//  Created by Rahardyan Bisma on 24/07/18.
//  Copyright © 2018 Qiscus. All rights reserved.
//

import Foundation
import SwiftyJSON

public class QNonce {
    public let expiredAt : Int
    public let nonce : String
    
    init(json: JSON) {
        self.expiredAt  = json["expired_at"].intValue
        self.nonce      = json["nonce"].stringValue
    }
}

//
//  RoomListModel.swift
//  QiscusCore
//
//  Created by Qiscus on 26/07/18.
//  Copyright © 2018 Qiscus. All rights reserved.
//
import Foundation
import SwiftyJSON


open class QiscusChannels : NSObject {
    public internal(set) var id : String = ""
    public internal(set) var name : String = ""
    public internal(set) var createdAt : String = ""
    public internal(set) var uniqueId : String = ""
    public internal(set) var avatarUrl : String = ""
    public internal(set) var extras : String = ""
    public internal(set) var isJoined : Bool = false
    
    init(json: JSON) {
        self.id             = json["id"].stringValue
        self.name           = json["name"].stringValue
        self.uniqueId       = json["unique_id"].stringValue
        self.avatarUrl      = json["avatar_url"].stringValue
        self.extras         = json["extras"].rawString() ?? ""
        self.isJoined       = json["is_joined"].boolValue
        self.createdAt      = json["created_at"].stringValue
    }
}



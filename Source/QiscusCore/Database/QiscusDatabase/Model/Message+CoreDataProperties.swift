//
//  Message+CoreDataProperties.swift
//  QiscusDatabase
//
//  Created by Qiscus on 12/09/18.
//  Copyright © 2018 Qiscus. All rights reserved.
//
//

import Foundation
import CoreData


extension Message {

    @nonobjc  class func fetchRequest() -> NSFetchRequest<Message> {
        return NSFetchRequest<Message>(entityName: "Message")
    }

    @NSManaged  var message: String?
    @NSManaged  var type: String?
    @NSManaged  var commentBeforeId: String?
    @NSManaged  var id: String?
    @NSManaged  var status: String?
    @NSManaged  var userAvatarUrl: String?
    @NSManaged  var userId: String?
    @NSManaged  var username: String?
    @NSManaged  var userEmail: String?
    @NSManaged  var roomId: String?
    @NSManaged  var extras: String?
    @NSManaged  var payload: String?
    @NSManaged  var uniqId: String?
    @NSManaged  var unixTimestamp: Int64
    @NSManaged  var timestamp: String?
    @NSManaged  var isPublicChannel: Bool
    @NSManaged  var localData: String?
    @NSManaged  var userExtras: String?

}

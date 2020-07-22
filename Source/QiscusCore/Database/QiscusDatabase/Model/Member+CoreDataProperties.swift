//
//  Member+CoreDataProperties.swift
//  QiscusDatabase
//
//  Created by Qiscus on 12/09/18.
//  Copyright © 2018 Qiscus. All rights reserved.
//
//

import Foundation
import CoreData


extension Member {

    @nonobjc  class func fetchRequest() -> NSFetchRequest<Member> {
        return NSFetchRequest<Member>(entityName: "Member")
    }

    @NSManaged  var id: String?
    @NSManaged  var avatarUrl: String?
    @NSManaged  var email: String?
    @NSManaged  var username: String?
    @NSManaged  var lastCommentReadId: Int64
    @NSManaged  var lastCommentReceivedId: Int64
    @NSManaged  var localData: String?
    @NSManaged public var rooms: NSSet?
    @NSManaged  var extras: String?
}

// MARK: Generated accessors for rooms
extension Member {
    
    @objc(addRoomsObject:)
    @NSManaged public func addToRooms(_ value: Room)
    
    @objc(removeRoomsObject:)
    @NSManaged public func removeFromRooms(_ value: Room)
    
    @objc(addRooms:)
    @NSManaged public func addToRooms(_ values: NSSet)
    
    @objc(removeRooms:)
    @NSManaged public func removeFromRooms(_ values: NSSet)
    
}

//
//  Room+CoreDataProperties.swift
//  QiscusDatabase
//
//  Created by Qiscus on 12/09/18.
//  Copyright © 2018 Qiscus. All rights reserved.
//
//

import Foundation
import CoreData


extension Room {

    @nonobjc  class func fetchRequest() -> NSFetchRequest<Room> {
        return NSFetchRequest<Room>(entityName: "Room")
    }

    @NSManaged  var lastCommentId: String?
    @NSManaged  var name: String?
    @NSManaged  var type: String?
    @NSManaged  var id: String?
    @NSManaged  var uniqueId: String?
    @NSManaged  var avatarUrl: String?
    @NSManaged  var options: String?
    @NSManaged  var unreadCount: Int16
    @NSManaged  var localData: String?
    @NSManaged public var members: NSSet?

}

// MARK: Generated accessors for members
extension Room {
    
    @objc(addMembersObject:)
    @NSManaged public func addToMembers(_ value: Member)
    
    @objc(removeMembersObject:)
    @NSManaged public func removeFromMembers(_ value: Member)
    
    @objc(addMembers:)
    @NSManaged public func addToMembers(_ values: NSSet)
    
    @objc(removeMembers:)
    @NSManaged public func removeFromMembers(_ values: NSSet)
    
}

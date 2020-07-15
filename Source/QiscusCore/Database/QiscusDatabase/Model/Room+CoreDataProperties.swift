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
    @NSManaged public var participants: NSSet?

}

// MARK: Generated accessors for members
extension Room {
    
    @objc(addParticipantsObject:)
    @NSManaged public func addToParticipants(_ value: Participant)
    
    @objc(removeParticipantsObject:)
    @NSManaged public func removeFromParticipants(_ value: Participant)
    
    @objc(addParticipants:)
    @NSManaged public func addToParticipants(_ values: NSSet)
    
    @objc(removeParticipants:)
    @NSManaged public func removeFromParticipants(_ values: NSSet)
    
}

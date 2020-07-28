//
//  Room+CoreDataClass.swift
//  QiscusDatabase
//
//  Created by Qiscus on 12/09/18.
//  Copyright © 2018 Qiscus. All rights reserved.
//
//

import Foundation
import CoreData


public class Room: NSManagedObject {

}

extension Room {
    // create behaviour like active record
     static func all() -> [Room] {
        let fetchRequest:NSFetchRequest<Room> = Room.fetchRequest()
        var results = [Room]()
        var resultsNullData = [Room]()
        
        do {
            results = try PresistentStore.context.fetch(fetchRequest)
            //check null data
            resultsNullData = results.filter{ $0.id == nil ||  $0.id == ""}
             
             if resultsNullData.count != 0{
                 for i in resultsNullData{
                     //remove null data from sqlite
                     i.remove()
                 }
             }
             
             results = results.filter{ $0.id != nil }

        } catch  {
            //
        }
        return results
    }
    
     static func generate() -> Room {
        if #available(iOS 10.0, *) {
            return Room(context: QiscusDatabase.context)
        } else {
            // Fallback on earlier versions
            let context = QiscusDatabase.context
            let description = NSEntityDescription.entity(forEntityName: "Room", in: context)
            return Room(entity: description!, insertInto: context)
        }
    }
    
     static func find(predicate: NSPredicate) -> [Room]? {
        let fetchRequest:NSFetchRequest<Room> = Room.fetchRequest()
        fetchRequest.predicate = predicate
        do {
            return try  QiscusDatabase.context.fetch(fetchRequest)
        } catch  {
            return nil
        }
    }
    
    static func find(limit : Int, offset : Int) -> [Room]? {
        let fetchRequest:NSFetchRequest<Room> = Room.fetchRequest()
        fetchRequest.fetchLimit = limit
        fetchRequest.fetchOffset = offset
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Room.lastCommentId, ascending: false)]
        do {
            return try  QiscusDatabase.context.fetch(fetchRequest)
        } catch  {
            return nil
        }
    }
    
    /// Clear all member data
     static func clear() {
        QiscusDatabase.context.perform({
            let fetchRequest:NSFetchRequest<Room> = Room.fetchRequest()
            do {
                let delete = NSBatchDeleteRequest(fetchRequest: fetchRequest as! NSFetchRequest<NSFetchRequestResult>)
                try  QiscusDatabase.context.execute(delete)
            } catch {
                // failed to clear data
            }
            
        })
        
//        let fetchRequest:NSFetchRequest<Room> = Room.fetchRequest()
//        let delete = NSBatchDeleteRequest(fetchRequest: fetchRequest as! NSFetchRequest<NSFetchRequestResult>)
//        do {
//            try  QiscusDatabase.context.execute(delete)
//        } catch  {
//            // failed to clear data
//        }
    }
    
    // non static
     func remove() {
        QiscusDatabase.context.delete(self)
        self.save()
    }
    
     func update() {
        self.save()
    }
    
     func save() {
        QiscusDatabase.save()
    }
}

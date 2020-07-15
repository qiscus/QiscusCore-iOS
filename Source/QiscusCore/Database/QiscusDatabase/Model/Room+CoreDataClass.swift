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
    var qiscusCore : QiscusCore? = nil
    var qiscusDatabase : QiscusDatabase{
        get{
            //return QiscusDatabase.init(qiscusCore: self.qiscusCore!)
            return (qiscusCore?.initDB)!
        }
    }
}

extension Room {
    // create behaviour like active record
    func all() -> [Room] {
        let fetchRequest:NSFetchRequest<Room> = Room.fetchRequest()
        var results = [Room]()
        var resultsNullData = [Room]()
        
        do {
            results = try qiscusDatabase.persistenStore.context.fetch(fetchRequest)
            
           //check null data
            resultsNullData = results.filter{ $0.id == nil }
            
            if resultsNullData.count != 0{
                for i in resultsNullData{
                    //remove null data from sqlite
                    i.qiscusCore = self.qiscusCore
                    i.remove()
                }
            }
            
            results = results.filter{ $0.id != nil }
            
        } catch  {
            //
        }
        return results
    }
    
    func generate() -> Room {
        if #available(iOS 10.0, *) {
            let room = Room(context: qiscusDatabase.persistenStore.context)
            room.qiscusCore = self.qiscusCore
            return room
        } else {
            // Fallback on earlier versions
            let context = qiscusDatabase.persistenStore.context
            let description = NSEntityDescription.entity(forEntityName: "Room", in: context)
            let room = Room(entity: description!, insertInto: context)
            room.qiscusCore = self.qiscusCore
            return room
        }
//        self.qiscusCore!._roomPersistens = nil
//        return self.qiscusCore!.roomPersistens
    }
    
    func find(predicate: NSPredicate) -> [Room]? {
        let fetchRequest:NSFetchRequest<Room> = Room.fetchRequest()
        fetchRequest.predicate = predicate
        do {
            return try  self.qiscusDatabase.persistenStore.context.fetch(fetchRequest)
        } catch  {
            return nil
        }
    }
    
    /// Clear all member data
    func clear() {
        qiscusDatabase.persistenStore.context.perform({
            let fetchRequest:NSFetchRequest<Room> = Room.fetchRequest()
            do {
                let delete = NSBatchDeleteRequest(fetchRequest: fetchRequest as! NSFetchRequest<NSFetchRequestResult>)
                try  self.qiscusDatabase.persistenStore.context.execute(delete)
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
        qiscusDatabase.persistenStore.context.delete(self)
        self.save()
    }
    
     func update() {
        self.save()
    }
    
     func save() {
        qiscusDatabase.save()
    }
}

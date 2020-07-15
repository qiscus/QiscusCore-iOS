//
//  Message+CoreDataClass.swift
//  QiscusDatabase
//
//  Created by Qiscus on 12/09/18.
//  Copyright © 2018 Qiscus. All rights reserved.
//
//

import Foundation
import CoreData

// @objc(Message)
 class Message: NSManagedObject {
    var qiscusCore : QiscusCore? = nil
    public var qiscusDatabase : QiscusDatabase{
        get{
            //return QiscusDatabase.init(qiscusCore: self.qiscusCore!)
            return (qiscusCore?.initDB)!
        }
    }
}

protocol ActiveRecord {
//    associatedtype T
    associatedtype U
    func all() -> [U]
}

// query
extension Message {
    // create behaviour like active record
    func all() -> [Message] {
        let fetchRequest:NSFetchRequest<Message> = Message.fetchRequest()
        var results = [Message]()
        var resultsNullData = [Message]()
        
        do {
            results = try  qiscusDatabase.persistenStore.context.fetch(fetchRequest)
            
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
            
        }
        return results
    }
    
    func generate() -> Message {
        if #available(iOS 10.0, *) {
            let message = Message(context:  self.qiscusDatabase.persistenStore.context)
            message.qiscusCore = self.qiscusCore
            return message
        } else {
            // Fallback on earlier versions
            let context = qiscusDatabase.persistenStore.context
            let description = NSEntityDescription.entity(forEntityName: "Message", in: context)
            let message = Message(entity: description!, insertInto: context)
            message.qiscusCore = self.qiscusCore
            return message
        }
//        self.qiscusCore!._messagePersistens = nil
//        return self.qiscusCore!.messagePersistens
    }
    
    func find(predicate: NSPredicate) -> [Message]? {
        let fetchRequest:NSFetchRequest<Message> = Message.fetchRequest()
        fetchRequest.predicate = predicate
        do {
            return try  self.qiscusDatabase.persistenStore.context.fetch(fetchRequest)
        } catch  {
            //QiscusLogger.errorPrint("Message with predicate \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Clear all Message data
    func clear() {
        qiscusDatabase.persistenStore.context.perform({
            let fetchRequest:NSFetchRequest<Message> = Message.fetchRequest()
            do {
                  let delete = NSBatchDeleteRequest(fetchRequest: fetchRequest as! NSFetchRequest<NSFetchRequestResult>)
                try  self.qiscusDatabase.persistenStore.context.execute(delete)
            } catch {
                 // failed to clear data
            }
            
        })
        
        
//        let fetchRequest:NSFetchRequest<Message> = Message.fetchRequest()
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

//
//  Participant+CoreDataClass.swift
//  QiscusDatabase
//
//  Created by Qiscus on 12/09/18.
//  Copyright © 2018 Qiscus. All rights reserved.
//
//

import Foundation
import CoreData

public class Participant: NSManagedObject {
    var qiscusCore : QiscusCore? = nil
    var qiscusDatabase : QiscusDatabase{
        get{
            //return QiscusDatabase.init(qiscusCore: self.qiscusCore!)
             return (qiscusCore?.initDB)!
        }
    }
}

extension Participant {
    // create behaviour like active record
    func all() -> [Participant] {
        let fetchRequest:NSFetchRequest<Participant> = Participant.fetchRequest()
        var results = [Participant]()
        var resultsNullData = [Participant]()
        
        do {
            results = try  self.qiscusDatabase.persistenStore.context.fetch(fetchRequest)
            
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
    
    func generate() -> Participant {
        if #available(iOS 10.0, *) {
            let part = Participant(context: qiscusDatabase.persistenStore.context)
            part.qiscusCore = self.qiscusCore
            return part
        } else {
            // Fallback on earlier versions
            let context = qiscusDatabase.persistenStore.context
            let description = NSEntityDescription.entity(forEntityName: "Participant", in: context)
            let participant = Participant(entity: description!, insertInto: context)
            participant.qiscusCore = self.qiscusCore
            return participant
        }
//        self.qiscusCore!._participantPersistens = nil
//        return self.qiscusCore!.participantPersistens
    }
    
    func find(predicate: NSPredicate) -> [Participant]? {
//        PresistentStore.persistentContainer.performBackgroundTask { () in
//
//        }
        let fetchRequest:NSFetchRequest<Participant> = Participant.fetchRequest()
        fetchRequest.predicate = predicate
        do {
            return try  qiscusDatabase.persistenStore.context.fetch(fetchRequest)
        } catch  {
            return nil
        }
    }
    
    /// Clear all Participant data
    func clear() {
        qiscusDatabase.persistenStore.context.perform({
            let fetchRequest:NSFetchRequest<Participant> = Participant.fetchRequest()
            do {
                let delete = NSBatchDeleteRequest(fetchRequest: fetchRequest as! NSFetchRequest<NSFetchRequestResult>)
                try  self.qiscusDatabase.persistenStore.context.execute(delete)
            } catch {
                // failed to clear data
            }
            
        })
        
//        let fetchRequest:NSFetchRequest<Participant> = Participant.fetchRequest()
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

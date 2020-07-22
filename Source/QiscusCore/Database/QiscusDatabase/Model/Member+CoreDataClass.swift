//
//  Member+CoreDataClass.swift
//  QiscusDatabase
//
//  Created by Qiscus on 12/09/18.
//  Copyright © 2018 Qiscus. All rights reserved.
//
//

import Foundation
import CoreData

public class Member: NSManagedObject {

}

extension Member {
    // create behaviour like active record
     static func all() -> [Member] {
        let fetchRequest:NSFetchRequest<Member> = Member.fetchRequest()
        var results = [Member]()
        var resultsNullData = [Member]()
        do {
            results = try  QiscusDatabase.context.fetch(fetchRequest)
            resultsNullData = results.filter{ $0.id == nil }
            
            if resultsNullData.count != 0{
                for i in resultsNullData{
                    //remove null data from sqlite
                    i.remove()
                }
            }
            
             results = results.filter{ $0.id != nil }
        } catch  {
            
        }
        return results
    }
    
     static func generate() -> Member {
        if #available(iOS 10.0, *) {
            return Member(context: QiscusDatabase.context)
        } else {
            // Fallback on earlier versions
            let context = QiscusDatabase.context
            let description = NSEntityDescription.entity(forEntityName: "Member", in: context)
            return Member(entity: description!, insertInto: context)
        }
    }
    
     static func find(predicate: NSPredicate) -> [Member]? {
//        PresistentStore.persistentContainer.performBackgroundTask { () in
//
//        }
        let fetchRequest:NSFetchRequest<Member> = Member.fetchRequest()
        fetchRequest.predicate = predicate
        do {
            return try  QiscusDatabase.context.fetch(fetchRequest)
        } catch  {
            return nil
        }
    }
    
    /// Clear all member data
     static func clear() {
        QiscusDatabase.context.perform({
            let fetchRequest:NSFetchRequest<Member> = Member.fetchRequest()
            do {
                let delete = NSBatchDeleteRequest(fetchRequest: fetchRequest as! NSFetchRequest<NSFetchRequestResult>)
                try  QiscusDatabase.context.execute(delete)
            } catch {
                // failed to clear data
            }
            
        })
        
//        let fetchRequest:NSFetchRequest<Member> = Member.fetchRequest()
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

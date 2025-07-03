//
//  Comment+CoreDataClass.swift
//  QiscusDatabase
//
//  Created by Qiscus on 12/09/18.
//  Copyright © 2018 Qiscus. All rights reserved.
//
//

import Foundation
import CoreData

// @objc(Comment)
 class Comment: NSManagedObject {

}

protocol ActiveRecord {
//    associatedtype T
    associatedtype U
    func all() -> [U]
}

// query
extension Comment {
    // create behaviour like active record
     static func all() -> [Comment] {
         if Thread.isMainThread {
             QiscusCore.eventdelegate?.onDebugEvent("InitQiscus-loadData()", message: "start load comment.ALL() with running in main thread with time \(QiscusLogger.getDateTime())")
         }else{
             QiscusCore.eventdelegate?.onDebugEvent("InitQiscus-loadData()", message: "start load comment.ALL() with running in background thread with time \(QiscusLogger.getDateTime())")
         }
         
        let fetchRequest:NSFetchRequest<Comment> = Comment.fetchRequest()
        var results = [Comment]()
        var resultsNullData = [Comment]()
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
         
         if Thread.isMainThread {
             QiscusCore.eventdelegate?.onDebugEvent("InitQiscus-loadData()", message: "finish load room.ALL() with running in main thread with time \(QiscusLogger.getDateTime())")
         }else{
             QiscusCore.eventdelegate?.onDebugEvent("InitQiscus-loadData()", message: "finish load room.ALL() with running in background thread with time \(QiscusLogger.getDateTime())")
         }
         
        return results
    }
    
     static func generate() -> Comment {
        if #available(iOS 10.0, *) {
            return Comment(context: QiscusDatabase.context)
        } else {
            // Fallback on earlier versions
            let context = QiscusDatabase.context
            let description = NSEntityDescription.entity(forEntityName: "Comment", in: context)
            return Comment(entity: description!, insertInto: context)
        }
    }
    
     static func find(predicate: NSPredicate) -> [Comment]? {
        let fetchRequest:NSFetchRequest<Comment> = Comment.fetchRequest()
        fetchRequest.predicate = predicate
        do {
            return try  QiscusDatabase.context.fetch(fetchRequest)
        } catch  {
            QiscusLogger.errorPrint("comment with predicate \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Clear all comment data
     static func clear() {
         QiscusDatabase.clearALLComment()
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

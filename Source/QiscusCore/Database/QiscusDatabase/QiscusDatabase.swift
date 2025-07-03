//
//  QiscusDatabase.swift
//  QiscusDatabase
//
//  Created by Qiscus on 12/09/18.
//  Copyright © 2018 Qiscus. All rights reserved.
//

import Foundation
import CoreData

class QiscusDatabase {
    class var bundle:Bundle{
        get{
            return QiscusCore.bundle
        }
    }
    
    static let context = PresistentStore.context
   
    static func save() {
        PresistentStore.saveContext()
    }
    
    /// Remove all data from db
    static func clear() {
        PresistentStore.clear()
    }
    
    static func clearALLComment(){
        if #available(iOS 10.0, *) {
            let backgroundContext = PresistentStore.persistentContainer.newBackgroundContext()
            backgroundContext.perform {
                let fetchRequest: NSFetchRequest<NSFetchRequestResult> = Comment.fetchRequest()
                let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

                do {
                    try backgroundContext.execute(deleteRequest)
                    try backgroundContext.save()
                } catch {
                    QiscusLogger.errorPrint("❌ Failed to clear Comment data")
                    QiscusLogger.errorPrint("\(error.localizedDescription)")
                }
            }
        }
    }
}

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
    
    static func clearALLComment() {
        if #available(iOS 10.0, *) {
            let backgroundContext = PresistentStore.persistentContainer.newBackgroundContext()
            backgroundContext.perform {
                let fetchRequest: NSFetchRequest<NSFetchRequestResult> = Comment.fetchRequest()
                let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
                deleteRequest.resultType = .resultTypeObjectIDs

                do {
                    // ✅ PERBAIKAN 1: Execute batch delete
                    let result = try backgroundContext.execute(deleteRequest) as? NSBatchDeleteResult

                    // ✅ PERBAIKAN 2: Save background context dulu
                    try backgroundContext.save()
                    
                    // ✅ PERBAIKAN 3: Merge ke main thread dengan delay
                    if let objectIDs = result?.result as? [NSManagedObjectID] {
                        DispatchQueue.main.async {
                            let changes: [AnyHashable: Any] = [NSDeletedObjectsKey: objectIDs]
                            
                            // ✅ PERBAIKAN 4: Merge ke view context
                            NSManagedObjectContext.mergeChanges(
                                fromRemoteContextSave: changes,
                                into: [PresistentStore.persistentContainer.viewContext]
                            )
                            
                            // ✅ PERBAIKAN 5: Refresh untuk clear fault objects
                            PresistentStore.persistentContainer.viewContext.refreshAllObjects()
                        }
                    }
                    
                    QiscusLogger.debugPrint("✅ Batch delete completed")
                    
                } catch {
                    QiscusLogger.errorPrint("❌ Failed to clear Comment data")
                    QiscusLogger.errorPrint("\(error.localizedDescription)")
                    backgroundContext.rollback()
                }
            }
        }
    }
}

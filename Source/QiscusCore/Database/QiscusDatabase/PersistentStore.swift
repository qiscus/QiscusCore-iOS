//
//  PersistentStore.swift
//  QiscusDatabase
//
//  Created by Qiscus on 12/09/18.
//  Copyright © 2018 Qiscus. All rights reserved.
//

import CoreData

let DB_NAME = "Qiscus"

class PresistentStore {
    let dbName  = "Qiscus"
    
    // MARK: Core Data stack
    private init() {
    }
    
    static var context:NSManagedObjectContext {
        if #available(iOS 10.0, *) {
            return persistentContainer.viewContext
        } else {
            // Fallback on earlier versions
            let context = managedObjectContext
            context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            return context
        }
    }
    
    @available(iOS 10.0, *)
    static var persistentContainer: NSPersistentContainer = {
        if let modelURL = QiscusCore.bundle.url(forResource: DB_NAME, withExtension: "momd") {
            let container = NSPersistentContainer.init(name: DB_NAME, managedObjectModel: NSManagedObjectModel(contentsOf: modelURL)!)
            container.loadPersistentStores(completionHandler: { (storeDescription, error) in
                container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
                if let error = error as NSError? {
                    QiscusLogger.errorPrint("Unresolved error \(error.localizedDescription), \(error.userInfo)")
                }
            })
            return container
        }else{
            let modelURL = Bundle.moduleData.url(forResource: DB_NAME, withExtension: "momd")!
            let container = NSPersistentContainer.init(name: DB_NAME, managedObjectModel: NSManagedObjectModel(contentsOf: modelURL)!)
            container.loadPersistentStores(completionHandler: { (storeDescription, error) in
                container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
                if let error = error as NSError? {
                    QiscusLogger.errorPrint("Unresolved error \(error.localizedDescription), \(error.userInfo)")
                }
            })
            return container
        }
    }()
    
    // iOS 9 and below
    static var applicationDocumentsDirectory: URL = {
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return urls[urls.count-1]
    }()
    
    static var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        if let modelURL = QiscusCore.bundle.url(forResource: DB_NAME, withExtension: "momd"){
            return NSManagedObjectModel(contentsOf: modelURL)!
        }else{
            let modelURL = Bundle.moduleData.url(forResource: DB_NAME, withExtension: "momd")!
            return NSManagedObjectModel(contentsOf: modelURL)!
        }
        
    }()
    
    static var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)
//        let modelURL = QiscusCore.bundle.url(forResource: DB_NAME, withExtension: "momd")!
        let modelURL = applicationDocumentsDirectory.appendingPathComponent("\(DB_NAME).sqlite")
        var failureReason = "There was an error creating or loading the application's saved data."
        do {
            try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: modelURL, options: nil)
        } catch {
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data" as AnyObject?
            dict[NSLocalizedFailureReasonErrorKey] = failureReason as AnyObject?
            
            dict[NSUnderlyingErrorKey] = error as NSError
            let wrappedError = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            NSLog("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
            abort()
        }
        
        return coordinator
    }()
    
    static var managedObjectContext: NSManagedObjectContext = {
        let coordinator = persistentStoreCoordinator
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()
    
    // MARK: Core Data Saving support
    static func saveContext() {
        context.perform {
            guard context.hasChanges else {
                return
            }
            
            do {
                // ✅ Process pending changes
                context.processPendingChanges()
                
                // ✅ Save
                try context.save()
                
            } catch let error as NSError {
                QiscusLogger.errorPrint("❌ Save error: \(error)")
                QiscusLogger.errorPrint("Error domain: \(error.domain)")
                QiscusLogger.errorPrint("Error code: \(error.code)")
                
                // ✅ Rollback
                context.rollback()
                
                // ✅ Log detailed errors
                if let detailedErrors = error.userInfo[NSDetailedErrorsKey] as? [NSError] {
                    for detailError in detailedErrors {
                        QiscusLogger.errorPrint("Detailed error: \(detailError)")
                    }
                }
            }
        }
    }
    
    static func clear() {
        let backgroundContext = PresistentStore.persistentContainer.newBackgroundContext()
            backgroundContext.perform {
                do {
                    // ✅ 1. Fetch semua Room (akan auto-delete Comment via cascade jika di-set di model)
                    let roomFetch: NSFetchRequest<Room> = Room.fetchRequest()
                    let rooms = try backgroundContext.fetch(roomFetch)
                    
                    for room in rooms {
                        backgroundContext.delete(room)
                    }
                    
                    // ✅ 2. Fetch dan delete Member
                    let memberFetch: NSFetchRequest<Member> = Member.fetchRequest()
                    let members = try backgroundContext.fetch(memberFetch)
                    
                    for member in members {
                        backgroundContext.delete(member)
                    }
                    
                    // ✅ 3. Fetch dan delete remaining Comment (jika ada)
                    let commentFetch: NSFetchRequest<Comment> = Comment.fetchRequest()
                    let comments = try backgroundContext.fetch(commentFetch)
                    
                    for comment in comments {
                        backgroundContext.delete(comment)
                    }
                    
                    // ✅ 4. Save
                    try backgroundContext.save()
                    
                    // ✅ 5. Refresh view context
                    DispatchQueue.main.async {
                        PresistentStore.persistentContainer.viewContext.refreshAllObjects()
                        QiscusLogger.debugPrint("✅ All data cleared successfully")
                    }
                    
                } catch {
                    QiscusLogger.errorPrint("❌ Failed to clear data: \(error)")
                    backgroundContext.rollback()
                }
            }
    }
}

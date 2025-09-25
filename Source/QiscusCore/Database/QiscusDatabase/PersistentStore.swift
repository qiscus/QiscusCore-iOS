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
    static func saveContext () {
        // persistentContainer.performBackgroundTask { (_context) in
            context.perform {
                do {
                    if context.hasChanges {
                        try context.save()
                    }else {
                        // QiscusLogger.debugPrint("no changes db")
                    }
                } catch {
                    let saveError = error as NSError
                    QiscusLogger.errorPrint("Unable to Save Changes of Managed Object Context")
                    QiscusLogger.errorPrint("\(saveError), \(saveError.localizedDescription)")
                }
            }
        // }
    }
    
    static func clear() {
        do {
            // Pastikan tidak ada perubahan pending di context
            if context.hasChanges {
                context.reset()
            }

            if #available(iOS 10.0, *) {
                for entity in persistentContainer.managedObjectModel.entities {
                    guard let name = entity.name else { continue }

                    let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: name)
                    let request = NSBatchDeleteRequest(fetchRequest: fetch)
                    request.resultType = .resultTypeObjectIDs

                    // Eksekusi batch delete
                    let result = try context.execute(request) as? NSBatchDeleteResult
                    if let objectIDs = result?.result as? [NSManagedObjectID] {
                        let changes = [NSDeletedObjectsKey: objectIDs]
                        // Merge supaya context tetap konsisten
                        NSManagedObjectContext.mergeChanges(
                            fromRemoteContextSave: changes,
                            into: [context]
                        )
                    }
                }
            } else {
                // Fallback iOS < 10: manual fetch + delete
                for entity in persistentContainer.managedObjectModel.entities {
                    guard let name = entity.name else { continue }
                    let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: name)
                    let objects = try context.fetch(fetch) as? [NSManagedObject] ?? []
                    for obj in objects {
                        context.delete(obj)
                    }
                }
                try context.save()
            }

        } catch {
            let saveError = error as NSError
            QiscusLogger.errorPrint("❌ Unable to clear DB: \(saveError), \(saveError.localizedDescription)")
        }
    }
}

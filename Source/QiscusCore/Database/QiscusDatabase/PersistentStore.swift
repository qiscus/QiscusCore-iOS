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
    var qiscusCore : QiscusCore? = nil
    
    // MARK: Core Data stack
    init(qiscusCore : QiscusCore) {
        self.qiscusCore = qiscusCore
    }
    
    var context:NSManagedObjectContext {
        if #available(iOS 10.0, *) {
            return persistentContainer.viewContext
        } else {
            // Fallback on earlier versions
            let context = modelContext()
            context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            return context
        }
    }
    
    
    @available(iOS 10.0, *)
    var persistentContainer: NSPersistentContainer {
        get{
            if self.qiscusCore!._persistentContainer == nil{
                var modelURL = QiscusCore.bundle.url(forResource: "\(DB_NAME)", withExtension: "momd")!
                 modelURL.appendPathComponent("Qiscus.mom")
                 let container = NSPersistentContainer.init(name: "\(DB_NAME)_\(qiscusCore!.appID)", managedObjectModel: NSManagedObjectModel(contentsOf: modelURL)!)
                
                container.persistentStoreDescriptions.first?.shouldMigrateStoreAutomatically = true
                container.persistentStoreDescriptions.first?.shouldInferMappingModelAutomatically = true
                
                 container.loadPersistentStores(completionHandler: { (storeDescription, error) in
                     container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
                     if let error = error as NSError? {
                         print("Unresolved error \(error.localizedDescription), \(error.userInfo)")
                     }
                 })
                 
                 self.qiscusCore!._persistentContainer = container
                return self.qiscusCore!._persistentContainer!
            }else{
                return self.qiscusCore!._persistentContainer!
            }
        }
    }

    // iOS 9 and below
    var applicationDocumentsDirectory: URL {
        get{
            let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            return urls[urls.count-1]
        }
        
    }
    
    var _model: NSManagedObjectModel?
    
    private var managedObjectModel: NSManagedObjectModel{
        get{
            if _model == nil {
                // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
                let modelURL = QiscusCore.bundle.url(forResource: "\(DB_NAME)_\(qiscusCore!.appID)", withExtension: "momd")!
                _model = NSManagedObjectModel(contentsOf: modelURL)!
            }
            return _model!
        }
    }
    
    var persistentStoreCoordinator: NSPersistentStoreCoordinator {
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)
//        let modelURL = QiscusCore.bundle.url(forResource: DB_NAME, withExtension: "momd")!
        let modelURL = applicationDocumentsDirectory.appendingPathComponent("\(DB_NAME)_\(qiscusCore!.appID).sqlite")
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
    }
    
    var _modelContext: NSManagedObjectContext?
    
    func modelContext() -> NSManagedObjectContext {
        if _modelContext == nil {
            let coordinator = persistentStoreCoordinator
            var managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
            managedObjectContext.persistentStoreCoordinator = coordinator
            _modelContext = managedObjectContext
        }
        return _modelContext!
    }
    
//    var managedObjectContext: NSManagedObjectContext {
//        let coordinator = persistentStoreCoordinator
//        var managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
//        managedObjectContext.persistentStoreCoordinator = coordinator
//        return managedObjectContext
//    }
//
    // MARK: Core Data Saving support
    func saveContext () {
        // persistentContainer.performBackgroundTask { (_context) in
            context.perform {
                do {
                    if self.context.hasChanges {
                        try self.context.save()
                    }else {
                        // QiscusLogger.debugPrint("no changes db")
                    }
                } catch {
                    let saveError = error as NSError
                    print("Unable to Save Changes of Managed Object Context")
                    print("\(saveError), \(saveError.localizedDescription)")
                }
            }
        // }
    }
    
    func clear() {
        do {
            if #available(iOS 10.0, *) {
                try persistentContainer.persistentStoreCoordinator.managedObjectModel.entities.forEach({ (entity) in
                    if let name = entity.name {
                        let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: name)
                        let request = NSBatchDeleteRequest(fetchRequest: fetch)
                        try context.execute(request)
                    }
                })
            } else {
                // Fallback on earlier versions
            }
            try context.save()
        } catch {
            let saveError = error as NSError
            print("Unable to clear DB")
            print("\(saveError), \(saveError.localizedDescription)")
        }
    }
}

extension NSManagedObject {
    convenience init(context: NSManagedObjectContext) {
        let name = String(describing: type(of: self))
        let entity = NSEntityDescription.entity(forEntityName: name, in: context)!
        self.init(entity: entity, insertInto: context)
    }

}

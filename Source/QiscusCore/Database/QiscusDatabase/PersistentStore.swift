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
    
    static var context: NSManagedObjectContext {
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
                // ✅ Set merge policy
                container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
                
                // ✅ Auto merge changes from parent
                container.viewContext.automaticallyMergesChangesFromParent = true
                
                // ✅ Add observer untuk merge changes
                NotificationCenter.default.addObserver(
                    forName: .NSManagedObjectContextDidSave,
                    object: nil,
                    queue: nil
                ) { notification in
                    guard let context = notification.object as? NSManagedObjectContext,
                          context != container.viewContext else { return }
                    
                    container.viewContext.perform {
                        container.viewContext.mergeChanges(fromContextDidSave: notification)
                    }
                }
                
                if let error = error as NSError? {
                    QiscusLogger.errorPrint("Unresolved error \(error.localizedDescription), \(error.userInfo)")
                }
            })
            return container
            
        } else {
            let modelURL = Bundle.moduleData.url(forResource: DB_NAME, withExtension: "momd")!
            let container = NSPersistentContainer.init(name: DB_NAME, managedObjectModel: NSManagedObjectModel(contentsOf: modelURL)!)
            
            container.loadPersistentStores(completionHandler: { (storeDescription, error) in
                // ✅ Set merge policy
                container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
                
                // ✅ Auto merge changes from parent
                container.viewContext.automaticallyMergesChangesFromParent = true
                
                // ✅ Add observer untuk merge changes
                NotificationCenter.default.addObserver(
                    forName: .NSManagedObjectContextDidSave,
                    object: nil,
                    queue: nil
                ) { notification in
                    guard let context = notification.object as? NSManagedObjectContext,
                          context != container.viewContext else { return }
                    
                    container.viewContext.perform {
                        container.viewContext.mergeChanges(fromContextDidSave: notification)
                    }
                }
                
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
    
//    // MARK: Core Data Saving support
//    static func saveContext() {
//        context.perform {
//            guard context.hasChanges else {
//                return
//            }
//            
//            do {
//                // ✅ Process pending changes
//                context.processPendingChanges()
//                
//                // ✅ Save
//                try context.save()
//                
//            } catch let error as NSError {
//                QiscusLogger.errorPrint("❌ Save error: \(error)")
//                QiscusLogger.errorPrint("Error domain: \(error.domain)")
//                QiscusLogger.errorPrint("Error code: \(error.code)")
//                
//                // ✅ Rollback
//                context.rollback()
//                
//                // ✅ Log detailed errors
//                if let detailedErrors = error.userInfo[NSDetailedErrorsKey] as? [NSError] {
//                    for detailError in detailedErrors {
//                        QiscusLogger.errorPrint("Detailed error: \(detailError)")
//                    }
//                }
//            }
//        }
//    }
    
    // MARK: Core Data Saving support
    static func saveContext() {
        context.perform {
            guard context.hasChanges else {
                return
            }
            
            do {
                // ✅ 1. Process pending changes FIRST
                context.processPendingChanges()
                
                // ✅ 2. Validate all objects BEFORE save
                try validateAllObjects()
                
                // ✅ 3. Clean up relationships
                cleanupRelationships()
                
                // ✅ 4. Validate again after cleanup
                context.processPendingChanges()
                
                // ✅ 5. Try to save
                try context.save()
                
                QiscusLogger.debugPrint("✅ Context saved successfully")
                
            } catch let validationError as NSError where validationError.domain == NSCocoaErrorDomain {
                // ✅ Handle validation errors
                handleValidationError(validationError)
                
            } catch let error as NSError {
                // ✅ Handle other errors
                handleSaveError(error)
            }
        }
    }

    // ✅ Validate all objects
    private static func validateAllObjects() throws {
        let allObjects = context.insertedObjects
            .union(context.updatedObjects)
            .union(context.deletedObjects)
        
        var validationErrors: [Error] = []
        
        for object in allObjects {
            guard !object.isFault, !object.isDeleted else { continue }
            
            // ✅ Validate each property individually untuk catch specific errors
            do {
                try object.validateForUpdate()
            } catch let error as NSError {
                QiscusLogger.errorPrint("❌ Validation failed for \(object.entity.name ?? "unknown"): \(error)")
                
                // ✅ Collect errors instead of throwing immediately
                validationErrors.append(error)
                
                // ✅ Try to fix common issues
                if error.code == NSValidationMissingMandatoryPropertyError {
                    // Handle missing required property
                    if let key = error.userInfo[NSValidationKeyErrorKey] as? String {
                        QiscusLogger.errorPrint("  Missing required property: \(key)")
                        // Optionally set default value
                    }
                }
            }
        }
        
        // ✅ If there were validation errors, throw the first one
        if let firstError = validationErrors.first {
            throw firstError
        }
    }

    // ✅ Clean up relationships
    private static func cleanupRelationships() {
        let allObjects = context.insertedObjects.union(context.updatedObjects)
        
        for object in allObjects {
            guard !object.isFault, !object.isDeleted else { continue }
            
            let entity = object.entity
            
            // Check to-many relationships
            for (name, relationship) in entity.relationshipsByName where relationship.isToMany {
                guard let relatedSet = object.value(forKey: name) as? NSSet else {
                    QiscusLogger.debugPrint("⚠️ Relationship '\(name)' is not NSSet")
                    continue
                }
                
                // Filter out deleted/invalid objects
                let validObjects = relatedSet.filter { obj in
                    guard let managedObj = obj as? NSManagedObject else { return false }
                    return !managedObj.isDeleted && managedObj.managedObjectContext != nil
                }
                
                // Update if different
                if validObjects.count != relatedSet.count {
                    QiscusLogger.debugPrint("🧹 Cleaned relationship '\(name)' in \(entity.name ?? "unknown")")
                    object.setValue(NSSet(array: Array(validObjects)), forKey: name)
                }
            }
            
            // Check to-one relationships
            for (name, relationship) in entity.relationshipsByName where !relationship.isToMany {
                guard let relatedObject = object.value(forKey: name) as? NSManagedObject else { continue }
                
                // Remove if deleted or invalid
                if relatedObject.isDeleted || relatedObject.managedObjectContext == nil {
                    QiscusLogger.debugPrint("🧹 Removed invalid relationship '\(name)' in \(entity.name ?? "unknown")")
                    object.setValue(nil, forKey: name)
                }
            }
        }
    }

    // ✅ Handle validation errors
    private static func handleValidationError(_ error: NSError) {
        QiscusLogger.errorPrint("❌ Validation error: \(error)")
        QiscusLogger.errorPrint("Error code: \(error.code)")
        
        // Log which object failed
        if let object = error.userInfo[NSValidationObjectErrorKey] as? NSManagedObject {
            QiscusLogger.errorPrint("Failed object: \(object.entity.name ?? "unknown")")
            QiscusLogger.errorPrint("Object: \(object)")
        }
        
        // Log which property failed
        if let key = error.userInfo[NSValidationKeyErrorKey] as? String {
            QiscusLogger.errorPrint("Failed property: \(key)")
        }
        
        // Log validation value
        if let value = error.userInfo[NSValidationValueErrorKey] {
            QiscusLogger.errorPrint("Failed value: \(value)")
        }
        
        // ✅ Rollback
        context.rollback()
    }

    // ✅ Handle save errors
    private static func handleSaveError(_ error: NSError) {
        QiscusLogger.errorPrint("❌ Save error: \(error)")
        QiscusLogger.errorPrint("Error domain: \(error.domain)")
        QiscusLogger.errorPrint("Error code: \(error.code)")
        QiscusLogger.errorPrint("Error description: \(error.localizedDescription)")
        
        // ✅ Log detailed errors
        if let detailedErrors = error.userInfo[NSDetailedErrorsKey] as? [NSError] {
            for (index, detailError) in detailedErrors.enumerated() {
                QiscusLogger.errorPrint("Detailed error \(index): \(detailError)")
                QiscusLogger.errorPrint("  Domain: \(detailError.domain)")
                QiscusLogger.errorPrint("  Code: \(detailError.code)")
                
                // Check for constraint violations
                if detailError.code == 133021 { // NSValidationMultipleErrorsError
                    QiscusLogger.errorPrint("  ⚠️ Multiple validation errors")
                } else if detailError.code == 1550 { // NSManagedObjectConstraintMergeError
                    QiscusLogger.errorPrint("  ⚠️ Constraint merge conflict")
                }
            }
        }
        
        // ✅ Rollback
        context.rollback()
        
        // ✅ Optionally refresh objects
        context.refreshAllObjects()
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

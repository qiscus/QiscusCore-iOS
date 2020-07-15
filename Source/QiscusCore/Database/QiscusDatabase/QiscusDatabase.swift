//
//  QiscusDatabase.swift
//  QiscusDatabase
//
//  Created by Qiscus on 12/09/18.
//  Copyright © 2018 Qiscus. All rights reserved.
//

import Foundation

class QiscusDatabase {
    var qiscusCore : QiscusCore? = nil
    class var bundle:Bundle{
        get{
            return QiscusCore.bundle
        }
    }
    
    init(qiscusCore : QiscusCore){
        self.qiscusCore = qiscusCore
    }
    
    var persistenStore : PresistentStore{
        get{
            let persistent = PresistentStore.init(qiscusCore: self.qiscusCore!)
            return persistent
        }
       
    }
//
//    var context: ManagedObjectContext {
//        get{
//            return self.persistenStore.context
//        }
//
//    }
   
    func save() {
        persistenStore.saveContext()
    }
    
    /// Remove all data from db
    func clear() {
        persistenStore.clear()
    }
}

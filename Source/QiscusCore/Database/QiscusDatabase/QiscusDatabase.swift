//
//  QiscusDatabase.swift
//  QiscusDatabase
//
//  Created by Qiscus on 12/09/18.
//  Copyright © 2018 Qiscus. All rights reserved.
//

import Foundation

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
}

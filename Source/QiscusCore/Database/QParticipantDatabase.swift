//
//  MemberDatabase.swift
//  QiscusCore
//
//  Created by Qiscus on 13/09/18.
//

import Foundation
import CoreData

class QParticipantDatabase {
    var qiscusCore: QiscusCore? = nil
    
    var participantStore: Participant{
//        if #available(iOS 10.0, *) {
//            let part = Participant(context:  QiscusDatabase.init(qiscusCore: self.qiscusCore!).persistenStore.context)
//            part.qiscusCore = self.qiscusCore
//            return part
//        } else {
//            // Fallback on earlier versions
//            let context =  QiscusDatabase.init(qiscusCore: self.qiscusCore!).persistenStore.context
//            let description = NSEntityDescription.entity(forEntityName: "Room", in: context)
//            let part = Participant(entity: description!, insertInto: context)
//            part.qiscusCore = self.qiscusCore
//            return part
//        }
        
        get{
            return self.qiscusCore!.participantPersistens
        }
        
    }
    
    var delegate : QiscusCoreDelegate{
        get{
            return (qiscusCore?.delegate)!
        }
    }
    
    init(qiscusCore : QiscusCore) {
        // MARK: TODO load data rooms from local storage to var data
        self.qiscusCore = qiscusCore
        
    }
    
    func loadData() {
        self.qiscusCore?.dataDBQParticipant = loadFromLocal()
    }
    
    func removeAll() {
        self.qiscusCore?.dataDBQParticipant.removeAll()
        self.clearDB()
    }
    
    func all() -> [QParticipant] {
        self.qiscusCore?.dataDBQParticipant = loadFromLocal()
        return self.qiscusCore!.dataDBQParticipant
    }
    
    func add(_ value: [QParticipant], inRoom room: Room) {
        // filter if room exist update, if not add
        for m in value {
            if let r = find(byID: m.id)  {
                if !updateMemberDataEvent(old: r, new: m, inRoom: room) {
                    // add new room
                    self.qiscusCore?.dataDBQParticipant.append(m)
                }
            }else {
                // add new room
                self.qiscusCore?.dataDBQParticipant.append(m)
                save(m, inRoom: room)
            }
        }
    }
    
    // update/replace === identical object
    private func updateMemberDataEvent(old: QParticipant, new: QParticipant, inRoom room: Room) -> Bool{
        if let index = self.qiscusCore?.dataDBQParticipant.index(where: { $0 === old }) {
            self.qiscusCore?.dataDBQParticipant[index] = new
            save(new, inRoom: room)
            return true
        }else {
            return false
        }
    }
    
    func find(byID id: String) -> QParticipant? {
        if self.qiscusCore!.dataDBQParticipant.isEmpty {
            return nil
        }else {
            return self.qiscusCore?.dataDBQParticipant.filter{ $0.id == id }.first
        }
    }
    
    func find(byEmail id: String) -> QParticipant? {
        if self.qiscusCore!.dataDBQParticipant.isEmpty {
            self.qiscusCore?.dataDBQParticipant = self.all()
        }
        
        if self.qiscusCore!.dataDBQParticipant.isEmpty {
            return nil
        }else {
            return self.qiscusCore?.dataDBQParticipant.filter{ $0.id == id }.first
        }
    }

}

// MARK: Local Database
extension QParticipantDatabase {
    func find(predicate: NSPredicate) -> [QParticipant]? {
        guard let members = participantStore.find(predicate: predicate) else { return nil}
        var results = [QParticipant]()
        for r in members {
            results.append(map(r))
        }
        return results
    }
    
    func clearDB() {
        participantStore.clear()
    }
    
    func save(_ data: QParticipant, inRoom room: Room) {
        // create new in db with relations
        let _member = self.map(data)
        _member.addToRooms(room)
        
        if let db = participantStore.find(predicate: NSPredicate(format: "id = %@", data.id))?.first {
            let _comment = map(data, data: db) // update value
            _comment.qiscusCore = self.qiscusCore
            _comment.update() // save to db
        }
    }
    
    func loadFromLocal() -> [QParticipant] {
        var results = [QParticipant]()
        let db = participantStore.all()
        
        for member in db {
            let _member = map(member)
            results.append(_member)
        }
        return results
    }
    
    /// create or update db object
    ///
    /// - Parameters:
    ///   - core: core model
    ///   - data: db model, if exist just update falue
    /// - Returns: db object
    internal func map(_ core: QParticipant, data: Participant? = nil) -> Participant {
        var result : Participant
        if let _result = data {
            result = _result // Update data
        }else {
             if let db = participantStore.find(predicate: NSPredicate(format: "id = %@", core.id))?.first {
                 result = db
             }else{
                // prepare create new
                result = participantStore.generate()
            }
        }
        QiscusThread.background {
            result.id           = core.id
            result.avatarUrl    = core.avatarUrl?.absoluteString
            result.email        = core.id
            result.username     = core.name
            result.lastCommentReadId        = Int64(core.lastMessageReadId)
            result.lastCommentReceivedId    = Int64(core.lastMessageDeliveredId)
        }
        return result
    }
    
    internal func map(_ member: Participant) -> QParticipant {
        let result = QParticipant()
        // check record data
        guard let id = member.id else { return result }
        guard let name = member.username else { return result }
        guard let email = member.email else { return result }
        guard let avatarUrl = member.avatarUrl else { return result }
        QiscusThread.background {
            result.id                       = id
            result.name                     = name
            result.id                       = email
            result.avatarUrl                = URL(string: avatarUrl)
            result.lastMessageDeliveredId   = Int(member.lastCommentReceivedId)
            result.lastMessageReadId        = Int(member.lastCommentReadId)
        }
        return result
    }
}

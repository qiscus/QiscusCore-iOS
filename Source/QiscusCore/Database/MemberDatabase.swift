//
//  MemberDatabase.swift
//  QiscusCore
//
//  Created by Qiscus on 13/09/18.
//

import Foundation

class MemberDatabase {
    private var data : [MemberModel] = [MemberModel]()
    var delegate = QiscusCore.eventManager.delegate
    
    init() {
        // MARK: TODO load data rooms from local storage to var data
        
    }
    
    func loadData() {
        self.data = loadFromLocal()
    }
    
    func removeAll() {
        data.removeAll()
        self.clearDB()
    }
    
    func all() -> [MemberModel] {
        return data
    }
    
    func add(_ value: [MemberModel], inRoom room: Room) {
        // filter if room exist update, if not add
        for m in value {
            if let r = find(byID: m.id)  {
                if !updateMemberDataEvent(old: r, new: m, inRoom: room) {
                    // add new room
                    data.append(m)
                }
            }else {
                // add new room
                data.append(m)
                save(m, inRoom: room)
            }
        }
    }
    
    // update/replace === identical object
    private func updateMemberDataEvent(old: MemberModel, new: MemberModel, inRoom room: Room) -> Bool{
        if let index = data.index(where: { $0 === old }) {
            data[index] = new
            save(new, inRoom: room)
            return true
        }else {
            return false
        }
    }
    
    func find(byID id: String) -> MemberModel? {
        if data.isEmpty {
            return nil
        }else {
            return data.filter{ $0.id == id }.first
        }
    }
    
    func find(byEmail id: String) -> MemberModel? {
        if data.isEmpty {
            return nil
        }else {
            return data.filter{ $0.email == id }.first
        }
    }

}

// MARK: Local Database
extension MemberDatabase {
    func find(predicate: NSPredicate) -> [MemberModel]? {
        guard let members = Member.find(predicate: predicate) else { return nil}
        var results = [MemberModel]()
        for r in members {
            results.append(map(r))
        }
        return results
    }
    
    func clearDB() {
        Member.clear()
    }
    
    func save(_ data: MemberModel, inRoom room: Room) {
        // create new in db with relations
        let _member = self.map(data)
        _member.addToRooms(room)
        
        if let db = Member.find(predicate: NSPredicate(format: "id = %@", data.id))?.first {
            let _comment = map(data, data: db) // update value
            _comment.update() // save to db
        }
    }
    
    func loadFromLocal() -> [MemberModel] {
        var results = [MemberModel]()
        let db = Member.all()
        
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
    internal func map(_ core: MemberModel, data: Member? = nil) -> Member {
        var result : Member
        if let _result = data {
            result = _result // Update data
        }else {
            result = Member.generate() // prepare create new
        }
        QiscusThread.background {
            result.id           = core.id
            result.avatarUrl    = core.avatarUrl?.absoluteString
            result.email        = core.email
            result.username     = core.username
            result.lastCommentReadId        = Int64(core.lastCommentReadId)
            result.lastCommentReceivedId    = Int64(core.lastCommentReceivedId)
            
            if let extras = core.extras {
                result.extras   = extras.dict2json()
            }
        }
        return result
    }
    
    internal func map(_ member: Member) -> MemberModel {
        let result = MemberModel()
        // check record data
        guard let id = member.id else { return result }
        guard let name = member.username else { return result }
        guard let email = member.email else { return result }
        guard let avatarUrl = member.avatarUrl else { return result }
        QiscusThread.background {
            result.id            = id
            result.username      = name
            result.email         = email
            result.avatarUrl     = URL(string: avatarUrl)
            result.lastCommentReceivedId    = Int(member.lastCommentReceivedId)
            result.lastCommentReadId        = Int(member.lastCommentReadId)
            
            if let _extras = member.extras {
                result.extras          = self.convertToDictionary(from: _extras)
            }else {
                result.extras          = nil
            }
        }
        return result
    }
    
    private func convertToDictionary(from text: String) -> [String: Any]? {
           guard let data = text.data(using: .utf8) else { return nil }
           let anyResult = try? JSONSerialization.jsonObject(with: data, options: [])
           return anyResult as? [String: Any]
       }
}

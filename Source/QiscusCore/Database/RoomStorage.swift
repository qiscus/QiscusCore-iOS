//
//  RoomStorage.swift
//  QiscusCore
//
//  Created by Qiscus on 16/08/18.
//
//  Responsiblilities :
//  save room from restAPI in temp(variable)
//  save room in local storage
//  get rooms from local storage

import Foundation

class RoomStorage {
    private var data : [RoomModel] = [RoomModel]()
    var delegate = QiscusCore.eventManager.delegate

    init() {
        // MARK: TODO load data rooms from local storage to var data
    }
    
    func loadData() {
        let local = loadFromLocal()
        data = sort(local)
    }
    
    func removeAll() {
        data.removeAll()
        self.clearDB()
    }
    
    func all() -> [RoomModel] {
        return data
    }
    
    func add(_ value: [RoomModel]) {
        // filter if room exist update, if not add
        for room in value {
            if let r = find(byID: room.id)  {
                if r.id.isEmpty || room.id == nil || room.id == "0" {
                    return
                }
                if !updateRoomDataEvent(old: r, new: room) {
                    // add new room
                    data.append(room)
                    data = sort(data)
                    // publish event add new room
                    QiscusEventManager.shared.roomNew(room: room)
                }
                
                QiscusLogger.debugDBPrint("save or update room with roomId = \(room.id)")
            }else {
                if room.id.isEmpty || room.id == nil || room.id == "0" {
                    return
                }
                // add new room
                data.append(room)
                save(room)
                data = sort(data)
                // publish event add new room
                QiscusEventManager.shared.roomNew(room: room)
                
                QiscusLogger.debugDBPrint("save or update room with roomId = \(room.id)")
            }
        }
    }
    
    // update/replace === identical object
    /// Update or replace room object from array then save to db
    ///
    /// - Parameters:
    ///   - old: old room object
    ///   - new: new room object
    /// - Returns: return true if room exist
    private func updateRoomDataEvent(old: RoomModel, new: RoomModel) -> Bool{
        if let index = data.index(where: { $0 === old }) {
            data[index] = new
            save(new)
            return true
        }else {
            return false
        }
    }
    
    func delete(byID id: String) -> Bool {
        // remove from memory
        if let index = self.data.index(where: {$0.id == id}) {
            data.remove(at: index)
        }else {
            return false
        }
        
        // remove from db
        if let db = Room.find(predicate: NSPredicate(format: "id = %@", id))?.first {
            db.remove()
        }else {
            return false
        }
        
        QiscusLogger.debugDBPrint("delete room for roomId = \(id)")
        return true
    }
    
    func find(byID id: String) -> RoomModel? {
        if data.isEmpty {
            return nil
        }else {
            return data.filter{ $0.id == id }.first
        }
    }
    
    func find(byUniqID id: String) -> RoomModel? {
        if data.isEmpty {
            return nil
        }else {
            return data.filter{ $0.uniqueId == id }.first
        }
    }
    
    // MARK: TODO Sorting not work
    func sort(_ data: [RoomModel]) -> [RoomModel]{
        var result = data
        result.sort { (room1, room2) -> Bool in
            if let comment1 = room1.lastComment, let comment2 = room2.lastComment {
                return comment1.unixTimestamp > comment2.unixTimestamp
            }else {
                return false
            }
        }
        return result
    }
    
    /// Update last comment in room
    ///
    /// - Parameter comment: new comment object
    /// - Returns: true if room already exist and false if room unavailable
    func updateLastComment(_ comment: CommentModel) -> Bool {
        if let r = find(byID: String(comment.roomId)) {
            guard let lastComment = r.lastComment else {
                //room already exist, but lastComment is nil
                //need save comment to update lastComment from nil
                return replaceLastComment(in: r, with: comment)
            }
            // check uniqtimestamp if nil, assume new comment from your
            if comment.unixTimestamp > lastComment.unixTimestamp {
                return replaceLastComment(in: r, with: comment)
            }else { return false }
        }else { return false }
    }
    
    private func replaceLastComment(in room: RoomModel, with comment: CommentModel) -> Bool {
        let new = room
        new.lastComment = comment
        // check if myComment
        if let user = QiscusCore.getProfile() {
            if comment.userEmail != user.email {
                new.unreadCount = new.unreadCount + 1
            }
        }
        // check data exist and update
        let isUpdate = updateRoomDataEvent(old: room, new: new)
        data = sort(data) // check data source
        return isUpdate
    }

    
    /// Update unread count -1 to read
    ///
    /// - Parameter comment: new comment object already read
    /// - Returns: true if room already exist and false if room unavailable
    func updateUnreadComment(_ comment: CommentModel) -> Bool {
        if let currentRoom = find(byID: String(comment.roomId)) {
            let newRoom = currentRoom
            newRoom.unreadCount = 0
            return updateRoomDataEvent(old: currentRoom, new: newRoom)
        }else {
            return false
        }
    }
}

// MARK: Local Database
extension RoomStorage {
    func find(predicate: NSPredicate) -> [RoomModel]? {
        guard let rooms = Room.find(predicate: predicate) else { return nil}
        var results = [RoomModel]()
        for r in rooms {
            results.append(map(r))
        }
        return results
    }
    
    func find(limit : Int, offset : Int) -> [RoomModel]? {
           guard let rooms = Room.find(limit: limit, offset: offset) else { return nil}
           var results = [RoomModel]()
           for r in rooms {
               results.append(map(r))
           }
           return results
       }
    
    func clearDB() {
        Room.clear()
        QiscusLogger.debugDBPrint("delete all rooms from DB")
    }
    
    private func save(_ data: RoomModel) {
        if let db = Room.find(predicate: NSPredicate(format: "id = %@", data.id))?.first {
            let _room = map(data, data: db) // update value
            _room.update() // save to db
        }else {
            // save new room
            let _room = self.map(data)
            _room.save()
            // get last comment and save to comment db
            if let comment = data.lastComment {
                CommentStorage().save(comment)
            }
        }
    }
    
    private func loadFromLocal() -> [RoomModel] {
        var results = [RoomModel]()
        let roomsdb = Room.all()
        
        if roomsdb.count != 0{
            for room in roomsdb {
                let _room = map(room)
                if _room.id == "" || _room.id.isEmpty || _room.id == "0"{
                    room.remove()
                } else {
                    results.append(_room)
                }
            }
        }
        
        return results
    }
    
    /// create or update db object
    ///
    /// - Parameters:
    ///   - core: core model
    ///   - data: db model, if exist just update falue
    /// - Returns: db object
    internal func map(_ core: RoomModel, data: Room? = nil) -> Room {
        var result : Room
        if let _result = data {
            result = _result // Update data
        }else {
            result = Room.generate() // prepare create new
        }
        result.id            = core.id
        result.uniqueId      = core.uniqueId
        result.unreadCount   = Int16(core.unreadCount)
        result.name          = core.name
        result.avatarUrl     = core.avatarUrl?.absoluteString ?? ""
        result.options       = core.options
        result.lastCommentId    = core.lastComment?.id
        result.type          = core.type.rawValue
        // participants
        if let participants = core.participants {
            for p in participants {
                let member = QiscusCore.database.member.map(p)
                result.addToMembers(member)
            }
        }
        return result
    }
    
    private func map(_ room: Room) -> RoomModel {
        let result = RoomModel()
        // check record data
        if let id = room.id {
            result.id            = id
        }
        
        if let uniqueId = room.uniqueId {
            result.uniqueId      = uniqueId
        }
        
        if let name = room.name {
            result.name          = name
        }
        
        result.unreadCount   = Int(room.unreadCount)
        
        result.options       = room.options
        
        if let avatarUrl = room.avatarUrl{
            result.avatarUrl     = URL(string: avatarUrl)
        }
        
        guard let type = room.type else {
            return result
        }
        // room type
        for t in RoomType.all {
            if type == t.rawValue {
                result.type = t
            }
        }
        
        // MARK: TODO get participants
        result.participants = [MemberModel]()
        for p in room.members! {
            let _member = p as! Member
            if let memberModel = QiscusCore.database.member.find(byEmail: _member.email ?? "") {
                result.participants?.append(memberModel)
            }
        }
        
        
        guard let lastCommentid = room.lastCommentId else { return result }
        // check comment
        result.lastComment   = QiscusCore.database.comment.find(id: lastCommentid)
        
        return result
    }
}

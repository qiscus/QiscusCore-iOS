//
//  QChatRoomStorage.swift
//  QiscusCore
//
//  Created by Qiscus on 16/08/18.
//
//  Responsiblilities :
//  save room from restAPI in temp(variable)
//  save room in local storage
//  get rooms from local storage

import Foundation
import CoreData

class QChatRoomStorage {
    var qiscusCore: QiscusCore? = nil
    
    var roomStore: Room{
        get{
//            if #available(iOS 10.0, *) {
//                let room = Room(context:  QiscusDatabase.init(qiscusCore: self.qiscusCore!).persistenStore.context)
//                room.qiscusCore = self.qiscusCore
//                return room
//            } else {
//                // Fallback on earlier versions
//                let context =  QiscusDatabase.init(qiscusCore: self.qiscusCore!).persistenStore.context
//                let description = NSEntityDescription.entity(forEntityName: "Room", in: context)
//                let room = Room(entity: description!, insertInto: context)
//                room.qiscusCore = self.qiscusCore
//                return room
//            }
            return self.qiscusCore!.roomPersistens
        }
        
    }
    
    
    var delegate : QiscusCoreDelegate{
        get{
            return (qiscusCore?.delegate)!
        }
    }

    init(qiscusCore : QiscusCore) {
        self.qiscusCore = qiscusCore
        // MARK: TODO load data rooms from local storage to var data
    }
    
    func loadData() {
        let local = loadFromLocal()
        if local.count != 0{
            self.qiscusCore?.dataDBQChatRoom = sort(local)
        }else{
            self.qiscusCore?.dataDBQChatRoom = local
        }
    }
    
    func removeAll() {
        var allDBCore = [QChatRoom]()
        if let data = self.qiscusCore?.dataDBQChatRoom{
            for room in data {
                let roomDeleted = self.delete(byID: room.id)
                if roomDeleted == false{
                    qiscusCore?.qiscusLogger.debugPrint("failed to delete room =\(room.id)")
                    allDBCore.append(room)
                }
            }

            if allDBCore.count != 0 {
                self.qiscusCore?.dataDBQChatRoom = sort(allDBCore)
            }
        }
    }
    
    func all() -> [QChatRoom] {
        let local = loadFromLocal()
        if local.count != 0{
             self.qiscusCore?.dataDBQChatRoom = sort(local)
        }else{
             self.qiscusCore?.dataDBQChatRoom = local
        }
       
        return self.qiscusCore!.dataDBQChatRoom
    }
    
    func add(_ value: [QChatRoom]) {
        // filter if room exist update, if not add
        for room in value {
            let room = room
            if let r = find(byID: room.id)  {
                if r.id.isEmpty || room.id == nil || room.id == "0" {
                    return
                }
                if !updateRoomDataEvent(old: r, new: room) {
                    // add new room
                    self.qiscusCore?.dataDBQChatRoom.append(room)
                    self.qiscusCore?.dataDBQChatRoom = sort(self.qiscusCore!.dataDBQChatRoom)
                    // publish event add new room
                    self.qiscusCore?.eventManager.roomNew(room: room)
                }
                
                self.qiscusCore?.qiscusLogger.debugDBPrint("save or update room with roomId = \(room.id)")
            }else {
                if room.id.isEmpty || room.id == nil || room.id == "0" {
                    return
                }
                // add new room
                self.qiscusCore?.dataDBQChatRoom.append(room)
                save(room)
                self.qiscusCore?.dataDBQChatRoom = sort(self.qiscusCore!.dataDBQChatRoom)
                // publish event add new room
                self.qiscusCore?.eventManager.roomNew(room: room)
                
                self.qiscusCore?.qiscusLogger.debugDBPrint("save or update room with roomId = \(room.id)")
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
    private func updateRoomDataEvent(old: QChatRoom, new: QChatRoom) -> Bool{
        if let index = self.qiscusCore?.dataDBQChatRoom.index(where: { $0 === old }) {
            self.qiscusCore?.dataDBQChatRoom[index] = new
            save(new)
            return true
        }else {
            return false
        }
    }
    
    func delete(byID id: String) -> Bool {
        // remove from memory
        if let index = self.qiscusCore?.dataDBQChatRoom.index(where: {$0.id == id}) {
            self.qiscusCore?.dataDBQChatRoom.remove(at: index)
        }else {
            return false
        }
        
        // remove from db
        if let db = roomStore.find(predicate: NSPredicate(format: "id = %@", id))?.first {
            db.qiscusCore = self.qiscusCore
            db.remove()
        }else {
            return false
        }
        
        self.qiscusCore?.qiscusLogger.debugDBPrint("delete room for roomId = \(id)")
        return true
    }
    
    func find(byID id: String) -> QChatRoom? {
        if self.qiscusCore!.dataDBQChatRoom.isEmpty {
            return nil
        }else {
            return self.qiscusCore?.dataDBQChatRoom.filter{ $0.id == id }.first
        }
    }
    
    func find(byUniqID id: String) -> QChatRoom? {
        if self.qiscusCore!.dataDBQChatRoom.isEmpty {
            return nil
        }else {
            return self.qiscusCore?.dataDBQChatRoom.filter{ $0.uniqueId == id }.first
        }
    }
    
    // MARK: TODO Sorting not work
    func sort(_ data: [QChatRoom]) -> [QChatRoom]{
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
    func updateLastComment(_ comment: QMessage) -> Bool {
        if let r = find(byID: String(comment.chatRoomId)) {
            guard let lastComment = r.lastComment else {
                //room already exist, but lastComment is nil
                //need save comment to update lastComment from nil
                return replaceLastComment(in: r, with: comment)
            }
            // check uniqtimestamp if nil, assume new comment from your
            if comment.unixTimestamp > lastComment.unixTimestamp {
                return replaceLastComment(in: r, with: comment)
            }else {
                return false
            }
        }else {
            return false
        }
    }
    
    private func replaceLastComment(in room: QChatRoom, with comment: QMessage) -> Bool {
        let new = room
        new.lastComment = comment
        // check if myComment
        if let user = self.qiscusCore?.getProfile() {
            if comment.userEmail != user.id {
                new.unreadCount = new.unreadCount + 1
            }
        }
        // check data exist and update
        let isUpdate = updateRoomDataEvent(old: room, new: new)
        self.qiscusCore?.dataDBQChatRoom = sort(self.qiscusCore!.dataDBQChatRoom) // check data source
        return isUpdate
    }

    
    /// Update unread count -1 to read
    ///
    /// - Parameter comment: new comment object already read
    /// - Returns: true if room already exist and false if room unavailable
    func updateUnreadComment(_ comment: QMessage) -> Bool {
        if let currentRoom = find(byID: String(comment.chatRoomId)) {
            let newRoom = currentRoom
            newRoom.unreadCount = 0
            return updateRoomDataEvent(old: currentRoom, new: newRoom)
        }else {
            return false
        }
    }
}

// MARK: Local Database
extension QChatRoomStorage {
    func find(predicate: NSPredicate) -> [QChatRoom]? {
        guard let rooms = roomStore.find(predicate: predicate) else { return nil}
        var results = [QChatRoom]()
        for r in rooms {
            results.append(map(r))
        }
        return results
    }
    
    func clearDB() {
        roomStore.clear()
        self.qiscusCore?.qiscusLogger.debugDBPrint("delete all rooms from DB")
    }
    
    private func save(_ data: QChatRoom) {
        if let db = roomStore.find(predicate: NSPredicate(format: "id = %@", data.id))?.first {
            let _room = map(data, data: db) // update value
            _room.qiscusCore = self.qiscusCore
            _room.update() // save to db
        }else {
            // save new room
            let _room = self.map(data)
            _room.qiscusCore = self.qiscusCore
            _room.save()
            // get last comment and save to comment db
            if let comment = data.lastComment {
                if comment.id.isEmpty || comment.id == "0" || comment.id == ""{
                    return
                }else{
                    QMessageStorage(qiscusCore : self.qiscusCore!).save(comment)
                }
                
            }
        }
    }
    
    private func loadFromLocal() -> [QChatRoom] {
        var results = [QChatRoom]()
        let roomsdb = roomStore.all()
        
        if roomsdb.count != 0{
            for room in roomsdb {
                let _room = map(room)
                results.append(_room)
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
    internal func map(_ core: QChatRoom, data: Room? = nil) -> Room {
        var result : Room
        if let _result = data {
            result = _result // Update data
        }else {
            if let db = roomStore.find(predicate: NSPredicate(format: "id = %@", core.id))?.first {
                result = db
            }else{
                 result = roomStore.generate() // prepare create new
            }
        }
        result.id            = core.id
        result.uniqueId      = core.uniqueId
        result.unreadCount   = Int16(core.unreadCount)
        result.name          = core.name
        result.avatarUrl     = core.avatarUrl?.absoluteString ?? ""
        result.options       = core.extras
        result.lastCommentId = core.lastComment?.id
        result.type          = core.type.rawValue
        // participants
        if let participants = core.participants {
            for p in participants {
                if let member = self.qiscusCore?.database.participant.map(p){
                     result.addToParticipants(member)
                }
            }
        }
        return result
    }
    
    private func map(_ room: Room) -> QChatRoom {
        let result = QChatRoom()
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
        
        result.extras       = room.options
        
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
        result.participants = [QParticipant]()
        for p in room.participants! {
            let _member = p as! Participant
            if let memberModel = self.qiscusCore?.database.participant.find(byEmail: _member.email ?? "") {
                result.participants?.append(memberModel)
            }
        }
        
        
        guard let lastCommentid = room.lastCommentId else { return result }
        // check comment
        result.lastComment   = self.qiscusCore?.database.message.find(id: lastCommentid)
        
        return result
    }
}

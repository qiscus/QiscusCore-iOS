//
//  QiscusDBManager.swift
//  QiscusCore
//
//  Created by Qiscus on 12/09/18.
//
import Foundation
import UIKit

public class QiscusDatabaseManager {
    var qiscusCore : QiscusCore? = nil
   // static var shared        : QiscusDatabaseManager = QiscusDatabaseManager()
//    public var room          : QChatRoomDB!
//    public var message       : QMessageDB!
//    public var participant   : QParticipantDB!
    
   public var participant : QParticipantDB{
        get{
            let participant = QParticipantDB()
            participant.qiscusCore = self.qiscusCore
            return participant
        }
    }
    
    public var room : QChatRoomDB{
        get{
            let qChatRoom = QChatRoomDB()
            qChatRoom.qiscusCore = self.qiscusCore
            return qChatRoom
        }
    }
    
    public var message : QMessageDB{
        get{
            let qMessage = QMessageDB()
            qMessage.qiscusCore = self.qiscusCore
            return qMessage
        }
    }
    
    public init() {
//        self.participant     = newParticipant
//        self.room            = newQChatRoom
//        self.message         = newQMessageDB
    }
    
    public func loadData() {
        participant.loadData()
        room.loadData()
        message.loadData()
    }
    
    public func clear() {
        //QiscusDatabase.clear()
        qiscusCore?.database.message.removeAllDB()
        qiscusCore?.database.room.removeAllDB()
        qiscusCore?.database.participant.removeAllDB()
        qiscusCore?.fileManager.clearTempFolder()
    }
    
}

public class QParticipantDB {
    var qiscusCore: QiscusCore? = nil
    private var participant : QParticipantDatabase{
           get {
            let participant = QParticipantDatabase(qiscusCore: self.qiscusCore!)
               participant.qiscusCore = self.qiscusCore
               return participant
           }
       }
    
    // MARK : Internal
    public func loadData() {
        participant.loadData()
    }
    
    public func removeAllDB(){
        participant.removeAll()
    }
    
    public func save(_ data: [QParticipant], roomID id: String) {
        for m in data {
            guard let room = self.qiscusCore?.database.room.find(id: id) else {
                qiscusCore?.qiscusLogger.errorPrint("Failed to save participant \(data) in db, mybe room not found")
                return
            }
            let roomDB = self.qiscusCore?.database.room.map(room)
            participant.add([m], inRoom: roomDB!)
        }
    }
    
    // manage relations rooms and participant
    public func map(_ core: QParticipant, data: Participant? = nil) -> Participant {
        return participant.map(core, data: data)
    }
    
    public func map(participant data: Participant) -> QParticipant {
        return participant.map(data)
    }
    
    // MARK : Public
    // take time, coz search in all rooms
    public func find(byEmail email: String) -> QParticipant? {
        if let participant = participant.find(byEmail: email) {
            return participant
        }else {
            return participant.find(predicate: NSPredicate(format: "email == %@", email))?.first
        }
    }
    
    public func find(byUserId id: String) -> QParticipant? {
        if let participant = participant.find(byEmail: id) {
            return participant
        }else {
            return participant.find(predicate: NSPredicate(format: "email == %@", id))?.first
        }
    }
    
}

public class QChatRoomDB {
    var qiscusCore: QiscusCore? = nil
    private var room : QChatRoomStorage{
        get {
            let storage = QChatRoomStorage(qiscusCore: self.qiscusCore!)
            storage.qiscusCore = self.qiscusCore
            return storage
        }
    }
    
    
    // MARK : Public
    public func loadData() {
        room.loadData()
    }
    
    public func removeAllDB(){
        room.removeAll()
    }
    
    public func map(_ core: QChatRoom, data: Room? = nil) -> Room {
        return room.map(core, data: data)
    }
    
    public func save(_ rooms: [QChatRoom]) {
        if rooms.count != 0{
            room.add(rooms)
        }
    }
    
    public func updateLastComment(_ comment: QMessage) -> Bool {
        return room.updateLastComment(comment)
    }
    
    public func updateReadComment(_ comment: QMessage) -> Bool {
        return room.updateUnreadComment(comment)
    }
    
    public func delete(_ data: QChatRoom) -> Bool {
        if room.delete(byID: data.id) {
            self.qiscusCore?.eventManager.deleteRoom(data)
            return true
        }else {
            // overlap with mqtt event
            qiscusCore?.qiscusLogger.errorPrint("Deleted Room from local succeed, but unfotunetly failed to delete from local db. Or room not exist")
            return false
        }
        qiscusCore?.qiscusLogger.debugDBPrint("delete room for roomId = \(data.id)")
    }
    
    // MARK : Private
    public func find(predicate: NSPredicate) -> [QChatRoom]? {
        return room.find(predicate: predicate)
    }
    
    public func find(id: String) -> QChatRoom? {
        if let room = room.find(byID: id) {
            return room
        }else {
            return find(predicate: NSPredicate(format: "id = %@", id))?.last
        }
    }
    
    public func find(uniqID: String) -> QChatRoom? {
        if let room = room.find(byUniqID: uniqID) {
            return room
        }else {
            return find(predicate: NSPredicate(format: "uniqueId = %@", uniqID))?.last
        }
    }
    
    public func all() -> [QChatRoom] {
        if self.qiscusCore?.dataDBQChatRoom.count != 0{
            let results = self.qiscusCore?.dataDBQChatRoom
            return results!
        }else{
            let results = room.all()
            return results
        }
        
    }
    
}

public class QMessageDB {
    var qiscusCore: QiscusCore? = nil
    
    private var comment: QMessageStorage{
        get{
            let storage = QMessageStorage(qiscusCore: self.qiscusCore!)
            storage.qiscusCore = self.qiscusCore
            return storage
        }
    }
    
    // MARK: Public
    public func evaluate() {
        comment.evaluate()
    }
    
    public func loadData() {
        comment.loadData()
    }
    
    public func removeAllDB(){
        comment.removeAll()
    }
    
    // MARK: TODO need to improve flow, check room then add comment
    public func save(_ data: [QMessage], publishEvent: Bool = true, isUpdateMessage : Bool = false) {
        DispatchQueue.global(qos: .background).sync {
            data.forEach { (c) in
                if c.id == "0"{
                    return
                }
                // listen callback to provide event
                comment.add(c, onCreate: { (result) in
            
                    if (self.qiscusCore?.database.room.find(id: result.chatRoomId) == nil){
                        self.qiscusCore?.network.getRoomById(roomId: result.chatRoomId, onSuccess: { (room, comments) in
                            // save room
                            if let comments = comments {
                                room.lastComment = comments.first
                                
                                self.qiscusCore?.shared.getChatRooms(roomIds: [room.id]) { (rooms) in
                                    room.unreadCount = rooms.first?.unreadCount ?? 0
                                    self.qiscusCore?.database.room.save([room])
                                } onError: { (error) in
                                    self.qiscusCore?.database.room.save([room])
                                }

                            }
                            
                            // save comments
                            var c = [QMessage]()
                            if let _comments = comments {
                                // save comments
                                self.qiscusCore?.database.message.save(_comments,publishEvent: false)
                                c = _comments
                            }
                        }) { (error) in
                            self.qiscusCore?.qiscusLogger.errorPrint(error.message)
                        }
                    }else{
                        // update last comment in room, mean comment where you send
                        if !(self.qiscusCore?.database.room.updateLastComment(result))! {
                        }
                        
                        if publishEvent && isUpdateMessage == false {
                            self.qiscusCore?.eventManager.gotNewMessage(comment: result)
                        } else if publishEvent == true && isUpdateMessage == true {
                            self.qiscusCore?.eventManager.gotUpdatedMessage(comment: result)
                        }
                        
                        self.markCommentAsRead(comment: result)
                    }
                    
                }) { (updatedResult) in
                    // MARK : TODO refactor comment update flow and event
                    
                    if publishEvent == true && isUpdateMessage == true {
                        self.qiscusCore?.eventManager.gotUpdatedMessage(comment: updatedResult)
                    }else{
                        self.qiscusCore?.eventManager.gotMessageStatus(comment: updatedResult)
                    }

                }
            }
        }
        
    }
    
    public func clear(inRoom id: String, timestamp: Int64? = nil) {
        guard var comments = comment.find(byRoomID: id) else { return }
        if let _timestamp = timestamp {
            comments = comments.filter({ $0.unixTimestamp < _timestamp })
        }
        // delete all comment by room
        comments.forEach { (comment) in
            _ = self.delete(comment)
        }
        
        self.qiscusCore?.eventManager.clearRoom(roomId: id)
    }
    
    public func delete(_ data: QMessage) -> Bool {
        if comment.delete(byUniqueID: data.uniqueId) {
            self.qiscusCore?.eventManager.deleteComment(data)
            return true
        }else {
            // overlap with mqtt event
            qiscusCore?.qiscusLogger.errorPrint("Deleted message from server, but unfotunetly failed to delete from local db. Or message not exist")
            return false
        }
    }
    
    /// Requirement said, we asume when receive comment from opponent then old my comment status is read
    public func markCommentAsRead(comment: QMessage) {
        if comment.status == .deleted { return }
        guard let user = qiscusCore?.getProfile() else { return }
        // check comment from opponent
        guard let comments = self.qiscusCore?.database.message.find(roomId: comment.chatRoomId) else { return }
        let myComments = comments.filter({ $0.userEmail == user.id }) // filter my comment
        let myCommentBefore = myComments.filter({ $0.unixTimestamp < comment.unixTimestamp })
        for c in myCommentBefore {
            // update comment
            if c.status.intValue < comment.status.intValue {
                c.status = .read
                self.qiscusCore?.database.message.save([c])
            }
        }
    }
    
    // MARK: Public comment
    public func all() -> [QMessage] {
        if self.qiscusCore?.dataDBQMessage.count != 0{
            let results = self.qiscusCore?.dataDBQMessage
            return results!
        }else{
             return comment.all()
        }
    }

    public func find(predicate: NSPredicate) -> [QMessage]? {
        return comment.find(predicate: predicate)
    }
    
    public func find(roomId id: String) -> [QMessage]? {
        if let comments = comment.find(byRoomID: id) {
            return comments
        }else {
            return comment.find(predicate: NSPredicate(format: "roomId == %@", id))
        }
    }
    
    public func findOlderCommentsThan(roomId id: String, message : QMessage, limit: Int) -> [QMessage]? {
        if var comments = comment.find(predicate: NSPredicate(format: "roomId == %@", id)){
            comments.sort { (comment1, comment2) -> Bool in
                return comment1.unixTimestamp > comment2.unixTimestamp
            }
            
            let olderComment = comments.filter({ $0.unixTimestamp <= message.unixTimestamp })
            var commentLimit = [QMessage]()
             
            for (index, element) in olderComment.enumerated() {
                commentLimit.append(element)
                if commentLimit.count == limit{
                    break
                }
             }
             
            let sortComment = commentLimit.filter({ $0.unixTimestamp <= message.unixTimestamp })
            return sortComment
        }else{
            return nil
        }
    }

    public func find(id: String) -> QMessage? {
        if let comment = comment.find(byID: id) {
            return comment
        }else {
            return comment.find(predicate: NSPredicate(format: "id == %@", id))?.first
        }
    }

    public func find(uniqueId id: String) -> QMessage? {
        if let comment = comment.find(byUniqueID: id) {
            return comment
        }else {
            return comment.find(predicate: NSPredicate(format: "uniqId == %@", id))?.first
        }
    }
    
    public func find(status: QMessageStatus) -> [QMessage]? {
        if let comment = comment.find(status: status) {
            return comment
        }else {
            return comment.find(predicate: NSPredicate(format: "status == %@", status.rawValue))
        }
    }
}

//
//  QiscusDBManager.swift
//  QiscusCore
//
//  Created by Qiscus on 12/09/18.
//
import Foundation

public class QiscusDatabaseManager {
    static var shared   : QiscusDatabaseManager = QiscusDatabaseManager()
    public var room    : RoomDB!
    public var comment : CommentDB!
    public var member   : MemberDB!
    
    public init() {
        self.member     = MemberDB()
        self.room       = RoomDB()
        self.comment    = CommentDB()
    }
    
    public func loadData() {
        member.loadData()
        room.loadData()
        comment.loadData()
    }
    
    public func clear() {
        //QiscusDatabase.clear()
        QiscusCore.database.comment.removeAllDB()
        QiscusCore.database.room.removeAllDB()
        QiscusCore.database.member.removeAllDB()
        QiscusCore.fileManager.clearTempFolder()
    }
    
}

public class MemberDB {
    private var member : MemberDatabase = MemberDatabase()
    
    // MARK : Internal
    public func loadData() {
        member.loadData()
    }
    
    public func removeAllDB(){
        member.removeAll()
    }
    
    public func save(_ data: [MemberModel], roomID id: String) {
        for m in data {
            guard let room = QiscusCore.database.room.find(id: id) else {
                QiscusLogger.errorPrint("Failed to save member \(data) in db, mybe room not found")
                return
            }
            let roomDB = QiscusCore.database.room.map(room)
            member.add([m], inRoom: roomDB)
        }
    }
    
    // manage relations rooms and member
    public func map(_ core: MemberModel, data: Member? = nil) -> Member {
        return member.map(core, data: data)
    }
    
    public func map(member data: Member) -> MemberModel {
        return member.map(data)
    }
    
    // MARK : Public
    // take time, coz search in all rooms
    public func find(byEmail email: String) -> MemberModel? {
        if let member = member.find(byEmail: email) {
            return member
        }else {
            return member.find(predicate: NSPredicate(format: "email == %@", email))?.first
        }
    }
    
    public func find(byUserId id: String) -> MemberModel? {
        if let member = member.find(byEmail: id) {
            return member
        }else {
            return member.find(predicate: NSPredicate(format: "email == %@", id))?.first
        }
    }
    
}

public class RoomDB {
    private var room : RoomStorage = RoomStorage()
    
    // MARK : Public
    public func loadData() {
        room.loadData()
    }
    
    public func removeAllDB(){
        room.removeAll()
    }
    
    public func map(_ core: RoomModel, data: Room? = nil) -> Room {
        return room.map(core, data: data)
    }
    
    public func save(_ rooms: [RoomModel]) {
        room.add(rooms)
    }
    
    public func updateLastComment(_ comment: CommentModel) -> Bool {
        return room.updateLastComment(comment)
    }
    
    public func updateReadComment(_ comment: CommentModel) -> Bool {
        return room.updateUnreadComment(comment)
    }
    
    public func delete(_ data: RoomModel) -> Bool {
        if room.delete(byID: data.id) {
            QiscusCore.eventManager.deleteRoom(data)
            return true
        }else {
            // overlap with mqtt event
            QiscusLogger.errorPrint("Deleted Room from local succeed, but unfotunetly failed to delete from local db. Or room not exist")
            return false
        }
        QiscusLogger.debugDBPrint("delete room for roomId = \(data.id)")
    }
    
    // MARK : Private
    public func find(predicate: NSPredicate) -> [RoomModel]? {
        return room.find(predicate: predicate)
    }
    
    public func find(id: String) -> RoomModel? {
        if let room = room.find(byID: id) {
            return room
        }else {
            return find(predicate: NSPredicate(format: "id = %@", id))?.last
        }
    }
    
    public func find(uniqID: String) -> RoomModel? {
        if let room = room.find(byUniqID: uniqID) {
            return room
        }else {
            return find(predicate: NSPredicate(format: "uniqueId = %@", uniqID))?.last
        }
    }
    
    public func all() -> [RoomModel] {
        let results = room.all()
        return results
    }
    
    public func findChatRooms(limit : Int = 10, offset: Int = 0) -> [RoomModel]? {
        return room.find(limit : limit, offset : offset)
    }
    
}

public class CommentDB {
    private var comment = CommentStorage()
    
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
    public func save(_ data: [CommentModel], publishEvent: Bool = true) {
        data.forEach { (c) in
            // listen callback to provide event
            comment.add(c, onCreate: { (result) in
        
                if (QiscusCore.database.room.find(id: result.roomId) == nil){
                    QiscusCore.network.getRoomById(roomId: result.roomId, onSuccess: { (room, comments) in
                        // save room
                        if let comments = comments {
                            room.lastComment = comments.first
                        }
                        
                        QiscusCore.database.room.save([room])
                        // save comments
                        var c = [CommentModel]()
                        if let _comments = comments {
                            // save comments
                            QiscusCore.database.comment.save(_comments,publishEvent: false)
                            c = _comments
                        }
                    }) { (error) in
                        QiscusLogger.errorPrint(error.message)
                    }
                }else{
                    // update last comment in room, mean comment where you send
                    if !QiscusCore.database.room.updateLastComment(result) {
                        QiscusLogger.debugPrint("Last message already updated")
                    }
                    
                    if publishEvent {
                        QiscusEventManager.shared.gotNewMessage(comment: result)
                    }
                    
                    self.markCommentAsRead(comment: result)
                }
                
            }) { (updatedResult) in
                // MARK : TODO refactor comment update flow and event
                QiscusCore.eventManager.gotMessageStatus(comment: updatedResult)
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
        
        QiscusCore.eventManager.clearRoom(roomId: id)
    }
    
    public func delete(_ data: CommentModel) -> Bool {
        if comment.delete(byUniqueID: data.uniqId) {
            QiscusCore.eventManager.deleteComment(data)
            return true
        }else {
            // overlap with mqtt event
            QiscusLogger.errorPrint("Deleted message from server, but unfotunetly failed to delete from local db. Or message not exist")
            return false
        }
    }
    
    /// Requirement said, we asume when receive comment from opponent then old my comment status is read
    public func markCommentAsRead(comment: CommentModel) {
        if comment.status == .deleted { return }
        guard let user = QiscusCore.getProfile() else { return }
        // check comment from opponent
        guard let comments = QiscusCore.database.comment.find(roomId: comment.roomId) else { return }
        let myComments = comments.filter({ $0.userEmail == user.email }) // filter my comment
        let myCommentBefore = myComments.filter({ $0.unixTimestamp < comment.unixTimestamp })
        for c in myCommentBefore {
            // update comment
            if c.status.intValue < comment.status.intValue {
                c.status = .read
                QiscusCore.database.comment.save([c])
            }
        }
    }
    
    // MARK: Public comment
    public func all() -> [CommentModel] {
        return comment.all()
    }

    public func find(predicate: NSPredicate) -> [CommentModel]? {
        return comment.find(predicate: predicate)
    }
    
    public func find(roomId id: String) -> [CommentModel]? {
        if let comments = comment.find(byRoomID: id) {
            return comments
        }else {
            return comment.find(predicate: NSPredicate(format: "roomId == %@", id))
        }
    }
    
    public func findOlderCommentsThan(roomId id: String, message : CommentModel, limit: Int) -> [CommentModel]? {
        if var comments = comment.find(predicate: NSPredicate(format: "roomId == %@", id)){
            comments.sort { (comment1, comment2) -> Bool in
                return comment1.unixTimestamp > comment2.unixTimestamp
            }
            
            let olderComment = comments.filter({ $0.unixTimestamp <= message.unixTimestamp })
            var commentLimit = [CommentModel]()
             
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

    public func find(id: String) -> CommentModel? {
        if let comment = comment.find(byID: id) {
            return comment
        }else {
            return comment.find(predicate: NSPredicate(format: "id == %@", id))?.first
        }
    }

    public func find(uniqueId id: String) -> CommentModel? {
        if let comment = comment.find(byUniqueID: id) {
            return comment
        }else {
            return comment.find(predicate: NSPredicate(format: "uniqId == %@", id))?.first
        }
    }
    
    public func find(status: CommentStatus) -> [CommentModel]? {
        if let comment = comment.find(status: status) {
            return comment
        }else {
            return comment.find(predicate: NSPredicate(format: "status == %@", status.rawValue))
        }
    }
}

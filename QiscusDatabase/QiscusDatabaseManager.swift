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
    
    init() {
        self.member     = MemberDB()
        self.room       = RoomDB()
        self.comment    = CommentDB()
    }
    
    func loadData() {
        member.loadData()
        room.loadData()
        comment.loadData()
    }
    
    func clear() {
        QiscusDatabase.clear()
    }
    
}

public class MemberDB {
    private var member : MemberDatabase = MemberDatabase()
    
    // MARK : Internal
    internal func loadData() {
        member.loadData()
    }
    
    internal func save(_ data: [MemberModel], roomID id: String) {
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
    internal func map(_ core: MemberModel, data: Member? = nil) -> Member {
        return member.map(core, data: data)
    }
    
    internal func map(member data: Member) -> MemberModel {
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
    
}

public class RoomDB {
    private var room : RoomStorage = RoomStorage()
    
    // MARK : Private
    internal func loadData() {
        room.loadData()
    }
    
    internal func map(_ core: RoomModel, data: Room? = nil) -> Room {
        return room.map(core, data: data)
    }
    
    internal func save(_ rooms: [RoomModel]) {
        room.add(rooms)
    }
    
    internal func updateLastComment(_ comment: CommentModel) -> Bool {
        return room.updateLastComment(comment)
    }
    
    internal func updateReadComment(_ comment: CommentModel) -> Bool {
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
    
}

public class CommentDB {
    private var comment = CommentStorage()
    
    // MARK: Internal
    internal func evaluate() {
        comment.evaluate()
    }
    
    internal func loadData() {
        comment.loadData()
    }
    
    // MARK: TODO need to improve flow, check room then add comment
    internal func save(_ data: [CommentModel], publishEvent: Bool = true) {
        data.forEach { (c) in
            // listen callback to provide event
            comment.add(c, onCreate: { (result) in
                // check is mycomment
                self.markCommentAsRead(comment: result)
                if publishEvent {
                    QiscusEventManager.shared.gotNewMessage(comment: result)
                }
                // update last comment in room, mean comment where you send
                if !QiscusCore.database.room.updateLastComment(result) {
                    QiscusLogger.errorPrint("Add new comment but can't replace last comment in room. Mybe room not found")
                }
            }) { (updatedResult) in
                // MARK : TODO refactor comment update flow and event
                QiscusCore.eventManager.gotMessageStatus(comment: updatedResult)
            }
        }
    }
    
    internal func clear(inRoom id: String, timestamp: Int64? = nil) {
        guard var comments = comment.find(byRoomID: id) else { return }
        if let _timestamp = timestamp {
            comments = comments.filter({ $0.unixTimestamp < _timestamp })
        }
        comments.forEach { (comment) in
            _ = self.delete(comment)
        }
    }
    
    internal func delete(_ data: CommentModel) -> Bool {
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
    private func markCommentAsRead(comment: CommentModel) {
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

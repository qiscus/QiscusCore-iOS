//
//  QiscusEventManager.swift
//  QiscusCore
//
//  Created by Qiscus on 14/08/18.
//

import Foundation

class QiscusEventManager {
    static var shared : QiscusEventManager = QiscusEventManager()
    // MARK: TODO delegate can't be accees from other class, please create setter/function
    var connectionDelegate : QiscusConnectionDelegate? = nil
    var delegate : QiscusCoreDelegate? = nil
    var roomDelegate : QiscusCoreRoomDelegate? = nil
    var room : RoomModel? = nil
    
    func gotMessageStatus(comment: CommentModel){
        guard let user = QiscusCore.getProfile() else { return }
        if comment.userEmail != user.email { return }
        guard let room = QiscusCore.database.room.find(id: comment.roomId) else { return }
        if let r = QiscusEventManager.shared.room {
            if r.id == room.id {
                roomDelegate?.didComment(comment: comment, changeStatus: comment.status)
                
                if comment.status == .delivered {
                    roomDelegate?.onMessageDelivered(message: comment)
                }else if comment.status == .read{
                     roomDelegate?.onMessageRead(message: comment)
                }
            }
        }
        if let delegate = delegate {
            delegate.onRoomDidChangeComment(comment: comment, changeStatus: comment.status)
            if comment.status == .delivered {
                delegate.onRoomMessageDelivered(message: comment)
            }else if comment.status == .read{
                delegate.onRoomMessageRead(message: comment)
            }
        }
        
    }
    
    func gotNewMessage(comment: CommentModel) {
        guard let user = QiscusCore.getProfile() else { return }
        // no update if your comment
        if user.email != comment.userEmail {
            // call api receive, need optimize
            QiscusCore.shared.markAsDelivered(roomId: comment.roomId, commentId: comment.id)
        }
        
        // filter event for active room
        if let r = QiscusEventManager.shared.room {
            if r.id == String(comment.roomId) {
                if roomDelegate != nil{
                    // publish event new comment inside room
                    roomDelegate?.onMessageReceived(message: comment)
                }
                
                if let comments = QiscusCore.database.comment.find(roomId: comment.roomId) {
                    
                    guard let user = QiscusCore.getProfile() else { return }
                    if comment.userEmail != user.email{
                        var mycomments = comments.filter({ $0.userEmail == user.email }) // filter my comment
                        mycomments = mycomments.filter({ $0.status == .sent || $0.status == .delivered })
                        
                        mycomments.forEach { (c) in
                            let new = c
                            // update comment
                            new.status = .read
                            QiscusCore.database.comment.save([new])
                            QiscusCore.eventManager.gotMessageStatus(comment: new)
                        }
                    }
                }
            }
        }
        // got new comment for other room
        if let room = QiscusCore.database.room.find(id: comment.roomId) {
            if delegate != nil{
                delegate?.onRoomMessageReceived(room, message: comment)
            }
        }
        
        ConfigManager.shared.lastCommentId = comment.id
    }
    
    func deleteRoom(_ room: RoomModel) {
        delegate?.onRoom(deleted: room)
    }
    
    func clearRoom(roomId: String){
        delegate?.onChatRoomCleared(roomId: roomId)
    }
    
    func deleteComment(_ comment: CommentModel) {
        if let r = QiscusEventManager.shared.room {
            if r.id == String(comment.roomId) {
                let room = QiscusCore.database.room.find(id: r.id)
                if let latestComment = room?.lastComment?.id {
                    if latestComment == comment.id {
                        ConfigManager.shared.lastCommentId = latestComment
                    }
                }
               
                roomDelegate?.onMessageDeleted(message: comment)
            }
        }
        // delete comment for other room
        if let room = QiscusCore.database.room.find(id: comment.roomId) {
            delegate?.onRoomMessageDeleted(room: room, message: comment)
        }
    }
    
    func gotTyping(roomID: String, user: String, value: Bool) {
        // filter event for room or qiscuscore
        if let r = QiscusEventManager.shared.room {
            if r.id == roomID {
                guard let member = QiscusCore.database.member.find(byEmail: user) else { return }
                roomDelegate?.onUserTyping(userId: member.id, roomId: r.id, typing: value)
            }
        }
    }
    
    func gotEvent(email: String, isOnline: Bool, timestamp time: String) {
        guard let member = QiscusCore.database.member.find(byEmail: email) else { return }
        guard let validTime = self.components(time, length: 13).first else { return }
        let date = getDate(timestampUTC: validTime)
        // filter event for room or qiscuscore
        if let room = QiscusEventManager.shared.room  {
            guard let participants = room.participants else { return }
            participants.forEach { (member) in
                if email == member.email {
                    self.roomDelegate?.onUserOnlinePresence(userId: member.id, isOnline: isOnline, lastSeen: date)
                }
                member.saveLastOnline(date)
            }
        }
    }
    
    private func getDate(timestampUTC: String) -> Date {
        let double = Double(timestampUTC) ?? 0.0
        let date = Date(timeIntervalSince1970: TimeInterval(double/1000))
        return date
    }
    
    func roomUpdate(room: RoomModel) {
        if let r = QiscusEventManager.shared.room {
            if r.id == room.id {
                roomDelegate?.onRoom(update: room)
            }
        }
        delegate?.onRoom(update: room)
    }
    
    func roomNew(room: RoomModel) {
        delegate?.gotNew(room: room)
    }
    
    func components(_ value:String, length: Int) -> [String] {
        return stride(from: 0, to: value.count, by: length).map {
            let start = value.index(value.startIndex, offsetBy: $0)
            let end = value.index(start, offsetBy: length, limitedBy: value.endIndex) ?? value.endIndex
            return String(value[start..<end])
        }
    }
    
    /// check comment exist in local
    ///
    /// - Parameter data: comment object
    /// - Returns: return true if comment is new or not exist in local
//    private func checkNewComment(_ data: CommentModel) -> Bool {
//        return !(QiscusCore.database.comment.find(uniqueId: data.uniqId) != nil)
//    }
}

//
//  QiscusEventManager.swift
//  QiscusCore
//
//  Created by Qiscus on 14/08/18.
//

import Foundation

public class QiscusEventManager {
    var qiscusCore: QiscusCore? = nil
    //static var shared : QiscusEventManager = QiscusEventManager()
    // MARK: TODO delegate can't be accees from other class, please create setter/function
//    var connectionDelegate : QiscusConnectionDelegate? = nil
//    var delegate : QiscusCoreDelegate? = nil
//    var roomDelegate : QiscusCoreRoomDelegate? = nil
//    var room : QChatRoom? = nil
    
    func gotMessageStatus(comment: QMessage){
        guard let user = self.qiscusCore?.getProfile() else { return }
        if comment.userEmail != user.id { return }
        guard let room = self.qiscusCore?.database.room.find(id: comment.chatRoomId) else { return }
        if let r = qiscusCore?.activeChatRoom {
            if r.id == room.id {
                qiscusCore?.roomDelegate?.didComment(comment: comment, changeStatus: comment.status)
                
                if comment.status == .delivered {
                    qiscusCore?.roomDelegate?.onMessageDelivered(message: comment)
                }else if comment.status == .read{
                    qiscusCore?.roomDelegate?.onMessageRead(message: comment)
                }
            }
        }
        if let delegate = qiscusCore?.delegate {
            delegate.onRoomDidChangeComment(comment: comment, changeStatus: comment.status)
            if comment.status == .delivered {
                delegate.onRoomMessageDelivered(message: comment)
            }else if comment.status == .read{
                delegate.onRoomMessageRead(message: comment)
            }
        }
        
    }
    
    func gotUpdatedMessage(comment: QMessage){
        // filter event for active room
        if let r = qiscusCore?.activeChatRoom{
            if r.id == String(comment.chatRoomId) {
                if qiscusCore?.roomDelegate != nil{
                    // publish event new comment inside room
                    qiscusCore?.roomDelegate?.onMessageUpdated(message: comment)
                }
            }
        }
        // got new comment for other room
        if let room = self.qiscusCore?.database.room.find(id: comment.chatRoomId) {
            if qiscusCore?.delegate != nil{
                qiscusCore?.delegate?.onRoomMessageUpdated(room, message: comment)
            }
        }
    }

    
    func gotNewMessage(comment: QMessage) {
        guard let user = self.qiscusCore?.getProfile() else { return }
        // no update if your comment
        if user.id != comment.userEmail {
            // call api receive, need optimize
            self.qiscusCore?.shared.markAsDelivered(roomId: comment.chatRoomId, commentId: comment.id)
        }
        
        // filter event for active room
        if let r = qiscusCore?.activeChatRoom {
            if r.id == String(comment.chatRoomId) {
                if qiscusCore?.roomDelegate != nil{
                    // publish event new comment inside room
                    qiscusCore?.roomDelegate?.onMessageReceived(message: comment)
                }
                
                if let comments = self.qiscusCore?.database.message.find(roomId: comment.chatRoomId) {
                    
                    guard let user = self.qiscusCore?.getProfile() else { return }
                    if comment.userEmail != user.id{
                        var mycomments = comments.filter({ $0.userEmail == user.id }) // filter my comment
                        mycomments = mycomments.filter({ $0.status == .sent || $0.status == .delivered })
                        
                        mycomments.forEach { (c) in
                            let new = c
                            // update comment
                            new.status = .read
                            self.qiscusCore?.database.message.save([new])
                            self.qiscusCore?.eventManager.gotMessageStatus(comment: new)
                        }
                    }
                }
            }
        }
        // got new comment for other room
        
        if let room = self.qiscusCore?.dataDBQChatRoom.filter({ ($0.id == comment.chatRoomId) }){
            if qiscusCore?.delegate != nil{
                if room.first != nil{
                    qiscusCore?.delegate?.onRoomMessageReceived(room.first!, message: comment)
                }
            }
        }else{
            if let room = self.qiscusCore?.database.room.find(id: comment.chatRoomId) {
                if qiscusCore?.delegate != nil{
                    qiscusCore?.delegate?.onRoomMessageReceived(room, message: comment)
                }
            }
        }
        
        if comment.status == .sent || comment.status == .delivered || comment.status == .read {
            qiscusCore?.config.lastCommentId = comment.id
        }
        
    }
    
    func deleteRoom(_ room: QChatRoom) {
        qiscusCore?.delegate?.onRoom(deleted: room)
    }
    
    func clearRoom(roomId: String){
        qiscusCore?.delegate?.onChatRoomCleared(roomId: roomId)
    }
    
    func deleteComment(_ comment: QMessage) {
        if let r = qiscusCore?.activeChatRoom {
            if r.id == String(comment.chatRoomId) {
                qiscusCore?.roomDelegate?.onMessageDeleted(message: comment)
            }
        }
        // delete comment for other room
        if let room = self.qiscusCore?.database.room.find(id: comment.chatRoomId) {
            qiscusCore?.delegate?.onRoomMessageDeleted(room: room, message: comment)
        }
    }
    
    func gotTyping(roomID: String, user: String, value: Bool) {
        // filter event for room or qiscuscore
        if let r = qiscusCore?.activeChatRoom {
            if r.id == roomID {
                guard let member = self.qiscusCore?.database.participant.find(byEmail: user) else { return }
                qiscusCore?.roomDelegate?.onUserTyping(userId: member.id, roomId: r.id, typing: value)
            }
        }
    }
    
    func gotEvent(email: String, isOnline: Bool, timestamp time: String) {
        guard let member = self.qiscusCore?.database.participant.find(byEmail: email) else { return }
        guard let validTime = self.components(time, length: 13).first else { return }
        let date = getDate(timestampUTC: validTime)
        // filter event for room or qiscuscore
        if let room = qiscusCore?.activeChatRoom  {
            guard let participants = room.participants else { return }
            participants.forEach { (member) in
                if email == member.id {
                    self.qiscusCore?.roomDelegate?.onUserOnlinePresence(userId: member.id, isOnline: isOnline, lastSeen: date)
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
    
    func roomUpdate(room: QChatRoom) {
        if let r = qiscusCore?.activeChatRoom {
            if r.id == room.id {
                qiscusCore?.roomDelegate?.onRoom(update: room)
            }
        }
        qiscusCore?.delegate?.onRoom(update: room)
    }
    
    func roomNew(room: QChatRoom) {
        qiscusCore?.delegate?.gotNew(room: room)
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
//        return !(self.qiscusCore?.database2.comment.find(uniqueId: data.uniqId) != nil)
//    }
}

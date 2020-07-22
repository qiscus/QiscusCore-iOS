//
//  QiscusConnectionDelegate.swift
//  QiscusCore
//
//  Created by Qiscus on 16/07/18.
//  Copyright © 2018 Qiscus. All rights reserved.
//

import UIKit
import QiscusRealtime

public protocol QiscusConnectionDelegate {
    func connectionState(change state: QiscusConnectionState)
    func onConnected()
    func onReconnecting()
    func onDisconnected(withError err: QError?)
}

public enum QiscusConnectionState : String{
    case connecting     = "connecting"
    case connected      = "connected"
    case disconnected   = "disconnected"
}

public protocol QiscusCoreDelegate {
    // MARK: Event Room List
    
    /// new comment is comming
    ///
    /// - Parameters:
    ///   - room: room where event happen
    ///   - comment: new comment object
    func onRoomMessageReceived(_ room: RoomModel, message: CommentModel)
    
    /// Deleted Comment
    ///
    /// - Parameter comment: comment deleted
     func onRoomMessageDeleted(room: RoomModel, message: CommentModel)
    
    /// comment status change
    ///
    /// - Parameters:
    ///   - comment: new comment where status is change, you can compare from local data
    ///   - status: comment status, exp: deliverd, receipt, or read.
    ///     special case for read, for example we have message 1,2,3,4,5 then you got status change for message 5 it's mean message 1-4 has been read
    @available(*, deprecated, message: "will soon become unavailable.")
    func onRoomDidChangeComment(comment: CommentModel, changeStatus status: CommentStatus)
    
    /// comment status change to Delivered
    ///
    /// - Parameters:
    ///   - comment: new comment where status is change, you can compare from local data
    func onRoomMessageDelivered(message : CommentModel)
    
    /// comment status change to Read
    ///
    /// - Parameters:
    ///   - comment: new comment where status is change, you can compare from local data
    func onRoomMessageRead(message : CommentModel)
    
    /// Room update
    ///
    /// - Parameter room: new room object
    @available(*, deprecated, message: "will soon become unavailable.")
    func onRoom(update room: RoomModel)
    
    /// Deleted room
    ///
    /// - Parameter room: object room
    @available(*, deprecated, message: "will soon become unavailable.")
    func onRoom(deleted room: RoomModel)
    
    func gotNew(room: RoomModel)
    
    func onChatRoomCleared(roomId : String)
}

public protocol QiscusCoreRoomDelegate {
    // MARK: Comment Event in Room
    
    /// new comment is comming
    ///
    /// - Parameters:
    ///   - comment: new comment object
    func onMessageReceived(message: CommentModel)
    
    /// comment status change
    ///
    /// - Parameters:
    ///   - comment: new comment where status is change, you can compare from local data
    ///   - status: comment status, exp: deliverd, receipt, or read.
    ///     special case for read, for example we have message 1,2,3,4,5 then you got status change for message 5 it's mean message 1-4 has been read
    @available(*, deprecated, message: "will soon become unavailable.")
    func didComment(comment: CommentModel, changeStatus status: CommentStatus)
    
    /// comment status change to Delivered
    ///
    /// - Parameters:
    ///   - comment: new comment where status is change, you can compare from local data
    func onMessageDelivered(message : CommentModel)
    
    /// comment status change to Read
    ///
    /// - Parameters:
    ///   - comment: new comment where status is change, you can compare from local data
    func onMessageRead(message : CommentModel)
    
    /// Deleted Comment
    ///
    /// - Parameter comment: comment deleted
    
    func onMessageDeleted(message: CommentModel)
    
    /// User Typing Indicator
    ///
    /// - Parameters:
    ///   - user: object user or participant
    ///   - typing: true if user start typing and false when finish typin
    func onUserTyping(userId : String, roomId : String, typing: Bool)
    
    /// User Online status
    ///
    /// - Parameters:
    ///   - userId: string of userId
    ///   - isOnline: true if user is online
    ///   - lastSeen: millisecond UTC
    func onUserOnlinePresence(userId: String, isOnline: Bool, lastSeen: Date)
    
    /// Room update
    ///
    /// - Parameter room: new room object
    @available(*, deprecated, message: "will soon become unavailable.")
    func onRoom(update room: RoomModel)
}

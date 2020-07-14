//
//  Protocol.swift
//  QiscusRealtime
//
//  Created by Qiscus on 09/08/18.
//

import Foundation


public enum QiscusRealtimeConnectionState : String{
    case initial        = "initial"
    case connecting     = "connecting"
    case connected      = "connected"
    case disconnected   = "disconnected"
}

public protocol QiscusRealtimeDelegate {
    /// Qiscus Realtime Server connection state
    ///
    /// - Parameter state: can be connection, connected, or disconnect
    func connectionState(change state: QiscusRealtimeConnectionState)
    
    /// Qiscus Realtime Server connection state disconnect
    ///
    /// - Parameter state: can be disconnect
    func disconnect(withError err: Error?)
    
    /// You will receive from qiscus realtime about user status
    ///
    /// - Parameters:
    ///   - userEmail: qiscus email
    ///   - timestamp: timestampt in UTC
    func didReceiveUser(userEmail: String, isOnline: Bool, timestamp: String)
    
    // MARK: TODO minor feature, waiting core can delete, parsing payload to complicated
    /// You will receive message from qiscus realtime about event like message delete, after you got this message
    ///
    /// - Parameters:
    ///   - roomId: roomId String
    ///   - message: message
    //func didReceiveMessageEvent(roomId: String, message: String)
    
    /// You will receive message from qiscus realtime about comment like new comment, user left room, remove member and other
    ///
    /// - Parameters:
    ///   - data: message as string JSON
    func didReceiveMessage(data: String)
    
    /// you will receive Message comment status
    /// - Parameters:
    ///   - roomId: roomId
    ///   - commentId: commentId
    ///   - Status: status read or deliver
    ///   - userID: userID / userEmail
    func didReceiveMessageStatus(roomId: String, commentId: String, commentUniqueId: String, Status: MessageStatus, userEmail: String)
    
    /// You will receive message from qiscus realtime about user typing
    ///
    /// - Parameters:
    ///   - roomId: roomId (String)
    ///   - userEmail: userEmail (String)
    func didReceiveUser(typing: Bool, roomId: String, userEmail: String)
    
    /// You will receive message from qiscus realtime about room event.
    ///
    /// - Parameters:
    ///   - data: message as string JSON
    func didReceiveRoomEvent(roomID: String, data: String)
}

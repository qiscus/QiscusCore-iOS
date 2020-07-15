//
//  CommentInfo.swift
//  QiscusCore
//
//  Created by Qiscus on 23/01/19.
//

import Foundation

public struct CommentInfo {
    public var comment = QMessage()
    public var deliveredUser = [QParticipant]()
    public var readUser = [QParticipant]()
    public var sentUser = [QParticipant]()
    
}



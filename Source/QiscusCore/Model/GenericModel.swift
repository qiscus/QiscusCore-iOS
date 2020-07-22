//
//  GenericModel.swift
//  QiscusCore
//
//  Created by Qiscus on 13/08/18.
//


/// Delete type
///
/// - forMe: Delete only for my account
/// - forEveryone: Deleted message for everyone
public enum DeleteType {
    case forMe
    case forEveryone
}

/// Delete source
///
/// - hard: Message totaly deleted from server
/// - soft: Soft delete this message still on there but content is changes "message has beed deleted"
public enum DeleteSource {
    case hard
    case soft
}

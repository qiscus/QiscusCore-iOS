//
//  Model.swift
//  Pods
//
//  Created by Qiscus on 10/09/18.
//

import Foundation

// Notification for delete comment and rooms
/**
 {
     "action_topic": "delete_message",
     "payload": {
         "actor": {
             "id": "user id",
             "email": "user email",
             "name": "user name"
         },
         "data": {
             "is_hard_delete": true,
             "deleted_messages": [
                 {
                 "room_id": "room id",
                 "message_unique_ids": ["abc", "hdfjjhv"]
                 }
             ]
         }
     }
 }
 */

import Foundation

struct PayloadNotification: Codable {
    let actionTopic: String
    let payload: Payload
    
    enum CodingKeys: String, CodingKey {
        case actionTopic = "action_topic"
        case payload
    }
}

struct Payload: Codable {
    let actor: Actor
    let data: DataClass
}

struct Actor: Codable {
    let id, email, name: String
}

struct DataClass: Codable {
    let isHardDelete: Bool
    let deletedMessages: [DeletedMessage]
    
    enum CodingKeys: String, CodingKey {
        case isHardDelete = "is_hard_delete"
        case deletedMessages = "deleted_messages"
    }
}

struct DeletedMessage: Codable {
    let roomID: String
    let messageUniqueIDS: [String]
    
    enum CodingKeys: String, CodingKey {
        case roomID = "room_id"
        case messageUniqueIDS = "message_unique_ids"
    }
}


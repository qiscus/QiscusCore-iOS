# Models / Response

All method are now using this structure for their response,

## Getting started

In version 3, we are basically rewrite and/or improve our chat sdk
so all method have unified response and/or method signature.

## User

In v3 all user related response are separated into 3 model

- `QUser` which stand for general user model
- `QAccount` which stand for user whom currently active user
  response of `setUser` method
- `QParticipant` which stand for user which is part of chat room

> Note: some api might only return this data partially

```
open class QUser {
    public var avatarUrl        : URL?
    public var id               : String
    public var name             : String
    public var extras           : [String:Any]?
}

public struct QAccount {
    public var avatarUrl        : URL       
    public var id               : String  
    public var rtKey            : String  
    public var token            : String 
    public var name             : String
    public var extras           : String
    public var lastMessageId    : String
    public var lastSyncEventId  : String
}

open class QParticipant {
    public var avatarUrl                : URL?             
    public var id                       : String
    public var lastMessageReadId        : Int 
    public var lastMessageDeliveredId   : Int
    public var name                     : String
    public var extras                   : [String:Any]? 
}
```

## Message

For all message related data, in v3 it will use the following structure.

> Note: some api might return this data partially

```
open class QMessage {
    public var previousMessageId                    : String
    public internal(set) var id                     : String
    public internal(set) var isDeleted              : Bool
    public internal(set) var isPublicChannel        : Bool
    public var status                               : QMessageStatus
    public var message                              : String
    /// Comment payload, to describe comment type.
    public var payload                              : [String:Any]?
   /// Extra data, set after comment is complate.
    public var extras                               : [String:Any]?
    public var userExtras                           : [String:Any]?
    public var chatRoomId                           : String
    public internal(set) var timestampString        : String
    public var type                                 : String
    public internal(set) var uniqueId               : String
    public internal(set) var unixTimestamp          : Int64
    public var userAvatarUrl                        : URL? 
    public internal(set) var userId                 : String 
    public var name                                 : String
    public var userEmail                            : String
    /// automatic set when comment initiated
    public var timestamp                            : Date 
   
   public var sender                                : QUser
}
```

## Chat Room

In version 3, all data that are related to chat room
will use this structure

> Note: some api might return this data partially

```
open class QChatRoom {
    public internal(set) var id                 : String
    public internal(set) var name               : String
    public internal(set) var uniqueId           : String
    public internal(set) var avatarUrl          : URL?
    public internal(set) var type               : RoomType
    public internal(set) var extras             : String?
    // can be update after got new comment
    public internal(set) var lastComment        : QMessage?
    public internal(set) var participants       : [QParticipant]?
    public internal(set) var totalParticipants  : Int
    public internal(set) var unreadCount        : Int
}
```

# Method

In version 3 you can use multiple appID in 1 app, any different how to call our method. 

First, you need to create QiscusCoreManager

```
public class QiscusCoreManager{
    public static var qiscusCore1 : QiscusCore = QiscusCore() //sample for call appID 1
    public static var qiscusCore2 : QiscusCore = QiscusCore() //sample for call appID 2
}
```

For example : 

```
QiscusCoreManager.qiscusCore1.setup(AppID: yourAppID1)
QiscusCoreManager.qiscusCore2.setup(AppID: yourAppID2)

QiscusCoreManager.qiscusCore1.enableDebugMode(value : true)
QiscusCoreManager.qiscusCore2.enableDebugMode(value : true)

```

In version 3 for call api is different from version 2.
In version 2:
```
QiscusCore.nameMethod
```

In version 3:
```
 QiscusCoreManager.qiscusCore1.nameMethod
```

## There are some method changes in this version 3, following the changes :

## `QiscusCore.setup` version 2 and 3 is same

In version 2 and 3, any 2 way call setup. first you can use default server, and seconds you can use manual or custom server

- `QiscusCoreManager.qiscusCore1.setup` for default configuration
- `QiscusCoreManager.qiscusCore1.setupWithCustomServer` for a more advanced option

```
QiscusCoreManager.qiscusCore1.setup(this, APPID1, "localKeyUser1")
```

if you have your own server (`On-Premise`) you can change the URL, here's the example:
```
QiscusCoreManager.qiscusCore1.setupWithCustomServer(this, AppID2, baseUrl, brokerUrl, brokerLBUrl, "localKeyUser1");
```

## `QiscusCore.setUser` version 2 and 3 is same
in version 2 :
```
QiscusCore.setUser(userId: userId, userKey: userKey, username: username, avatarURL: avatarUrl, extras: extras, onSuccess: { (user) in                
    //success            
    
}) { (error) in                
    //error             
}
```

in version3
```
QiscusCoreManager.qiscusCore1.setUser(userId: userId, userKey: userKey, username: username, avatarURL: avatarUrl, extras: extras, onSuccess: { (user) in                
    //success            
    
}) { (error) in                
    //error             
}
```

## `QiscusCore.setUserWithIdentityToken` version 2 and 3 is same
In version 2
```
QiscusCore.setUserWithIdentityToken(token: tokenNonce, onSuccess: { (user) in             
    //success         
}) { (error) in             
    //error         
}
```

In version 3
```
QiscusCoreManager.qiscusCore1.setUserWithIdentityToken(token: tokenNonce, onSuccess: { (user) in             
    //success         
}) { (error) in             
    //error         
}
```

## `QiscusCore.shared.blockUser` version 2 and 3 name method is same, just different how to call this method

In version 2 :
```
QiscusCore.shared.blockUser(userId: userId, onSuccess: { (user) in             
    //success         
}) { (error) in             
    //error         
}
```
In version 3:
```
QiscusCoreManager.qiscusCore1.shared.blockUser(userId: userId, onSuccess: { (user) in             
    //success         
}) { (error) in             
    //error         
}
```

## `QiscusCore.shared.unblockUser`  version 2 and 3 name method is same, just different how to call this method

In version 2
```
QiscusCore.shared.unblockUser(userId: userId, onSuccess: { (user) in             
    //success         
}) { (error) in             
    //error         
}
```

In version 3
```
QiscusCoreManager.qiscusCore1.shared.unblockUser(userId: userId, onSuccess: { (user) in             
    //success         
}) { (error) in             
    //error         
}
```

## `QiscusCore.shared.getBlockedUsers` version 2 and 3 name method is same, just different how to call this method

In version 2
```
QiscusCore.shared.getBlockedUsers(page: page, limit: limit, onSuccess: { (usersBlock) in             
    //success         
}) { (error) in             
    //error         
}
```

In version 3
```
QiscusCoreManager.qiscusCore1.shared.getBlockedUsers(page: page, limit: limit, onSuccess: { (usersBlock) in          
    //success         
}) { (error) in             
    //error         
}
```

## `QiscusCore.clearUser` version 2 and 3 name method is same, just different how to call this method
In version 2
```
QiscusCore.clearUser()
```

In version 3
```
 QiscusCoreManager.qiscusCore1.clearUser()
```

## `QiscusCore.updateUser` version 2 and 3 name method is same, just different how to call this method
In version 2
```
QiscusCore.shared.updateUser(name: name, avatarURL: avatarURL, extras: extras, onSuccess: { (user) in 
    //success         
}) { (error) in             
    //error        
}
```

In version 3
```
QiscusCoreManager.qiscusCore1.shared.updateUser(name: name, avatarURL: avatarURL, extras: extras, onSuccess: { (user) in 
    //success         
}) { (error) in             
    //error        
}
```

## `QiscusCore.shared.getUsers` version 2 and 3 name method is same, just different how to call this method
In version 2
```
QiscusCore.shared.getUsers(searchUsername: searchUsername, page: page, limit: limit, onSuccess: { (participants, meta) in             
    //success         
}) { (error) in             
    //error         
}
```

In version 3
```
QiscusCoreManager.qiscusCore1.shared.getUsers(searchUsername: searchUsername, page: page, limit: limit, onSuccess: { (participants, meta) in             
    //success         
}) { (error) in             
    //error         
}
```

## `QiscusCore.getJWTNonce` version 2 and 3 name method is same, just different how to call this method
In version 2
```
QiscusCore.getJWTNonce(onSuccess: { (nonce) in             
    //success         
}, onError: { (error) in             
    //error         
})
```

In version 3
```
QiscusCoreManager.qiscusCore1.getJWTNonce(onSuccess: { (nonce) in             
    //success         
}, onError: { (error) in             
    //error         
})
```

## `QiscusCore.shared.getUserData` version 2 and 3 name method is same, just different how to call this method
In version 2
```
QiscusCore.shared.getUserData(onSuccess: { (user) in             
    //success         
}) { (error) in             
    //error         
}
```

In version 3
```
QiscusCoreManager.qiscusCore1.shared.getUserData(onSuccess: { (user) in             
    //success         
}) { (error) in             
    //error         
}
```

## `QiscusCore.registerDeviceToken()` version 2 and 3 name method is same, just different how to call this method
In version 2
```
var tokenString: String = ""         
for i in 0..<deviceToken.count {             
    tokenString += String(format: "%02.2hhx", deviceToken[i] as CVarArg)         
}         

if QiscusCore.isLogined {             
    QiscusCore.shared.registerDeviceToken(token: tokenString, onSuccess: { (response) in                    
        print("success register device token =\(tokenString)")             
    }) { (error) in                 
        print("failed register device token = \(error.message)")             
    }
}
```

In version 3
```
var tokenString: String = ""         
for i in 0..<deviceToken.count {             
    tokenString += String(format: "%02.2hhx", deviceToken[i] as CVarArg)         
}         

if QiscusCoreManager.qiscusCore1.isLogined {             
    QiscusCoreManager.qiscusCore1.shared.registerDeviceToken(token: tokenString, onSuccess: { (response) in                    
        print("success register device token =\(tokenString)")             
    }) { (error) in                 
        print("failed register device token = \(error.message)")             
    }
}
```

## `QiscusCore.removeDeviceToken` version 2 and 3 name method is same, just different how to call this method
In version 2
```
if QiscusCore.isLogined {             
    QiscusCore.shared.registerDeviceToken(token: tokenString, onSuccess: { (response) in                    
        print("success register device token =\(tokenString)")             
    }) { (error) in                 
        print("failed register device token = \(error.message)")             
    }
}
```

In version 3
```
if QiscusCoreManager.qiscusCore1.isLogined {             
    QiscusCoreManager.qiscusCore1.shared.registerDeviceToken(token: tokenString, onSuccess: { (response) in                    
        print("success register device token =\(tokenString)")             
    }) { (error) in                 
        print("failed register device token = \(error.message)")             
    }
}
```

## `QiscusCore.shared.updateChatRoom` version 2 and 3 name method is same, just different how to call this method
In version 2
```
QiscusCore.shared.updateChatRoom(roomId:roomId, name:roomName, avatarURL: avatarUrl, extras: extras, onSuccess: { (roomModel) in                 
    //success             
}) { (error) in                 
    //error             
}
```

In version 3
```
QiscusCoreManager.qiscusCore1.shared.updateChatRoom(roomId:roomId, name:roomName, avatarURL: avatarUrl, extras: extras, onSuccess: { (roomModel) in                 
    //success             
}) { (error) in                 
    //error             
}
```

## `QiscusCore.shared.getChannel` version 2 and 3 name method is same, just different how to call this method
In version 2
```
QiscusCore.shared.createChannel(uniqueId: uniqueId,name: name, avatarURL :avatarUrl, extras: extras, onSuccess: { (rooms) in             
    //success         
}) { (error) in             
    //error         
}
```

In version 3
```
QiscusCoreManager.qiscusCore1.shared.createChannel(uniqueId: uniqueId,name: name, avatarURL :avatarUrl, extras: extras, onSuccess: { (rooms) in             
    //success         
}) { (error) in             
    //error         
}
```

## `QiscusCore.shared.chatUser()` version 2 and 3 name method is same, just different how to call this method
In version 2
```
QiscusCore.shared.chatUser(userId: userId, avatarURL: avatarURL, extras: extras, onSuccess: { (room, comments) in     
    //success         
}) { (error) in             
    //error         
}
```

In version 3
```
QiscusCoreManager.qiscusCore1.shared.chatUser(userId: userId, avatarURL: avatarURL, extras: extras, onSuccess: { (room, comments) in     
    //success         
}) { (error) in             
    //error         
}
```

## `QiscusCore.shared.addParticipants()` version 2 and 3 name method is same, just different how to call this method
In version 2
```
QiscusCore.shared.addParticipants(roomId: roomId, userIds: userIds, onSuccess: { (users) in             
    //success         
}) { (error) in             
    //error         
}
```

In version 3
```
QiscusCoreManager.qiscusCore1.shared.addParticipants(roomId: roomId, userIds: userIds, onSuccess: { (users) in        
    //success         
}) { (error) in             
    //error         
}  
```

## `QiscusCore.shared.removeParticipants()` version 2 and 3 name method is same, just different how to call this method
In version 2
```
QiscusCore.shared.removeParticipants(roomId: roomId, userIds: userIds, onSuccess: { (success) in                
    //success         
}) { (error) in             
    //error         
}
```

In version 3
```
QiscusCoreManager.qiscusCore1.shared.removeParticipants(roomId: roomId, userIds: userIds, onSuccess: { (success) in   
    //success         
}) { (error) in             
    //error         
}  
```

## `QiscusCore.shared.clearMessagesByChatRoomId` version 2 and 3 name method is same, just different how to call this method
In version 2
```
QiscusCore.shared.clearMessagesByChatRoomId(roomIds: roomIds) { (error) in             
    if error != nil {                 
        //error             
    }else{                 
        //success             
    }         
}                  

QiscusCore.shared.clearMessagesByChatRoomId(roomUniqIds: roomUniqIds) { (error) in             
    if error != nil {                 
        //error             
    }else{                 
        //success             
    }
}
```

In version 3
```
QiscusCoreManager.qiscusCore1.shared.clearMessagesByChatRoomId(roomIds: roomIds) { (error) in             
    if error != nil {                 
        //error             
    }else{                 
        //success             
    }         
}                  

QiscusCoreManager.qiscusCore1.shared.clearMessagesByChatRoomId(roomUniqIds: roomUniqIds) { (error) in             
    if error != nil {                 
        //error             
    }else{                 
        //success             
    }
}
```

## `QiscusCore.shared.createGroupChat()` version 2 and 3 name method is same, just different how to call this method
In version 2
```
QiscusCore.shared.createGroupChat(name: title, userIds: participantsId, avatarURL: avatarUrl, extras: extras, onSuccess: { (room) in                    
    //success                 
}) { (error) in                     
    print("error create group =\(error.message)")                 
}
```

In version 3
```
QiscusCoreManager.qiscusCore1.shared.createGroupChat(name: title, userIds: participantsId, avatarURL: avatarUrl, extras: extras, onSuccess: { (room) in                    
    //success                 
}) { (error) in                     
    print("error create group =\(error.message)")                 
}  
```

## `QiscusCore.shared.createChannel()` version 2 and 3 name method is same, just different how to call this method
In version 2
```
QiscusCore.shared.createChannel(uniqueId: uniqueId,name: name, avatarURL :avatarUrl, extras: extras, onSuccess: { (rooms) in               
    //success        
}) { (error) in             
    //error         
}
```

In version 3
```
QiscusCoreManager.qiscusCore1.shared.createChannel(uniqueId: uniqueId,name: name, avatarURL :avatarUrl, extras: extras, onSuccess: { (rooms) in               
    //success        
}) { (error) in             
    //error         
}
```

## `QiscusCore.shared.getParticipants()` version 2 and 3 name method is same, just different how to call this method
In version 2
```
QiscusCore.shared.getParticipants(roomUniqueId: uniqueId, offset: nil, sorting: .asc, onSuccess: { (participants) in      //success         
}) { (error) in            
    //error         
}
```

In version 3
```
QiscusCoreManager.qiscusCore1.shared.getParticipants(roomUniqueId: uniqueId, offset: nil, sorting: .asc, onSuccess: { (participants) in      //success         
}) { (error) in            
    //error         
}
```

## `QiscusCore.shared.getChatRooms()` version 2 and 3 name method is same, just different how to call this method
In version 2
```
QiscusCore.shared.getChatRooms(roomIds: roomIds, showRemoved: showRemoved, showParticipant: showParticipant, onSuccess: { (rooms) in             
    //success         
}) { (error) in             
    //error         
}                  

QiscusCore.shared.getChatRooms(uniqueIds: uniqueIds, showRemoved: showRemoved, showParticipant: showParticipant, onSuccess: { (rooms) in             
    //success         
}) { (error) in             
    //error         
}
```

In version 3
```
QiscusCoreManager.qiscusCore1.shared.getChatRooms(roomIds: roomIds, showRemoved: showRemoved, showParticipant: showParticipant, onSuccess: { (rooms) in             
    //success         
}) { (error) in             
    //error         
}                  

QiscusCoreManager.qiscusCore1.shared.getChatRooms(uniqueIds: uniqueIds, showRemoved: showRemoved, showParticipant: showParticipant, onSuccess: { (rooms) in             
    //success         
}) { (error) in             
    //error         
}
```

## `QiscusCore.shared.getAllChatRooms()` version 2 and 3 name method is same, just different how to call this method
In version 2
```
QiscusCore.shared.getAllChatRooms(showParticipant: showParticipant, showRemoved: showRemoved, showEmpty: showEmpty, page: page, limit: limit, onSuccess: { (rooms, meta) in                      

}) { (error) in                      

}
```

In version 3
```
QiscusCoreManager.qiscusCore1.shared.getAllChatRooms(showParticipant: showParticipant, showRemoved: showRemoved, showEmpty: showEmpty, page: page, limit: limit, onSuccess: { (rooms, meta) in                      

}) { (error) in                      

}
```

## `QiscusSDK.getChatRoomWithMessages()` version 2 and 3 name method is same, just different how to call this method
In version 2
```
QiscusCore.shared.getChatRoomWithMessages(roomId: roomId, onSuccess: { (room, comments) in             
    //success         
}) { (error) in             
    //error         
}
```

In version 3
```
QiscusCoreManager.qiscusCore1.shared.getChatRoomWithMessages(roomId: roomId, onSuccess: { (room, comments) in         
    //success         
}) { (error) in             
    //error         
}
```

## `QiscusCore.shared.getTotalUnreadCount()` version 2 and 3 name method is same, just different how to call this method
In version 2
```
QiscusCore.shared.getTotalUnreadCount { (count, error) in             
    if error != nil {                 
        //error             
    }else{                 
        //success             
    }
}
```

In version 3
```
QiscusCoreManager.qiscusCore1.shared.getTotalUnreadCount { (count, error) in             
    if error != nil {                 
        //error             
    }else{                 
        //success             
    }
}
```

## `QiscusCore.shared.sendMessage()` version 2 and 3 name method is same, just different how to call this method
In version 2
```
let message = CommentModel() 
message.message = text 
message.type    = "text" 
message.roomId  = roomId  

QiscusCore.shared.sendMessage(message: commentModel, onSuccess: { (comment) in             
    //success         
}) { (error) in             
    //error         
}
```

In version 3
```
let message = CommentModel() 
message.message = text 
message.type    = "text" 
message.roomId  = roomId  

QiscusCoreManager.qiscusCore1.shared.sendMessage(message: commentModel, onSuccess: { (comment) in             
    //success         
}) { (error) in             
    //error         
} 
```

## `QiscusCore.shared.sendFileMessage()` version 2 and 3 name method is same, just different how to call this method
In version 2
```
let file = FileUploadModel()
file.caption = caption
file.data = fileData
file.name = fileName

let message = CommentModel() 
message.message = text 
message.type    = "file_attachment" 
message.roomId  = roomId  

QiscusCore.shared.sendFileMessage(message: message, file: file, progressUploadListener: { (progress) in
    
}, onSuccess: { (qMessage) in
    
}) { (error) in
    
}
```

In version 3
```
let file = FileUploadModel()
file.caption = caption
file.data = fileData
file.name = fileName

let message = CommentModel() 
message.message = text 
message.type    = "file_attachment" 
message.roomId  = roomId  

QiscusCoreManager.qiscusCore1.shared.sendFileMessage(message: message, file: file, progressUploadListener: { (progress) in
    
}, onSuccess: { (qMessage) in
    
}) { (error) in
    
}
```

## `QiscusCore.shared.markAsDelivered()` version 2 and 3 name method is same, just different how to call this method
In version 2
```
QiscusCore.shared.markAsDelivered(roomId: roomID, commentId: messageID)          
```

In version 3
```
QiscusCoreManager.qiscusCore1.shared.markAsDelivered(roomId: roomID, commentId: messageID)  
```

## `QiscusCore.shared.markAsRead()` version 2 and 3 name method is same, just different how to call this method
In version 2
```
QiscusCore.shared.markAsRead(roomId: roomId, commentId: lastComment.id)             
```

In version 3
```
QiscusCoreManager.qiscusCore1.shared.markAsRead(roomId: roomId, commentId: lastComment.id) 
```

## ` QiscusCore.shared.deleteMessages()` version 2 and 3 name method is same, just different how to call this method
In version 2
```
QiscusCore.shared.deleteMessages(messageUniqueIds: messageUniqueIds, onSuccess: { (comments) in             
    //success         
}) { (error) in             
    //error         
}         
```

In version 3
```
QiscusCoreManager.qiscusCore1.shared.deleteMessages(messageUniqueIds: messageUniqueIds, onSuccess: { (comments) in    
    //success         
}) { (error) in             
    //error         
}             
```

## `QiscusCore.shared.getPreviousMessagesById()` version 2 and 3 name method is same, just different how to call this method
In version 2
```
QiscusCore.shared.getPreviousMessagesById(roomID: roomId, limit: limit, messageId: messageId, onSuccess: { (comments) in             
    //success         
}) { (error) in             
    //error        
}                     
```

In version 3
```
QiscusCore.shared.getPreviousMessagesById(roomID: roomId, limit: limit, messageId: messageId, onSuccess: { (comments) in             
    //success         
}) { (error) in             
    //error        
}                   
```

## `QiscusCore.shared.getNextMessagesById()` version 2 and 3 name method is same, just different how to call this method
In version 2
```
QiscusCore.shared.getNextMessagesById(roomID: roomId, limit: limit, messageId: messageId, onSuccess: { (comments) in      //success         
}) { (error) in             
    //error         
}          
```

In version 3
```
QiscusCoreManager.qiscusCore1.shared.getNextMessagesById(roomID: roomId, limit: limit, messageId: messageId, onSuccess: { (comments) in      //success         
}) { (error) in             
    //error         
}  
```

## `QiscusCore.hasSetupUser()` version 2 and 3 name method is same, just different how to call this method
In version 2
```
QiscusCore.hasSetupUser()        
```

In version 3
```
QiscusCoreManager.qiscusCore1.hasSetupUser() 
```

## `QiscusCore.shared.upload()` version 2 and 3 name method is same, just different how to call this method
In version 2
```
let file = FileUploadModel() 
file.data = data 
file.name = imageName                  

QiscusCore.shared.upload(file: file, onSuccess: { (fileURL) in                     

}, onError: { (error) in       
    print("error upload avatar =\(error.message)") 
}) { (progress) in  

}
```

In version 3
```
let file = FileUploadModel() 
file.data = data 
file.name = imageName                  

QiscusCoreManager.qiscusCore1.shared.upload(file: file, onSuccess: { (fileURL) in                     

}, onError: { (error) in       
    print("error upload avatar =\(error.message)") 
}) { (progress) in  

}
```

## `QiscusCore.shared.getThumbnailURL` version 2 and 3 name method is same, just different how to call this method
In version 2
```
QiscusCore.shared.getThumbnailURL(url: String, onSuccess: { (urlThumb) in             
    //success         
}) { (error) in             
    //error         
}
```

In version 3
```
QiscusCoreManager.qiscusCore1.shared.getThumbnailURL(url: String, onSuccess: { (urlThumb) in             
    //success         
}) { (error) in             
    //error         
}
```

# Realtime Event

while in version 2, realtime event are passed as an arguments when initializing qiscus sdk,
in version 3, in comes with it own method, so you can initialized realtime event handling at a later code.

## Subscribe custom events `publishCustomEvent(), subscribeCustomEvent(), and unsubscribeCustomEvent()` 

In version 1
```
QiscusCore.shared.publishCustomEvent(roomId: roomId, data: data)
QiscusCore.shared.subscribeCustomEvent(roomId: roomId) { (roomEvent) in }
QiscusCore.shared.unsubscribeCustomEvent(roomId: roomId)
```
In version 2
```
QiscusCoreManager.qiscusCore1.shared.publishCustomEvent(roomId: roomId, data: data)
QiscusCoreManager.qiscusCore1.shared.subscribeCustomEvent(roomId: roomId) { (roomEvent) in }
QiscusCoreManager.qiscusCore1.shared.unsubscribeCustomEvent(roomId: roomId)
```

## Subscribe Chat Room related events

this event include message being read and delivered, and user typing on that room

In version 1
```
QiscusCore.shared.publishOnlinePresence(isOnline: isOnline)
QiscusCore.shared.publishTyping(roomID: roomID, isTyping: isTyping)
QiscusCore.shared.subscribeChatRoom(room)
QiscusCore.shared.unSubcribeChatRoom(room)
```
In version 2
```
QiscusCoreManager.qiscusCore1.shared.publishOnlinePresence(isOnline: isOnline)
QiscusCoreManager.qiscusCore1.shared.publishTyping(roomID: roomID, isTyping: isTyping)
QiscusCoreManager.qiscusCore1.shared.subscribeChatRoom(room)
QiscusCoreManager.qiscusCore1.shared.unSubcribeChatRoom(room)
```

## Subscribe user online presence

In version 1
```
QiscusCore.shared.subscribeUserOnlinePresence(userId: userId)
QiscusCore.shared.unsubscribeUserOnlinePresence(userId: userId)
```
In version 2
```
QiscusCoreManager.qiscusCore1.shared.subscribeUserOnlinePresence(userId: userId)
QiscusCoreManager.qiscusCore1.shared.unsubscribeUserOnlinePresence(userId: userId)
```

## Handler

This delegate related to QiscusCoreRoomDelegate  (inChatRoom)
```
// MARK: Core Delegate
extension UIChatPresenter : QiscusCoreRoomDelegate {
    func onMessageReceived(message: QMessage){
        // 2check comment already in ui?
        if (self.getIndexPath(comment: message) == nil) {
            self.addNewCommentUI(message, isIncoming: true)
        }
    }
    
    func onMessageDelivered(message : QMessage){
        // check comment already exist in view
        for (group,c) in comments.enumerated() {
            if let index = c.index(where: { $0.uniqueId == message.uniqueId }) {
                comments[group][index] = message
                self.viewPresenter?.onUpdateComment(comment: message, indexpath: IndexPath(row: index, section: group))
            }
        }
    }
    
    func onMessageRead(message : QMessage){
        // check comment already exist in view
        for (group,c) in comments.enumerated() {
            if let index = c.index(where: { $0.uniqueId == message.uniqueId }) {
                comments[group][index] = message
                self.viewPresenter?.onUpdateComment(comment: message, indexpath: IndexPath(row: index, section: group))
            }
        }
    }
    
    func onMessageDeleted(message: QMessage){
        for (group,var c) in comments.enumerated() {
            if let index = c.index(where: { $0.uniqueId == message.uniqueId }) {
                c.remove(at: index)
                self.comments = groupingComments(c)
                self.lastIdToLoad = ""
                self.loadMoreAvailable = true
                self.viewPresenter?.onReloadComment()
            }
        }
    }
    
    func onUserTyping(userId : String, roomId : String, typing: Bool){
        if let user = QiscusCoreManager.qiscusCore1.database.participant.find(byUserId : userId){
            self.viewPresenter?.onUser(name: user.name, typing: typing)
        }
    }
    
    func onUserOnlinePresence(userId: String, isOnline: Bool, lastSeen: Date){
        if let room = self.room {
            if room.type != .group {
                let message = lastSeen.timeAgoSinceDate(numericDates: false)
                if let user = QiscusCoreManager.qiscusCore1.database.participant.find(byUserId : userId){
                    self.viewPresenter?.onUser(name: user.name, isOnline: isOnline, message: message)
                }
            }
        }
    }
    
    //this func was deprecated
    func didDelete(Comment comment: QMessage) {
        for (group,var c) in comments.enumerated() {
            if let index = c.index(where: { $0.uniqueId == comment.uniqueId }) {
                c.remove(at: index)
                self.comments = groupingComments(c)
                self.lastIdToLoad = ""
                self.loadMoreAvailable = true
                self.viewPresenter?.onReloadComment()
            }
        }
    }
    
    //this func was deprecated
    func onRoom(update room: QChatRoom) {
        // 
    }
    
     //this func was deprecated
    func didComment(comment: QMessage, changeStatus status: QMessageStatus) {
       // check comment already exist in view
       for (group,c) in comments.enumerated() {
           if let index = c.index(where: { $0.uniqueId == comment.uniqueId }) {
               comments[group][index] = comment
               self.viewPresenter?.onUpdateComment(comment: comment, indexpath: IndexPath(row: index, section: group))
           }
       }
    }
}
```

This delegate related to QiscusCoreDelegate (outChatRoom)
```
extension UIChatListPresenter : QiscusCoreDelegate {
    func onRoomMessageReceived(_ room: QChatRoom, message: QMessage){
        // show in app notification
        print("got new comment: \(message.message)")
        self.rooms = filterRoom(data: self.rooms)
        self.viewPresenter?.updateRooms(data: room)
        
    }
    
    func onRoomMessageDelivered(message : QMessage){
        //
    }
    
    func onRoomMessageRead(message : QMessage){
        //
    }
    
    func onChatRoomCleared(roomId : String){
        self.loadFromLocal()
    }
    
    func onRoomMessageDeleted(room: QChatRoom, message: QMessage) {
        //
    }
    
    func gotNew(room: QChatRoom) {
        // add not if exist
        loadFromLocal(refresh: false)
        self.viewPresenter?.updateRooms(data: room)
    }
    
    func onRoom(deleted room: QChatRoom) {
        self.loadFromLocal()
    }
    func onRoom(update room: QChatRoom) {
        self.loadFromLocal()
    }
    
    //this func was deprecated
    func onRoomDidChangeComment(comment: QMessage, changeStatus status: QMessageStatus) {
        print("check commentDidChange = \(comment.message) status = \(status.rawValue)")
    }
}
```

## Subscribe realtime server connection state

this event related to connection state of mqtt, which is our realtime mechanism

```
extension AppDelegate : QiscusConnectionDelegate {
    func onConnected(){
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "reSubscribeRoom"), object: nil)
    }
    func onReconnecting(){
        
    }
    func onDisconnected(withError err: QError?){
        
    }
    
    func connectionState(change state: QiscusConnectionState) {
        if (state == .disconnected){
            var roomsId = [String]()
            
            let rooms = QiscusCoreManager.qiscusCore1.database.room.all()
            
            if rooms.count != 0{
                
                for room in rooms {
                    roomsId.append(room.id)
                }
                
                QiscusCoreManager.qiscusCore1.shared.getChatRooms(roomIds: roomsId, showRemoved: false, showParticipant: true, onSuccess: { (rooms) in
                    //brodcast rooms to your update ui ex in ui listRoom
                }, onError: { (error) in
                    print("error = \(error.message)")
                })
                
            }
            
        }
        
    }
}
```


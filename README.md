# [QiscusCore](https://github.com/qiscus) - Messaging and Chat Core API for iOS
[Qiscus](https://qiscus.com) Enable custom in-app messaging in your Mobile App and Web using Qiscus Chat SDK and Messaging API

[![Platform](https://img.shields.io/badge/platform-iOS-orange.svg)](https://cocoapods.org/pods/QiscusCore)
[![Languages](https://img.shields.io/badge/language-Objective--C%20%7C%20Swift-orange.svg)](https://github.com/qiscus)
[![CocoaPods](https://img.shields.io/badge/pod-v3.0.109-green.svg)](https://cocoapods.org/pods/QiscusCore)



### Main Features

| Feature                                       | Description                                                                                                                                                                            |
|-----------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **Lite Version Chat SDK**                   | Qiscus Chat SDK without UI.                                       |
| **Realtime Event**                          | QiscusCore handle realtime event like publish typing or online status and Automatic subscribe all Qiscus Messaging Event(incoming message, change message status, etc). |
| **Local Database**                       | Save Room and Comment in local db. |
| **Local Storage**                       | Manage downloaded file and uploaded file. |

## Features

- [x] Create Chat Room, 1 on 1, group, and channel
- [x] List Chat Room
- [x] Receive Message
- [x] Debuger true or false
- [x] Set AppID
- [x] Login or Register
- [x] Login with JWT
- [x] Register DeviceToken Apns nor Pushkit
- [x] Receive Realtime Event(new message, message status, etc)
- [x] [API Reference](https://qiscuscoreios.firebaseapp.com/Classes/QiscusCore.html)

## Component Libraries

In order to keep QiscusCore focused specifically on core messaging implementation, additional libraries have beed create by the [Qiscus IOS] (https://qiscus.com).

* [QiscusRaltime](https://github.com/qiscus) - An realtime messaging library. Already handle realtime event like user typing, online status, etc.
* [QiscusUI](https://github.com/qiscus) - An chat component library, make it easy to custom your chat UI.
* [Qiscus](https://github.com/qiscus) - An chat sdk with complete feature, simple, easy to integrate.


## Installation

[CocoaPods](https://cocoapods.org) is a dependency manager for Cocoa projects. You can install it with the following command:

```bash
$ gem install cocoapods
```

To integrate QiscusCore into your Xcode project using CocoaPods, specify it in your `Podfile`:

```ruby
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '10.0'
use_frameworks!

target '<Your Target Name>' do
    pod 'QiscusCore',
end
```

Then, run the following command:

```bash
$ pod install
```
## Setup

### Init APP ID
Set your app Qiscus APP ID, always set app ID everytime launch your app. After login successfuly, no need to setup again

```
///- Parameter WithAppID: Qiscus SDK App ID
QiscusCore.setup(WithAppID: "yourAppId")
```
### Init APP ID using custom server
If you have your own server, you can set in Qiscus, by adding your server host in ***customParameter***.

```
/// Setup custom server, when you use Qiscus on premise
///
/// - Parameters:
///   - customServer: your custom server host
///   - realtimeServer: your qiscus realtime host, without port
///   - realtimePort: your qiscus realtime port
QiscusCore.set(customServer: URL.init(string: "BaseUrl")!, realtimeServer: "realTimeServer", realtimePort: realtimePort)
```
Then add your APP ID

```
QiscusCore.setup(WithAppID: "yourAppId")
```

## User

### Authentication with UserID & UserKey

```
QiscusCore.login(userID: userID, userKey: key) { (result, error) in
    if result != nil {
        print("success")
    }else {
        print("error \(String(describing: error?.message))")
    }
}
```

### Authentication with JWT

```
QiscusCore.login(withIdentityToken: identityToken, completion: { (result, error) in
     if result != nil {
        print("success")
     }else{
        print("error \(String(describing: error?.message))")
    }
})
```

### Updating a user profile (Image, Extras)

```
/// Update user profile
///
/// - Parameters:
///   - displayName: nick name
///   - avatarUrl: user avatar url
///   - completion: The code to be executed once the request has finished
QiscusCore.shared.updateProfile(displayName : "yourName", avatarUrl: avatarURL) { (result, error) in
            if result != nil {
                print("success")
            }else{
                print("error \(String(describing: error?.message))")
            }
        }
```

### Check is user logged in

```
QiscusCore.isLoggedIn // BOOL can be true or false
```

### Logout user

```
QiscusCore.logout { (error) in
            if let error != nil {
                print("error \(String(describing: error?.message))")
            }
        }
```

## Message

### Send message

* Text comment:

```
let message = CommentModel()
message.message = "textComment"
message.type    = "text"
QiscusCore.shared.sendMessage(roomID: roomId comment: message) { (message, error) in
    if let message != nil {
        print("success")
    }else{
        print("error \(String(describing: error?.message))")
    }
}
```

* Custom type

How to send comment with your mimetype or comment type. You can defind *type* as string and *payload* as Dictionary [String:Any]. type can be anything except: ***text, file_attachment, account_linking, buttons, button_postback_response, replay, system_event, card, custom, location, contactPerson, carousel***. the comment types already used by Qiscus SDK with specific payload.


```
let message = CommentModel()
message.type = "Coupon/BukaToko"
message.payload = [
    "name"  : "BukaToko",
    "voucher" : "xyz"
]
message.message = "Send Coupon"
QiscusCore.shared.sendMessage(roomID: "roomId", comment: message) { (result, error) in
    if let result != nil {
        print("success")
    }else{
        print("error \(String(describing: error?.message))")
    }
}
```

* With extras (text)
You can put your meta data in your message by adding extras property.

```
import SwiftyJson
import QiscusCore

let extraData : [String: Any] = ["qiscus_ios_pn" : [
            "aps" : [
                "alert" : [
                    "title" : "new message",
                    "body" : "You got new message",
                ],
                "badge": 1,
                "sound": "default"
            ],
            "qiscus_sdk": true,
            "payload": [
                "consultation_id" : 1234
            ]
            ]
        ]
        
        
        let message = CommentModel()
        message.message = "textComment"
        message.type    = "text"
        message.extras = JSON(extraData).rawString()
        QiscusCore.shared.sendMessage(roomID: roomId comment: message) { (message, error) in
            if let message != nil {
                print("success")
            }else{
                print("error \(String(describing: error?.message))")
            }
        }

```

### Load Messages

* Get message from server

```
/// Load Comment by room
 ///
 /// - Parameters:
 /// - id: Room ID
 /// - limit: by default set 20, min 0 and max 100
 /// - completion: Response new Qiscus Array of Comment Object and error if exist.
QiscusCore.shared.loadComments(roomID: id, limit: limit) { (result, error) in
            if result != nil{
                print("success")
            }else{
                print("error \(String(describing: error?.message))")
            }
        }
```

* Get from local

Get all comments from local

```
 let comments : [CommentModel]? = QiscusCore.database.comment.all()
```

*Get comments by room id

```
 let comments : [CommentModel]? = QiscusCore.database.comment.find(roomId: "123")
```

### Load More Message in room (with limit)

```
/// Load More Message in room
///
/// - Parameters:
///   - roomID: Room ID
///   - lastCommentID: last comment id want to load
///   - limit: by default set 20, min 0 and max 50
///   - completion: Response new Qiscus Array of Comment Object and error if exist.

QiscusCore.shared.loadMore(roomID: roomID, lastCommentID: lastCommentID, limit: limit) { (result, error) in
            if result != nil{
                print("success")
            }else{
                print("error \(String(describing: error?.message))")
            }
        }
```

### Delete Message
You can delete a message by using this API, once you delete a message, in your opponent side, their messages will be deleted as well. 

```
/// Delete message by id
///
/// - Parameters:
/// - uniqueID: comment unique id
/// - type: ForEveryone
/// - completion: Response Comments your deleted
QiscusCore.shared.deleteMessage(uniqueIDs: id, type: type) { (qComments, error) in
            if let qCommentsData = qComments{
                print("success")
            }else{
                print("error \(String(describing: error?.message))")
            }
        }

```

### Clear Messages
You can use this API for delete all messages in particular room. Once you call this API, in your opponent side, their messages won't be deleted.

```
/// Delete all message in room
///
/// - Parameters:
/// - roomID: array of room id
/// - completion: Response error if exist
QiscusCore.shared.deleteAllMessage(roomID: roomID) { (error) in
            if let errorData = error?.message{
                onError(errorData)
            }else{
                onSuccess()
            }
        }
```

## Room

### Create a Room (1-on-1)

```
/// Get or create room with participant
///
/// - Parameters:
/// - withUsers: Qiscus user email.
/// - completion: Qiscus Room Object and error if exist.
QiscusCore.shared.getRoom(withUser: "user") { (result, error) in
            if result != nil{
                print("success")
            }else{
                print("error \(String(describing: error?.message))")
            }
        }
```

### Create a room (group)

```
/// Create new Group room
    ///
    /// - Parameters:
    ///   - withName: Name of group
    ///   - participants: array of user id/qiscus email
    ///   - completion: Response Qiscus Room Object and error if exist.
QiscusCore.shared.createGroup(withName: nameGroup, participants: users, avatarUrl: avatarURL) { (result, error) in
            if result != nil{
                print("success")
            }else{
                print("error \(error)")
            }
        }
```

### Get Chat Room by Id

* Get room from server

```
/// Get room with room id
///
/// - Parameters:
/// - withID: existing roomID from server or local db.
/// - completion: Response Qiscus Room Object and error if exist.
QiscusCore.shared.getRoom(withID: roomId) { (result, error) in
            if result != nil{
                print("success")
            }else{
                print("error \(String(describing: error?.message))")
            }
        }
```

* Get room from local db
```
if let room = QiscusCore.dataStore.findRoom(byID: "123"){
            
        }
```

### Get Chat Room by Channel

```
/// Get room by channel
///
/// - Parameters:
///   - channel: channel name or channel id
///   - completion: Response Qiscus Room Object and error if exist.
QiscusCore.shared.getRoom(withChannel: channel) { (result, error) in
            if result != nil{
                print("success")
            }else{
                print("error \(String(describing: error?.message))")
            }
        }
```


### Get Chat Room by Opponent user_id

```
/// Get or create room with participant
///
/// - Parameters:
/// - withUsers: Qiscus user email.
/// - completion: Qiscus Room Object and error if exist.
QiscusCore.shared.getRoom(withUser: "user") { (result, error) in
            if result != nil{
                print("success")
            }else{
                print("error \(String(describing: error?.message))")
            }
        }
```

### Get Rooms List

* Get room list from server

```
/// 
///
/// - Parameter completion: First Completion will return data from local if exist, then return from server with meta data(totalpage,current). Response new Qiscus Room Object and error if exist.

QiscusCore.shared.getAllRoom(limit: 20, page: 1) { (result, metaData, error) in
            if result != nil {
                print("success")
                let currentPage = metaData?.currentPage
                let totalRoom = metaData?.totalRoom
            }else{
                print("error =\(error?.message)")
            }
        }
```
* Get room list from local db

```
let rooms = QiscusCore.dataStore.getRooms()
```

### Getting a List of Participants in a Room

* Get from server
```
/// get participant by room id
///
/// - Parameters:
///   - roomId: room id (group)
///   - completion: Response new Qiscus Participant Object and error if exist.
QiscusCore.shared.getParticipant(roomId: id) { (qMembersUser, error) in
            if let qMembers = qMembersUser {
                print("success")
            }else{
                print("error =\(error?.message)")
            }
        }
```

* Get from local
```
 if let room = QiscusCore.dataStore.findRoom(byID: "123"){
             let participant = room.participants
        }
```

### Update Room (including update options)

```
/// Update Room
///
/// - Parameters:
///   - name: room name
///   - avatarUrl: room avatar
///   - options: options, string or json string
///   - completion: Response new Qiscus Room Object and error if exist.
QiscusCore.shared.updateRoom(roomId: roomId, name: roomName, avatarUrl: avatarURL, options: options) { (result, error) in
            if result != nil {
                print("success")
            }else{
                print("error =\(error?.message)")
            }
        }
```

### Getting Total Unread Count

* Get from server
```
/// Get total unreac count by user
///
/// - Parameter completion: number of unread cout for all room
QiscusCore.shared.unreadCount { (unread, error) in
            if error == nil {
               print("success")
            }else{
                print("error =\(error?.message)")
            }
        }
```

* Get from local db

```
let qRooms = QiscusCore.dataStore.getRooms()
var countUnread = 0
for room in qRooms.enumerated() {
    countUnread = countUnread + room.element.unreadCount
}
        
print("countUnread =\(countUnread)")
```

### Add Participant in a Room

```
/// Add new participant in room(Group)
///
/// - Parameters:
///   - userEmails: qiscus user email
///   - roomId: room id
///   - completion:  Response new Qiscus Participant Object and error if exist.
QiscusCore.shared.addParticipant(userEmails: userEmails, roomId: id) { (qMembers, error) in
            if let qMembersData = qMembers {
                print("success")
            }else{
                print("error =\(error?.message)")
            }
        }
```

### Remove Participant in a Room

```
/// remove users from room(Group)
///
/// - Parameters:
///   - emails: array qiscus email
///   - roomId: room id (group)
///   - completion: Response true if success and error if exist
QiscusCore.shared.removeParticipant(userEmails: userEmails, roomId: id) { (removed, error) in
            if error == nil {
                print("success")
            }else{
                print("error =\(error?.message)")
            }
            
        }
```

### Statuses

* Publish start and stop typing
You can use this API to publish typing event. set **true** for start typing, and set **false** stop typing

```
/// Start typing in room,
///
/// - Parameters:
/// - value: set true if user start typing, and false when finish
/// - roomID: room id where you typing
/// - keepTyping: automatic false after n second
QiscusCore.shared.isTyping(true, roomID: roomID)
```


* Update message status (read)
You can call this API for marking a message is read

```
/// Mark Comment as read, include comment before
///
/// - Parameters:
/// - roomId: room id, where comment cooming
/// - lastCommentReadId: comment id
QiscusCore.shared.updateCommentRead(roomId: roomId, lastCommentReadId: commentId)
```

* Viewing who has read a message

Get room from local db

```
if let room = QiscusCore.dataStore.findRoom(byID: (self.room?.id)!){
            var userMemberRead = [MemberModel]()
            var userMemberReceive = [MemberModel]()
            for participant in room.participants!  {
                if(participant.username.lowercased() != QiscusCore.getProfile()?.email.lowercased()){
                    if (participant.lastCommentReadId >= Int((room.lastComment?.id)!)!) {
                        userMemberRead.append(participant)
                    }
                    
                    if (participant.lastCommentReceivedId >= Int((room.lastComment?.id)!)!) {
                        userMemberReceive.append(participant)
                    }
                }
            }
        }
  ```   
        
Get room from server 
```
QiscusCore.shared.getRoom(withID: "123") { (roomData, error) in
            if let room = roomData {
                var userMemberRead = [MemberModel]()
                var userMemberReceive = [MemberModel]()
                for participant in room.participants!  {
                    if(participant.username.lowercased() != QiscusCore.getProfile()?.email.lowercased()){
                        if (participant.lastCommentReadId >= Int((room.lastComment?.id)!)!) {
                            userMemberRead.append(participant)
                        }
                        
                        if (participant.lastCommentReceivedId >= Int((room.lastComment?.id)!)!) {
                            userMemberReceive.append(participant)
                        }
                    }
                }
            }else {
                // show error
                print("error load room \(String(describing: error?.message))")
            }
        }
```

## Events handler

### Event handler in Chat Room
```
//set your delegate in viewWillAppear
func setRoomDelegage(){
    if let room = self.room {
         room.delegate = self
     }       
}

//remove your delegate in viewWillDisappear
func removeRoomDelegate() {
    if let room = self.room {
         room.delegate = nil
    }
}

extension YourViewController : QiscusCoreRoomDelegate {
    //On got new message
    func gotNewComment(comment: CommentModel) {
      
    }
    //On message status change
    func didComment(comment: CommentModel, changeStatus status: CommentStatus) {
        
    }
    
    //On user typing
    func onRoom(thisParticipant user: MemberModel, isTyping typing: Bool) {
       
    }

    //On user update status online, offline and time
    func onChangeUser(_ user: MemberModel, onlineStatus status: Bool, whenTime time: Date) {
        
    }
}
```

### Event handler in Room List

```
import QiscusCore

//set your delegate in viewDidLoad
private func setDelegate() {
    QiscusCore.delegate = self
}

extension YourViewController : QiscusCoreDelegate {
    //On got new message
    func onRoom(_ room: RoomModel, gotNewComment comment: CommentModel) {
    
    }
    
    //On message change
    func onRoom(_ room: RoomModel, didChangeComment comment: CommentModel, changeStatus status: CommentStatus) {
        
    }
    
    //On user typing (with information on which room)
    func onRoom(_ room: RoomModel, thisParticipant user: MemberModel, isTyping typing: Bool) {
        
    }

    //On user update status online, offline and time
    func onChange(user: MemberModel, isOnline online: Bool, at time: Date) {
        
    }

    //On got new room
    func gotNew(room: RoomModel) {
        
    }

    //On got remove room
    func remove(room: RoomModel) {
        
    }
    //On receiveRoomEvent
    func didReceiveRoomEvent(roomID: String, data: String) {
        // MARK : TODO parsing sender and payload
        print(data)
    }
}
```


### Publish Event

```
QiscusCore.shared.publishEvent(roomID: String, payload: [String : Any]) -> Bool
```

### Subscribe Event

```
QiscusCore.shared.subscribeEvent(roomID: id) { (event) in
   print("room event : \(event.sender) \n data : \(event.data)")
}
```

### Unsubscribe Event
```
QiscusCore.shared.unsubscribeEvent(roomID: String)
```

## Notification

### Register Device Token

```
QiscusCore.shared.register(deviceToken: tokenString) { (isRegister, erorr) in
            if error == nil {
               print("success")
            }else{
                print("error =\(error?.message)")
            }
                
}
```

## Enable Debugger

```
QiscusCore.enableDebugPrint = true
```

## File Management

### Upload

Qiscus uploader, upload your file as Data to Qiscus. Example:

```
let data = UIImageJPEGRepresentation(YourImage, 0.5)!
let timestamp = "\(NSDate().timeIntervalSince1970 * 1000).jpg"
QiscusCore.shared.upload(data: data, filename: timestamp, onSuccess: { (file) in 
    print(file.url.absoluteString)
}, onError: { (error) in
    print(error)
}) { (progress) in
    print("upload progress: \(progress)")
}
```


### Download

Download file from url and save to Qiscus Local Storage. Cache file already active by default.

```
QiscusCore.shared.download(url: URL(string: url)!, onSuccess: { (localPath) in
    print("download result : \(localPath)")
    }
}) { (progress) in
    print("Download Progress \(progress)")
}
```

### Example

You can download example how to use QiscusCore with advance usage from [QiscusUI Example](https://github.com/qiscus/QiscusUI-iOS).

### Security Disclosure

If you believe you have identified a security vulnerability with QiscusCore, you should report it as soon as possible via email to juang@qiscus.co. Please do not post it to a public issue.


## FAQ

### When we use QiscusCore intead Qiscus?

QiscusCore is lite version chat sdk, if you wan't to build your own chat ui best option is use QiscusCore. But, if you need in App chat quickly use Qiscus Chat SDK(build in UI and simple configuration). please visit [Qiscus](https://github.com/qiscus/qiscus-sdk-ios) to use qiscus chat sdk.



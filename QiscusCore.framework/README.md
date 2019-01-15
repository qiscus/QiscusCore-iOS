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

### Init AppId
Initiate qiscus with app id

```
QiscusCore.setup(WithAppID: "yourAppId")
```


## Authentication

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

## Message

### send message

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

### load messages

* Get rooms from server

```
QiscusCore.shared.getAllRoom(limit: 50, page: 1) { (rooms, meta, error) in
    if let results = rooms {
        // success load rooms
    }else {
        // failed load rooms
    }
}
```

* Get from local

Get all rooms from local

```
 let rooms : [RoomModel]? = QiscusCore.database.room.all()
```

Get room by room id

```
let rooms : RoomModel? = QiscusCore.database.room.find(id: "room id")
```


### load messages

* Get message from server

```
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

Get comments by room id

```
 let comments : [CommentModel]? = QiscusCore.database.comment.find(roomId: "123")
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



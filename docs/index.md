## Introduction

With Qiscus Chat SDK (Software Development Kit), You can embed chat feature inside your Application quickly and easily without dealing with complexity of real-time communication infrastructure. We provide powerful API to let you quickly and seamlessly implement it into your App.

Qiscus Chat SDK provides features such as:

* 1-on-1 chat 
* Group chat
* Channel chat
* Typing indicator
* Image and file attachment
* Online presence
* Delivery receipt
* Read receipt
* Delete message
* Offline message
* Block user
* Custom real-time event
* Server side integration with Server API and Webhook
* Embed bot engine in your App
* Enable Push notification
* Export and import messages from your App

### How Qiscus Works 

We recommend that you understand the concept before proceeding with the rest

* Messaging

The messaging flow is simple: a user register to Qiscus Server, a user open a room, send a message to a Chat Room, and then other participants will receive the message within the room. As long as user connect to Qiscus Server user will get events in [event handler section](#event-handler), such as **on receive message, read receipt**, and so on.  

* Application

To start building your application using Qiscus Chat SDK you need a key called APP ID. This APP ID acts as identifier of your Application so that Qiscus Chat SDK can connect a user to other users. You can get your APP ID [here](https://dashboard.qiscus.com/dashboard/login). You can find your APP ID on your Qiscus application dashboard. Here you can see the picture as a reference.

<p align="center"><br/><img src="https://d3p8ijl4igpb16.cloudfront.net/docs/assets/app_id_docs.png" width="100%" /><br/></p>

> **Note**
*All users within the same APP ID are able to communicate with each other, across all platforms. This means users using iOS, Android, Web clients, etc. can all chat with one another. However, users in different Qiscus applications cannot talk to each other.*

* Stage (Sandbox) or Production environment

You can create both sandbox or production app in [Qiscus dashboard](https://dashboard.qiscus.com/dashboard/login) by adding new APP ID. You may set your sandbox as paid or as a trail. Once your APP ID trail is expired we may disable your APP ID from accessing Qiscus Chat SDK. Given that you can upgrade plan to continue your apps accessing Qiscus Chat SDK.


## Try Sample App 

In order to help you to get to know with our chat SDK, we have provided a sample app. This sample app is built with full functionalities so that you can figure out the flow and main activities using Qiscus Chat SDK. And you can freely customize your own UI, for further detail you can download [Sample](https://github.com/qiscus/qiscus-chat-sdk-ios-sample). You can also build your own app on top of our sample app.

```
git clone https://github.com/qiscus/qiscus-chat-sdk-ios-sample.git
```


This sample use **sample APP ID**, means, you will share data with others, in case you want to try by your own you can change the APP ID into your own APP ID, you can find your APP ID in your [dashboard](https://www.qiscus.com/dashboard/login). 

## Getting Started

This section help you to start building your integration, start with send your first message.

### Step 1 : Get Your APP ID

Firstly, you need to create your application in dashboard, by accessing this link [dashboard](https://www.qiscus.com/dashboard/login). You can create more than one APP ID, for further information you can refer to [in Aplication section](#Application)

### Step 2 : Install Qiscus Chat SDK

Qiscus Chat SDK requires minimum IOS  SDK 9, To integrate your app with Qiscus, it can be done in 2 steps. Firstly, you need to add dependency QiscusCore in your Podfile,

```
pod 'QiscusCore'
```

Secondly, you need to pod install from terminal

```
pod install
```

### Step 3 : Initialization Qiscus Chat SDK

You need to initiate your APP ID for your chat App before carry out to Authentication. Can be implemented in the initial startup. Here is how you can do that:

```
QiscusCore.setup(WithAppID: "yourAppId")
```



> **Note:  
**The initialization should be called always . The best practise you can put in AppDelegate

### Step 4 : Authentication To Qiscus 

To use Qiscus Chat SDK features a user firstly need to authenticate to Qiscus Server, for further detail you might figure out [Authentication section link]. This authentication is done by calling `loginOrRegister`() function. This function will retrieve or create user credential based on the unique **User Id** ,for example:

```
QiscusCore.loginOrRegister(userID: userID, userKey: key, username: username) { (result, error) in
                        if result != nil {
                            print("success")
                        }else {
                            print("error \(String(describing: error?.message))")
                        }
                    }
```

Where:

* `userID`  (string, unique): A User identifier that will be used to identify a user and used whenever another user need to chat with this user. It can be anything, whether is is user's email, your user database index, etc. 
* `userKey`string): userKey for authentication purpose, so even if a stranger knows your user Id, he cannot access the user data.
* `username`string): Username for display name inside Chat Room purposes.
* `avatarUrl` (string, optional): to display user's avatar, fallback to default avatar if not provided.
* `extras [string:any]`: to give additional information (metadata) to user, which consist key-value, for example **key: position, **and** value: engineer.**

### Step 5 : Create Chat Room

There are three Chat Room types, 1-on-1, group, and channel, for further detail you can see [Chat Room type](#Chat-Room-Type) for this section let's use 1-on-1. We assume that you already know a targeted user you want to chat with. To start a conversation with your targeted user, it can be done with `getRoom(withUser)`method. Qiscus Chat SDK, then, will serve you a new Chat Room, asynchronously. When the room is successfully created, Qiscus Chat SDK will return a Chat Room and comment package through `onSuccess()` 

```
QiscusCore.shared.getRoom(withUser: withUserId, onSuccess: { (room, comments) in
    print("success")
}) { (error) in
    print(error.message)
}
```

> **Note:**  Make sure that your targeted user has been registered in Qiscus Chat SDK 

### Step 6 : Send Message

You can send any type of data through Qiscus Chat SDK, in this section let's send a “Hi” **message**, 
with type value is **text**. For further detail about message you can find at [Message](#message)

```
let message = CommentModel()
message.message = "textComment"
message.type    = "text"
QiscusCore.shared.sendMessage(roomID: roomId, comment: message, onSuccess: { (commentModel) in
 print("success")
}) { (error) in
 print(error.message)
}
```

> Note : You can define type and data freely, you can use it for custom UI purposes


after you send message, you will get event new comment. Here is you will get this event:

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

extension YourChatViewController : QiscusCoreRoomDelegate {
    // MARK: Comment Event in Room
    
    /// new comment is comming
    ///
    /// - Parameters:
    ///   - comment: new comment object
    func gotNewComment(comment: CommentModel){

    }
    
    func didComment(comment: CommentModel, changeStatus status: CommentStatus){

    }
    func didDelete(Comment comment: CommentModel){

    }
    func onRoom(thisParticipant user: MemberModel, isTyping typing: Bool){

    }
    func onChangeUser(_ user: MemberModel, onlineStatus status: Bool, whenTime time: Date){

    }
    func onRoom(update room: RoomModel){

    }
}
```

## Authentication 

To use Qiscus Chat SDK features, authentication to Qiscus Server is needed, your application needs to have user credential locally stored for further requests. The credential consists of a token that will identify a user in Qiscus Server. When you want to disconnect from Qiscus server, terminating authentication will be done by clearing the stored credential. 

You need to initiate your APP ID for your chat App before carry out to Authentication. Should be called always in the app lifecycle. Initialization can be implemented in the initial startup. Here is how you can do that:

```
QiscusCore.setup(WithAppID: "yourAppId")
```


If you have your own server **(on Premise)** you can change the URL, here's the example 

```
let customServer = QiscusServer(url: URLCustomServer, realtimeURL: realtimeURL, realtimePort: realtimePort)


QiscusCore.setup(WithAppID: "your appID", server: customServer)
```

Where:

* `WithAppID` : your appID
* `server` : your custom server host, with parameter url, realtimeURL, realtimePort

For further detail on premise information you can contact us link [contact.us@qiscus.com].


> **Note**: The initialization should be called always . The best practise you can put in AppDelegate


There are 2 type of authentications that you can choose to use: Client Authentication and Server Authentication

* Client Authentication can be done simply by providing userID and userKey through your client app. On the other hand, Server Authentication, the credential information is provided by your Server App. In this case, you need o prepare your own Backend.
* The Client Authentication is easier to implement but Server Authentication is more secure.

### Client Authentications

This authentication is done by calling `loginOrRegister()`function. This function will retrieve or create user credential based on the unique user Id. Here is example:

```
QiscusCore.loginOrRegister(userID: userID, userKey: key, username: username) { (result, error) in
                        if result != nil {
                            print("success")
                        }else {
                            print("error \(String(describing: error?.message))")
                        }
                    }
```


Where:

* `userId` (string, unique): A User identifier that will be used to identify a user and used whenever another user need to chat with this user. It can be anything, whether is is user's email, your user database index, etc. HiAs long as it is unique and a string.
* `userKey` (string): userKey for authentication purpose, so even if a stranger knows your user Id, he cannot access the user data.
* `username` (string): Username for display name inside Chat Room purposes.
* `avatarUrl` (string, optional): to display user's avatar, fallback to default avatar if not provided.
* `extras [string:any]`: to give additional information (metadata) to user, which consist key-value, for example **key: position, **and** value: engineer**.

You can learn from the figure below to understand what really happened when calling setUser() function:
<p align="center"><br/><img src="https://s3-ap-southeast-1.amazonaws.com/qiscus-sdk/docs/assets/docs-screenshot-android/docs_ss_set_user_client_auth.png" width="100%" /><br/></p>

> **Note**
Email addresses are a bad choice for user IDs because users may change their email address. It also unnecessarily exposes private information. We recommend to be *unique* for every user in your app, and *stable*, meaning that they can never change

### Server Authentication (JWT Token)

Server Authentication is another option, which allow you to authenticate using JSON Web Tokens [(JWT)](https://jwt.io/). JSON Web Tokens contains your app account details which typically consists of a single string which contains information of two parts, JOSE Header, JWT Claims Set.

<p align="center"><br/><img src="https://d3p8ijl4igpb16.cloudfront.net/docs/assets/docs-screenshot-android/docs_ss_jwt_authentication.png" width="100%" /><br/></p>

The steps to authenticate with JWT goes like this:

1. Your App request a Nonce from Qiscus Server
2. Qiscus Server send Nonce to Your App
3. Your App send user credentials and Nonce that is obtained from Qiscus Server to Your backend
4. Your backend send the token to Your App
5. Your App send that token to Qiscus Server
6. Qiscus Server send Qiscus Account to Your App


Do the following authentication tasks as described step above:

* Step 1 : Setting JOSE Header and JWT Claim Set in your backend

When your backend returns a JWT after receiving Nonce from your App, the JWT will be caught by your App and will be forwarded to Qiscus Server. In this phase, Qiscus Server will verify the JWT before returning Qiscus Account for your user. To allow Qiscus Server successfully recognize the JWT, you need to setup JOSE Header and JWT Claim Set in your backend as follow :

* JOSE Header

```
{
  "alg": "HS256",  // must be HMAC algorithm
  "typ": "JWT", // must be JWT
  "ver": "v2" // must be v2
}
```

* JWT Claim Set

```
{
  "iss": "QISCUS SDK APP ID", // your qiscus app id, can obtained from dashboard
  "iat": 1502985644, // current timestamp in unix
  "exp": 1502985704, // An arbitrary time in the future when this token should expire. In epoch/unix time. We encourage you to limit 2 minutes
  "nbf": 1502985644, // current timestamp in unix
  "nce": "nonce", // nonce string as Number used Once
  "prn": "YOUR APP USER ID", // your user identity, (userId), should be unique and stable
  "name": "displayname", // optional, string for user display name
  "avatar_url": "" // optional, string url of user avatar
}
```

* Signature

JWT need to be signed using **Qiscus Secret Key**, the one you get in [dashboard](https://www.qiscus.com/dashboard/login). The signature is used to verify that the sender of the JWT is who it says it is. To create the signature part you have to take the encoded JOSE Header, the encoded JWT Claim Set, a Qiscus Secret Key, the algorithm specified in the header, and sign that.

The signature is computed using the following pseudo code :

```
HMACSHA256(
  base64UrlEncode(JOSE Header) + "." +
  base64UrlEncode(JWT Claim Set),
  Qiscus Secret Key)
```

To make this easier, we provide sample backends in [PHP](https://bitbucket.org/qiscus/qiscus-sdk-jwt-sample/src/master/). You can use any other language or platform.

> Note :
JWT Sample backend in PHP can be found by clicking this [link](https://bitbucket.org/qiscus/qiscus-sdk-jwt-sample/src/master/)

* Step 2 : Start to get a **Nonce**

You need to request a Nonce from Qiscus Server. **Nonce (Number Used Once)** is a unique, randomly generated string used to identify a single request. Please be noted that a Nonce will expire in 10 minutes. So you need to implement your code to request JWT from your backend right after you got the returned Nonce. Here's the how to get a Nonce:

```
QiscusCore.getNonce(onSuccess: { (qNonce) in
                onSuccess("nonce =\(qNonce.nonce)")
            }) { error in
                onFailed(error.message)
            }
```

* Step 3 : Verify the JWT 

Once you get a Nonce, you can request JWT from your backend by sending Nonce you got from Qiscus Server. When you got the JWT Token, you can pass that JWT to `login(withIdentityToken)` method to allow Qiscus to authenticate your user and return Qiscus Account, as shown in the code below:

```
QiscusCore.login(withIdentityToken: withuserIdentityToken, onSuccess: { (qUser) in
  print("success")

 if QiscusCore.isLogined {
       target = YourViewController()
       // Connect to Qiscus server
       _ = QiscusCore.connect()
 }else {
 // Back to your login ViewController
     target = LoginViewController()
 }
  
}) { (error) in
  print("error \(String(describing: error?.message))")
}

```

### Clear User Data And Disconnected 

As mentioned in previous section, when you did setUser(), user's data will be stored locally. When you need to disconnect from Qiscus Server, you need to clear the user data that is related to Qiscus Chat SDK, such as token, profile, messages, rooms, etc, from local device, hence later you will not get any **message, or event**.  You can do this by calling this code:

```
QiscusCore.logout { (error) in
           if let errorLogout = error {
               print("error logout \(errorLogout.message)")
          }}
```

## Term Of User

Qiscus Chat SDK has three term of user, Qiscus Account and Participant. Qiscus Account is user who success through authentication phase, hence this  user able to use Qiscus Chat SDK features. In other hand, Participant is user who in a Chat Room. At some case, you need add more user to your Chat Room, what you can do you can add participant, then your Chat Room increase the number of participant and decrease whenever you remove participant. To use add participant you can refer to this [add participant](#add-participant-in-chat-room)

Term of user Table:

|Type |Description  |
|---  |---  |
|Qiscus Account |The user who can use Qiscus Chat SDK features that has been verified in Qiscus Server  |
|Participant  |The user who is in a Chat Room |
|Blocked User |The user who is blocked by another user  |

### Blocked User 

Blocked user is user who is blocked by another user. Once a user is blocked they cannot receive message from another user only in 1-on-1 Chat Room, but still get message in Channel or Group Chat Room. Blocked user do not know they are blocked, hence when send a message to a user, blocked user's message indicator stay sent receipt.


> Note :
Block user feature works only for 1-on-1 Chat Room

## Chat Room Type 

### 1-On-1 Chat Room

Chat Room that consist of 1-on-1 chat between two users. This type of chat room allow you to have always same chat room between two users. Header of the room will be name of the pair. To create single chat, you will need to know the user Id of the opponent.

### Group Chat Room

When you want your many users to chat together in a single room, you need to create Group Chat Room. Basically Group Chat Room has the same concept as 1-on-1 Chat Room, but the different is that Group Chat Room will target array of user Id in a single method. The return of the function is `QiscusCore.shared.createGroup()`  you can store it in your persistent storage and then use it to enter the same room anytime you want. Maximum number of participant for now is : **100** participants

### Channel 

Channel is Chat Room which allow users to join without invitation. This will allow our user to implement our SDK to create Forum, Live Chat in Video Streaming, or Public Channel like in Forum or Telegram. Maximum number of participants in Channel for now : **5000** participants

### Chat Room Type Comparison Table 

|Item |1-1  |Group  |Channel  |
|---  |---  |---  |---  |
|Number of participant  |2  |100  |5000 |
|Sent Receipt |v  |v  |-  |
|Delivered Receipt  |v  |v  |-  |
|Read Receipt |v  |v  |-  |
|Push Notification  |v  |v  |-  |
|Unread Count |v  |v  |v  |
|Support Chatbot interface  |v  |v  |v  |
|Block User |v  |-  |-  |
|Adding or  Removing participant  |-  |v  |v  |

## User

This section contains user Qiscus Chat SDK behaviour, you can do **update user profile with additional metadata,** **block user**, **unblock user**, and **get list of blocked user.**

### Update User Profile With Metadata

You can update user's data, for example :

```
QiscusCore.shared.updateProfile(username : "yourName", avatarUrl: nil, extras: nil) { (result, error) in
     if result != nil {
          print("success")
     }else{
          print("error \(String(describing: error?.message))")
     }
}
```

Where:

* `username`: username of its user, for display name purpose if in 1-on-1 Chat Room
* `avatarUrl` : Url to display user's avatar, fallback to default avatar if not provided.
* `extras` : metadata that can be as additional information to user, which consist key-value, for example **key: position, **and** value: engineer**.

### Check Is User Authenticated

You can check whether user is authenticated or not, and make sure that a user allow to use Qiscus Chat SDK features.
When return **true** means user already authenticated, otherwise **false** means user not yet authenticate.

```
QiscusCore.isLogined //boolean
```

### Block User

You can block a user with related **user Id** parameter, this block user only works in 1-on-1 Chat Room. When a user in same Group or Channel with blocked user, a user still receive message from blocked user, for further information you can see this [User - blocked](#block-user). You can use this function by calling this method, for example: 

```
QiscusCore.shared.blockUser(email: user_email, onSuccess: { (memberUser) in
     print("success")
}) { (error) in
     print("error \(String(describing: error?.message))")
}
```

### Unblock User

You can unblock a user with related `user Id` parameter. Unblocked user can send a message again into particular Chat Room, for example: 

```
QiscusCore.shared.unblockUser(email: user_email, onSuccess: { (memberUser) in
    print("success")
}) { (error) in
    print("error \(String(describing: error?.message))")
}
```

### Get Blocked User List 

You can get blocked user list with pagination, with `page`  parameter and you can set also the `limit` number of blocked users, for example: 

```
QiscusCore.shared.listBlocked(page: page, limit: limit, onSuccess: { (memberUser) in
     print("success")
}) { (error) in
      print("error \(String(describing: error?.message))")
}
```

## Chat Room

This section consist Chat Room Qiscus Chat SDK behaviour In Chat Room you can add additional information called **options. options** is automatically synchronized by each participant in the conversation. While Qiscus has gone to great lengths to implement **options** in a way that maximizes efficiency on the wire, it is important that the amount of data stored in **options** is kept to a minimum to ensure the quickest synchronization possible. You can use **options** tag a room for changing background colour purposes, or you can add a latitude or longitude.


> **Note:** options consist string key-value pairs

### Create 1-on-1 Chat Room With Metadata

The ideal creating 1-on-1 Chat Room is for use cases that require 2 users, for further information you can see this [Chat Room-1-on-1 section](#1-on-1-chat-room). After success creating a 1-on-1 Chat room, room name is another userId.

```
QiscusCore.shared.getRoom(withUser: withUserId,options: options, onSuccess: { (roomModel, _) in
  print("success")
}) { (error) in
  print("error \(String(describing: error?.message))")  
}        
```

Where:

* `userId`:  A User identifier that will be used to identify a user and used whenever another user need to chat with this user. It can be anything, whether is is user's email, your user database index, etc. As long as it is unique and a string.
* `options:` metadata that can be as additional information to Chat Room, which consist key-value, for example **key: background, **and** value: red.**

### Create Group Chat Room With Metadata

When you want your many users to chat together in a 1-on-1 Chat Room, you need to create Group Chat Room. Basically Group Chat Room has the same concept as 1-on-1 Chat Room, but the different is that Group Chat Room will target array of user Id in a single method. 

```
/// After Create new Group room, you can update room with option
QiscusCore.shared.createGroup(withName: title, participants: users, onSuccess: { (roomModel) in
 print("success")
  //update room
  QiscusCore.shared.updateRoom(withID: roomModel.id, name: nil, avatarURL: nil, options: options, onSuccess: { (roomModel) in
     print("success update room with option")
  }, onError: { (error) in
     print("error update room \(error)")
  })
}) { (error) in
 print("error \(error)")
}        
```

You can get Channel Chat Room from your local data, for example: 

```
if let room =  QiscusCore.database.room.find(id: roomId){
    //success
}
```

### Create Or Get Channel With MetaData

The ideal creating Channel Chat Room is for use cases that requires a lot of number of participant. You need set `uniqueId` for identify a Channel Chat Room, If a Chat Room with predefined `unique id `is not exist then it create a new one with requester as the only one participant. Otherwise, if Chat Room with predefined unique id is already exist, it will return that room and add requester as a participant. 

When first call (room is not exist), if requester did not send `avatar_ur`l and/or room `name` it will use default value. But, after the second call (room is exist) and user (requester) send `avatar_url` and / or room `name`, it will be updated to that value.

```
QiscusCore.shared.getRoom(withChannel: channel, options: options, onSuccess: { (room) in
      print("success")
}) { (error) in
      print("error")
}
```

You can get Channel Chat Room from your local data, for example: 

```
if let room =  QiscusCore.database.room.find(uniqID: uniqID){
     //success
}
```

### Get Chat Room By Id (Enter Existing Chat Room)

You can enter existing Chat Room by using `roomId` and creating freely your own chat UI. The return as pair of a Chat Room and List of `Comments` that you can use to init data comment for the first time as reference you can see in sample [Sample github](https://github.com/qiscus/QiscusCore-Example). You can use to 1-on-1 Chat Room, Group Chat room or Channel, here's how to get a Chat Room by `roomId:`

```
QiscusCore.shared.getRoom(withID: roomId, onSuccess: { (roomModel,comments) in
    print("success")
}) { (error) in
     print("error \(String(describing: error?.message))")
}        
```

### Get Chat Room Opponent By UserId

You can get a Chat Room by `userId`. This only works 1-on-1 Chat Room.

```
QiscusCore.shared.getRoom(withUser: withUserId, onSuccess: { (roomModel, comments) in
  print("success")
}) { (error) in
  print("error \(String(describing: error?.message))")
}        
```

### Get Chat Rooms Information

You can get more than one Chat Room, by passing list of `roomId`, for `uniqueIds` will deprecate soon, for now you can set same as `roomIds` . You can see participant for each room by set `showMembers` to **true**, or you can set **false **to hide participant in each room.

```
QiscusCore.shared.getRooms(withId: arrayRoomID, showParticipant: false, onSuccess: { (rooms) in
     print("success")
}) { (error) in
     print(error.message)
}
```

Where:

* `withID` : array of room id
* `showParticipant`: show participant in room, default is false (optional)
* `showRemoved` : show room is removed, default is false (optional)

You can get Chat Rooms from your local data, for example:

```
let rooms = QiscusCore.database.room.all()
   //success    
}
```

### Get Chat Room List

Get Chat Room list is ideal case for retrieve all Chat Rooms that Qiscus Account has. Showing maximum 100 data per page. 

```
 QiscusCore.shared.getAllRoom(onSuccess: { (rooms, metaData) in
      print("success")
 }) { (error) in
      print("error \(error.message)")
 }
```

Where:

* `limit` : by default is 20 (optional)
* `page` : page (optional)
* `showRemoved` : show room is removed, default is false (optional)
* `showEmpty` : empty comment in room (optional)

You can get Chat Room List from your local data, for example:

```
let rooms = QiscusCore.database.room.all()
   //success    
}
```

### Update Chat Room With Metadata

You can update your Chat Room metadata, you need `roomId`, your Chat Room `name`, your Chat Room `avatar Url`, and `options`, for example:

```
 QiscusCore.shared.updateRoom(withID: roomId, options: options, onSuccess: { (rooms) in
 print("success")
}) { (error) in
 print(error.message)
}
```

Where:

* `roomId` : roomId
* `name` : room name (optional)
* `avatarUrl` : room avatar (optional)
* `options` : options is [string:any] (optional)

### Get Participant List In Chat Room

You can get participant list in Chat Room, you can get from `getRoom()` directly, from your local data, or you can retrieve from Qiscus Server.

This example code you can retrieve from object `getRoom()`

```
QiscusCore.shared.getRoom(withID: roomID, onSuccess: { (room, comments) in
            if let participant = room.participants{
                //success
            }
        }) { (error) in
            print("error =\(error.message)")
        }
```

Retrieving local data you need `roomId`, for example:

```
if let room = QiscusCore.database.room.find(id: roomID){
            if let participant = room.participants{
                //success
            }
        }
```

Retrieving from Qiscus Server, you need `roomUniqueId`, you get default 100 participants, for example:

```
QiscusCore.shared.getParticipant(roomUniqeId: roomUniqeId, onSuccess: { (participants) in
            print("success")
        }) { (error) in
            print(error.message)
        }
```

You can get advance by adding some parameter, for example you can order the list based on either ascending `(asc)` or descending `(desc)`. 

```
QiscusCore.shared.getParticipant(roomUniqeId: roomUniqeId, offset: offset, sorting: .asc, onSuccess: { (participants) in
             print("success participants=\(participants.count)")
        }) { (error) in
            print(error.message)
        }
```

Where:

* `roomUniqueId`:  unique Id each of Chat Room
* `offset`: number of offset (default is nil)
* `sorting`: filtering based on ascending (**asc)** or descending (**desc)**, by default refer to **asc**

> Note :
Default return 100 participants

### Add Participant in Chat Room

You can add more than a participant in Chat Room by calling this method `addParticipant()` you can pass multiple `userId` . Once a participant success join the Chat Room, they get new Chat Room in their Chat Room list.

```
QiscusCore.shared.addParticipant(userEmails: userEmails, roomId: roomID, onSuccess: { (participants) in
     print("sucess")               
}) { (error) in
     print("error =\(error.message)")
}
```

### Remove Participant in Chat Room

You can remove more than a participant in Chat Room by calling this method `removeParticipant()` you can pass multiple `userId` . Once a participant remove from the Chat Room, they will not find related Chat Room in their Chat Room list.

```
QiscusCore.shared.removeParticipant(userEmails: userEmails, roomId: roomID, onSuccess: { (success) in
    print("sucess")                 
}, onError: { (error) in
   print("error =\(error.message)")                     
})
```

### Get Total Unread Count In Chat Room

You can get total unread count user have in every Chat Room, ideal this case is when you want to show badge icon, for example getting total unread count:

```
QiscusCore.shared.unreadCount { (count, error) in
            if error != nil {
                print("error")
            }else{
                print("success")
            }
        }
```

## Message

This section consist of Message Qiscus Chat SDK behaviour. In Message you can add metadata called **extras.** **extras** is automatically synchronized by each participant in the Chat Room. Qiscus Chat SDK has 3 statues, Sent, Delivered, and Read for a message. 

### Send Message 

You can send a **text** message or **custom** message **type**. Ideal case for **custom** message is for creating custom UI message needs by sending structured data, such as you need to **send location** message, a **ticket concert** message, a **product** info, and others UI message that need to be customized. You need to create  CommentModel() object first before sending it, for example: 

Create CommentModel object, **text** type :

```
let message = CommentModel()
message.message = "textComment"
message.type    = "text"
QiscusCore.shared.sendMessage(roomID: roomId, comment: message, onSuccess: { (commentModel) in
    //success
}) { (error) in
    print(error.message)
}
```

Create CommentModel object, **custom** type :

```
let message = CommentModel()
message.message = "textComment"
message.type    = "yourtype"
message.payload = yourPayload
```

Where:

* `roomId`:  ChatRoom Identity (Id), you can get this Id in RoomModel object 
* `text`: message text that you send to other participant
* `type`: message type, that you can define freely, there are predefined rich messages **type, for example: text, file_attachment, account_linking, buttons, button_postback_response, replay, system_event, card, custom, location, contact_person, carousel.** These type have taken, if you use it you may face your structured data will not work, these type for bot API, hence you need define other type name.
* `payload`: Payload for defining the structured message data, for example you want to create your own **file** message, you can fill the `content` using this example JSON :

```
{
  "url": "https://d1edrlpyc25xu0.cloudfront.net/sampleapp-65ghcsaysse/docs/upload/2sxErjgAfp/Android-Studio-Shortcuts-You-Need-the-Most-3.pdf",
  "caption": "",
  "file_name": "Android-Studio-Shortcuts-You-Need-the-Most.pdf"
}
```

You can find how to implement this `content` in Sample [[l](https://github.com/qiscus/QiscusCore-Example)[ink sample](https://github.com/qiscus/QiscusCore-Example)].  Another example `content` you can craft:

```
{
  "cards": [
    {
      "header": {
        "title": "Pizza Bot Customer Support",
        "subtitle": "pizzabot@example.com",
        "imageUrl": "https://goo.gl/aeDtrS",
        "imageStyle": "IMAGE"
      },
    ...
    }
  ]
}
```

You can add **extras** before sending a message, for example:

```
let extraData : [String: Any] =[
            "data": [
                "latitude" : 9091234123,
                "longtitue": -9091234123,
            ]
           ]
        

let message = CommentModel()
message.message = "textComment"
message.type    = "yourtype"
message.extras  = extraData
```

> Note: 
Metadata is automatically synchronized by each participant in the Chat Room, it is important that the amount of data stored in metadata is kept to a minimum to ensure the quickest synchronization possible.


Secondly, you can send a message using `sendMessage()`  method and need a message / commentModel as parameter, for example:

```
QiscusCore.shared.sendMessage(roomID: roomId, comment: message, onSuccess: { (commentModel) in
    //success
}) { (error) in
    print(error.message)
}
```


### Update Message Read Status

You can set your message status into **read**, the ideal case of this is to notify other participant that a message has **read.**
You need to pass `roomId ` and lastCommentReadId.  When you have **10 messages**, and the latest message Id, let say is **10**, once you set read message status with the latest message, in this case is **10**, your previous messages will update into **read** as well. You can update message read status by calling updateCommentRead method, for example:

```
/// Mark Comment as read, include comment before
QiscusCore.shared.updateCommentRead(roomId: roomId, lastCommentReadId: commentId)
```

### Load Message (With *Limit* And *Offset*)

You can get previous messages by calling loadComments method, by default you get 20 messages start from your `lastCommentId`, and also you can use this for load more the older messages, for example:

```
 QiscusCore.shared.loadComments(roomID: roomID, lastCommentId: lastCommentId, limit: 20, onSuccess: { (comments) in
       print("success")
 }) { (error) in
       print("error =\(error.message)")
}
```

Where:


* `roomId` : ChatRoom Id
* `lastCommentId`: messageId that you can get from commentModel object 

You can a get from local data, you can set `limit` to get number of comments, for example:

```
if let comments = QiscusCore.database.comment.find(id: "roomId"){
    //success
}
```

### Viewing Who Has Read, Delivered A Message

You can get information who has read your message by passing `commentId` in return you get participants who have **sent**, **delivered**, and **read** message status, for example: 

```
 QiscusCore.shared.readReceiptStatus(commentId: commentId, onSuccess: { (commentInfo) in
            let comment = commentInfo.comment
            let deliveredUser = commentInfo.deliveredUser
            let readUser = commentInfo.readUser
            let sentUser = commentInfo.sentUser
        }) { (error) in
            print("error =\(error.message)")
        }
```

### Upload File

You can send a raw file into by passing `file` Qiscus Chat SDK, in return you will get `Uri`  and `progress listener`.

```
QiscusCore.shared.upload(data: data, filename: fileName, onSuccess: { (fileModel) in
      print("success")
}, onError: { (error) in
      print("error \(String(describing: error?.message))")
}) { (progress) in
      print("progress \(progress)")    
}
```

### Download Media (The *Path *And % Of Process)

You can download file by passing `url` and return you get progress listener. You can use this listener to create your own progress UI, for example:

```
QiscusCore.shared.download(url: url, onSuccess: { (urlFile) in
      print("success")
}) { (progress) in
      print("progress \(progress)")
}
 
```

### Delete Message

You can delete a message by calling this `deleteMessage()` method , and passing parameter array of comment uniqueIDs for example:

```
QiscusCore.shared.deleteMessage(uniqueIDs: uniqueIDs, onSuccess: { (comments) in
             print("success")
        }) { (error) in
             print("error \(String(describing: error.message))")
        }
```

### Clear All Messages 

You can clear all message by passing array of `roomId`  or `roomUniqueIds` this clear all messages only effect `QiscusAccount` side, other participants still remain. For example:

```
QiscusCore.shared.deleteAllMessage(roomID: roomsID) { (error) in
     print("error \(error?.message)")
}
```

roomUniqueIds you can get in RoomModel object 

```
QiscusCore.shared.deleteAllMessage(roomUniqID: roomsID) { (error) in
     print("error \(error?.message)")
}
```

## Event Handler

Qiscus Chat SDK provides a simple way to let applications publish and listen some real time event. You can publish **typing, read, user status, custom event** and you can handle freely in event handler. This lets you inform users that another participant is actively engaged in communicating with them.

Qiscus Chat SDK is using delegate for broadcasting event to entire application. What you need to do is registering the object which will receive event from delegate.

### Event Handler In Chat Room

You need register delegate:

```
//set your delegate in viewWillAppear
func setRoomDelegage(){
    if let room = self.room {
         room.delegate = self
     }       
}
```

You need unregister the receiver after you don't need to listen event anymore by calling this method:

```
//remove your delegate in viewWillDisappear
func removeRoomDelegate() {
    if let room = self.room {
         room.delegate = nil
    }
}
```

This is example how ViewController can receive event from delegate: 

```
extension YourViewController : QiscusCoreRoomDelegate {
    // MARK: Comment Event in Room
    
    /// new comment is comming
    ///
    /// - Parameters:
    ///   - comment: new comment object
    func gotNewComment(comment: CommentModel){

    }
    
    /// comment status change
    ///
    /// - Parameters:
    ///   - comment: new comment where status is change, you can compare from local data
    ///   - status: comment status, exp: deliverd, receipt, or read.
    ///     special case for read, for example we have message 1,2,3,4,5 then you got status change for message 5 it's mean message 1-4 has been read
    func didComment(comment: CommentModel, changeStatus status: CommentStatus){

    }
    
    /// Deleted Comment
    ///
    /// - Parameter comment: comment deleted
    func didDelete(Comment comment: CommentModel){

    }
    
    // MARK: User Event in Room
    
    /// User Typing Indicator
    ///
    /// - Parameters:
    ///   - user: object user or participant
    ///   - typing: true if user start typing and false when finish typing. typing time avarange is 5-10s, we assume user typing is finish after that
    func onRoom(thisParticipant user: MemberModel, isTyping typing: Bool){

    }
    
    /// User Online status
    ///
    /// - Parameters:
    ///   - user: object member
    ///   - status: true if user login
    ///   - time: millisecond UTC
    func onChangeUser(_ user: MemberModel, onlineStatus status: Bool, whenTime time: Date){

    }
    
    /// Room update
    ///
    /// - Parameter room: new room object
    func onRoom(update room: RoomModel){

    }
}
```

> Note: don't forget to import QiscusCore

### **Event Handler In List Chat Room**

You need register delegate:

```
//set your delegate in viewWillAppear
private func setDelegate() {
    QiscusCore.delegate = self
}
```

You need unregister the receiver after you don't need to listen event anymore by calling this method:

```
//remove your delegate in viewWillDisappear
func removeRoomDelegate() {
    if let room = self.room {
         room.delegate = nil
    }
}
```

This is example how ViewController can receive event from delegate: 

```
extension YourViewController : QiscusCoreDelegate {
    // MARK: Event Room List
    
    /// new comment is comming
    ///
    /// - Parameters:
    ///   - room: room where event happen
    ///   - comment: new comment object
    func onRoom(_ room: RoomModel, gotNewComment comment: CommentModel){

    }
    
    /// comment status change
    ///
    /// - Parameters:
    ///   - room: room where event happen
    ///   - comment: new comment where status is change, you can compare from local data
    ///   - status: comment status, exp: deliverd, receipt, or read.
    ///     special case for read, for example we have message 1,2,3,4,5 then you got status change for message 5 it's mean message 1-4 has been read
    func onRoom(_ room: RoomModel, didChangeComment comment: CommentModel, changeStatus status: CommentStatus){

    }
    
    /// Deleted Comment
    ///
    /// - Parameter comment: comment deleted
    func onRoom(_ room: RoomModel, didDeleteComment comment: CommentModel){

    }
    
    // MARK: User Event in Room
    
    /// User Typing Indicator
    ///
    /// - Parameters:
    ///   - room: room where event happen
    ///   - user: object user or participant
    ///   - typing: true if user start typing and false when finish typing. typing time avarange is 5-10s, we assume user typing is finish after that
    func onRoom(_ room: RoomModel, thisParticipant user: MemberModel, isTyping typing: Bool){

    }
    
    /// Room update
    ///
    /// - Parameter room: new room object
    func onRoom(update room: RoomModel){

    }
    
    /// Deleted room
    ///
    /// - Parameter room: object room
    func onRoom(deleted room: RoomModel){

    }
    
    /// User Online status
    ///
    /// - Parameters:
    ///   - user: object member
    ///   - status: true if user login
    ///   - time: millisecond UTC
    func onChange(user: MemberModel, isOnline online: Bool, at time: Date){

    }

    /// Got New Room
    ///
    /// - Parameters:
    ///   - room: object room
    func gotNew(room: RoomModel){

    }

    /// Got clear all message in Room
    ///
    /// - Parameters:
    ///   - room: object room
    func remove(room: RoomModel){

    }
}
```

> Note: don't forget to import QiscusCore



Here's Event Delegate In Chat Room Table:

|Method |When to call   |
|---  |---  |
|gotNewComment(comment: CommentModel) |when you get new comment |
|didComment(comment: CommentModel, changeStatus status: CommentStatus)  |when you get comment change, like status read, delivered, sent, and pending  |
|didDelete(Comment comment: CommentModel) |when you get  comment delete  from other user or self  |
|onRoom(thisParticipant user: MemberModel, isTyping typing: Bool) |when other user is typing  |
|onChangeUser(_ user: MemberModel, onlineStatus status: Bool, whenTime time: Date)  |when other user is online  |
|onRoom(update room: RoomModel) |when any update room from self or from other user  |

Here's Event Delegate In List Chat Room Table:

|Method |When to call   |
|---  |---  |
|onRoom(_ room: RoomModel, gotNewComment comment: CommentModel) |when you get new comment |
|onRoom(_ room: RoomModel, didChangeComment comment: CommentModel, changeStatus status: CommentStatus)  |when you get comment change, like status read, delivered, sent, and pending  |
|onRoom(_ room: RoomModel, didDeleteComment comment: CommentModel)  |when you get  comment delete  from other user or self  |
|onRoom(_ room: RoomModel, thisParticipant user: MemberModel, isTyping typing: Bool)  |when other user is typing  |
|onRoom(update room: RoomModel) |when you get any update room from self or from other user  |
|onRoom(deleted room: RoomModel)  |when you get a delete room |
|onChange(user: MemberModel, isOnline online: Bool, at time: Date)  |when other user is online  |
|gotNew(room: RoomModel)  |when you get new room  |
|remove(room: RoomModel)  |when you get a delete room |


### Subscribe Typing in outside Chat Room
You can subscribe typing manualy, example like this, this will trigger `onRoom(_ room: RoomModel, thisParticipant user: MemberModel, isTyping typing: Bool)` event handler 

```
for room in rooms {
  DispatchQueue.global(qos: .background).asyncAfter(deadline: .now()+1, execute: {
    QiscusCore.shared.subscribeTyping(roomID: room.id) { (roomTyping) in
       if let room = QiscusCore.database.room.find(id: roomTyping.roomID){
         //update you tableView cell
       }
    }
  })
}
```

### UnSubscribe Typing
You can unsubscribe typing using this method, it will stop getting typing event on Chat Room List.
```
  QiscusCore.shared.unsubscribeTyping(roomID: roomID)
```


### Start And Stop Typing Indicator

You can have typing indicator by publish the typing event in Chat Room. You need to pass `roomId` and `typing` status. Set **true** to indicate the `typing` event is active, set **false** to indicate the event is inactive. The ideal of this case is if you can put this to any class for example, you need to put in Homepage, to notify that there's an active user. for example:

```
QiscusCore.shared.isTyping(true, roomID: r.id)
```

### Custom Realtime Event

You can publish and listen any events such as when **participant is listening music**, **writing document**, and many other case that you need to tell an event to other participant in a Chat Room. 

Firstly you need passing `roomId` which ChatRoom you want to set, and the structured `data` for defining what event you want to send. Example of structured `data` of **writing document** event:

```
{
  "sender": "John Doe",
  "event": "writing document...",
  "active": "true"
}
```

Then you can send event using this following method publishEvent: 

```
let publish = QiscusCore.shared.publishEvent(roomID: roomId, payload: payload)
```

If you need to stop telling other participant that event is ended, you can send a flag to be **false** inside your structured data, for example:

```
{
  "sender": "John Doe",
  "event": "writing document...",
  "active": "false"
}
```

After sending an event, then you need to listen the event with related `roomId`,  for example:

```
QiscusCore.shared.subscribeEvent(roomID: roomID) { (roomEvent) in
            print(roomEvent.sender)
            print(roomEvent.data)
}
```

You need unlisten the event with related `roomId`, for example:

```
QiscusCore.shared.unsubscribeEvent(roomID: roomID)
```

## Push Notification

The Qiscus Chat SDK receives pushes through both the Qiscus Chat SDK protocol and Apple Push Notification Service (APNS), depending on usage and other conditions. Default notification sent by Qiscus Chat SDK protocol. In order to enable your application to receive apple push notifications, some setup must be performed in both application and the Qiscus Dashboard.

Do the following steps to setup push notifications:

1. Create a Certificate Signing Request(CSR).
2. Create a Push Notification SSL certificate in Apple Developer site.
3. Export a p12 file and upload it to Qiscus Dashboard.
4. Register a device token in Qiscus SDK and parse Qiscus APNS messages.

### Step 1:  Create A Certificate Signing Request(CSR)

Open **Keychain Access** on your Mac (Applications -> Utilities -> Keychain Access). Select **Request a Certificate From a Certificate Authority**.
<p align="center"><br/><img src="https://d3p8ijl4igpb16.cloudfront.net/docs/assets/apns1.png" width="100%" /><br/></p>

In the **Certificate Information** window, do the following:

* In the **User Email Address** field, enter your email address.
* In the **Common Name** field, create a name for your private key (for example, John Doe Dev Key).
* The **CA Email Address** field must be left empty.
* In the **Request is** group, select the **Saved to disk** option.

<p align="center"><br/><img src="https://d3p8ijl4igpb16.cloudfront.net/docs/assets/apns2.png" width="100%" /><br/></p>

### Step 2: Create A Push Notification SSL Certificate In Apple Developer Site.

Log in to the [Apple Developer Member Center](https://developer.apple.com/) and find the **Certificates, Identifiers & Profiles** menu. Select **App IDs**, find your target application, and click the **Edit** button.
<p align="center"><br/><img src="https://d3p8ijl4igpb16.cloudfront.net/docs/assets/apns3.png" width="100%" /><br/></p>

<p align="center"><br/><img src="https://d3p8ijl4igpb16.cloudfront.net/docs/assets/apns4.png" width="100%" /><br/></p>

Turn on **Push Notifications** and create a development or production certificate to fit your purpose. 
<p align="center"><br/><img src="https://d3p8ijl4igpb16.cloudfront.net/docs/assets/apns5.png" width="100%" /><br/></p>
Upload the **CSR file** that you created in section (1) to complete this process. After doing so, download a **SSL certificate**.
Double-click the file and register it to your **login keychain.**


### Step 3: Export A p12 File and Upload It To Qiscus Dashboard

Under the Keychain Access, click the Certificates category from the left menu. Find the Push SSL certificate you just registered and right-click it without expanding the certificate. Then select Export to save the file to your disk.

<p align="center"><br/><img src="https://d3p8ijl4igpb16.cloudfront.net/docs/assets/apns6.png" width="100%" /><br/></p>

<p align="center"><br/><img src="https://d3p8ijl4igpb16.cloudfront.net/docs/assets/apns7.png" width="100%" /><br/></p>

<p align="center"><br/><img src="https://d3p8ijl4igpb16.cloudfront.net/docs/assets/apns8.png" width="100%" /><br/></p>

Then, log in to the [dashboard](https://www.qiscus.com/dashboard/login) and upload your `.p12` file to the Push Notification section, under Settings.

<p align="center"><br/><img src="https://d3p8ijl4igpb16.cloudfront.net/docs/assets/apns9.png" width="100%" /><br/></p>

klik add and fill the form upload certificates

<p align="center"><br/><img src="https://d3p8ijl4igpb16.cloudfront.net/docs/assets/apns10.png" width="100%" /><br/></p>

### Step 4: Register A Device Token In Qiscus SDK And Parse Qiscus APNS Messages.   

In your app's AppDelegate, store your device token as a variable.

```
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        if #available(iOS 10.0, *) {
            // For iOS 10 display notification (sent via APNS)
            UNUserNotificationCenter.current().delegate = self
            
            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            UNUserNotificationCenter.current().requestAuthorization(
                options: authOptions,
                completionHandler: {_, _ in })
        } else {
            let settings: UIUserNotificationSettings =
                UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            application.registerUserNotificationSettings(settings)
        }
        
        application.registerForRemoteNotifications()
        
        return true
    }
```

```
func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        
        var tokenString: String = ""
        for i in 0..<deviceToken.count {
            tokenString += String(format: "%02.2hhx", deviceToken[i] as CVarArg)
        }
        print("token = \(tokenString)")
        QiscusCore.shared.register(deviceToken: tokenString, onSuccess: { (response) in
            //
        }) { (error) in
            //
        }
    }
    

func application(_ application: UIApplication, didReceive notification: UILocalNotification) {
       print("AppDelegate. didReceive: \(notification)")
}
    
func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any]) {
        print("AppDelegate. didReceiveRemoteNotification: \(userInfo)")
}
    
func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print("AppDelegate. didReceiveRemoteNotification2: \(userInfo)")
}

// [START ios_10_message_handling]
@available(iOS 10, *)
extension AppDelegate : UNUserNotificationCenterDelegate {
    
    // Receive displayed notifications for iOS 10 devices.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        
        // Print full message.
        print(userInfo)
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        
        
        // Print full message.
        print(userInfo)
        
        completionHandler()
    }
}
// [END ios_10_message_handling]
```

Don't forget set **Remote notifications and Background fetch** in menu **Capabilities**

<p align="center"><br/><img src="https://d3p8ijl4igpb16.cloudfront.net/docs/assets/apns11.png" width="100%" /><br/></p>

### Turning Off Push Notification 

You can turning off your push notification, for example:

```
QiscusCore.shared.remove(deviceToken: deviceToken, onSuccess: { (response) in
            print("sucess")
        }) { (error) in
            print(error.message)
        }
```

## Migration From Previous Version 

if you use Qiscus Chat SDK v2.8.xx to Qiscus Chat SDK v2.9.xx, you will migration data to new database. You need call method `QiscusCore.isLogined()`

```
if QiscusCore.isLogined {
       target = YourViewController()
       // Connect to Qiscus server
       _ = QiscusCore.connect()
 }else {
     //force logout
     target = LoginViewController()
 }
```

## Change Log
You can see the change log by clicking this link
https://github.com/qiscus/QiscusCore-iOS/releases

## API Reference 
You can see the API Reference by clicking this link
https://qiscuscoreios.firebaseapp.com/index.html

## On Premise 

Qiscus Chat SDK is available to be deployed on premise option. For further information you might contact  at [contact.us@qiscus.com](mailto:contact.us@qiscus.com.)

## Support  

If you are facing any issue in the Qiscus Chat SDK then you can contact us and share as much information as you can. 
Firstly, you can enable the **debugger** to get the logs, we recommend to use these debugger only in development environment. You can enable or disable the **debugger** using `enableDebugPrint` method for example: 

```
QiscusCore.enableDebugPrint = true
```

Then, you can sent the inquiries in our support platform https://support.qiscus.com/hc/en-us/requests/new with information that you have.


> Note: Enable debugger only in development environment 


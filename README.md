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
| **Local Database**                       | InProgress, already cache api response. |
| **Local Storage**                       | Not Yet. |

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
- [x] [Complete Documentation](https://qiscus.com)

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


### Security Disclosure

If you believe you have identified a security vulnerability with QiscusCore, you should report it as soon as possible via email to juang@qiscus.co. Please do not post it to a public issue.


## FAQ

### When we use QiscusCore intead Qiscus?

QiscusCore is lite version chat sdk, if you wan't to build your own chat ui best option is use QiscusCore. But, if you need in App chat quickly use Qiscus Chat SDK(build in UI and simple configuration). please visit [Qiscus](https://github.com/qiscus/qiscus-sdk-ios) to use qiscus chat sdk.

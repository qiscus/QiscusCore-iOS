# [QiscusCore](https://github.com/qiscus) - Messaging and Chat Core API for iOS
[Qiscus](https://qiscus.com) Enable custom in-app messaging in your Mobile App and Web using Qiscus Chat SDK and Messaging API

[![Platform](https://img.shields.io/badge/platform-iOS-orange.svg)](https://cocoapods.org/pods/QiscusCore)
[![Languages](https://img.shields.io/badge/language-Objective--C%20%7C%20Swift-orange.svg)](https://github.com/qiscus)
[![CocoaPods](https://img.shields.io/badge/pod-v3.0.109-green.svg)](https://cocoapods.org/pods/QiscusCore)


## Installation Cocoapods

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
    pod 'QiscusCore'
end
```

Then, run the following command:

```bash
$ pod install
```

## Installation Carthage
[Carthage](https://github.com/Carthage/Carthage) is a decentralized dependency manager that builds your dependencies and provides you with binary frameworks. To integrate QiscusCore into your Xcode project using Carthage, specify it in your Cartfile:

```bash
$ github "qiscus/QiscusCore-iOS" "carthage-support"
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


## Docs

for other documents can be viewed on this page, [Qiscus Docs](https://documentation.qiscus.com/chat-sdk-ios)


## Example

You can download example how to use QiscusCore with advance usage from [QiscusCore Example](https://github.com/qiscus/qiscus-chat-sdk-ios-sample).

## Security Disclosure / Question / Other

If you any security disclosure, question, or other, you can make [Ticket](https://support.qiscus.com/hc/en-us/requests/new)



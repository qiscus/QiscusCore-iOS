# [QiscusRealtime](https://github.com/qiscus/QiscusRealtime-iOS) - Messaging and Chat Core API for iOS
[Qiscus](https://qiscus.com) Enable custom in-app messaging in your Mobile App and Web using Qiscus Chat SDK and Messaging API

[![Platform](https://img.shields.io/badge/platform-iOS-orange.svg)](https://github.com/qiscus/QiscusRealtime-iOS)
[![Languages](https://img.shields.io/badge/language-Objective--C%20%7C%20Swift-orange.svg)](https://github.com/qiscus)
[![CocoaPods](https://img.shields.io/badge/pod-v3.0.109-green.svg)](https://github.com/qiscus/QiscusRealtime-iOS)


## Requirements

- iOS 10.0+
- minimum Xcode 11.4.1
- Swift 5

## Dependency

- CocoaMQTT

## Features

- [x] Config Realtime Server. 
- [x] Connect with username and qiscus token.
- [x] Publish typing and online status.
- [x] Subscribe(receive) new comment, online status, typing, deliverd and read comment.
- [x] [Complete Documentation](https://qiscusrealtime.firebaseapp.com)

## Component Libraries

In order to keep QiscusRealtime focused specifically on realtime event implementation, additional libraries have been create by the [Qiscus IOS] (https://qiscus.com).

* [QiscusCore](https://github.com/qiscus) - Chat Core API, All chat functionality already on there.
* [QiscusUI](https://github.com/qiscus) - An chat component library, make it easy to custom your chat UI.
* [Qiscus](https://github.com/qiscus) - An chat sdk with complete feature, simple, easy to integrate.


## Installation

[CocoaPods](https://cocoapods.org) is a dependency manager for Cocoa projects. You can install it with the following command:

```bash
$ gem install cocoapods
```

To integrate QiscusRealtime into your Xcode project using CocoaPods, specify it in your `Podfile`:

```ruby
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '10.0'
use_frameworks!

target '<Your Target Name>' do
    pod 'QiscusRealtime'
end
```

Then, run the following command:

```bash
$ pod install
```

[Carthage](https://github.com/Carthage/Carthage) is a decentralized dependency manager that builds your dependencies and provides you with binary frameworks. To integrate MultichannelWidget into your Xcode project using Carthage, specify it in your Cartfile:

```bash
$ github "qiscus/QiscusRealtime-iOS" "carthage-support"
```

### Security Disclosure

If you believe you have identified a security vulnerability with QiscusRealtime, you should report it as soon as possible via email to juang@qiscus.co. Please do not post it to a public issue.


## FAQ

### When we use Qiscus

intead Qiscus?

QiscusCore is lite version chat sdk, if you wan't to build your own chat ui best option is use QiscusCore. But, if you need in App chat quickly use Qiscus Chat SDK(build in UI and simple configuration). please visit [Qiscus](https://github.com/qiscus/qiscus-chat-sdk-ios-sample) to use qiscus chat sdk.



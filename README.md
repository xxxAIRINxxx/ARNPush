# ARNPush

[![CI Status](http://img.shields.io/travis/xxxAIRINxxx/ARNPush.svg?style=flat)](https://travis-ci.org/xxxAIRINxxx/ARNPush)
[![Version](https://img.shields.io/cocoapods/v/ARNPush.svg?style=flat)](http://cocoadocs.org/docsets/ARNPush)
[![License](https://img.shields.io/cocoapods/l/ARNPush.svg?style=flat)](http://cocoadocs.org/docsets/ARNPush)
[![Platform](https://img.shields.io/cocoapods/p/ARNPush.svg?style=flat)](http://cocoadocs.org/docsets/ARNPush)

## Usage

To run the example project, clone the repo, and run `pod install` from the Example directory first.

```objective-c

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [ARNPush setAlertBlock:^(NSDictionary *userInfo) {
        NSLog(@"Call ARNPush Alert Block");
    }];

    [ARNPush setSoundBlock:^(NSDictionary *userInfo) {
        NSLog(@"Call ARNPush Sound Block");
    }];

    [ARNPush setBadgeBlock:^(NSDictionary *userInfo) {
        NSLog(@"Call ARNPush Badge Block");
    }];

    [ARNPush registerForTypes:(UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge)
                launchOptions:launchOptions];

    return YES;
}

```

## Requirements

* iOS 7.0+
* ARC

## Installation

ARNPush is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

    pod "ARNPush"

## License

ARNPush is available under the MIT license. See the LICENSE file for more info.


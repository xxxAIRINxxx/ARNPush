//
//  ARNPush.h
//  ARNPush
//
//  Created by Airin on 2014/10/08.
//  Copyright (c) 2014 Airin. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^ARNPushBlock)(NSDictionary *userInfo);
typedef void (^ARNPushDeviceTokenBlock)(NSData *deviceToken, NSError *error);
typedef void (^ARNPushBackgroundFetchsBlock)(NSDictionary *userInfo, void (^resultBlock)(UIBackgroundFetchResult result));
typedef void (^ARNPushHandleActionBlock)(NSString *identifier, NSDictionary *userInfo, void (^completionHandler)());

@interface ARNPush : NSObject

+ (void)setup;

+ (NSData *)deviceToken;

+ (NSString *)deviceTokenString;

+ (NSString *)stringFromDeviceToken:(NSData *)deviceToken;

+ (void)canReceivedPush:(BOOL)canReceivedPush;

+ (void)setDeviceTokenBlock:(ARNPushDeviceTokenBlock)deviceTokenBlock;

+ (void)setAlertBlock:(ARNPushBlock)alertBlock;

+ (void)setSoundBlock:(ARNPushBlock)soundBlock;

+ (void)setBadgeBlock:(ARNPushBlock)badgeBlock;

+ (void)setBackgroundFetchBlock:(ARNPushBackgroundFetchsBlock)backgroundFetchBlock;

+ (void)setHandleActionBlock:(ARNPushHandleActionBlock)handleActionBlock NS_AVAILABLE_IOS(8_0);

+ (void)registerForTypes:(UIRemoteNotificationType)types
              categories:(NSSet *)categories; // categories is iOS8 Only uses

@end

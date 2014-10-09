//
//  ARNPush.h
//  ARNPush
//
//  Created by Airin on 2014/10/08.
//  Copyright (c) 2014 Airin. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^ARNPushDeviceTokenBlock)(NSString *deviceToken, NSError *error);
typedef void (^ARNPushBlock)(NSDictionary *userInfo);

@interface ARNPush : NSObject

+ (void)canReceivedPush:(BOOL)canReceivedPush;

+ (void)setDeviceTokenBlock:(ARNPushDeviceTokenBlock)deviceTokenBlock;

+ (void)setAlertBlock:(ARNPushBlock)alertBlock;

+ (void)setSoundBlock:(ARNPushBlock)soundBlock;

+ (void)setBadgeBlock:(ARNPushBlock)badgeBlock;

+ (void)registerForTypes:(UIRemoteNotificationType)types
           launchOptions:(NSDictionary *)launchOptions
              categories:(NSSet *)categories; // categories is iOS8 Only uses

@end

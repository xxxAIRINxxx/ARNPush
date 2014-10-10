//
//  ARNPush.m
//  ARNPush
//
//  Created by Airin on 2014/10/08.
//  Copyright (c) 2014 Airin. All rights reserved.
//

#import "ARNPush.h"

#import <objc/runtime.h>

#if !__has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

static BOOL ARNPush_canReceivedPush_ = NO;

static ARNPushDeviceTokenBlock ARNPush_deviceTokenBlock_ = nil;
static ARNPushBlock ARNPush_alertBlock_ = nil;
static ARNPushBlock ARNPush_soundBlock_ = nil;
static ARNPushBlock ARNPush_badgeBlock_ = nil;
static ARNPushBackgroundFetchsBlock ARNPush_backgroundFetchBlock_ = nil;
static ARNPushHandleActionBlock ARNPush_handleActionBlock_ = nil;

static void ARNPushReplaceClassMethod(Class class, SEL originalSelector, id block) {
    IMP newIMP = imp_implementationWithBlock(block);
    class_replaceMethod(class, originalSelector, newIMP, method_getTypeEncoding(class_getInstanceMethod(class, originalSelector)));
}

@implementation ARNPush

+ (BOOL)isiOS8orLater
{
    if (([[[UIDevice currentDevice] systemVersion] compare:@"8" options:NSNumericSearch] != NSOrderedAscending)) {
        return YES;
    } else {
        return NO;
    }
}

+ (void)canReceivedPush:(BOOL)canReceivedPush
{
    ARNPush_canReceivedPush_ = canReceivedPush;
}

+ (void)setDeviceTokenBlock:(ARNPushDeviceTokenBlock)deviceTokenBlock
{
    ARNPush_deviceTokenBlock_ = [deviceTokenBlock copy];
}

+ (void)setAlertBlock:(ARNPushBlock)alertBlock
{
    ARNPush_alertBlock_ = [alertBlock copy];
}

+ (void)setSoundBlock:(ARNPushBlock)soundBlock
{
    ARNPush_soundBlock_ = [soundBlock copy];
}

+ (void)setBadgeBlock:(ARNPushBlock)badgeBlock
{
    ARNPush_badgeBlock_ = [badgeBlock copy];
}

+ (void)setBackgroundFetchBlock:(ARNPushBackgroundFetchsBlock)backgroundFetchBlock
{
    ARNPush_backgroundFetchBlock_ = [backgroundFetchBlock copy];
}

+ (void)setHandleActionBlock:(ARNPushHandleActionBlock)handleActionBlock
{
    ARNPush_handleActionBlock_ = [handleActionBlock copy];
}

+ (void)registerForTypes:(UIRemoteNotificationType)types
           launchOptions:(NSDictionary *)launchOptions
              categories:(NSSet *)categories
{
    ARNPush_canReceivedPush_ = YES;
    
    UIApplication *app = [UIApplication sharedApplication];
    if ([[self class] isiOS8orLater]) {
        [app registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:(UIUserNotificationType)types
                                                                                categories:categories]];
        
        [app registerForRemoteNotifications];
    } else {
        [app registerForRemoteNotificationTypes:types];
    }
    
    NSDictionary *userInfo = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
    if (userInfo) {
        [[self class] pushNotificationWithUserInfo:userInfo];
    }
    
    ARNPushReplaceClassMethod([app.delegate class],
                              @selector(application:didRegisterForRemoteNotificationsWithDeviceToken:),
                              ^(id selfObj, id app, NSData *data) {
                                  [[self class] didRegisterForRemoteNotificationsWithDeviceToken:data];
                              });
    ARNPushReplaceClassMethod([app.delegate class],
                              @selector(application:didFailToRegisterForRemoteNotificationsWithError:),
                              ^(id selfObj, id app, NSError *error) {
                                  [[self class] didFailToRegisterForRemoteNotificationsWithError:error];
                              });
    ARNPushReplaceClassMethod([app.delegate class],
                              @selector(application:didReceiveRemoteNotification:),
                              ^(id selfObj, id app, NSDictionary *userInfo) {
                                  [[self class] didReceiveRemoteNotification:userInfo];
                              });
    ARNPushReplaceClassMethod([app.delegate class],
                              @selector(application:didReceiveRemoteNotification:fetchCompletionHandler:),
                              ^(id selfObj, id app, NSDictionary *userInfo, void (^resultBlock)(UIBackgroundFetchResult result)) {
                                  [[self class] didReceiveRemoteNotification:userInfo fetchCompletionHandler:resultBlock];
                              });
    if ([[self class] isiOS8orLater]) {
        ARNPushReplaceClassMethod([app.delegate class],
                                  @selector(application:handleActionWithIdentifier:forRemoteNotification:completionHandler:),
                                  ^(id selfObj, id app, NSString *identifier, NSDictionary *userInfo, void (^completionHandler)()) {
                                      [[self class] handleActionWithIdentifier:identifier
                                                         forRemoteNotification:userInfo
                                                             completionHandler:completionHandler];
                                  });
    }
}

+ (void)pushNotificationWithUserInfo:(NSDictionary *)userInfo
{
    if (!ARNPush_canReceivedPush_) {
        return;
    }
    
    BOOL pushAlert = NO;
    BOOL pushSound = NO;
    BOOL pushBadge = NO;
    
    NSUInteger notificationTypes;
    
    if ([[self class] isiOS8orLater]) {
        UIUserNotificationSettings *notificationSettings = [[UIApplication sharedApplication] currentUserNotificationSettings];
        notificationTypes = notificationSettings.types;
    } else {
        notificationTypes = [[UIApplication sharedApplication] enabledRemoteNotificationTypes];
    }
    
    if (notificationTypes == UIRemoteNotificationTypeNone) {
        
    } else if (notificationTypes == UIRemoteNotificationTypeBadge) {
        pushBadge = YES;
    } else if (notificationTypes == UIRemoteNotificationTypeAlert) {
        pushAlert = YES;
    } else if (notificationTypes == UIRemoteNotificationTypeSound) {
        pushSound = YES;
    } else if (notificationTypes == (UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeAlert)) {
        pushBadge = YES;
        pushAlert = YES;
    } else if (notificationTypes == (UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound)) {
        pushBadge = YES;
        pushSound = YES;
    } else if (notificationTypes == (UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound)) {
        pushAlert = YES;
        pushSound = YES;
    } else if (notificationTypes == (UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound)) {
        pushBadge = YES;
        pushAlert = YES;
        pushSound = YES;
    }
    
    if (pushAlert && ARNPush_alertBlock_) {
        ARNPush_alertBlock_(userInfo);
    }
    if (pushSound && ARNPush_soundBlock_) {
        ARNPush_soundBlock_(userInfo);
    }
    if (pushBadge && ARNPush_badgeBlock_) {
        ARNPush_badgeBlock_(userInfo);
    }
}

// -------------------------------------------------------------------------------------------------------------------------------//
#pragma mark - Method Swizzling

+ (void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    NSString *deviceTokenString = [[deviceToken description] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]];
    
    deviceTokenString = [deviceTokenString stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    if (ARNPush_deviceTokenBlock_) {
        ARNPush_deviceTokenBlock_(deviceTokenString, nil);
    }
}

+ (void)didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    if (ARNPush_deviceTokenBlock_) {
        ARNPush_deviceTokenBlock_(nil, error);
    }
}

+ (void)didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    [[self class] pushNotificationWithUserInfo:userInfo];
}

+ (void)didReceiveRemoteNotification:(NSDictionary *)userInfo
              fetchCompletionHandler:(void (^)(UIBackgroundFetchResult result))completionHandler
{
    if (ARNPush_backgroundFetchBlock_) {
        ARNPush_backgroundFetchBlock_(userInfo, completionHandler);
    }
}

+ (void)handleActionWithIdentifier:(NSString *)identifier
             forRemoteNotification:(NSDictionary *)userInfo
                 completionHandler:(void(^)())completionHandler
{
    if (ARNPush_handleActionBlock_) {
        ARNPush_handleActionBlock_(identifier, userInfo, completionHandler);
    }
}

@end

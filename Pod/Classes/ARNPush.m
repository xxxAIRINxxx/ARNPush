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

static BOOL canReceivedPush_ = NO;

static ARNPushDeviceTokenBlock deviceTokenBlock_ = nil;
static ARNPushBlock alertBlock_ = nil;
static ARNPushBlock soundBlock_ = nil;
static ARNPushBlock badgeBlock_ = nil;

static void ARNPushReplaceClassMethod(Class class, SEL originalSelector, void (^block)(id selfObj, id app, id params)) {
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
    canReceivedPush_ = canReceivedPush;
}

+ (void)setDeviceTokenBlock:(ARNPushDeviceTokenBlock)deviceTokenBlock
{
    deviceTokenBlock_ = [deviceTokenBlock copy];
}

+ (void)setAlertBlock:(ARNPushBlock)alertBlock
{
    alertBlock_ = [alertBlock copy];
}

+ (void)setSoundBlock:(ARNPushBlock)soundBlock
{
    soundBlock_ = [soundBlock copy];
}

+ (void)setBadgeBlock:(ARNPushBlock)badgeBlock
{
    badgeBlock_ = [badgeBlock copy];
}

+ (void)registerForTypes:(UIRemoteNotificationType)types
           launchOptions:(NSDictionary *)launchOptions
              categories:(NSSet *)categories;
{
    canReceivedPush_ = YES;
    
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
    
    //Method Swizzling
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
}

+ (void)pushNotificationWithUserInfo:(NSDictionary *)userInfo
{
    if (!canReceivedPush_) {
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
    
    if (pushAlert && alertBlock_) {
        alertBlock_(userInfo);
    }
    if (pushSound && soundBlock_) {
        soundBlock_(userInfo);
    }
    if (pushBadge && badgeBlock_) {
        badgeBlock_(userInfo);
    }
}

// -------------------------------------------------------------------------------------------------------------------------------//
#pragma mark - Method Swizzling

+ (void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    NSString *deviceTokenString = [[deviceToken description] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]];
    
    deviceTokenString = [deviceTokenString stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    if (deviceTokenBlock_) {
        deviceTokenBlock_(deviceTokenString, nil);
    }
}

+ (void)didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    if (deviceTokenBlock_) {
        deviceTokenBlock_(nil, error);
    }
}

+ (void)didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    [[self class] pushNotificationWithUserInfo:userInfo];
}

@end

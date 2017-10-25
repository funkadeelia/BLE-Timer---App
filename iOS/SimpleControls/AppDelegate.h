//
//  AppDelegate.h
//  SimpleControl
//
//  Created by Cheong on 6/11/12.
//  Copyright (c) 2012 RedBearLab. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <UserNotifications/UserNotifications.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate,UNUserNotificationCenterDelegate>

// used for notifications
@property (strong, nonatomic) NSString *strDeviceToken;

// used for app?
@property (strong, nonatomic) UIWindow *window;

@end

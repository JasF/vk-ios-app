//
//  VKSdkManager.h
//  vk
//
//  Created by Jasf on 09.04.2018.
//  Copyright © 2018 Home. All rights reserved.
//

#import <UIKit/UIKit.h>

@class VKAccessToken;
@protocol VKSdkManager <NSObject>
@property (nonatomic, copy) void (^getTokenSuccess)(VKAccessToken *token);
@property (nonatomic, copy) void (^getTokenFailed)(NSError *error, BOOL cancelled);
@property (strong, nonatomic) UIViewController *viewController;
- (void)authorize;
@end

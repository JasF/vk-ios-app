//
//  VKSdkManagerImpl.m
//  vk
//
//  Created by Jasf on 09.04.2018.
//  Copyright © 2018 Home. All rights reserved.
//

#import "VKSdkManagerImpl.h"
#import <VK-ios-sdk/VKSdk.h>

static NSString *kVkAppId = @"6442149";
static NSInteger const kUserCancelledErrorCode = -999;

@interface VKSdkManagerImpl () <VKSdkDelegate, VKSdkUIDelegate>
@property (strong, nonatomic) VKSdk *sdk;
@end


@implementation VKSdkManagerImpl

@synthesize getTokenSuccess = _getTokenSuccess;
@synthesize getTokenFailed = _getTokenFailed;
@synthesize viewController = _viewController;

- (id)init {
    if (self = [super init]) {
        _sdk = [VKSdk initializeWithAppId:kVkAppId];
        [_sdk registerDelegate:self];
        _sdk.uiDelegate = self;
    }
    return self;
}
    
#pragma mark - VKSdkDelegate
- (void)vkSdkAccessAuthorizationFinishedWithResult:(VKAuthorizationResult *)result {
    if (result.error) {
        if (_getTokenFailed) {
            _getTokenFailed(result.error, (result.error.code == kUserCancelledErrorCode));
        }
        return;
    }
    else if (result.token) {
        if (_getTokenSuccess) {
            _getTokenSuccess(result.token);
        }
    }
}
    
- (void)vkSdkUserAuthorizationFailed {
    NSLog(@"vkSdkUserAuthorizationFailed");
}
    
#pragma mark - VKSdkUIDelegate
- (void)vkSdkShouldPresentViewController:(UIViewController *)controller {
    NSCParameterAssert(_viewController);
    [_viewController presentViewController:controller animated:YES completion:nil];
    NSLog(@"vkSdkShouldPresentViewController");
}
    
- (void)vkSdkNeedCaptchaEnter:(VKError *)captchaError {
    NSLog(@"vkSdkNeedCaptchaEnter");
}
    
#pragma mark - Private Methods
- (NSArray *)scope {
    NSArray *SCOPE = @[@"friends", @"email", @"messages", @"notifications", @"groups", @"docs", @"wall", @"notes", @"status", @"stories", @"video", @"audio", @"photos"];
    return SCOPE;
}

#pragma mark - VKSdkManager
- (void)authorize {
    [VKSdk authorize:[self scope]];
}
    
@end

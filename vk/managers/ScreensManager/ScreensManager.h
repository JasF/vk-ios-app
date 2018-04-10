//
//  ScreensManager.h
//  vk
//
//  Created by Jasf on 09.04.2018.
//  Copyright © 2018 Home. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ScreensManager <NSObject>
- (UIViewController *)rootViewController;
- (void)createWindowIfNeeded;
- (void)showAuthorizationViewController;
@end

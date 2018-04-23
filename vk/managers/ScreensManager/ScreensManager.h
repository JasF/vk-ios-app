//
//  ScreensManager.h
//  vk
//
//  Created by Jasf on 09.04.2018.
//  Copyright © 2018 Home. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ScreensManager <NSObject>
- (void)createWindowIfNeeded;
- (void)showAuthorizationViewController;
- (void)showWallViewController;
- (void)showWallViewController:(NSNumber *)userId;
- (void)showWallPostViewControllerWithOwnerId:(NSNumber *)ownerId postId:(NSNumber *)postId;
- (void)showChatListViewController;
- (void)showFriendsViewController;
- (void)showMenu;
- (void)showDialogViewController:(NSNumber *)userId;
@end

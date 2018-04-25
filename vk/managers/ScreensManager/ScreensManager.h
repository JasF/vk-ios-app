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
- (void)showPhotoAlbumsViewController:(NSNumber *)ownerId;
- (void)showGalleryViewControllerWithOwnerId:(NSNumber *)ownerId albumId:(id)albumId;
- (void)showImagesViewerViewControllerWithOwnerId:(NSNumber *)ownerId albumId:(NSNumber *)albumId photoId:(NSNumber *)photoId;
- (void)showNewsViewController;
- (void)showAnswersViewController;
- (void)showGroupsViewController:(NSNumber *)userId;
- (void)showBookmarksViewController;
- (void)showVideosViewController:(NSNumber *)ownerId;
- (void)showDocumentsViewController:(NSNumber *)ownerId;
- (void)showSettingsViewController;
@end

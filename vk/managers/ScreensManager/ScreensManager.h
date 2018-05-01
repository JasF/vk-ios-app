//
//  ScreensManager.h
//  vk
//
//  Created by Jasf on 09.04.2018.
//  Copyright © 2018 Home. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Video;

@protocol ScreensManager <NSObject>
- (void)createWindowIfNeeded;
- (void)showAuthorizationViewController;
- (void)showWallViewController;
- (void)showWallViewController:(NSNumber *)userId;
- (void)showWallViewController:(NSNumber *)userId push:(NSNumber *)push;
- (void)showWallPostViewControllerWithOwnerId:(NSNumber *)ownerId postId:(NSNumber *)postId;
- (void)showChatListViewController;
- (void)showFriendsViewController:(NSNumber *)userId usersListType:(NSNumber *)usersListType;
- (void)showMenu;
- (void)showDialogViewController:(NSNumber *)userId;
- (void)showPhotoAlbumsViewController:(NSNumber *)ownerId;
- (void)showGalleryViewControllerWithOwnerId:(NSNumber *)ownerId albumId:(id)albumId;
- (void)showImagesViewerViewControllerWithOwnerId:(NSNumber *)ownerId albumId:(NSNumber *)albumId photoId:(NSNumber *)photoId;
- (void)showDetailPhotoViewControllerWithOwnerId:(NSNumber *)ownerId albumId:(NSNumber *)albumId photoId:(NSNumber *)photoId;
- (void)showNewsViewController;
- (void)showAnswersViewController;
- (void)showGroupsViewController:(NSNumber *)userId;
- (void)showBookmarksViewController;
- (void)showVideosViewController:(NSNumber *)ownerId;
- (void)showDocumentsViewController:(NSNumber *)ownerId;
- (void)showSettingsViewController;
- (void)showDetailVideoViewControllerWithOwnerId:(NSNumber *)ownerId videoId:(NSNumber *)videoId;
- (void)showVideoPlayerViewControllerWithVideo:(Video *)video;
- (void)presentAddPostViewController;
- (UIViewController *)topViewController;
@end

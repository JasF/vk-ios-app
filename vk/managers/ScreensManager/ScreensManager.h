//
//  ScreensManager.h
//  vk
//
//  Created by Jasf on 09.04.2018.
//  Copyright © 2018 Home. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Video;

@protocol ViewControllerActionsExtension <NSObject>
@property (nonatomic) BOOL needsUpdateContentOnAppear;
@end

@protocol ScreensManager <NSObject>
- (void)createWindowIfNeeded;
- (void)showAuthorizationViewController;
- (void)showWallViewController;
- (void)showWallViewController:(NSNumber *)userId;
- (void)showWallViewController:(NSNumber *)userId push:(NSNumber *)push;
- (void)showWallPostViewControllerWithOwnerId:(NSNumber *)ownerId postId:(NSNumber *)postId;
- (void)showChatListViewController;
- (void)showFriendsViewController:(NSNumber *)userId usersListType:(NSNumber *)usersListType push:(NSNumber *)push;
- (void)showMenu;
- (void)showDialogViewController:(NSNumber *)userId;
- (void)showPhotoAlbumsViewController:(NSNumber *)ownerId push:(NSNumber *)push;
- (void)showGalleryViewControllerWithOwnerId:(NSNumber *)ownerId albumId:(id)albumId;
- (void)showImagesViewerViewControllerWithOwnerId:(NSNumber *)ownerId albumId:(NSNumber *)albumId photoId:(NSNumber *)photoId;
- (void)showImagesViewerViewControllerWithOwnerId:(NSNumber *)ownerId postId:(NSNumber *)postId photoIndex:(NSNumber *)photoIndex;
- (void)showImagesViewerViewControllerWithMessageId:(NSNumber *)messageId index:(NSNumber *)photoIndex;
- (void)showDetailPhotoViewControllerWithOwnerId:(NSNumber *)ownerId photoId:(NSNumber *)photoId;
- (void)showNewsViewController;
- (void)showAnswersViewController;
- (void)showGroupsViewController:(NSNumber *)userId;
- (void)showBookmarksViewController;
- (void)showVideosViewController:(NSNumber *)ownerId push:(NSNumber *)push;
- (void)showDocumentsViewController:(NSNumber *)ownerId;
- (void)showSettingsViewController;
- (void)showDetailVideoViewControllerWithOwnerId:(NSNumber *)ownerId videoId:(NSNumber *)videoId;
- (void)showVideoPlayerViewControllerWithVideo:(Video *)video;
- (void)presentAddPostViewController:(NSNumber *)ownerId;
- (void)dismissCreatePostViewController:(NSNumber *)isPostPublished;
- (void)showEulaViewController;
- (NSString *)getCaptchaInput:(NSDictionary *)response;
- (NSNumber *)getValidationResponse:(NSDictionary *)response;
- (UIViewController *)topViewController;
@end

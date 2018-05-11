//
//  HandlersFactory.h
//  vk
//
//  Created by Jasf on 13.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import <CoreFoundation/CoreFoundation.h>

@protocol PyChatListViewModel;
@protocol PyDialogScreenViewModel;
@protocol PyWallViewModel;
@protocol PyMenuViewModel;
@protocol PyFriendsViewModel;
@protocol PyWallPostViewModel;
@protocol PyNotificationsManager;
@protocol PyPhotoAlbumsViewModel;
@protocol PyGalleryViewModel;
@protocol PyImagesViewerViewModel;
@protocol PyNewsViewModel;
@protocol PyAnswersViewModel;
@protocol PyGroupsViewModel;
@protocol PyBookmarksViewModel;
@protocol PyVideosViewModel;
@protocol PyDocumentsViewModel;
@protocol PySettingsViewModel;
@protocol PyDetailPhotoViewModel;
@protocol PyAuthorizationViewModel;
@protocol PyDetailVideoViewModel;
@protocol PyPostsViewModel;
@protocol PyDialogsManager;
@protocol PyCreatePostViewModel;
@protocol PyMWPhotoBrowserViewModel;
@protocol PyAnalytics;
@protocol PySystemEvents;

@protocol HandlersFactory <NSObject>
- (id<PyChatListViewModel>)chatListViewModelHandler:(id)delegate;
- (id<PyDialogScreenViewModel>)dialogViewModelHandler:(id)delegate parameters:(NSDictionary *)parameters;
- (id<PyWallViewModel>)wallViewModelHandlerWithDelegate:(id)delegate parameters:(NSDictionary *)parameters;
- (id<PyWallPostViewModel>)wallPostViewModelHandlerWithDelegate:(id)delegate parameters:(NSDictionary *)parameters;
- (id<PyMenuViewModel>)menuViewModelHandler;
- (id<PyFriendsViewModel>)friendsViewModelHandler:(NSInteger)userId
                                    usersListType:(NSNumber *)usersListType;
- (id<PyNotificationsManager>)notificationsManagerHandler;
- (id<PyPhotoAlbumsViewModel>)photoAlbumsViewModelHandler:(NSInteger)ownerId;
- (id<PyGalleryViewModel>)galleryViewModelHandlerWithOwnerId:(NSInteger)ownerId albumId:(id)albumId;
- (id<PyImagesViewerViewModel>)imagesViewerViewModelHandlerWithDelegate:(id)delegate ownerId:(NSInteger)ownerId postId:(NSInteger)postId photoIndex:(NSInteger)photoIndex;
- (id<PyImagesViewerViewModel>)imagesViewerViewModelHandlerWithDelegate:(id)delegate ownerId:(NSInteger)ownerId albumId:(NSInteger)albumId photoId:(NSInteger)photoId;
- (id<PyImagesViewerViewModel>)imagesViewerViewModelHandlerWithDelegate:(id)delegate messageId:(NSInteger)messageId photoIndex:(NSInteger)photoIndex;
- (id<PyDetailPhotoViewModel>)detailPhotoViewModelHandlerWithOwnerId:(NSInteger)ownerId photoId:(NSInteger)photoId;
- (id<PyNewsViewModel>)newsViewModelHandler;
- (id<PyAnswersViewModel>)answersViewModelHandler;
- (id<PyGroupsViewModel>)groupsViewModelHandler:(NSInteger)userId;
- (id<PyBookmarksViewModel>)bookmarksViewModelHandler;
- (id<PyVideosViewModel>)videosViewModelHandler:(NSInteger)ownerId;
- (id<PyDocumentsViewModel>)documentsViewModelHandler:(NSInteger)ownerId;
- (id<PySettingsViewModel>)settingsViewModelHandler;
- (id<PyAuthorizationViewModel>)authorizationViewModelHandler;
- (id<PyDetailVideoViewModel>)detailVideoViewModelHandlerWithDelegate:(id)delegate ownerId:(NSInteger)ownerId videoId:(NSInteger)videoId;
- (id<PyPostsViewModel>)postsViewModelHandlerWithDelegate:(id)delegate;
- (id<PyDialogsManager>)dialogManagerHandlerWithDelegate:(id)delegate;
- (id<PyCreatePostViewModel>)createPostViewModelHandler:(NSInteger)ownerId;
- (id<PyMWPhotoBrowserViewModel>)photoBrowserViewModelHandler;
- (id<PyAnalytics>)analyticsHandlerWithDelegate:(id)delegate;
- (id<PySystemEvents>)systemEventsHandler;
@end

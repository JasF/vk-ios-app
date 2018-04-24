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

@protocol HandlersFactory <NSObject>
- (id<PyChatListViewModel>)chatListViewModelHandler:(id)delegate;
- (id<PyDialogScreenViewModel>)dialogViewModelHandler:(id)delegate parameters:(NSDictionary *)parameters;
- (id<PyWallViewModel>)wallViewModelHandlerWithDelegate:(id)delegate parameters:(NSDictionary *)parameters;
- (id<PyWallPostViewModel>)wallPostViewModelHandlerWithDelegate:(id)delegate parameters:(NSDictionary *)parameters;
- (id<PyMenuViewModel>)menuViewModelHandler;
- (id<PyFriendsViewModel>)friendsViewModelHandler;
- (id<PyNotificationsManager>)notificationsManagerHandler;
- (id<PyPhotoAlbumsViewModel>)photoAlbumsViewModelHandler:(NSInteger)ownerId;
- (id<PyGalleryViewModel>)galleryViewModelHandlerWithOwnerId:(NSInteger)ownerId albumId:(id)albumId;
- (id<PyImagesViewerViewModel>)imagesViewerViewModelHandlerWithOwnerId:(NSInteger)ownerId albumId:(NSInteger)albumId photoId:(NSInteger)photoId;
@end

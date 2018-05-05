//
//  HandlersFactoryImpl.m
//  vk
//
//  Created by Jasf on 13.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "HandlersFactoryImpl.h"
#import "WallServiceImpl.h"
#import "WallViewController.h"
#import "ChatListViewController.h"
#import "ChatListServiceImpl.h"
#import "vk-Swift.h"
#import "DialogServiceImpl.h"
#import "ChatListViewModelImpl.h"
#import "DialogScreenViewModelImpl.h"
#import "WallViewModelImpl.h"
#import "MenuViewModelImpl.h"
#import "FriendsViewModelImpl.h"
#import "WallPostViewModelImpl.h"
#import "NotificationsManagerImpl.h"
#import "PhotoAlbumsViewModelImpl.h"
#import "GalleryViewModelImpl.h"
#import "ImagesViewerViewModelImpl.h"
#import "NewsViewModelImpl.h"
#import "AnswersViewModelImpl.h"
#import "GroupsViewModelImpl.h"
#import "BookmarksViewModelImpl.h"
#import "VideosViewModelImpl.h"
#import "DocumentsViewModelImpl.h"
#import "SettingsViewModelImpl.h"
#import "DetailPhotoViewModelImpl.h"
#import "AuthorizationViewModelImpl.h"
#import "DetailVideoViewModelImpl.h"
#import "PostsViewModelImpl.h"
#import "DialogsManagerImpl.h"

@interface HandlersFactoryImpl ()
@property (strong, nonatomic) id<PythonBridge> pythonBridge;
@end

@implementation HandlersFactoryImpl

- (id)initWithPythonBridge:(id<PythonBridge>)pythonBridge {
    NSCParameterAssert(pythonBridge);
    if (self) {
        _pythonBridge = pythonBridge;
    }
    return self;
}

- (id<PyChatListViewModel>)chatListViewModelHandler:(id)delegate {
    return [_pythonBridge instantiateHandlerWithProtocol:@protocol(PyChatListViewModel) delegate:delegate];
}

- (id<PyDialogScreenViewModel>)dialogViewModelHandler:(id)delegate parameters:(NSDictionary *)parameters {
    return [_pythonBridge instantiateHandlerWithProtocol:@protocol(PyDialogScreenViewModel)
                                                delegate:delegate
                                              parameters:parameters];
}

- (id<PyWallViewModel>)wallViewModelHandlerWithDelegate:(id)delegate parameters:(NSDictionary *)parameters {
    return [_pythonBridge instantiateHandlerWithProtocol:@protocol(PyWallViewModel)
                                                delegate:delegate
                                              parameters:parameters];
}

- (id<PyWallPostViewModel>)wallPostViewModelHandlerWithDelegate:(id)delegate parameters:(NSDictionary *)parameters {
    return [_pythonBridge instantiateHandlerWithProtocol:@protocol(PyWallPostViewModel)
                                                delegate:delegate
                                              parameters:parameters];
}

- (id<PyMenuViewModel>)menuViewModelHandler {
    return [_pythonBridge instantiateHandlerWithProtocol:@protocol(PyMenuViewModel)];
}

- (id<PyFriendsViewModel>)friendsViewModelHandler:(NSInteger)userId
                                    usersListType:(NSNumber *)usersListType {
    return [_pythonBridge instantiateHandlerWithProtocol:@protocol(PyFriendsViewModel)
                                              parameters:@{@"userId":@(userId), @"usersListType":usersListType}];
}

- (id<PyNotificationsManager>)notificationsManagerHandler {
    return [_pythonBridge instantiateHandlerWithProtocol:@protocol(PyNotificationsManager)];
}

- (id<PyPhotoAlbumsViewModel>)photoAlbumsViewModelHandler:(NSInteger)ownerId {
    return [_pythonBridge instantiateHandlerWithProtocol:@protocol(PyPhotoAlbumsViewModel)
                                              parameters:@{@"ownerId":@(ownerId)}];
}

- (id<PyGalleryViewModel>)galleryViewModelHandlerWithOwnerId:(NSInteger)ownerId
                                                     albumId:(id)albumId {
    NSCParameterAssert(albumId);
    return [_pythonBridge instantiateHandlerWithProtocol:@protocol(PyGalleryViewModel)
                                              parameters:@{@"ownerId":@(ownerId), @"albumId":albumId}];
}

- (id<PyImagesViewerViewModel>)imagesViewerViewModelHandlerWithDelegate:(id)delegate
                                                                ownerId:(NSInteger)ownerId
                                                                 postId:(NSInteger)postId
                                                             photoIndex:(NSInteger)photoIndex {
    return [_pythonBridge instantiateHandlerWithProtocol:@protocol(PyImagesViewerViewModel)
                                                delegate:delegate
                                              parameters:@{@"ownerId":@(ownerId), @"postId":@(postId), @"photoIndex":@(photoIndex)}];
}

- (id<PyImagesViewerViewModel>)imagesViewerViewModelHandlerWithDelegate:(id)delegate ownerId:(NSInteger)ownerId albumId:(NSInteger)albumId photoId:(NSInteger)photoId {
    return [_pythonBridge instantiateHandlerWithProtocol:@protocol(PyImagesViewerViewModel)
                                                delegate:delegate
                                              parameters:@{@"ownerId":@(ownerId), @"albumId":@(albumId), @"photoId":@(photoId)}];
}

- (id<PyDetailPhotoViewModel>)detailPhotoViewModelHandlerWithOwnerId:(NSInteger)ownerId photoId:(NSInteger)photoId {
    return [_pythonBridge instantiateHandlerWithProtocol:@protocol(PyDetailPhotoViewModel)
                                              parameters:@{@"ownerId":@(ownerId), @"photoId":@(photoId)}];
}

- (id<PyNewsViewModel>)newsViewModelHandler {
    return [_pythonBridge instantiateHandlerWithProtocol:@protocol(PyNewsViewModel)];
}

- (id<PyAnswersViewModel>)answersViewModelHandler {
    return [_pythonBridge instantiateHandlerWithProtocol:@protocol(PyAnswersViewModel)];
}

- (id<PyGroupsViewModel>)groupsViewModelHandler:(NSInteger)userId {
    return [_pythonBridge instantiateHandlerWithProtocol:@protocol(PyGroupsViewModel)
                                              parameters:@{@"userId":@(userId)}];
}

- (id<PyBookmarksViewModel>)bookmarksViewModelHandler {
    return [_pythonBridge instantiateHandlerWithProtocol:@protocol(PyBookmarksViewModel)];
}

- (id<PyVideosViewModel>)videosViewModelHandler:(NSInteger)ownerId {
    return [_pythonBridge instantiateHandlerWithProtocol:@protocol(PyVideosViewModel)
                                              parameters:@{@"ownerId":@(ownerId)}];
}

- (id<PyDocumentsViewModel>)documentsViewModelHandler:(NSInteger)ownerId {
    return [_pythonBridge instantiateHandlerWithProtocol:@protocol(PyDocumentsViewModel)
                                              parameters:@{@"ownerId":@(ownerId)}];
}

- (id<PySettingsViewModel>)settingsViewModelHandler {
    return [_pythonBridge instantiateHandlerWithProtocol:@protocol(PySettingsViewModel)];
}

- (id<PyAuthorizationViewModel>)authorizationViewModelHandler {
    return [_pythonBridge instantiateHandlerWithProtocol:@protocol(PyAuthorizationViewModel)];
}

- (id<PyDetailVideoViewModel>)detailVideoViewModelHandlerWithDelegate:(id)delegate ownerId:(NSInteger)ownerId
                                                             videoId:(NSInteger)videoId {
    return [_pythonBridge instantiateHandlerWithProtocol:@protocol(PyDetailVideoViewModel)
                                                delegate:delegate
                                              parameters:@{@"ownerId":@(ownerId), @"videoId":@(videoId)}];
}

- (id<PyPostsViewModel>)postsViewModelHandlerWithDelegate:(id)delegate {
    return [_pythonBridge instantiateHandlerWithProtocol:@protocol(PyPostsViewModel)
                                                delegate:delegate];
}

- (id<PyDialogsManager>)dialogManagerHandlerWithDelegate:(id)delegate {
    return [_pythonBridge instantiateHandlerWithProtocol:@protocol(PyDialogsManager)
                                                delegate:delegate];
}

- (id<PyCreatePostViewModel>)createPostViewModelHandler:(NSInteger)ownerId {
    return [_pythonBridge instantiateHandlerWithProtocol:@protocol(PyCreatePostViewModel)
                                              parameters:@{@"ownerId":@(ownerId)}];
}

- (id<PyMWPhotoBrowserViewModel>)photoBrowserViewModelHandler {
    return [_pythonBridge instantiateHandlerWithProtocol:@protocol(PyMWPhotoBrowserViewModel)];
}

@end

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

- (id<PyFriendsViewModel>)friendsViewModelHandler {
    return [_pythonBridge instantiateHandlerWithProtocol:@protocol(PyFriendsViewModel)];
}

- (id<PyNotificationsManager>)notificationsManagerHandler {
    return [_pythonBridge instantiateHandlerWithProtocol:@protocol(PyNotificationsManager)];
}

- (id<PyPhotoAlbumsViewModel>)photoAlbumsViewModelHandler:(NSInteger)ownerId {
    return [_pythonBridge instantiateHandlerWithProtocol:@protocol(PyPhotoAlbumsViewModel)
                                              parameters:@{@"ownerId":@(ownerId)}];
}

- (id<PyGalleryViewModel>)galleryViewModelHandlerWithOwnerId:(NSInteger)ownerId albumId:(id)albumId {
    NSCParameterAssert(albumId);
    return [_pythonBridge instantiateHandlerWithProtocol:@protocol(PyGalleryViewModel)
                                              parameters:@{@"ownerId":@(ownerId), @"albumId":albumId}];
}

- (id<PyImagesViewerViewModel>)imagesViewerViewModelHandlerWithOwnerId:(NSInteger)ownerId albumId:(NSInteger)albumId photoId:(NSInteger)photoId {
    return [_pythonBridge instantiateHandlerWithProtocol:@protocol(PyImagesViewerViewModel)
                                              parameters:@{@"ownerId":@(ownerId), @"albumId":@(albumId), @"photoId":@(photoId)}];
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

@end

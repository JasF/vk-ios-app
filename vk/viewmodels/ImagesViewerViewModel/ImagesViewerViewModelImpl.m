//
//  ImagesViewerViewModelImpl.m
//  vk
//
//  Created by Jasf on 24.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "ImagesViewerViewModelImpl.h"
#import "WallPost.h"

@protocol PyImagesViewerViewModelDelegate <NSObject>
- (void)photosDataDidUpdatedFromApi;
@end

@interface ImagesViewerViewModelImpl ()
@property id<PyImagesViewerViewModel> handler;
@property id<GalleryService> galleryService;
@property (nonatomic) BOOL withPost;
@property (nonatomic) NSInteger photoIndex;
@end

@implementation ImagesViewerViewModelImpl

@synthesize photoId = _photoId;
@synthesize delegate = _delegate;

#pragma mark - Initialization
- (instancetype)initWithHandlersFactory:(id<HandlersFactory>)handlersFactory
                         galleryService:(id<GalleryService>)galleryService
                                ownerId:(NSNumber *)ownerId
                                albumId:(NSNumber *)albumId
                                photoId:(NSNumber *)photoId {
    NSCParameterAssert(handlersFactory);
    NSCParameterAssert(galleryService);
    NSCParameterAssert(ownerId);
    NSCParameterAssert(albumId);
    if (self = [super init]) {
        self.photoId = photoId.integerValue;
        _galleryService = galleryService;
        _handler = [handlersFactory imagesViewerViewModelHandlerWithDelegate:self
                                                                     ownerId:ownerId.integerValue
                                                                     albumId:albumId.integerValue
                                                                     photoId:photoId.integerValue];
    }
    return self;
}

- (instancetype)initWithHandlersFactory:(id<HandlersFactory>)handlersFactory
                         galleryService:(id<GalleryService>)galleryService
                                ownerId:(NSNumber *)ownerId
                                 postId:(NSNumber *)postId
                             photoIndex:(NSNumber *)photoIndex {
    NSCParameterAssert(handlersFactory);
    NSCParameterAssert(galleryService);
    NSCParameterAssert(ownerId);
    NSCParameterAssert(postId);
    NSCParameterAssert(photoIndex);
    if (self = [super init]) {
        self.galleryService = galleryService;
        self.handler = [handlersFactory imagesViewerViewModelHandlerWithDelegate:self
                                                                         ownerId:ownerId.integerValue
                                                                          postId:postId.integerValue
                                                                      photoIndex:photoIndex.integerValue];
        _withPost = YES;
        _photoIndex = photoIndex.integerValue;
    }
    return self;
}

#pragma mark - ImagesViewerViewModel
- (void)getPhotos:(NSInteger)offset completion:(void(^)(NSArray *photos))completion {
    dispatch_python(^{
        if (self.withPost) {
            if (offset) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (completion) {
                        completion(@[]);
                    }
                });
                return;
            }
            NSDictionary *data = [self.handler getPostData];
            NSDictionary *postData = data[@"post_data"];
            /*
            NSDictionary *imagesData = data[@"images_data"];
            NSArray *photos = [self.galleryService parse:imagesData];
            if (_photoIndex < photos.count) {
                Photo *photo = photos[_photoIndex];
                self.photoId = photo.id;
            }
             */
            WallPost *post = [self.galleryService parsePost:postData];
            NSMutableArray *photos = [NSMutableArray new];
            NSInteger i=0;
            for (Attachments *attachment in post.photoAttachments) {
                if (i == _photoIndex) {
                    self.photoId = attachment.photo.id;
                }
                [photos addObject:attachment.photo];
                ++i;
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) {
                    completion(photos);
                }
            });
        }
        else {
            NSDictionary *data = [self.handler getPhotos:@(offset)];
            NSArray *photos = [self.galleryService parse:data];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) {
                    completion(photos);
                }
            });
        }
    });
}

- (void)navigateWithPhoto:(Photo *)photo {
    dispatch_python(^{
        [self.handler navigateWithPhotoId:@(photo.id)];
    });
}

#pragma mark - PyImagesViewerViewModel
- (void)photosDataDidUpdatedFromApi {
    if ([self.delegate respondsToSelector:@selector(photosDataDidUpdatedFromApi)]) {
        [self.delegate photosDataDidUpdatedFromApi];
    }
}
@end

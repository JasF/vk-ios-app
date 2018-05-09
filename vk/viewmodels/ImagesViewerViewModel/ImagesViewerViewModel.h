//
//  ImagesViewerViewModel.h
//  vk
//
//  Created by Jasf on 24.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Photo.h"

@protocol ImagesViewerViewModelDelegate <NSObject>
- (void)photosDataDidUpdatedFromApi;
@end

@protocol ImagesViewerViewModel <NSObject>
@property (weak, nonatomic) id<ImagesViewerViewModelDelegate> delegate;
@property NSInteger photoId;
@property (nonatomic) BOOL withMessage;
@property (nonatomic) BOOL withPhotoItems;
- (void)getPhotos:(NSInteger)offset completion:(void(^)(NSArray *photos))completion;
- (void)navigateWithPhoto:(Photo *)photo;
@end

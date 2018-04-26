//
//  ImagesViewerViewModel.h
//  vk
//
//  Created by Jasf on 24.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Photo.h"

@protocol ImagesViewerViewModel <NSObject>
@property NSInteger photoId;
- (void)getPhotos:(NSInteger)offset completion:(void(^)(NSArray *photos))completion;
- (void)navigateWithPhoto:(Photo *)photo;
@end

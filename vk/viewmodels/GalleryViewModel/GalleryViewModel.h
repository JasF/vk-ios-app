//
//  GalleryViewModel.h
//  vk
//
//  Created by Jasf on 23.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Photo;

@protocol GalleryViewModel <NSObject>
- (void)getPhotos:(NSInteger)offset completion:(void(^)(NSArray *photos, NSError *error))completion;
- (void)tappedOnPhoto:(Photo *)photo;
@end

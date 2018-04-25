//
//  DetailPhotoServiceImpl.h
//  vk
//
//  Created by Jasf on 25.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DetailPhotoService.h"
#import "GalleryService.h"

@interface DetailPhotoServiceImpl : NSObject <DetailPhotoService>
- (id)initWithGalleryService:(id<GalleryService>)galleryService;
@end

//
//  PhotoAlbum.h
//  vk
//
//  Created by Jasf on 23.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SizedPhoto.h"
#import <EasyMapping/EasyMapping.h>

@interface PhotoAlbum : NSObject <EKMappingProtocol>
@property NSInteger id;
@property NSInteger thumb_id;
@property NSInteger owner_id;
@property NSString *title;
@property NSInteger size;
@property NSString *thumb_src;
@property NSArray<SizedPhoto *> *sizes;
@end

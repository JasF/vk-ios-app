//
//  GalleryService.h
//  vk
//
//  Created by Jasf on 23.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import <Foundation/Foundation.h>

@class WallPost;
@protocol GalleryService <NSObject>
- (NSArray *)parse:(NSDictionary *)photosData;
- (WallPost *)parsePost:(NSDictionary *)data;
- (NSArray *)parseAttachments:(NSDictionary *)data;
@end

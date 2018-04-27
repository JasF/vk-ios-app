//
//  Likes.h
//  vk
//
//  Created by Jasf on 10.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import <Foundation/Foundation.h>

@import EasyMapping;

@interface Likes : NSObject <EKMappingProtocol>
@property NSInteger count;
@property BOOL user_likes;
@property BOOL can_like;
@property BOOL can_publish;
@end

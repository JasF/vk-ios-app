//
//  PostType.h
//  vk
//
//  Created by Jasf on 10.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <EasyMapping/EasyMapping.h>

typedef NS_ENUM(NSInteger, PostsTypes) {
    PostTypeUnknown,
    PostTypePost
};

@interface PostType : NSObject <EKMappingProtocol>
@property PostsTypes type;
@end

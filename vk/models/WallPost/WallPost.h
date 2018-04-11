//
//  WallPost.h
//  vk
//
//  Created by Jasf on 10.04.2018.
//  Copyright © 2018 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Comments.h"
#import "Attachments.h"
#import "Likes.h"
#import "PostSource.h"
#import "PostType.h"
#import "Reposts.h"
#import "Views.h"
#import "CopyHistory.h"

@import EasyMapping;

@interface WallPost : NSObject <EKMappingProtocol>
@property BOOL canDelete;
@property BOOL canPin;
@property NSInteger date;
@property NSInteger fromId;
@property NSInteger identifier;
@property Comments *comments;
@property NSArray *history;
@property Likes *likes;
@property NSInteger ownerId;
@property PostSource *postSource;
@property PostType *postType;
@property Reposts *reposts;
@property NSString *text;
@property Views *views;

@property NSString *firstName;
@property NSString *lastName;
@property NSString *avatarURLString;
@end

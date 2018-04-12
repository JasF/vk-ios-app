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

@import EasyMapping;

@interface WallPost : NSObject <EKMappingProtocol>
@property BOOL can_delete;
@property BOOL can_pin;
@property NSInteger date;
@property NSInteger from_id;
@property NSInteger identifier;
@property Comments *comments;
@property NSArray<WallPost *> *history;
@property Likes *likes;
@property NSInteger owner_id;
@property PostSource *postSource;
@property PostType *postType;
@property Reposts *reposts;
@property NSString *text;
@property Views *views;
@property NSArray<Attachments *> *photoAttachments;
@property NSArray<Attachments *> *attachments;


@property NSString *firstName;
@property NSString *avatarURLString;
@end

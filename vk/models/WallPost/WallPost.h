//
//  WallPost.h
//  vk
//
//  Created by Jasf on 10.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Comments.h"
#import "Attachments.h"
#import "Likes.h"
#import "PostSource.h"
#import "PostType.h"
#import "Reposts.h"
#import "Views.h"
#import "Audio.h"
#import "User.h"

@import EasyMapping;

@interface WallPost : NSObject <EKMappingProtocol>
@property BOOL can_delete;
@property BOOL can_pin;
@property NSInteger date;
@property NSInteger from_id;
@property NSInteger source_id;
@property (assign) NSInteger identifier;
@property NSInteger post_id;
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
@property NSArray<Photo *> *photos;
@property NSArray<Attachments *> *attachments;
@property NSArray<Audio *> *audio;
@property NSString *type;

@property NSArray<UserId *> *friendsIds;
@property NSArray<User *> *friends;

@property User *user;

- (NSInteger)validId;
@end

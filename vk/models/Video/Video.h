//
//  Video.h
//  vk
//
//  Created by Jasf on 25.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Likes.h"
#import "Reposts.h"

#import <EasyMapping/EasyMapping.h>

@interface Video : NSObject <EKMappingProtocol>
@property NSInteger id;
@property NSInteger owner_id;
@property NSString *title;
@property NSInteger duration;
@property NSString *videoDescription;
@property NSInteger date;
@property NSInteger comments;
@property NSInteger views;
@property NSString *photo_130;
@property NSString *photo_320;
@property NSInteger adding_date;
@property NSString *player;
@property NSInteger can_edit;
@property NSInteger can_add;
@property NSString *privacy_view;
@property NSString *privacy_comment;
@property NSInteger can_comment;
@property NSInteger can_repost;
@property Likes *likes;
@property Reposts *reposts;
@property NSInteger repeat;

@property NSInteger width;
@property NSInteger height;
@property NSString *photo_800;
@property NSString *first_frame_320;
@property NSString *first_frame_160;
@property NSString *first_frame_130;
@property NSString *first_frame_800;

- (NSString *)imageURL;
@end

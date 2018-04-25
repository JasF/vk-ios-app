//
//  Video.h
//  vk
//
//  Created by Jasf on 25.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import <UIKit/UIKit.h>

@import EasyMapping;

@interface Video : NSObject <EKMappingProtocol>
@property NSInteger id;
@property NSInteger owner_id;
@property NSString *title;
@property NSInteger duration;
@property NSString *videoDescription;
@property NSInteger date;
@property NSInteger comments;
@property NSInteger views;
@property NSInteger width;
@property NSInteger height;
@property NSString *photo_130;
@property NSString *photo_320;
@property NSString *photo_800;
@property NSInteger adding_date;
@property NSString *first_frame_320;
@property NSString *first_frame_160;
@property NSString *first_frame_130;
@property NSString *first_frame_800;
@property NSString *player;
@property NSInteger can_add;

- (NSString *)imageURL;
@end

//
//  Video.h
//  vk
//
//  Created by Jasf on 12.04.2018.
//  Copyright © 2018 Facebook. All rights reserved.
//

#import <UIKit/UIKit.h>

@import EasyMapping;

@interface Video : NSObject <EKMappingProtocol>
@property NSInteger identifier;
@property NSInteger owner_id;
@property NSString *title;
@property NSInteger duration;
@property NSString *videoDescription;
@property NSInteger date;
@property NSInteger comments;
@property NSInteger views;
@property NSString *photo_130;
@property NSString *photo_320;
@property NSString *photo_800;
@property NSString *photo_640;
@property NSString *access_key;
@property NSString *platform;
@property NSInteger can_edit;
@property NSInteger can_add;
@end

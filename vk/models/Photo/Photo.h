//
//  Photo.h
//  vk
//
//  Created by Jasf on 10.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import <UIKit/UIKit.h>

@import EasyMapping;

@interface Photo : NSObject <EKMappingProtocol>
@property NSString *access_key;
@property NSInteger id;
@property NSInteger album_id;
@property NSInteger owner_id;
@property NSString *photo_75;
@property NSString *photo_130;
@property NSString *photo_604;
@property NSString *photo_807;
@property NSString *photo_1280;
@property NSString *photo_2560;
@property NSInteger width;
@property NSInteger height;
@property NSString *text;
@property NSInteger date;
@property NSString *likes;
@property NSString *reposts;
@property NSString *comments;
@property NSInteger can_comment;
@property NSString *tags;

- (NSString *)bigPhotoURL;
@end

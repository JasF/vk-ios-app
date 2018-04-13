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
@property NSString *accessKey;
@property NSInteger albumId;
@property NSInteger date;
@property NSInteger height;
@property NSInteger identifier;
@property NSInteger ownerId;
@property NSString *photo130;
@property NSString *photo604;
@property NSString *photo75;
@property NSInteger postId;
@property NSString *text;
@property NSInteger userId;
@property NSInteger width;
@end

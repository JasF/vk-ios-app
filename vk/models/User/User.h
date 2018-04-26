//
//  User.h
//  vk
//
//  Created by Jasf on 11.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import <Foundation/Foundation.h>

@import EasyMapping;

@interface UserId : NSObject <EKMappingProtocol>
@property NSInteger user_id;
+ (instancetype)userId:(NSInteger)userId;
@end

@interface User : NSObject <EKMappingProtocol>
@property (assign, nonatomic) NSInteger identifier;
@property (strong, nonatomic) NSString *first_name;
@property (strong, nonatomic) NSString *last_name;
@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSString *photo_50;
@property (strong, nonatomic) NSString *photo_100;
@property (strong, nonatomic) NSString *photo_200_orig;
@property (strong, nonatomic) NSString *photo_200;
@property (strong, nonatomic) NSString *photo_400_orig;
@property (strong, nonatomic) NSString *photo_max;
@property (strong, nonatomic) NSString *photo_max_orig;

@property NSInteger is_admin;
@property NSInteger is_closed;
@property NSInteger is_member;
@property NSString *screen_name;
@property NSString *type;

- (NSString *)nameString;
- (NSString *)avatarURLString;
@end

@interface WallUser : NSObject
@property User *user;
- (id)initWithUser:(User *)user;
@end

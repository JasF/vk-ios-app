//
//  User.h
//  vk
//
//  Created by Jasf on 11.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <EasyMapping/EasyMapping.h>

@class Covers, Cover;

@interface UserId : NSObject <EKMappingProtocol>
@property NSInteger user_id;
+ (instancetype)userId:(NSInteger)userId;
@end

@interface User : NSObject <EKMappingProtocol>

@property NSInteger id;
@property NSString *first_name;
@property NSString *last_name;
@property NSInteger sex;
@property NSString *nickname;
@property NSString *domain;
@property NSString *screen_name;
@property NSString *bdate;
@property NSString *city;
@property NSString *country;
@property NSInteger timezone;
@property NSString *photo_50;
@property NSString *photo_100;
@property NSString *photo_200;
@property NSString *photo_max;
@property NSString *photo_200_orig;
@property NSString *photo_400_orig;
@property NSString *photo_max_orig;
@property NSString *photo_id;
@property NSInteger has_photo;
@property NSInteger has_mobile;
@property NSInteger is_friend;
@property NSInteger friend_status;
@property NSInteger online;
@property NSInteger wall_comments;
@property NSInteger can_post;
@property NSInteger can_see_all_posts;
@property NSInteger can_see_audio;
@property NSInteger can_write_private_message;
@property NSInteger can_send_friend_request;
@property NSString *mobile_phone;
@property NSString *home_phone;
@property NSString *skype;
@property NSString *site;
@property NSString *status;
@property NSString *last_seen;
@property NSString *crop_photo;
@property NSInteger verified;
@property NSInteger followers_count;
@property NSInteger blacklisted;
@property NSInteger blacklisted_by_me;
@property NSInteger is_favorite;
@property NSInteger is_hidden_from_feed;
@property NSInteger common_count;
@property NSString *career;
@property NSString *military;
@property NSInteger university;
@property NSString *university_name;
@property NSInteger faculty;
@property NSString *faculty_name;
@property NSInteger graduation;
@property NSString *home_town;
@property NSInteger relation;
@property NSString *personal;
@property NSString *interests;
@property NSString *music;
@property NSString *activities;
@property NSString *movies;
@property NSString *tv;
@property NSString *books;
@property NSString *games;
@property NSString *universities;
@property NSString *schools;
@property NSString *about;
@property NSString *relatives;
@property NSString *quotes;

@property NSString *name;

@property NSInteger is_admin;
@property NSInteger is_closed;
@property NSInteger is_member;
@property NSString *type;
@property Covers *cover;

@property NSInteger friends_count;
@property NSInteger photos_count;
@property NSInteger videos_count;
@property NSInteger subscriptions_count;
@property NSInteger groups_count;

- (NSString *)nameString;
- (NSString *)avatarURLString;
- (NSString *)bigAvatarURLString;
- (Cover *)getCover;

@property BOOL currentUser;
@end

@interface WallUser : NSObject
@property User *user;
- (id)initWithUser:(User *)user;
@end

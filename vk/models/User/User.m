//
//  User.m
//  vk
//
//  Created by Jasf on 11.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "User.h"
#import "Oxy_Feed-Swift.h"
#import "Counters.h"

@implementation WallUser
- (id)initWithUser:(User *)user {
    if (self = [super init]) {
        _user = user;
    }
    return self;
}
@end

@interface UserId ()
@property (assign, nonatomic) NSInteger from_id;
@end
@implementation UserId
+ (instancetype)userId:(NSInteger)userId {
    UserId *result = [UserId new];
    result.user_id = userId;
    return result;
}
+(EKObjectMapping *)objectMapping
{
    return [EKObjectMapping mappingForClass:self withBlock:^(EKObjectMapping *mapping) {
        [mapping mapPropertiesFromArray:@[@"user_id", @"from_id"]];
    }];
}

- (void)setFrom_id:(NSInteger)from_id {
    if (from_id && !_user_id) {
        _user_id = from_id;
    }
}

@end

@implementation User

+(EKObjectMapping *)objectMapping
{
    return [EKObjectMapping mappingForClass:self withBlock:^(EKObjectMapping *mapping) {
        [mapping mapPropertiesFromArray:@[@"id", @"first_name", @"last_name", @"name", @"sex", @"nickname", @"domain", @"screen_name", @"bdate", @"city", @"country", @"timezone", @"photo_50", @"photo_100", @"photo_200", @"photo_max", @"photo_200_orig", @"photo_400_orig", @"photo_max_orig", @"photo_id", @"has_photo", @"has_mobile", @"is_friend", @"friend_status", @"online", @"wall_comments", @"can_post", @"can_see_all_posts", @"can_see_audio", @"can_write_private_message", @"can_send_friend_request", @"mobile_phone", @"home_phone", @"skype", @"site", @"status", @"last_seen", @"crop_photo", @"verified", @"followers_count", @"blacklisted", @"blacklisted_by_me", @"is_favorite", @"is_hidden_from_feed", @"common_count", @"career", @"military", @"university", @"university_name", @"faculty", @"faculty_name", @"graduation", @"home_town", @"relation", @"personal", @"interests", @"music", @"activities", @"movies", @"tv", @"books", @"games", @"universities", @"schools", @"about", @"relatives", @"quotes", @"friends_count", @"photos_count", @"videos_count", @"subscriptions_count", @"groups_count", @"currentUser", @"type", @"is_closed", @"is_member"]];
        
        [mapping mapKeyPath:@"cover" toProperty:@"cover" withValueBlock:^id _Nullable(NSString * _Nonnull key, id  _Nullable value) {
            Covers *cover = [EKMapper objectFromExternalRepresentation:value
                                                           withMapping:[Covers objectMapping]];
            return cover;
        }];
        [mapping mapKeyPath:@"counters" toProperty:@"counters" withValueBlock:^id _Nullable(NSString * _Nonnull key, id  _Nullable value) {
            Covers *cover = [EKMapper objectFromExternalRepresentation:value
                                                           withMapping:[Counters objectMapping]];
            return cover;
        }];
    }];
}

- (NSString *)nameString {
    if (_name.length) {
        return _name;
    }
    else if (_first_name.length && _last_name.length) {
        return [NSString stringWithFormat:@"%@ %@", _first_name, _last_name];
    }
    else if (_first_name.length) {
        return _first_name;
    }
    return _last_name;
}

- (NSString *)avatarURLString {
    NSString *result = _photo_100;
    if (!result.length) {
        result = _photo_200;
    }
    if (!result.length) {
        result = _photo_400_orig;
    }
    if (!result.length) {
        result = _photo_50;
    }
    if (!result.length) {
        result = _photo_max;
    }
    if (!result.length) {
        result = _photo_max_orig;
    }
    return result;
}

- (NSString *)bigAvatarURLString {
    NSString *result = _photo_400_orig;
    if (!result.length) {
        result = _photo_max_orig;
    }
    if (!result.length) {
        result = _photo_max;
    }
    if (!result.length) {
        result = _photo_200_orig;
    }
    if (!result.length) {
        result = _photo_200;
    }
    if (!result.length) {
        result = [self avatarURLString];
    }
    return result;
}

- (Cover *)getCover {
    if (!self.cover.enabled) {
        return nil;
    }
    for (Cover *cover in _cover.covers) {
        if (cover.width > 500) {
            return cover;
        }
    }
    return _cover.covers.firstObject;
}

- (BOOL)isGroup {
    return [@[@"page", @"group", @"event"] containsObject:_type];
}
@end

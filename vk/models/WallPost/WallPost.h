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

#import <EasyMapping/EasyMapping.h>

@interface WallPost : NSObject <EKMappingProtocol>
@property BOOL can_delete;
@property BOOL can_pin;
@property NSInteger date;
@property NSInteger from_id;
@property NSInteger source_id;
@property (nonatomic) NSInteger identifier;
@property NSInteger post_id;
@property Comments *comments;
@property NSArray<WallPost *> *history;
@property Likes *likes;
@property (nonatomic) NSInteger owner_id;
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

/* Geo
{
    "coordinates": "53.150011483215 29.233310206932",
 Place
    "place": {
        "city": "\u0411\u043e\u0431\u0440\u0443\u0439\u0441\u043a",
        "country": "\u0411\u0435\u043b\u0430\u0440\u0443\u0441\u044c",
        "created": 0,
        "icon": "https://vk.com/images/places/place.png",
        "id": 0,
        "latitude": 0.0,
        "longitude": 0.0,
        "title": "\u0443\u043b\u0438\u0446\u0430 \u0421\u043e\u0432\u0435\u0442\u0441\u043a\u0430\u044f, \u0411\u043e\u0431\u0440\u0443\u0439\u0441\u043a"
    },
    "type": "point"
}
*/

@property NSArray<UserId *> *friendsIds;
@property NSArray<User *> *friends;

@property (nonatomic) User *user;

- (NSInteger)validId;
- (NSInteger)getOwnerId;
@end

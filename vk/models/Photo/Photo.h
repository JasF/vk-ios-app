//
//  Photo.h
//  vk
//
//  Created by Jasf on 10.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Likes.h"
#import "Reposts.h"
#import "Comments.h"
#import "User.h"
#import "Tags.h"

#import <EasyMapping/EasyMapping.h>


@interface Photo : NSObject <EKMappingProtocol>
@property NSString *access_key;
@property NSInteger id;
@property NSInteger album_id;
@property NSInteger owner_id;
@property (nonatomic) NSString *photo_75;
@property (nonatomic) NSString *photo_130;
@property (nonatomic) NSString *photo_604;
@property (nonatomic) NSString *photo_807;
@property (nonatomic) NSString *photo_1280;
@property (nonatomic) NSString *photo_2560;
@property CGFloat width;
@property CGFloat height;
@property NSString *text;
@property NSInteger date;
@property Likes *likes;
@property Reposts *reposts;
@property Comments *comments;
@property NSInteger can_comment;
@property NSInteger can_repost;
@property Tags *tags;

@property (nonatomic) NSNumber *asGallery;
@property (nonatomic) User *owner;

- (NSString *)bigPhotoURL;
@end

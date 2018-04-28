//
//  Answer.h
//  vk
//
//  Created by Jasf on 25.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WallPost.h"
#import "Photo.h"
#import "Comment.h"
#import "User.h"

#import <EasyMapping/EasyMapping.h>

@interface Answer : NSObject <EKMappingProtocol>
@property NSString *type;
@property NSInteger date;

@property WallPost *post;
@property Photo *photo;
@property Comment *parentComment;
@property Comment *feedbackComment;
@property Comment *replyComment;
@property NSArray<User *> *users;
    
- (BOOL)fillWithRepresentation:(NSDictionary *)representation users:(NSDictionary *)users;
    
@end

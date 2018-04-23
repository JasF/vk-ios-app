//
//  Comment.h
//  vk
//
//  Created by Jasf on 23.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import <Foundation/Foundation.h>

@import EasyMapping;

@interface Comment : NSObject <EKMappingProtocol>
@property NSInteger id;
@property NSInteger from_id;
@property NSInteger date;
@property NSString *text;
@property NSInteger reply_to_user;
@property NSInteger reply_to_comment;
@end

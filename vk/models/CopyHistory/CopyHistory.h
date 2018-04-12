//
//  CopyHistory.h
//  vk
//
//  Created by Jasf on 10.04.2018.
//  Copyright © 2018 Facebook. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Attachments.h"
#import "PostSource.h"
#import "PostType.h"

@import EasyMapping;

@interface CopyHistory : NSObject <EKMappingProtocol>
@property NSArray<Attachments *> *attachments;
@property NSInteger date;
@property NSInteger fromId;
@property NSInteger identifier;
@property NSInteger ownerId;
@property PostSource *postSource;
@property PostType *postType;
@property NSString *text;
@end

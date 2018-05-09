//
//  Message.h
//  vk
//
//  Created by Jasf on 12.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Attachments.h"

#import <EasyMapping/EasyMapping.h>

@interface Message : NSObject <EKMappingProtocol>
@property NSString *body;
@property NSInteger date;
@property NSInteger identifier;
@property NSInteger isOut;
@property NSInteger random_id;
@property NSInteger read_state;
@property NSString *title;
@property NSInteger user_id;
@property NSInteger from_id;
@property BOOL isTyping;
@property (nonatomic) NSArray<Attachments *> *photoAttachments;
@property (nonatomic) NSArray<Attachments *> *attachments;

@end

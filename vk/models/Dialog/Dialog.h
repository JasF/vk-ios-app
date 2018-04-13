//
//  Dialog.h
//  vk
//
//  Created by Jasf on 12.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Message.h"

@import EasyMapping;

@interface Dialog : NSObject <EKMappingProtocol>
@property NSInteger unread;
@property NSInteger in_read;
@property NSInteger out_read;
@property Message *message;

@property NSString *username;
@property NSString *avatarURLString;
@end

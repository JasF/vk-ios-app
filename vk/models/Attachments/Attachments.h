//
//  Attachments.h
//  vk
//
//  Created by Jasf on 10.04.2018.
//  Copyright © 2018 Facebook. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Photo.h"

@import EasyMapping;

typedef NS_ENUM(NSInteger, AttachmentTypes) {
    AttachmentUnknown,
    AttachmentPhoto
};

@interface Attachments : NSObject <EKMappingProtocol>
@property AttachmentTypes type;
@property Photo *photo;
@end

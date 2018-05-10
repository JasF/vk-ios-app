//
//  Attachments.h
//  vk
//
//  Created by Jasf on 10.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Photo.h"
#import "Video.h"
#import "Sticker.h"

#import <EasyMapping/EasyMapping.h>

typedef NS_ENUM(NSInteger, AttachmentTypes) {
    AttachmentUnknown,
    AttachmentPhoto,
    AttachmentVideo,
    AttachmentSticker
};

@interface Attachments : NSObject <EKMappingProtocol>
@property AttachmentTypes type;
@property Photo *photo;
@property Video *video;
@property (nonatomic) Sticker *sticker;
- (NSString *)uid;
@end

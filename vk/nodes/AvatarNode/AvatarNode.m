//
//  AvatarNode.m
//  vk
//
//  Created by Jasf on 18.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "AvatarNode.h"

static CGFloat const kSize = 40.f;

@implementation AvatarNode

#pragma mark - Initialization
- (id)initWithUser:(User *)user {
    if (self = [super init]) {
        _user = user;
        self.backgroundColor = ASDisplayNodeDefaultPlaceholderColor();
        self.style.width = ASDimensionMakeWithPoints(kSize);
        self.style.height = ASDimensionMakeWithPoints(kSize);
        self.cornerRadius = kSize/2;
        self.URL = [NSURL URLWithString:_user.avatarURLString];
        self.imageModificationBlock = ^UIImage *(UIImage *image) {
            UIImage *modifiedImage;
            CGRect rect = CGRectMake(0, 0, image.size.width, image.size.height);
            UIGraphicsBeginImageContextWithOptions(image.size, false, [[UIScreen mainScreen] scale]);
            [[UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:kSize] addClip];
            [image drawInRect:rect];
            modifiedImage = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            return modifiedImage;
        };
    }
    return self;
}

@end

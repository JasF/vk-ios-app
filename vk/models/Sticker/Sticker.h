//
//  Sticker.h
//  vk
//
//  Created by Jasf on 10.05.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <EasyMapping/EasyMapping.h>
#import "Photo.h"

@interface Sticker : NSObject <EKMappingProtocol>
@property NSInteger product_id;
@property NSInteger sticker_id;
@property NSArray<Photo *> *images;
@property NSArray<Photo *> *images_with_background;
- (Photo *)photoForChatCell;
@end

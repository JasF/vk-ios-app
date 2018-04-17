//
//  DeallocSubscriber.h
//  vk
//
//  Created by Jasf on 17.04.2018.
//  Copyright © 2018 Ebay Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DeallocSubscriber : NSObject
+ (void)subscribe:(id)object releasingBlock:(dispatch_block_t)block;
@end

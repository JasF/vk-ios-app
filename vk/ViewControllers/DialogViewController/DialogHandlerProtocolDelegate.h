//
//  DialogHandlerProtocolDelegate.h
//  vk
//
//  Created by Jasf on 16.04.2018.
//  Copyright © 2018 Ebay Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol DialogHandlerProtocolDelegate <NSObject>
- (void)handleIncomingMessage:(NSString *)message
                       userId:(NSNumber *)userId
                    timestamp:(NSNumber *)timestamp;
@end


//
//  RunLoop.h
//  Electrum
//
//  Created by Jasf on 20.03.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RunLoop : NSObject
+ (instancetype)shared;
- (void)exec:(NSInteger)requestId;
- (dispatch_group_t)enter:(NSInteger)requestId;
- (void)waitForGroup:(dispatch_group_t)group;
- (void)exit:(NSInteger)requestId;
@end

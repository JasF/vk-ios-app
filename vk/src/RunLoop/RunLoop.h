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
- (NSInteger)exec;
- (void)exit:(NSInteger)resultCode;
@end

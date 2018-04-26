//
//  PI_NRemoteImageTask+Subclassing.h
//  PI_NRemoteImage
//
//  Created by Garrett Moon on 5/22/17.
//  Copyright © 2017 Pinterest. All rights reserved.
//

#import "PI_NRemoteImageTask.h"

NS_ASSUME_NONNULL_BEGIN

@interface PI_NRemoteImageTask (Subclassing)

- (NSMutableDictionary *)l_callbackBlocks;
- (BOOL)l_cancelWithUUID:(NSUUID *)UUID;

@end

NS_ASSUME_NONNULL_END

//
//  PI_NRemoteImageMemoryContainer.m
//  Pods
//
//  Created by Garrett Moon on 3/17/16.
//
//

#import "PI_NRemoteImageMemoryContainer.h"

@implementation PI_NRemoteImageMemoryContainer

- (instancetype)init
{
    if (self = [super init]) {
        _lock = [[PI_NRemoteLock alloc] initWithName:@"PI_NRemoteImageMemoryContainer" lockType:PI_NRemoteLockTypeNonRecursive];
    }
    return self;
}

@end

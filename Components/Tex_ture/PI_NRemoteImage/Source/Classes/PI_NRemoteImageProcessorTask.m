//
//  PI_NRemoteImageProcessorTask.m
//  Pods
//
//  Created by Garrett Moon on 3/9/15.
//
//

#import "PI_NRemoteImageProcessorTask.h"

@implementation PI_NRemoteImageProcessorTask

@synthesize downloadTaskUUID = _downloadTaskUUID;

- (BOOL)cancelWithUUID:(NSUUID *)UUID resume:(PI_NResume **)resume
{
    BOOL noMoreCompletions = [super cancelWithUUID:UUID resume:resume];
    [self.lock lockWithBlock:^{
        if (noMoreCompletions && self->_downloadTaskUUID) {
            [self.manager cancelTaskWithUUID:self->_downloadTaskUUID];
            self->_downloadTaskUUID = nil;
        }
    }];
    return noMoreCompletions;
}

- (void)setDownloadTaskUUID:(NSUUID *)downloadTaskUUID
{
    [self.lock lockWithBlock:^{
        NSAssert(self->_downloadTaskUUID == nil, @"downloadTaskUUID should be nil");
        self->_downloadTaskUUID = downloadTaskUUID;
    }];
}

- (NSUUID *)downloadTaskUUID
{
    __block NSUUID *downloadTaskUUID;
    [self.lock lockWithBlock:^{
        downloadTaskUUID = self->_downloadTaskUUID;
    }];
    return downloadTaskUUID;
}

@end

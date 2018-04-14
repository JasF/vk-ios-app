//
//  PI_NRemoteImageTask.m
//  Pods
//
//  Created by Garrett Moon on 3/9/15.
//
//

#import "PI_NRemoteImageTask.h"

#import "PI_NRemoteImageCallbacks.h"
#import "PI_NRemoteImageManager+Private.h"

@interface PI_NRemoteImageTask ()
{
    NSMutableDictionary<NSUUID *, PI_NRemoteImageCallbacks *> *_callbackBlocks;
}

@end

@implementation PI_NRemoteImageTask

@synthesize lock = _lock;

- (instancetype)initWithManager:(PI_NRemoteImageManager *)manager
{
    if (self = [super init]) {
        _lock = [[PI_NRemoteLock alloc] initWithName:@"Task Lock"];
        _manager = manager;
        _callbackBlocks = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p> completionBlocks: %lu", NSStringFromClass([self class]), self, (unsigned long)self.callbackBlocks.count];
}

- (void)addCallbacksWithCompletionBlock:(PI_NRemoteImageManagerImageCompletion)completionBlock
                     progressImageBlock:(PI_NRemoteImageManagerImageCompletion)progressImageBlock
                  progressDownloadBlock:(PI_NRemoteImageManagerProgressDownload)progressDownloadBlock
                               withUUID:(NSUUID *)UUID
{
    PI_NRemoteImageCallbacks *completion = [[PI_NRemoteImageCallbacks alloc] init];
    completion.completionBlock = completionBlock;
    completion.progressImageBlock = progressImageBlock;
    completion.progressDownloadBlock = progressDownloadBlock;
    
    [self.lock lockWithBlock:^{
        [self->_callbackBlocks setObject:completion forKey:UUID];
    }];
}

- (void)removeCallbackWithUUID:(NSUUID *)UUID
{
    [self.lock lockWithBlock:^{
        [self l_removeCallbackWithUUID:UUID];
    }];
}

- (void)l_removeCallbackWithUUID:(NSUUID *)UUID
{
    [_callbackBlocks removeObjectForKey:UUID];
}

- (NSDictionary<NSUUID *, PI_NRemoteImageCallbacks *> *)callbackBlocks
{
    __block NSDictionary *callbackBlocks;
    [self.lock lockWithBlock:^{
        callbackBlocks = [self->_callbackBlocks copy];
    }];
    return callbackBlocks;
}

- (void)callCompletionsWithImage:(PI_NImage *)image
       alternativeRepresentation:(id)alternativeRepresentation
                          cached:(BOOL)cached
                        response:(NSURLResponse *)response
                           error:(NSError *)error
                          remove:(BOOL)remove;
{
    __weak typeof(self) weakSelf = self;
    [self.callbackBlocks enumerateKeysAndObjectsUsingBlock:^(NSUUID *UUID, PI_NRemoteImageCallbacks *callback, BOOL *stop) {
        typeof(self) strongSelf = weakSelf;
      PI_NRemoteImageManagerImageCompletion completionBlock = callback.completionBlock;
        if (completionBlock != nil) {
            PI_NLog(@"calling completion for UUID: %@ key: %@", UUID, strongSelf.key);
            CFTimeInterval requestTime = callback.requestTime;
          
            dispatch_async(self.manager.callbackQueue, ^
            {
                PI_NRemoteImageResultType result;
                if (image || alternativeRepresentation) {
                    result = cached ? PI_NRemoteImageResultTypeCache : PI_NRemoteImageResultTypeDownload;
                } else {
                    result = PI_NRemoteImageResultTypeNone;
                }
                completionBlock([self imageResultWithImage:image
                                 alternativeRepresentation:alternativeRepresentation
                                             requestLength:CACurrentMediaTime() - requestTime
                                                resultType:result
                                                      UUID:UUID
                                                  response:response
                                                     error:error]);
            });
        }
        if (remove) {
            [strongSelf removeCallbackWithUUID:UUID];
        }
    }];
}

- (BOOL)cancelWithUUID:(NSUUID *)UUID resume:(PI_NResume **)resume
{
    __block BOOL noMoreCompletions;
    [self.lock lockWithBlock:^{
        noMoreCompletions = [self l_cancelWithUUID:UUID];
    }];
    return noMoreCompletions;
}

- (BOOL)l_cancelWithUUID:(NSUUID *)UUID
{
    BOOL noMoreCompletions = NO;
    [self l_removeCallbackWithUUID:UUID];
    if ([_callbackBlocks count] == 0) {
        noMoreCompletions = YES;
    }
    return noMoreCompletions;
}

- (void)setPriority:(PI_NRemoteImageManagerPriority)priority
{
    
}

- (nonnull PI_NRemoteImageManagerResult *)imageResultWithImage:(nullable PI_NImage *)image
                                    alternativeRepresentation:(nullable id)alternativeRepresentation
                                                requestLength:(NSTimeInterval)requestLength
                                                   resultType:(PI_NRemoteImageResultType)resultType
                                                         UUID:(nullable NSUUID *)UUID
                                                     response:(NSURLResponse *)response
                                                        error:(nullable NSError *)error
{
    return [PI_NRemoteImageManagerResult imageResultWithImage:image
                                   alternativeRepresentation:alternativeRepresentation
                                               requestLength:requestLength
                                                  resultType:resultType
                                                        UUID:UUID
                                                    response:response
                                                       error:error];
}

- (NSMutableDictionary *)l_callbackBlocks
{
    return _callbackBlocks;
}

@end

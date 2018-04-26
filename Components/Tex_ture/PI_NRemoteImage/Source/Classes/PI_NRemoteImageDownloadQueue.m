//
//  PI_NRemoteImageDownloadQueue.m
//  PI_NRemoteImage
//
//  Created by Garrett Moon on 3/1/17.
//  Copyright © 2017 Pinterest. All rights reserved.
//

#import "PI_NRemoteImageDownloadQueue.h"

#import "PI_NURLSessionManager.h"
#import "PI_NRemoteLock.h"

@interface PI_NRemoteImageDownloadQueue ()
{
    PI_NRemoteLock *_lock;
    
    NSMutableOrderedSet <NSURLSessionDataTask *> *_highPriorityQueuedOperations;
    NSMutableOrderedSet <NSURLSessionDataTask *> *_defaultPriorityQueuedOperations;
    NSMutableOrderedSet <NSURLSessionDataTask *> *_lowPriorityQueuedOperations;
    NSMutableSet <NSURLSessionTask *> *_runningTasks;
}

@end

@implementation PI_NRemoteImageDownloadQueue

@synthesize maxNumberOfConcurrentDownloads = _maxNumberOfConcurrentDownloads;

+ (PI_NRemoteImageDownloadQueue *)queueWithMaxConcurrentDownloads:(NSUInteger)maxNumberOfConcurrentDownloads
{
    return [[PI_NRemoteImageDownloadQueue alloc] initWithMaxConcurrentDownloads:maxNumberOfConcurrentDownloads];
}

- (PI_NRemoteImageDownloadQueue *)initWithMaxConcurrentDownloads:(NSUInteger)maxNumberOfConcurrentDownloads
{
    if (self = [super init]) {
        _maxNumberOfConcurrentDownloads = maxNumberOfConcurrentDownloads;
        
        _lock = [[PI_NRemoteLock alloc] initWithName:@"PI_NRemoteImageDownloadQueue Lock"];
        _highPriorityQueuedOperations = [[NSMutableOrderedSet alloc] init];
        _defaultPriorityQueuedOperations = [[NSMutableOrderedSet alloc] init];
        _lowPriorityQueuedOperations = [[NSMutableOrderedSet alloc] init];
        _runningTasks = [[NSMutableSet alloc] init];
    }
    return self;
}

- (NSUInteger)maxNumberOfConcurrentDownloads
{
    [self lock];
        NSUInteger maxNumberOfConcurrentDownloads = _maxNumberOfConcurrentDownloads;
    [self unlock];
    return maxNumberOfConcurrentDownloads;
}

- (void)setMaxNumberOfConcurrentDownloads:(NSUInteger)maxNumberOfConcurrentDownloads
{
    [self lock];
        _maxNumberOfConcurrentDownloads = maxNumberOfConcurrentDownloads;
    [self unlock];
    
    [self scheduleDownloadsIfNeeded];
}

- (NSURLSessionDataTask *)addDownloadWithSessionManager:(PI_NURLSessionManager *)sessionManager
                                                request:(NSURLRequest *)request
                                               priority:(PI_NRemoteImageManagerPriority)priority
                                      completionHandler:(PI_NRemoteImageDownloadCompletion)completionHandler
{
    NSURLSessionDataTask *dataTask = [sessionManager dataTaskWithRequest:request completionHandler:^(NSURLSessionTask *task, NSError *error) {
        completionHandler(task.response, error);
        [self lock];
            [self->_runningTasks removeObject:task];
        [self unlock];
        
        [self scheduleDownloadsIfNeeded];
    }];
    
    [self setQueuePriority:priority forTask:dataTask addIfNecessary:YES];
    
    [self scheduleDownloadsIfNeeded];
    
    return dataTask;
}

- (void)scheduleDownloadsIfNeeded
{
    [self lock];
        while (_runningTasks.count < _maxNumberOfConcurrentDownloads) {
            NSMutableOrderedSet <NSURLSessionDataTask *> *queue = nil;
            if (_highPriorityQueuedOperations.count > 0) {
                queue = _highPriorityQueuedOperations;
            } else if (_defaultPriorityQueuedOperations.count > 0) {
                queue = _defaultPriorityQueuedOperations;
            } else if (_lowPriorityQueuedOperations.count > 0) {
                queue = _lowPriorityQueuedOperations;
            }
            
            if (!queue) {
                break;
            }
            
            NSURLSessionDataTask *task = [queue firstObject];
            [queue removeObjectAtIndex:0];
            [task resume];
            
            
            [_runningTasks addObject:task];
        }
    [self unlock];
}

- (BOOL)removeDownloadTaskFromQueue:(NSURLSessionDataTask *)downloadTask
{
    BOOL containsTask = NO;
    [self lock];
        if ([_highPriorityQueuedOperations containsObject:downloadTask]) {
            containsTask = YES;
            [_highPriorityQueuedOperations removeObject:downloadTask];
        } else if ([_defaultPriorityQueuedOperations containsObject:downloadTask]) {
            containsTask = YES;
            [_defaultPriorityQueuedOperations removeObject:downloadTask];
        } else if ([_lowPriorityQueuedOperations containsObject:downloadTask]) {
            containsTask = YES;
            [_lowPriorityQueuedOperations removeObject:downloadTask];
        }
    [self unlock];
    return containsTask;
}

- (void)setQueuePriority:(PI_NRemoteImageManagerPriority)priority forTask:(NSURLSessionDataTask *)downloadTask
{
    [self setQueuePriority:priority forTask:downloadTask addIfNecessary:NO];
}

- (void)setQueuePriority:(PI_NRemoteImageManagerPriority)priority forTask:(NSURLSessionDataTask *)downloadTask addIfNecessary:(BOOL)addIfNecessary
{
    BOOL containsTask = [self removeDownloadTaskFromQueue:downloadTask];
    
    if (containsTask || addIfNecessary) {
        NSMutableOrderedSet <NSURLSessionDataTask *> *queue = nil;
        [self lock];
            switch (priority) {
                case PI_NRemoteImageManagerPriorityLow:
                    queue = _lowPriorityQueuedOperations;
                    break;
                    
                case PI_NRemoteImageManagerPriorityDefault:
                    queue = _defaultPriorityQueuedOperations;
                    break;
                    
                case PI_NRemoteImageManagerPriorityHigh:
                    queue = _highPriorityQueuedOperations;
                    break;
                    
                default:
                    NSAssert(NO, @"invalid priority: %tu", priority);
                    break;
            }
            [queue addObject:downloadTask];
        [self unlock];
    }
}

- (void)lock
{
    [_lock lock];
}

- (void)unlock
{
    [_lock unlock];
}

@end

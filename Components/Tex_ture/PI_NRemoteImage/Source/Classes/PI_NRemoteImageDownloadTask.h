//
//  PI_NRemoteImageDownloadTask.h
//  Pods
//
//  Created by Garrett Moon on 3/9/15.
//
//

#import <PI_NOperation/PI_NOperation.h>

#import "PI_NRemoteImageManager+Private.h"
#import "PI_NRemoteImageTask.h"
#import "PI_NProgressiveImage.h"
#import "PI_NResume.h"

@interface PI_NRemoteImageDownloadTask : PI_NRemoteImageTask

@property (nonatomic, strong, nullable, readonly) NSURL *URL;
@property (nonatomic, copy, nullable) NSString *ifRange;
@property (nonatomic, copy, readonly, nullable) NSData *data;

@property (nonatomic, readonly) CFTimeInterval estimatedRemainingTime;

- (void)scheduleDownloadWithRequest:(nonnull NSURLRequest *)request
                             resume:(nullable PI_NResume *)resume
                          skipRetry:(BOOL)skipRetry
                           priority:(PI_NRemoteImageManagerPriority)priority
                  completionHandler:(nonnull PI_NRemoteImageManagerDataCompletion)completionHandler;

- (void)didReceiveData:(nonnull NSData *)data;
- (void)didReceiveResponse:(nonnull NSURLResponse *)response;

@end

//
//  PI_NRemoteImageTask.h
//  Pods
//
//  Created by Garrett Moon on 3/9/15.
//
//

#import <Foundation/Foundation.h>
#import <PI_NOperation/PI_NOperation.h>

#import "PI_NRemoteImageCallbacks.h"
#import "PI_NRemoteImageManager.h"
#import "PI_NRemoteImageMacros.h"
#import "PI_NRemoteLock.h"
#import "PI_NResume.h"

@interface PI_NRemoteImageTask : NSObject

@property (nonatomic, strong, readonly, nonnull) PI_NRemoteLock *lock;

@property (nonatomic, copy, readonly, nonnull) NSDictionary<NSUUID *, PI_NRemoteImageCallbacks *> *callbackBlocks;

@property (nonatomic, weak, nullable) PI_NRemoteImageManager *manager;

@property (nonatomic, strong, nullable) id<PI_NRequestRetryStrategy> retryStrategy;
#if PI_NRemoteImageLogging
@property (nonatomic, copy, nullable) NSString *key;
#endif

- (_Nonnull instancetype)init NS_UNAVAILABLE;
- (_Nonnull instancetype)initWithManager:(nonnull PI_NRemoteImageManager *)manager NS_DESIGNATED_INITIALIZER;

- (void)addCallbacksWithCompletionBlock:(nonnull PI_NRemoteImageManagerImageCompletion)completionBlock
                     progressImageBlock:(nullable PI_NRemoteImageManagerImageCompletion)progressImageBlock
                  progressDownloadBlock:(nullable PI_NRemoteImageManagerProgressDownload)progressDownloadBlock
                               withUUID:(nonnull NSUUID *)UUID;

- (void)removeCallbackWithUUID:(nonnull NSUUID *)UUID;

- (void)callCompletionsWithImage:(nullable PI_NImage *)image
       alternativeRepresentation:(nullable id)alternativeRepresentation
                          cached:(BOOL)cached
                        response:(nullable NSURLResponse *)response
                           error:(nullable NSError *)error
                          remove:(BOOL)remove;

//returns YES if no more attached completionBlocks
- (BOOL)cancelWithUUID:(nonnull NSUUID *)UUID resume:(PI_NResume * _Nullable * _Nullable)resume;

- (void)setPriority:(PI_NRemoteImageManagerPriority)priority;

- (nonnull PI_NRemoteImageManagerResult *)imageResultWithImage:(nullable PI_NImage *)image
                                    alternativeRepresentation:(nullable id)alternativeRepresentation
                                                requestLength:(NSTimeInterval)requestLength
                                                   resultType:(PI_NRemoteImageResultType)resultType
                                                         UUID:(nullable NSUUID *)uuid
                                                     response:(nullable NSURLResponse *)response
                                                        error:(nullable NSError *)error;

@end

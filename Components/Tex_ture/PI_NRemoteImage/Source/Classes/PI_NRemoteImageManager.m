//
//  PI_NRemoteImageManager.m
//  Pods
//
//  Created by Garrett Moon on 8/17/14.
//
//

#import "PI_NRemoteImageManager.h"

#import <CommonCrypto/CommonDigest.h>
#import <PI_NOperation/PI_NOperation.h>

#import "PI_NAlternateRepresentationProvider.h"
#import "PI_NRemoteImage.h"
#import "PI_NRemoteLock.h"
#import "PI_NProgressiveImage.h"
#import "PI_NRemoteImageCallbacks.h"
#import "PI_NRemoteImageTask.h"
#import "PI_NRemoteImageProcessorTask.h"
#import "PI_NRemoteImageDownloadTask.h"
#import "PI_NResume.h"
#import "PI_NRemoteImageMemoryContainer.h"
#import "PI_NRemoteImageCaching.h"
#import "PI_NRequestRetryStrategy.h"
#import "PI_NRemoteImageDownloadQueue.h"
#import "PI_NRequestRetryStrategy.h"
#import "PI_NSpeedRecorder.h"
#import "PI_NURLSessionManager.h"

#import "NSData+ImageDe_tectors.h"
#import "PI_NImage+DecodedImage.h"
#import "PI_NImage+ScaledImage.h"

#if USE_PI_NCACHE
#import "PI_NCache+PI_NRemoteImageCaching.h"
#else
#import "PI_NRemoteImageBasicCache.h"
#endif


#define PI_NRemoteImageManagerDefaultTimeout            30.0
#define PI_NRemoteImageHTTPMaximumConnectionsPerHost    UINT16_MAX
//A limit of 200 characters is chosen because PI_NDiskCache
//may expand the length by encoding certain characters
#define PI_NRemoteImageManagerCacheKeyMaxLength 200

PI_NOperationQueuePriority operationPriorityWithImageManagerPriority(PI_NRemoteImageManagerPriority priority);
PI_NOperationQueuePriority operationPriorityWithImageManagerPriority(PI_NRemoteImageManagerPriority priority) {
    switch (priority) {
        case PI_NRemoteImageManagerPriorityLow:
            return PI_NOperationQueuePriorityLow;
            break;
            
        case PI_NRemoteImageManagerPriorityDefault:
            return PI_NOperationQueuePriorityDefault;
            break;
            
        case PI_NRemoteImageManagerPriorityHigh:
            return PI_NOperationQueuePriorityHigh;
            break;
    }
}

float dataTaskPriorityWithImageManagerPriority(PI_NRemoteImageManagerPriority priority) {
    switch (priority) {
        case PI_NRemoteImageManagerPriorityLow:
            return 0.0;
            break;
            
        case PI_NRemoteImageManagerPriorityDefault:
            return 0.5;
            break;
            
        case PI_NRemoteImageManagerPriorityHigh:
            return 1.0;
            break;
    }
}

NSErrorDomain const PI_NRemoteImageManagerErrorDomain = @"PI_NRemoteImageManagerErrorDomain";
NSString * const PI_NRemoteImageCacheKey = @"cacheKey";
NSString * const PI_NRemoteImageCacheKeyResumePrefix = @"R-";
typedef void (^PI_NRemoteImageManagerDataCompletion)(NSData *data, NSURLResponse *response, NSError *error);

@interface PI_NRemoteImageManager () <PI_NURLSessionManagerDelegate>
{
  dispatch_queue_t _callbackQueue;
  PI_NRemoteLock *_lock;
  PI_NOperationQueue *_concurrentOperationQueue;
  PI_NRemoteImageDownloadQueue *_urlSessionTaskQueue;
  
  // Necesarry to have a strong reference to _defaultAlternateRepresentationProvider because _alternateRepProvider is __weak
  PI_NAlternateRepresentationProvider *_defaultAlternateRepresentationProvider;
  __weak PI_NAlternateRepresentationProvider *_alternateRepProvider;
  NSURLSessionConfiguration *_sessionConfiguration;

}

@property (nonatomic, strong) id<PI_NRemoteImageCaching> cache;
@property (nonatomic, strong) PI_NURLSessionManager *sessionManager;
@property (nonatomic, strong) NSMutableDictionary <NSString *, __kindof PI_NRemoteImageTask *> *tasks;
@property (nonatomic, strong) NSHashTable <NSUUID *> *canceledTasks;
@property (nonatomic, strong) NSArray <NSNumber *> *progressThresholds;
@property (nonatomic, assign) BOOL shouldBlurProgressive;
@property (nonatomic, assign) CGSize maxProgressiveRenderSize;
@property (nonatomic, assign) NSTimeInterval estimatedRemainingTimeThreshold;
@property (nonatomic, strong) dispatch_queue_t callbackQueue;
@property (nonatomic, strong) PI_NOperationQueue *concurrentOperationQueue;
@property (nonatomic, strong) PI_NRemoteImageDownloadQueue *urlSessionTaskQueue;
@property (nonatomic, assign) float highQualityBPSThreshold;
@property (nonatomic, assign) float lowQualityBPSThreshold;
@property (nonatomic, assign) BOOL shouldUpgradeLowQualityImages;
@property (nonatomic, copy) PI_NRemoteImageManagerAuthenticationChallenge authenticationChallengeHandler;
@property (nonatomic, copy) id<PI_NRequestRetryStrategy> (^retryStrategyCreationBlock)(void);
@property (nonatomic, copy) PI_NRemoteImageManagerRequestConfigurationHandler requestConfigurationHandler;
@property (nonatomic, strong) NSMutableDictionary <NSString *, NSString *> *httpHeaderFields;
#if DEBUG
@property (nonatomic, assign) NSUInteger totalDownloads;
#endif

@end

#pragma mark PI_NRemoteImageManager

@implementation PI_NRemoteImageManager

static PI_NRemoteImageManager *sharedImageManager = nil;
static dispatch_once_t sharedDispatchToken;

+ (instancetype)sharedImageManager
{
    dispatch_once(&sharedDispatchToken, ^{
        sharedImageManager = [[[self class] alloc] init];
    });
    return sharedImageManager;
}

+ (void)setSharedImageManagerWithConfiguration:(NSURLSessionConfiguration *)configuration
{
    NSAssert(sharedImageManager == nil, @"sharedImageManager singleton is already configured");

    dispatch_once(&sharedDispatchToken, ^{
        sharedImageManager = [[[self class] alloc] initWithSessionConfiguration:configuration];
    });
}

- (instancetype)init
{
    return [self initWithSessionConfiguration:nil];
}

- (instancetype)initWithSessionConfiguration:(NSURLSessionConfiguration *)configuration
{
    return [self initWithSessionConfiguration:configuration alternativeRepresentationProvider:nil];
}

- (instancetype)initWithSessionConfiguration:(NSURLSessionConfiguration *)configuration alternativeRepresentationProvider:(id <PI_NRemoteImageManagerAlternateRepresentationProvider>)alternateRepProvider
{
    return [self initWithSessionConfiguration:configuration alternativeRepresentationProvider:alternateRepProvider imageCache:nil];
}

- (nonnull instancetype)initWithSessionConfiguration:(nullable NSURLSessionConfiguration *)configuration
                   alternativeRepresentationProvider:(nullable id <PI_NRemoteImageManagerAlternateRepresentationProvider>)alternateRepProvider
                                          imageCache:(nullable id<PI_NRemoteImageCaching>)imageCache
{
    if (self = [super init]) {
        
        if (imageCache) {
            self.cache = imageCache;
        } else {
            self.cache = [self defaultImageCache];
        }
        
        _sessionConfiguration = [configuration copy];
        if (!_sessionConfiguration) {
            _sessionConfiguration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
            _sessionConfiguration.timeoutIntervalForRequest = PI_NRemoteImageManagerDefaultTimeout;
        }
        _sessionConfiguration.HTTPMaximumConnectionsPerHost = PI_NRemoteImageHTTPMaximumConnectionsPerHost;
        
        _callbackQueue = dispatch_queue_create("PI_NRemoteImageManagerCallbackQueue", DISPATCH_QUEUE_CONCURRENT);
        _lock = [[PI_NRemoteLock alloc] initWithName:@"PI_NRemoteImageManager"];

        _concurrentOperationQueue = [[PI_NOperationQueue alloc] initWithMaxConcurrentOperations:[[NSProcessInfo processInfo] activeProcessorCount] * 2];
        _urlSessionTaskQueue = [PI_NRemoteImageDownloadQueue queueWithMaxConcurrentDownloads:10];
        
        self.sessionManager = [[PI_NURLSessionManager alloc] initWithSessionConfiguration:configuration];
        self.sessionManager.delegate = self;
        
        self.estimatedRemainingTimeThreshold = 0.1;
      
        _highQualityBPSThreshold = 500000;
        _lowQualityBPSThreshold = 50000; // approximately edge speeds
        _shouldUpgradeLowQualityImages = NO;
        _shouldBlurProgressive = YES;
        _maxProgressiveRenderSize = CGSizeMake(1024, 1024);
        self.tasks = [[NSMutableDictionary alloc] init];
        self.canceledTasks = [[NSHashTable alloc] initWithOptions:NSHashTableWeakMemory capacity:5];
        
        if (alternateRepProvider == nil) {
            _defaultAlternateRepresentationProvider = [[PI_NAlternateRepresentationProvider alloc] init];
            alternateRepProvider = _defaultAlternateRepresentationProvider;
        }
        _alternateRepProvider = alternateRepProvider;
        __weak typeof(self) weakSelf = self;
        _retryStrategyCreationBlock = ^id<PI_NRequestRetryStrategy>{
            return [weakSelf defaultRetryStrategy];
        };
        _httpHeaderFields = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (id<PI_NRequestRetryStrategy>)defaultRetryStrategy {
    return [[PI_NRequestExponentialRetryStrategy alloc] initWithRetryMaxCount:3 delayBase:4];
}

- (id<PI_NRemoteImageCaching>)defaultImageCache
{
#if USE_PI_NCACHE
    NSString * const kPI_NRemoteImageDiskCacheName = @"PI_NRemoteImageManagerCache";
    NSString * const kPI_NRemoteImageDiskCacheVersionKey = @"kPI_NRemoteImageDiskCacheVersionKey";
    const NSInteger kPI_NRemoteImageDiskCacheVersion = 1;
    NSUserDefaults *pinDefaults = [[NSUserDefaults alloc] init];
    
    NSString *cacheURLRoot = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    
    if ([pinDefaults integerForKey:kPI_NRemoteImageDiskCacheVersionKey] != kPI_NRemoteImageDiskCacheVersion) {
        //remove the old version of the disk cache
        NSURL *diskCacheURL = [PI_NDiskCache cacheURLWithRootPath:cacheURLRoot prefix:PI_NDiskCachePrefix name:kPI_NRemoteImageDiskCacheName];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSURL *dstURL = [[[NSURL alloc] initFileURLWithPath:NSTemporaryDirectory()] URLByAppendingPathComponent:kPI_NRemoteImageDiskCacheName];
        [fileManager moveItemAtURL:diskCacheURL toURL:dstURL error:nil];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [fileManager removeItemAtURL:dstURL error:nil];
        });
        [pinDefaults setInteger:kPI_NRemoteImageDiskCacheVersion forKey:kPI_NRemoteImageDiskCacheVersionKey];
    }
  
    return [[PI_NCache alloc] initWithName:kPI_NRemoteImageDiskCacheName rootPath:cacheURLRoot serializer:^NSData * _Nonnull(id<NSCoding>  _Nonnull object, NSString * _Nonnull key) {
        id <NSCoding, NSObject> obj = (id <NSCoding, NSObject>)object;
        if ([key hasPrefix:PI_NRemoteImageCacheKeyResumePrefix]) {
            return [NSKeyedArchiver archivedDataWithRootObject:obj];
        }
        return (NSData *)object;
    } deserializer:^id<NSCoding> _Nonnull(NSData * _Nonnull data, NSString * _Nonnull key) {
        if ([key hasPrefix:PI_NRemoteImageCacheKeyResumePrefix]) {
            return [NSKeyedUnarchiver unarchiveObjectWithData:data];
        }
        return data;
    }];
#else
    return [[PI_NRemoteImageBasicCache alloc] init];
#endif
}

- (void)lockOnMainThread
{
#if !DEBUG
    NSAssert(NO, @"lockOnMainThread should only be called for testing on debug builds!");
#endif
    [_lock lock];
}

- (void)lock
{
    NSAssert([NSThread isMainThread] == NO, @"lock should not be called from the main thread!");
    [_lock lock];
}

- (void)unlock
{
    [_lock unlock];
}

- (void)setValue:(nullable NSString *)value forHTTPHeaderField:(nullable NSString *)header {
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        typeof(self) strongSelf = weakSelf;
        [strongSelf lock];
            strongSelf.httpHeaderFields[[header copy]] = [value copy];
        [strongSelf unlock];
    });
}

- (void)setRequestConfiguration:(PI_NRemoteImageManagerRequestConfigurationHandler)configurationBlock {
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        typeof(self) strongSelf = weakSelf;
        [strongSelf lock];
            strongSelf.requestConfigurationHandler = configurationBlock;
        [strongSelf unlock];
    });
}

- (void)setAuthenticationChallenge:(PI_NRemoteImageManagerAuthenticationChallenge)challengeBlock {
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        typeof(self) strongSelf = weakSelf;
        [strongSelf lock];
            strongSelf.authenticationChallengeHandler = challengeBlock;
        [strongSelf unlock];
    });
}

- (void)setMaxNumberOfConcurrentOperations:(NSInteger)maxNumberOfConcurrentOperations completion:(dispatch_block_t)completion
{
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        typeof(self) strongSelf = weakSelf;
        [strongSelf lock];
            strongSelf.concurrentOperationQueue.maxConcurrentOperations = maxNumberOfConcurrentOperations;
        [strongSelf unlock];
        if (completion) {
            completion();
        }
    });
}

- (void)setMaxNumberOfConcurrentDownloads:(NSInteger)maxNumberOfConcurrentDownloads completion:(dispatch_block_t)completion
{
    NSAssert(maxNumberOfConcurrentDownloads <= PI_NRemoteImageHTTPMaximumConnectionsPerHost, @"maxNumberOfConcurrentDownloads must be less than or equal to %d", PI_NRemoteImageHTTPMaximumConnectionsPerHost);
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        typeof(self) strongSelf = weakSelf;
        [strongSelf lock];
            strongSelf.urlSessionTaskQueue.maxNumberOfConcurrentDownloads = maxNumberOfConcurrentDownloads;
        [strongSelf unlock];
        if (completion) {
            completion();
        }
    });
}

- (void)setEstimatedRemainingTimeThresholdForProgressiveDownloads:(NSTimeInterval)estimatedRemainingTimeThreshold completion:(dispatch_block_t)completion
{
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        typeof(self) strongSelf = weakSelf;
        [strongSelf lock];
            strongSelf.estimatedRemainingTimeThreshold = estimatedRemainingTimeThreshold;
        [strongSelf unlock];
        if (completion) {
            completion();
        }
    });
}

- (void)setProgressThresholds:(NSArray *)progressThresholds completion:(dispatch_block_t)completion
{
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        typeof(self) strongSelf = weakSelf;
        [strongSelf lock];
            strongSelf.progressThresholds = progressThresholds;
        [strongSelf unlock];
        if (completion) {
            completion();
        }
    });
}

- (void)setProgressiveRendersShouldBlur:(BOOL)shouldBlur completion:(nullable dispatch_block_t)completion
{
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        typeof(self) strongSelf = weakSelf;
        [strongSelf lock];
            strongSelf.shouldBlurProgressive = shouldBlur;
        [strongSelf unlock];
        if (completion) {
            completion();
        }
    });
}

- (void)setProgressiveRendersMaxProgressiveRenderSize:(CGSize)maxProgressiveRenderSize completion:(nullable dispatch_block_t)completion
{
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        typeof(self) strongSelf = weakSelf;
        [strongSelf lock];
            strongSelf.maxProgressiveRenderSize = maxProgressiveRenderSize;
        [strongSelf unlock];
        if (completion) {
            completion();
        }
    });
}

- (void)setHighQualityBPSThreshold:(float)highQualityBPSThreshold completion:(dispatch_block_t)completion
{
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        typeof(self) strongSelf = weakSelf;
        [strongSelf lock];
            strongSelf.highQualityBPSThreshold = highQualityBPSThreshold;
        [strongSelf unlock];
        if (completion) {
            completion();
        }
    });
}

- (void)setLowQualityBPSThreshold:(float)lowQualityBPSThreshold completion:(dispatch_block_t)completion
{
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        typeof(self) strongSelf = weakSelf;
        [strongSelf lock];
            strongSelf.lowQualityBPSThreshold = lowQualityBPSThreshold;
        [strongSelf unlock];
        if (completion) {
            completion();
        }
    });
}

- (void)setShouldUpgradeLowQualityImages:(BOOL)shouldUpgradeLowQualityImages completion:(dispatch_block_t)completion
{
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        typeof(self) strongSelf = weakSelf;
        [strongSelf lock];
            strongSelf.shouldUpgradeLowQualityImages = shouldUpgradeLowQualityImages;
        [strongSelf unlock];
        if (completion) {
            completion();
        }
    });
}

- (NSUUID *)downloadImageWithURL:(NSURL *)url
                      completion:(PI_NRemoteImageManagerImageCompletion)completion
{
    return [self downloadImageWithURL:url
                              options:PI_NRemoteImageManagerDownloadOptionsNone
                           completion:completion];
}

- (NSUUID *)downloadImageWithURL:(NSURL *)url
                         options:(PI_NRemoteImageManagerDownloadOptions)options
                      completion:(PI_NRemoteImageManagerImageCompletion)completion
{
    return [self downloadImageWithURL:url
                              options:options
                        progressImage:nil
                           completion:completion];
}

- (NSUUID *)downloadImageWithURL:(NSURL *)url
                         options:(PI_NRemoteImageManagerDownloadOptions)options
                   progressImage:(PI_NRemoteImageManagerImageCompletion)progressImage
                      completion:(PI_NRemoteImageManagerImageCompletion)completion
{
    return [self downloadImageWithURL:url
                              options:options
                             priority:PI_NRemoteImageManagerPriorityDefault
                         processorKey:nil
                            processor:nil
                        progressImage:progressImage
                     progressDownload:nil
                           completion:completion
                            inputUUID:nil];
}

- (NSUUID *)downloadImageWithURL:(NSURL *)url
                         options:(PI_NRemoteImageManagerDownloadOptions)options
                progressDownload:(PI_NRemoteImageManagerProgressDownload)progressDownload
                      completion:(PI_NRemoteImageManagerImageCompletion)completion
{
    return [self downloadImageWithURL:url
                              options:options
                             priority:PI_NRemoteImageManagerPriorityDefault
                         processorKey:nil
                            processor:nil
                        progressImage:nil
                     progressDownload:progressDownload
                           completion:completion
                            inputUUID:nil];
}

- (NSUUID *)downloadImageWithURL:(NSURL *)url
                         options:(PI_NRemoteImageManagerDownloadOptions)options
                   progressImage:(PI_NRemoteImageManagerImageCompletion)progressImage
                progressDownload:(PI_NRemoteImageManagerProgressDownload)progressDownload
                      completion:(PI_NRemoteImageManagerImageCompletion)completion
{
    return [self downloadImageWithURL:url
                              options:options
                             priority:PI_NRemoteImageManagerPriorityDefault
                         processorKey:nil
                            processor:nil
                        progressImage:progressImage
                     progressDownload:progressDownload
                           completion:completion
                            inputUUID:nil];
}

- (NSUUID *)downloadImageWithURL:(NSURL *)url
                         options:(PI_NRemoteImageManagerDownloadOptions)options
                    processorKey:(NSString *)processorKey
                       processor:(PI_NRemoteImageManagerImageProcessor)processor
                      completion:(PI_NRemoteImageManagerImageCompletion)completion
{
    return [self downloadImageWithURL:url
                              options:options
                             priority:PI_NRemoteImageManagerPriorityDefault
                         processorKey:processorKey
                            processor:processor
                        progressImage:nil
                     progressDownload:nil
                           completion:completion
                            inputUUID:nil];
}

- (NSUUID *)downloadImageWithURL:(NSURL *)url
                         options:(PI_NRemoteImageManagerDownloadOptions)options
                    processorKey:(NSString *)processorKey
                       processor:(PI_NRemoteImageManagerImageProcessor)processor
                progressDownload:(PI_NRemoteImageManagerProgressDownload)progressDownload
                      completion:(PI_NRemoteImageManagerImageCompletion)completion
{
    return [self downloadImageWithURL:url
                          options:options
                         priority:PI_NRemoteImageManagerPriorityDefault
                     processorKey:processorKey
                        processor:processor
                    progressImage:nil
                 progressDownload:progressDownload
                       completion:completion
                        inputUUID:nil];
}

- (NSUUID *)downloadImageWithURL:(NSURL *)url
                         options:(PI_NRemoteImageManagerDownloadOptions)options
                        priority:(PI_NRemoteImageManagerPriority)priority
                    processorKey:(NSString *)processorKey
                       processor:(PI_NRemoteImageManagerImageProcessor)processor
                   progressImage:(PI_NRemoteImageManagerImageCompletion)progressImage
                progressDownload:(PI_NRemoteImageManagerProgressDownload)progressDownload
                      completion:(PI_NRemoteImageManagerImageCompletion)completion
                       inputUUID:(NSUUID *)UUID
{
    NSAssert((processor != nil && processorKey.length > 0) || (processor == nil && processorKey == nil), @"processor must not be nil and processorKey length must be greater than zero OR processor must be nil and processorKey must be nil");
    
    Class taskClass;
    if (processor && processorKey.length > 0) {
        taskClass = [PI_NRemoteImageProcessorTask class];
    } else {
        taskClass = [PI_NRemoteImageDownloadTask class];
    }
    
    NSString *key = [self cacheKeyForURL:url processorKey:processorKey];

    if (url == nil) {
        [self earlyReturnWithOptions:options url:nil key:key object:nil completion:completion];
        return nil;
    }
    
    NSAssert([url isKindOfClass:[NSURL class]], @"url must be of type NSURL, if it's an NSString, we'll try to correct");
    if ([url isKindOfClass:[NSString class]]) {
        url = [NSURL URLWithString:(NSString *)url];
    }

    if (UUID == nil) {
        UUID = [NSUUID UUID];
    }

    if ((options & PI_NRemoteImageManagerDownloadOptionsIgnoreCache) == 0) {
        //Check to see if the image is in memory cache and we're on the main thread.
        //If so, special case this to avoid flashing the UI
        id object = [self.cache objectFromMemoryForKey:key];
        if (object) {
            if ([self earlyReturnWithOptions:options url:url key:key object:object completion:completion]) {
                return nil;
            }
        }
    }
    
    if ([url.scheme isEqualToString:@"data"]) {
        NSData *data = [NSData dataWithContentsOfURL:url];
        if (data) {
            if ([self earlyReturnWithOptions:options url:url key:key object:data completion:completion]) {
                return nil;
            }
        }
    }
    
    [_concurrentOperationQueue scheduleOperation:^
    {
        [self lock];
            //check canceled tasks first
            if ([self.canceledTasks containsObject:UUID]) {
                PI_NLog(@"skipping starting %@ because it was canceled.", UUID);
                [self unlock];
                return;
            }
        
            PI_NRemoteImageTask *task = [self.tasks objectForKey:key];
            BOOL taskExisted = NO;
            if (task == nil) {
                task = [[taskClass alloc] initWithManager:self];
                PI_NLog(@"Task does not exist creating with key: %@, URL: %@, UUID: %@, task: %p", key, url, UUID, task);
    #if PI_NRemoteImageLogging
                task.key = key;
    #endif
            } else {
                taskExisted = YES;
                PI_NLog(@"Task exists, attaching with key: %@, URL: %@, UUID: %@, task: %@", key, url, UUID, task);
            }
            [task addCallbacksWithCompletionBlock:completion progressImageBlock:progressImage progressDownloadBlock:progressDownload withUUID:UUID];
            [self.tasks setObject:task forKey:key];
        
            NSAssert(taskClass == [task class], @"Task class should be the same!");
        [self unlock];
        
        if (taskExisted == NO) {
            [self.concurrentOperationQueue scheduleOperation:^
             {
                 [self objectForKey:key options:options completion:^(BOOL found, BOOL valid, PI_NImage *image, id alternativeRepresentation) {
                     if (found) {
                         if (valid) {
                             [self callCompletionsWithKey:key image:image alternativeRepresentation:alternativeRepresentation cached:YES response:nil error:nil finalized:YES];
                         } else {
                             //Remove completion and try again
                             [self lock];
                                 PI_NRemoteImageTask *task = [self.tasks objectForKey:key];
                                 [task removeCallbackWithUUID:UUID];
                                 if (task.callbackBlocks.count == 0) {
                                     [self.tasks removeObjectForKey:key];
                                 }
                             [self unlock];
                             
                             //Skip early check
                             [self downloadImageWithURL:url
                                                options:options | PI_NRemoteImageManagerDownloadOptionsSkipEarlyCheck
                                               priority:priority
                                           processorKey:processorKey
                                              processor:processor
                                          progressImage:(PI_NRemoteImageManagerImageCompletion)progressImage
                                       progressDownload:nil
                                             completion:completion
                                              inputUUID:UUID];
                         }
                     } else {
                         if ([taskClass isSubclassOfClass:[PI_NRemoteImageProcessorTask class]]) {
                             //continue processing
                             [self downloadImageWithURL:url
                                                options:options
                                               priority:priority
                                                    key:key
                                              processor:processor
                                                   UUID:UUID];
                         } else if ([taskClass isSubclassOfClass:[PI_NRemoteImageDownloadTask class]]) {
                             //continue downloading
                             [self downloadImageWithURL:url
                                                options:options
                                               priority:priority
                                                    key:key
                                          progressImage:progressImage
                                                   UUID:UUID];
                         }
                     }
                 }];
             } withPriority:operationPriorityWithImageManagerPriority(priority)];
        }
    } withPriority:operationPriorityWithImageManagerPriority(priority)];
    
    return UUID;
}

- (void)downloadImageWithURL:(NSURL *)url
                     options:(PI_NRemoteImageManagerDownloadOptions)options
                    priority:(PI_NRemoteImageManagerPriority)priority
                         key:(NSString *)key
                   processor:(PI_NRemoteImageManagerImageProcessor)processor
                        UUID:(NSUUID *)UUID
{
    PI_NRemoteImageProcessorTask *task = nil;
    [self lock];
        task = [self.tasks objectForKey:key];
        //check processing task still exists and download hasn't been started for another task
        if (task == nil || task.downloadTaskUUID != nil) {
            [self unlock];
            return;
        }
        
        __weak typeof(self) weakSelf = self;
        NSUUID *downloadTaskUUID = [self downloadImageWithURL:url
                                                      options:options | PI_NRemoteImageManagerDownloadOptionsSkipEarlyCheck
                                                   completion:^(PI_NRemoteImageManagerResult *result)
        {
            typeof(self) strongSelf = weakSelf;
            NSUInteger processCost = 0;
            NSError *error = result.error;
            PI_NRemoteImageProcessorTask *task = nil;
            [strongSelf lock];
                task = [strongSelf.tasks objectForKey:key];
            [strongSelf unlock];
            //check processing task still exists
            if (task == nil) {
                return;
            }
            if (result.image && error == nil) {
                //If completionBlocks.count == 0, we've canceled before we were even able to start.
                PI_NImage *image = processor(result, &processCost);
                
                if (image == nil) {
                    error = [NSError errorWithDomain:PI_NRemoteImageManagerErrorDomain
                                                code:PI_NRemoteImageManagerErrorFailedToProcessImage
                                            userInfo:nil];
                }
                [strongSelf callCompletionsWithKey:key image:image alternativeRepresentation:nil cached:NO response:result.response error:error finalized:NO];
              
                if (error == nil && image != nil) {
                    BOOL saveAsJPEG = (options & PI_NRemoteImageManagerSaveProcessedImageAsJPEG) != 0;
                    NSData *diskData = nil;
                    if (saveAsJPEG) {
                        diskData = PI_NImageJPEGRepresentation(image, 1.0);
                    } else {
                        diskData = PI_NImagePNGRepresentation(image);
                    }
                    
                    [strongSelf materializeAndCacheObject:image cacheInDisk:diskData additionalCost:processCost url:url key:key options:options outImage:nil outAltRep:nil];
                }
                
                [strongSelf callCompletionsWithKey:key image:image alternativeRepresentation:nil cached:NO response:result.response error:error finalized:YES];
            } else {
                if (error == nil) {
                    error = [NSError errorWithDomain:PI_NRemoteImageManagerErrorDomain
                                                code:PI_NRemoteImageManagerErrorFailedToFetchImageForProcessing
                                            userInfo:nil];
                }

                [strongSelf callCompletionsWithKey:key image:nil alternativeRepresentation:nil cached:NO response:result.response error:error finalized:YES];
            }
        }];
        task.downloadTaskUUID = downloadTaskUUID;
    [self unlock];
}

- (void)downloadImageWithURL:(NSURL *)url
                     options:(PI_NRemoteImageManagerDownloadOptions)options
                    priority:(PI_NRemoteImageManagerPriority)priority
                         key:(NSString *)key
               progressImage:(PI_NRemoteImageManagerImageCompletion)progressImage
                        UUID:(NSUUID *)UUID
{
    PI_NResume *resume = nil;
    if ((options & PI_NRemoteImageManagerDownloadOptionsIgnoreCache) == NO) {
        NSString *resumeKey = [self resumeCacheKeyForURL:url];
        resume = [self.cache objectFromDiskForKey:resumeKey];
        [self.cache removeObjectForKey:resumeKey completion:nil];
    }
    
    [self lock];
        PI_NRemoteImageDownloadTask *task = [self.tasks objectForKey:key];
    [self unlock];
    
    [task scheduleDownloadWithRequest:[self requestWithURL:url key:key]
                               resume:resume
                            skipRetry:(options & PI_NRemoteImageManagerDownloadOptionsSkipRetry)
                             priority:priority
                    completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
    {
        [self->_concurrentOperationQueue scheduleOperation:^
        {
            NSError *remoteImageError = error;
            PI_NImage *image = nil;
            id alternativeRepresentation = nil;
             
            if (remoteImageError == nil) {
                 //stores the object in the caches
                 [self materializeAndCacheObject:data cacheInDisk:data additionalCost:0 url:url key:key options:options outImage:&image outAltRep:&alternativeRepresentation];
             }

             if (error == nil && image == nil && alternativeRepresentation == nil) {
                 remoteImageError = [NSError errorWithDomain:PI_NRemoteImageManagerErrorDomain
                                                        code:PI_NRemoteImageManagerErrorFailedToDecodeImage
                                                    userInfo:nil];
             }

            [self callCompletionsWithKey:key image:image alternativeRepresentation:alternativeRepresentation cached:NO response:response error:remoteImageError finalized:YES];
         } withPriority:operationPriorityWithImageManagerPriority(priority)];
    }];
}

-(BOOL)insertImageDataIntoCache:(nonnull NSData*)data
                        withURL:(nonnull NSURL *)url
                   processorKey:(nullable NSString *)processorKey
                 additionalCost:(NSUInteger)additionalCost
{
  
  if (url != nil) {
    NSString *key = [self cacheKeyForURL:url processorKey:processorKey];
    
    PI_NRemoteImageManagerDownloadOptions options = PI_NRemoteImageManagerDownloadOptionsSkipDecode | PI_NRemoteImageManagerDownloadOptionsSkipEarlyCheck;
    PI_NRemoteImageMemoryContainer *container = [[PI_NRemoteImageMemoryContainer alloc] init];
    container.data = data;
    
    return [self materializeAndCacheObject:container cacheInDisk:data additionalCost:additionalCost url:url key:key options:options outImage: nil outAltRep: nil];
  }
  
  return NO;
}

- (BOOL)earlyReturnWithOptions:(PI_NRemoteImageManagerDownloadOptions)options url:(NSURL *)url key:(NSString *)key object:(id)object completion:(PI_NRemoteImageManagerImageCompletion)completion
{
    PI_NImage *image = nil;
    id alternativeRepresentation = nil;
    PI_NRemoteImageResultType resultType = PI_NRemoteImageResultTypeNone;

    BOOL allowEarlyReturn = !(PI_NRemoteImageManagerDownloadOptionsSkipEarlyCheck & options);

    if (url != nil && object != nil) {
        resultType = PI_NRemoteImageResultTypeMemoryCache;
        [self materializeAndCacheObject:object url:url key:key options:options outImage:&image outAltRep:&alternativeRepresentation];
    }
    
    if (completion && ((image || alternativeRepresentation) || (url == nil))) {
        //If we're on the main thread, special case to call completion immediately
        NSError *error = nil;
        if (!url) {
            error = [NSError errorWithDomain:NSURLErrorDomain
                                        code:NSURLErrorUnsupportedURL
                                    userInfo:@{ NSLocalizedDescriptionKey : @"unsupported URL" }];
        }
        PI_NRemoteImageManagerResult *result = [PI_NRemoteImageManagerResult imageResultWithImage:image
                                                                      alternativeRepresentation:alternativeRepresentation
                                                                                  requestLength:0
                                                                                     resultType:resultType
                                                                                           UUID:nil
                                                                                       response:nil
                                                                                          error:error];
        if (allowEarlyReturn && [NSThread isMainThread]) {
            completion(result);
        } else {
            dispatch_async(self.callbackQueue, ^{
                completion(result);
            });
        }
        return YES;
    }
    return NO;
}

- (NSURLRequest *)requestWithURL:(NSURL *)url key:(NSString *)key
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url
                                                           cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                       timeoutInterval:_sessionConfiguration.timeoutIntervalForRequest];
    
    NSMutableDictionary *headers = [self.httpHeaderFields mutableCopy];
    
    if (headers.count > 0) {
        request.allHTTPHeaderFields = headers;
    }
    
    if (_requestConfigurationHandler) {
        request = [_requestConfigurationHandler(request) mutableCopy];
    }
    
    [NSURLProtocol setProperty:key forKey:PI_NRemoteImageCacheKey inRequest:request];
    
    return request;
}

- (void)callCompletionsWithKey:(NSString *)key
                         image:(PI_NImage *)image
     alternativeRepresentation:(id)alternativeRepresentation
                        cached:(BOOL)cached
                      response:(NSURLResponse *)response
                         error:(NSError *)error
                     finalized:(BOOL)finalized
{
    [self lock];
        PI_NRemoteImageDownloadTask *task = [self.tasks objectForKey:key];
        [task callCompletionsWithImage:image alternativeRepresentation:alternativeRepresentation cached:cached response:response error:error remove:!finalized];
        if (finalized) {
            [self.tasks removeObjectForKey:key];
        }
    [self unlock];
}

#pragma mark - Prefetching

- (NSArray<NSUUID *> *)prefetchImagesWithURLs:(NSArray <NSURL *> *)urls
{
    return [self prefetchImagesWithURLs:urls options:PI_NRemoteImageManagerDownloadOptionsNone | PI_NRemoteImageManagerDownloadOptionsSkipEarlyCheck];
}

- (NSArray<NSUUID *> *)prefetchImagesWithURLs:(NSArray <NSURL *> *)urls options:(PI_NRemoteImageManagerDownloadOptions)options
{
    NSMutableArray *tasks = [NSMutableArray arrayWithCapacity:urls.count];
    for (NSURL *url in urls) {
        NSUUID *task = [self prefetchImageWithURL:url options:options];
        if (task != nil) {
            [tasks addObject:task];
        }
    }
    return tasks;
}

- (NSUUID *)prefetchImageWithURL:(NSURL *)url
{
    return [self prefetchImageWithURL:url options:PI_NRemoteImageManagerDownloadOptionsNone | PI_NRemoteImageManagerDownloadOptionsSkipEarlyCheck];
}

- (NSUUID *)prefetchImageWithURL:(NSURL *)url options:(PI_NRemoteImageManagerDownloadOptions)options
{
    return [self downloadImageWithURL:url
                              options:options
                             priority:PI_NRemoteImageManagerPriorityLow
                         processorKey:nil
                            processor:nil
                        progressImage:nil
                     progressDownload:nil
                           completion:nil
                            inputUUID:nil];
}

#pragma mark - Cancelation & Priority

- (void)cancelTaskWithUUID:(NSUUID *)UUID
{
    [self cancelTaskWithUUID:UUID storeResumeData:NO];
}

- (void)cancelTaskWithUUID:(nonnull NSUUID *)UUID storeResumeData:(BOOL)storeResumeData
{
    if (UUID == nil) {
        return;
    }
    PI_NLog(@"Attempting to cancel UUID: %@", UUID);
    [_concurrentOperationQueue scheduleOperation:^{
        PI_NResume *resume = nil;
        [self lock];
            NSString *taskKey = nil;
            PI_NRemoteImageTask *taskToEvaluate = [self _locked_taskForUUID:UUID key:&taskKey];
            
            if (taskToEvaluate == nil) {
                //maybe task hasn't been added to task list yet, add it to canceled tasks.
                //there's no need to ever remove a UUID from canceledTasks because it is weak.
                [self.canceledTasks addObject:UUID];
            }
            
            if ([taskToEvaluate cancelWithUUID:UUID resume:storeResumeData ? &resume : NULL]) {
                [self.tasks removeObjectForKey:taskKey];
            }
        [self unlock];
        
        if (resume) {
            //store resume data away, only download tasks currently return resume data
            [self storeResumeData:resume forURL:[(PI_NRemoteImageDownloadTask *)taskToEvaluate URL]];
        }
    } withPriority:PI_NOperationQueuePriorityHigh];
}

- (void)setPriority:(PI_NRemoteImageManagerPriority)priority ofTaskWithUUID:(NSUUID *)UUID
{
    if (UUID == nil) {
        return;
    }
    PI_NLog(@"Setting priority of UUID: %@ priority: %lu", UUID, (unsigned long)priority);
    [_concurrentOperationQueue scheduleOperation:^{
        [self lock];
            PI_NRemoteImageTask *task = [self _locked_taskForUUID:UUID key:NULL];
            [task setPriority:priority];
        [self unlock];
    } withPriority:PI_NOperationQueuePriorityHigh];
}

- (void)setProgressImageCallback:(nullable PI_NRemoteImageManagerImageCompletion)progressImageCallback ofTaskWithUUID:(nonnull NSUUID *)UUID
{
    if (UUID == nil) {
        return;
    }
    
    PI_NLog(@"setting progress block of UUID: %@ progressBlock: %@", UUID, progressImageCallback);
    [_concurrentOperationQueue scheduleOperation:^{
        [self lock];
            PI_NRemoteImageTask *task = [self _locked_taskForUUID:UUID key:NULL];
            if ([task isKindOfClass:[PI_NRemoteImageDownloadTask class]]) {
                PI_NRemoteImageCallbacks *callbacks = task.callbackBlocks[UUID];
                callbacks.progressImageBlock = progressImageCallback;
            }
        [self unlock];
    } withPriority:PI_NOperationQueuePriorityHigh];
}

- (void)setRetryStrategyCreationBlock:(id<PI_NRequestRetryStrategy> (^)(void))retryStrategyCreationBlock {
    [_concurrentOperationQueue scheduleOperation:^{
        [self lock];
            self->_retryStrategyCreationBlock = retryStrategyCreationBlock;
        [self unlock];
    } withPriority:PI_NOperationQueuePriorityHigh];
}

#pragma mark - Caching

- (void)imageFromCacheWithCacheKey:(NSString *)cacheKey
                        completion:(PI_NRemoteImageManagerImageCompletion)completion
{
    [self imageFromCacheWithCacheKey:cacheKey options:PI_NRemoteImageManagerDownloadOptionsNone completion:completion];
}

- (void)imageFromCacheWithCacheKey:(NSString *)cacheKey
                           options:(PI_NRemoteImageManagerDownloadOptions)options
                        completion:(PI_NRemoteImageManagerImageCompletion)completion
{
    [self imageFromCacheWithURL:nil processorKey:nil cacheKey:cacheKey options:options completion:completion];
}

- (void)imageFromCacheWithURL:(nonnull NSURL *)url
                 processorKey:(nullable NSString *)processorKey
                      options:(PI_NRemoteImageManagerDownloadOptions)options
                   completion:(nonnull PI_NRemoteImageManagerImageCompletion)completion
{
    [self imageFromCacheWithURL:url processorKey:processorKey cacheKey:nil options:options completion:completion];
}

- (void)imageFromCacheWithURL:(NSURL *)url
                 processorKey:(NSString *)processorKey
                     cacheKey:(NSString *)cacheKey
                      options:(PI_NRemoteImageManagerDownloadOptions)options
                   completion:(PI_NRemoteImageManagerImageCompletion)completion
{
    CFTimeInterval requestTime = CACurrentMediaTime();
    
    if ((PI_NRemoteImageManagerDownloadOptionsSkipEarlyCheck & options) == NO && [NSThread isMainThread]) {
        PI_NRemoteImageManagerResult *result = [self synchronousImageFromCacheWithURL:url processorKey:processorKey cacheKey:cacheKey options:options];
        if (result.image && result.error == nil) {
            completion((result));
            return;
        }
    }
    
    [self objectForURL:url processorKey:processorKey key:cacheKey options:options completion:^(BOOL found, BOOL valid, PI_NImage *image, id alternativeRepresentation) {
        NSError *error = nil;
        if (valid == NO) {
            error = [NSError errorWithDomain:PI_NRemoteImageManagerErrorDomain
                                        code:PI_NRemoteImageManagerErrorInvalidItemInCache
                                    userInfo:nil];
        }
        
        dispatch_async(self.callbackQueue, ^{
            completion([PI_NRemoteImageManagerResult imageResultWithImage:image
                                               alternativeRepresentation:alternativeRepresentation
                                                           requestLength:CACurrentMediaTime() - requestTime
                                                              resultType:PI_NRemoteImageResultTypeCache
                                                                    UUID:nil
                                                                response:nil
                                                                   error:error]);
        });
    }];
}

- (PI_NRemoteImageManagerResult *)synchronousImageFromCacheWithCacheKey:(NSString *)cacheKey options:(PI_NRemoteImageManagerDownloadOptions)options
{
    return [self synchronousImageFromCacheWithURL:nil processorKey:nil cacheKey:cacheKey options:options];
}

- (nonnull PI_NRemoteImageManagerResult *)synchronousImageFromCacheWithURL:(NSURL *)url processorKey:(nullable NSString *)processorKey options:(PI_NRemoteImageManagerDownloadOptions)options
{
    return [self synchronousImageFromCacheWithURL:url processorKey:processorKey cacheKey:nil options:options];
}

- (PI_NRemoteImageManagerResult *)synchronousImageFromCacheWithURL:(NSURL *)url processorKey:(NSString *)processorKey cacheKey:(NSString *)cacheKey options:(PI_NRemoteImageManagerDownloadOptions)options
{
    CFTimeInterval requestTime = CACurrentMediaTime();
  
    if (cacheKey == nil && url == nil) {
        return nil;
    }
  
    cacheKey = cacheKey ?: [self cacheKeyForURL:url processorKey:processorKey];
    
    id object = [self.cache objectFromMemoryForKey:cacheKey];
    PI_NImage *image;
    id alternativeRepresentation;
    NSError *error = nil;
    if (object == nil) {
        image = nil;
        alternativeRepresentation = nil;
    } else if ([self materializeAndCacheObject:object url:url key:cacheKey options:options outImage:&image outAltRep:&alternativeRepresentation] == NO) {
        error = [NSError errorWithDomain:PI_NRemoteImageManagerErrorDomain
                                    code:PI_NRemoteImageManagerErrorInvalidItemInCache
                                userInfo:nil];
    }
    
    return [PI_NRemoteImageManagerResult imageResultWithImage:image
                                   alternativeRepresentation:alternativeRepresentation
                                               requestLength:CACurrentMediaTime() - requestTime
                                                  resultType:PI_NRemoteImageResultTypeMemoryCache
                                                        UUID:nil
                                                    response:nil
                                                       error:error];
}

#pragma mark - Session Task Blocks

- (void)didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge forTask:(NSURLSessionTask *)dataTask completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler {
    [self lock];
        if (self.authenticationChallengeHandler) {
            self.authenticationChallengeHandler(dataTask, challenge, completionHandler);
        } else {
            completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
        }
    [self unlock];
}

- (void)didReceiveResponse:(nonnull NSURLResponse *)response forTask:(nonnull NSURLSessionTask *)dataTask
{
    [self lock];
        NSString *cacheKey = [NSURLProtocol propertyForKey:PI_NRemoteImageCacheKey inRequest:dataTask.originalRequest];
        PI_NRemoteImageDownloadTask *task = [self.tasks objectForKey:cacheKey];
    [self unlock];
    [task didReceiveResponse:response];
}

- (void)didReceiveData:(NSData *)data forTask:(NSURLSessionTask *)dataTask
{
    [self lock];
        NSString *cacheKey = [NSURLProtocol propertyForKey:PI_NRemoteImageCacheKey inRequest:dataTask.originalRequest];
        PI_NRemoteImageDownloadTask *task = [self.tasks objectForKey:cacheKey];
    [self unlock];
    [task didReceiveData:data];
}

#pragma mark - QOS

- (NSUUID *)downloadImageWithURLs:(NSArray <NSURL *> *)urls
                          options:(PI_NRemoteImageManagerDownloadOptions)options
                    progressImage:(PI_NRemoteImageManagerImageCompletion)progressImage
                       completion:(PI_NRemoteImageManagerImageCompletion)completion
{
    return [self downloadImageWithURLs:urls
                               options:options
                         progressImage:progressImage
                      progressDownload:nil
                            completion:completion];
}

- (nullable NSUUID *)downloadImageWithURLs:(nonnull NSArray <NSURL *> *)urls
                                   options:(PI_NRemoteImageManagerDownloadOptions)options
                             progressImage:(nullable PI_NRemoteImageManagerImageCompletion)progressImage
                          progressDownload:(nullable PI_NRemoteImageManagerProgressDownload)progressDownload
                                completion:(nullable PI_NRemoteImageManagerImageCompletion)completion
{
    NSUUID *UUID = [NSUUID UUID];
    if (urls.count <= 1) {
        NSURL *url = [urls firstObject];
        [self downloadImageWithURL:url
                           options:options
                          priority:PI_NRemoteImageManagerPriorityDefault
                      processorKey:nil
                         processor:nil
                     progressImage:progressImage
                  progressDownload:progressDownload
                        completion:completion
                         inputUUID:UUID];
        return UUID;
    }
    
    [self.concurrentOperationQueue scheduleOperation:^{
        __block NSInteger highestQualityDownloadedIdx = -1;
        
        //check for the highest quality image already in cache. It's possible that an image is in the process of being
        //cached when this is being run. In which case two things could happen:
        // -    If network conditions dictate that a lower quality image should be downloaded than the one that is currently
        //      being cached, it will be downloaded in addition. This is not ideal behavior, worst case scenario and unlikely.
        // -    If network conditions dictate that the same quality image should be downloaded as the one being cached, no
        //      new image will be downloaded as either the caching will have finished by the time we actually request it or
        //      the task will still exist and our callback will be attached. In this case, no detrimental behavior will have
        //      occurred.
        [urls enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSURL *url, NSUInteger idx, BOOL *stop) {
            NSAssert([url isKindOfClass:[NSURL class]], @"url must be of type URL");
            NSString *cacheKey = [self cacheKeyForURL:url processorKey:nil];
            
            //we don't actually need the object, just need to know it exists so that we can request it later
            BOOL hasObject = [self.cache objectExistsForKey:cacheKey];
            
            if (hasObject) {
                highestQualityDownloadedIdx = idx;
                *stop = YES;
            }
        }];
        
        [self lock];
            float highQualityQPSThreshold = [self highQualityBPSThreshold];
            float lowQualityQPSThreshold = [self lowQualityBPSThreshold];
            BOOL shouldUpgradeLowQualityImages = [self shouldUpgradeLowQualityImages];
        [self unlock];
        
        NSUInteger desiredImageURLIdx = [PI_NSpeedRecorder appropriateImageIdxForURLsGivenHistoricalNetworkConditions:urls
                                                                                              lowQualityQPSThreshold:lowQualityQPSThreshold
                                                                                             highQualityQPSThreshold:highQualityQPSThreshold];
        
        NSUInteger downloadIdx;
        //if the highest quality already downloaded is less than what currentBPS would dictate and shouldUpgrade is
        //set, download the new higher quality image. If no image has been cached, download the image dictated by
        //current bps
        
        if ((highestQualityDownloadedIdx < desiredImageURLIdx && shouldUpgradeLowQualityImages) || highestQualityDownloadedIdx == -1) {
            downloadIdx = desiredImageURLIdx;
        } else {
            downloadIdx = highestQualityDownloadedIdx;
        }
        
        NSURL *downloadURL = [urls objectAtIndex:downloadIdx];
        
        [self downloadImageWithURL:downloadURL
                                 options:options
                                priority:PI_NRemoteImageManagerPriorityDefault
                            processorKey:nil
                               processor:nil
                           progressImage:progressImage
                        progressDownload:progressDownload
                              completion:^(PI_NRemoteImageManagerResult *result) {
                                  //clean out any lower quality images from the cache
                                  for (NSInteger idx = downloadIdx - 1; idx >= 0; idx--) {
                                      [[self cache] removeObjectForKey:[self cacheKeyForURL:[urls objectAtIndex:idx] processorKey:nil]];
                                  }
                                  
                                  if (completion) {
                                      completion(result);
                                  }
                              }
                               inputUUID:UUID];
    } withPriority:PI_NOperationQueuePriorityDefault];
    return UUID;
}

#pragma mark - Caching

- (BOOL)materializeAndCacheObject:(id)object
                              url:(NSURL *)url
                              key:(NSString *)key
                          options:(PI_NRemoteImageManagerDownloadOptions)options
                         outImage:(PI_NImage **)outImage
                        outAltRep:(id *)outAlternateRepresentation
{
    return [self materializeAndCacheObject:object cacheInDisk:nil additionalCost:0 url:url key:key options:options outImage:outImage outAltRep:outAlternateRepresentation];
}

//takes the object from the cache and returns an image or animated image.
//if it's a non-alternative representation and skipDecode is not set it also decompresses the image.
- (BOOL)materializeAndCacheObject:(id)object
                      cacheInDisk:(NSData *)diskData
                   additionalCost:(NSUInteger)additionalCost
                              url:(NSURL *)url
                              key:(NSString *)key
                          options:(PI_NRemoteImageManagerDownloadOptions)options
                         outImage:(PI_NImage **)outImage
                        outAltRep:(id *)outAlternateRepresentation
{
    NSAssert(object != nil, @"Object should not be nil.");
    if (object == nil) {
        return NO;
    }
    BOOL alternateRepresentationsAllowed = (PI_NRemoteImageManagerDisallowAlternateRepresentations & options) == 0;
    BOOL skipDecode = (options & PI_NRemoteImageManagerDownloadOptionsSkipDecode) != 0;
    __block id alternateRepresentation = nil;
    __block PI_NImage *image = nil;
    __block NSData *data = nil;
    __block BOOL updateMemoryCache = NO;
    
    PI_NRemoteImageMemoryContainer *container = nil;
    if ([object isKindOfClass:[PI_NRemoteImageMemoryContainer class]]) {
        container = (PI_NRemoteImageMemoryContainer *)object;
        [container.lock lockWithBlock:^{
            data = container.data;
        }];
    } else {
        updateMemoryCache = YES;
        
        // don't need to lock the container here because we just init it.
        container = [[PI_NRemoteImageMemoryContainer alloc] init];
        
        if ([object isKindOfClass:[PI_NImage class]]) {
            data = diskData;
            container.image = (PI_NImage *)object;
        } else if ([object isKindOfClass:[NSData class]]) {
            data = (NSData *)object;
        } else {
            //invalid item in cache
            updateMemoryCache = NO;
            data = nil;
            container = nil;
        }
        
        container.data = data;
    }
    
    if (alternateRepresentationsAllowed) {
        alternateRepresentation = [_alternateRepProvider alternateRepresentationWithData:data options:options];
    }
    
    if (alternateRepresentation == nil) {
        //we need the image
        [container.lock lockWithBlock:^{
            image = container.image;
        }];
        if (image == nil && container.data) {
            image = [PI_NImage pin_decodedImageWithData:container.data skipDecodeIfPossible:skipDecode];
            
            if (url != nil) {
                image = [PI_NImage pin_scaledImageForImage:image withKey:key];
            }
            
            if (skipDecode == NO) {
                [container.lock lockWithBlock:^{
                    updateMemoryCache = YES;
                    container.image = image;
                }];
            }
        }
    }
    
    if (updateMemoryCache) {
        [container.lock lockWithBlock:^{
            NSUInteger cacheCost = additionalCost;
            cacheCost += [container.data length];
            CGImageRef imageRef = container.image.CGImage;
            NSAssert(container.image == nil || imageRef != NULL, @"We only cache a decompressed image if we decompressed it ourselves. In that case, it should be backed by a CGImageRef.");
            if (imageRef) {
                cacheCost += CGImageGetHeight(imageRef) * CGImageGetBytesPerRow(imageRef);
            }
            [self.cache setObjectInMemory:container forKey:key withCost:cacheCost];
        }];
    }
    
    if (diskData) {
        [self.cache setObjectOnDisk:diskData forKey:key];
    }
    
    if (outImage) {
        *outImage = image;
    }
    
    if (outAlternateRepresentation) {
        *outAlternateRepresentation = alternateRepresentation;
    }
    
    if (image == nil && alternateRepresentation == nil) {
        PI_NLog(@"Invalid item in cache");
        [self.cache removeObjectForKey:key completion:nil];
        return NO;
    }
    return YES;
}

- (NSString *)cacheKeyForURL:(NSURL *)url processorKey:(NSString *)processorKey
{
    return [self cacheKeyForURL:url processorKey:processorKey resume:NO];
}

- (NSString *)cacheKeyForURL:(NSURL *)url processorKey:(NSString *)processorKey resume:(BOOL)resume
{
    NSString *cacheKey = [url absoluteString];
    NSAssert((processorKey.length == 0 && resume == YES) || resume == NO, @"It doesn't make sense to use resume with processing.");
    if (processorKey.length > 0) {
        cacheKey = [cacheKey stringByAppendingFormat:@"-<%@>", processorKey];
    }

    //PI_NDiskCache uses this key as the filename of the file written to disk
    //Due to the current filesystem used in Darwin, this name must be limited to 255 chars.
    //In case the generated key exceeds PI_NRemoteImageManagerCacheKeyMaxLength characters,
    //we return the hash of it instead.
    if (cacheKey.length > PI_NRemoteImageManagerCacheKeyMaxLength) {
        __block CC_MD5_CTX ctx;
        CC_MD5_Init(&ctx);
        NSData *data = [cacheKey dataUsingEncoding:NSUTF8StringEncoding];
        [data enumerateByteRangesUsingBlock:^(const void * _Nonnull bytes, NSRange byteRange, BOOL * _Nonnull stop) {
            CC_MD5_Update(&ctx, bytes, (CC_LONG)byteRange.length);
        }];

        unsigned char digest[CC_MD5_DIGEST_LENGTH];
        CC_MD5_Final(digest, &ctx);

        NSMutableString *hexString  = [NSMutableString stringWithCapacity:(CC_MD5_DIGEST_LENGTH * 2)];
        for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
            [hexString appendFormat:@"%02lx", (unsigned long)digest[i]];
        }
        cacheKey = [hexString copy];
    }
    //The resume key must not be hashed, it is used to decide whether or not to decode from the disk cache.
    if (resume) {
      cacheKey = [PI_NRemoteImageCacheKeyResumePrefix stringByAppendingString:cacheKey];
    }

    return cacheKey;
}

- (void)objectForKey:(NSString *)key options:(PI_NRemoteImageManagerDownloadOptions)options completion:(void (^)(BOOL found, BOOL valid, PI_NImage *image, id alternativeRepresentation))completion
{
    return [self objectForURL:nil processorKey:nil key:key options:options completion:completion];
}

- (void)objectForURL:(NSURL *)url processorKey:(NSString *)processorKey key:(NSString *)key options:(PI_NRemoteImageManagerDownloadOptions)options completion:(void (^)(BOOL found, BOOL valid, PI_NImage *image, id alternativeRepresentation))completion
{
    if ((options & PI_NRemoteImageManagerDownloadOptionsIgnoreCache) != 0) {
        completion(NO, YES, nil, nil);
        return;
    }
  
    if (key == nil && url == nil) {
        completion(NO, YES, nil, nil);
        return;
    }
  
    key = key ?: [self cacheKeyForURL:url processorKey:processorKey];

    void (^materialize)(id object) = ^(id object) {
        PI_NImage *image = nil;
        id alternativeRepresentation = nil;
        BOOL valid = [self materializeAndCacheObject:object
                                                 url:nil
                                                 key:key
                                             options:options
                                            outImage:&image
                                           outAltRep:&alternativeRepresentation];
        
        completion(YES, valid, image, alternativeRepresentation);
    };
    
    PI_NRemoteImageMemoryContainer *container = [self.cache objectFromMemoryForKey:key];
    if (container) {
        materialize(container);
    } else {
        [self.cache objectFromDiskForKey:key completion:^(id<PI_NRemoteImageCaching> _Nonnull cache,
                                                         NSString *_Nonnull key,
                                                         id _Nullable object) {
          if (object) {
              materialize(object);
          } else {
              completion(NO, YES, nil, nil);
          }
        }];
    }
}

#pragma mark - Resume support

- (NSString *)resumeCacheKeyForURL:(NSURL *)url
{
    return [self cacheKeyForURL:url processorKey:nil resume:YES];
}

- (void)storeResumeData:(PI_NResume *)resume forURL:(NSURL *)URL
{
    NSString *resumeKey = [self resumeCacheKeyForURL:URL];
    [self.cache setObjectOnDisk:resume forKey:resumeKey];
}

/// Attempt to find the task with the callbacks for the given uuid
- (nullable PI_NRemoteImageTask *)_locked_taskForUUID:(NSUUID *)uuid key:(NSString * __strong *)outKey
{
    __block PI_NRemoteImageTask *result = nil;
    __block NSString *strongKey = nil;

    [self.tasks enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, __kindof PI_NRemoteImageTask * _Nonnull task, BOOL * _Nonnull stop) {
        // If this isn't our task, just return.
        if (task.callbackBlocks[uuid] == nil) {
            return;
        }

        // Found it! Save our results and end enumeration
        result = task;
        strongKey = key;
        *stop = YES;
    }];
    
    if (outKey != nil) {
        *outKey = strongKey;
    }
    return result;
}

#if DEBUG
- (NSUInteger)totalDownloads
{
    //hack to avoid main thread assertion since these are only used in testing
    [_lock lock];
        NSUInteger totalDownloads = _totalDownloads;
    [_lock unlock];
    return totalDownloads;
}
#endif

@end

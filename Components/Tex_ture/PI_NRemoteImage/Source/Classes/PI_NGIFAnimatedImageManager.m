//
//  PI_NGIFAnimatedImageManager.m
//  Pods
//
//  Created by Garrett Moon on 4/5/16.
//
//

#import "PI_NGIFAnimatedImageManager.h"

#import <ImageIO/ImageIO.h>
#if PI_N_TARGET_IOS
#import <MobileCoreServices/UTCoreTypes.h>
#elif PI_N_TARGET_MAC
#import <CoreServices/CoreServices.h>
#endif

#import "PI_NRemoteLock.h"

static const NSUInteger maxFileSize = 50000000; //max file size in bytes
static const Float32 maxFileDuration = 1; //max duration of a file in seconds
static const NSUInteger kCleanupAfterStartupDelay = 10; //clean up files after 10 seconds if it hasn't been done.

typedef void(^PI_NAnimatedImageInfoProcessed)(PI_NImage *coverImage, NSUUID *UUID, Float32 *durations, CFTimeInterval totalDuration, size_t loopCount, size_t frameCount, UInt32 width, UInt32 height, size_t bitsPerPixel, UInt32 bitmapInfo);

static BOOL PI_NStatusCoverImageCompleted(PI_NAnimatedImageStatus status);
BOOL PI_NStatusCoverImageCompleted(PI_NAnimatedImageStatus status) {
  return status == PI_NAnimatedImageStatusInfoProcessed || status == PI_NAnimatedImageStatusFirstFileProcessed || status == PI_NAnimatedImageStatusProcessed;
}

typedef NS_ENUM(NSUInteger, PI_NAnimatedImageManagerCondition) {
  PI_NAnimatedImageManagerConditionNotReady = 0,
  PI_NAnimatedImageManagerConditionReady = 1,
};

@interface PI_NGIFAnimatedImageManager ()
{
  NSConditionLock *_lock;
}

+ (instancetype)sharedManager;

@property (nonatomic, strong, readonly) NSMapTable <NSData *, PI_NSharedAnimatedImage *> *animatedImages;
@property (nonatomic, strong, readonly) dispatch_queue_t serialProcessingQueue;

@end

@implementation PI_NGIFAnimatedImageManager

+ (void)load
{
  if (self == [PI_NGIFAnimatedImageManager class]) {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kCleanupAfterStartupDelay * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      //This forces a cleanup of files
      [PI_NGIFAnimatedImageManager sharedManager];
    });
  }
}

+ (instancetype)sharedManager
{
  static dispatch_once_t onceToken;
  static PI_NGIFAnimatedImageManager *sharedManager;
  dispatch_once(&onceToken, ^{
    sharedManager = [[PI_NGIFAnimatedImageManager alloc] init];
  });
  return sharedManager;
}

+ (NSString *)temporaryDirectory
{
  static dispatch_once_t onceToken;
  static NSString *temporaryDirectory;
  dispatch_once(&onceToken, ^{
    //On iOS temp directories are not shared between apps. This may not be safe on OS X or other systems
    temporaryDirectory = [NSTemporaryDirectory() stringByAppendingPathComponent:@"A_SAnimatedImageCache"];
  });
  return temporaryDirectory;
}

- (instancetype)init
{
  if (self = [super init]) {
    _lock = [[NSConditionLock alloc] initWithCondition:PI_NAnimatedImageManagerConditionNotReady];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      [self->_lock lockWhenCondition:PI_NAnimatedImageManagerConditionNotReady];
        [PI_NGIFAnimatedImageManager cleanupFiles];
        if ([[NSFileManager defaultManager] fileExistsAtPath:[PI_NGIFAnimatedImageManager temporaryDirectory]] == NO) {
          [[NSFileManager defaultManager] createDirectoryAtPath:[PI_NGIFAnimatedImageManager temporaryDirectory] withIntermediateDirectories:YES attributes:nil error:nil];
        }
      [self->_lock unlockWithCondition:PI_NAnimatedImageManagerConditionReady];
    });
    
    _animatedImages = [[NSMapTable alloc] initWithKeyOptions:NSMapTableWeakMemory valueOptions:NSMapTableWeakMemory capacity:1];
    _serialProcessingQueue = dispatch_queue_create("Serial animated image processing queue.", DISPATCH_QUEUE_SERIAL);
    
#if PI_N_TARGET_IOS
    NSString * const notificationName = UIApplicationWillTerminateNotification;
#elif PI_N_TARGET_MAC
    NSString * const notificationName = NSApplicationWillTerminateNotification;
#endif
    [[NSNotificationCenter defaultCenter] addObserverForName:notificationName
                                                      object:nil
                                                       queue:nil
                                                  usingBlock:^(NSNotification * _Nonnull note) {
                                                    [PI_NGIFAnimatedImageManager cleanupFiles];
                                                  }];
  }
  return self;
}

+ (void)cleanupFiles
{
  [[NSFileManager defaultManager] removeItemAtPath:[PI_NGIFAnimatedImageManager temporaryDirectory] error:nil];
}

- (void)animatedPathForImageData:(NSData *)animatedImageData infoCompletion:(PI_NAnimatedImageSharedReady)infoCompletion completion:(PI_NAnimatedImageDecodedPath)completion
{
  __block BOOL startProcessing = NO;
  __block PI_NSharedAnimatedImage *sharedAnimatedImage = nil;
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    [self->_lock lockWhenCondition:PI_NAnimatedImageManagerConditionReady];
      sharedAnimatedImage = [self.animatedImages objectForKey:animatedImageData];
      if (sharedAnimatedImage == nil) {
        sharedAnimatedImage = [[PI_NSharedAnimatedImage alloc] init];
        [self.animatedImages setObject:sharedAnimatedImage forKey:animatedImageData];
        startProcessing = YES;
      }
      
      if (PI_NStatusCoverImageCompleted(sharedAnimatedImage.status)) {
        //Info is already processed, call infoCompletion immediately
        if (infoCompletion) {
          infoCompletion(sharedAnimatedImage.coverImage, sharedAnimatedImage);
        }
      } else {
        //Add infoCompletion to sharedAnimatedImage
        if (infoCompletion) {
          //Since A_SSharedAnimatedImages are stored weakly in our map, we need a strong reference in completions
          PI_NAnimatedImageSharedReady capturingInfoCompletion = ^(PI_NImage *coverImage, PI_NSharedAnimatedImage *newShared) {
            __unused PI_NSharedAnimatedImage *strongShared = sharedAnimatedImage;
            infoCompletion(coverImage, newShared);
          };
          sharedAnimatedImage.infoCompletions = [sharedAnimatedImage.infoCompletions arrayByAddingObject:capturingInfoCompletion];
        }
      }
      
      if (sharedAnimatedImage.status == PI_NAnimatedImageStatusProcessed) {
        //Animated image is already fully processed, call completion immediately
        if (completion) {
          completion(YES, nil, nil);
        }
      } else if (sharedAnimatedImage.status == PI_NAnimatedImageStatusError) {
        if (completion) {
          completion(NO, nil, sharedAnimatedImage.error);
        }
      } else {
        //Add completion to sharedAnimatedImage
        if (completion) {
          //Since PI_NSharedAnimatedImages are stored weakly in our map, we need a strong reference in completions
          PI_NAnimatedImageDecodedPath capturingCompletion = ^(BOOL finished, NSString *path, NSError *error) {
            __unused PI_NSharedAnimatedImage *strongShared = sharedAnimatedImage;
            completion(finished, path, error);
          };
          sharedAnimatedImage.completions = [sharedAnimatedImage.completions arrayByAddingObject:capturingCompletion];
        }
      }
    [self->_lock unlockWithCondition:PI_NAnimatedImageManagerConditionReady];
  
    if (startProcessing) {
      dispatch_async(self.serialProcessingQueue, ^{
        [[self class] processAnimatedImage:animatedImageData temporaryDirectory:[PI_NGIFAnimatedImageManager temporaryDirectory] infoCompletion:^(PI_NImage *coverImage, NSUUID *UUID, Float32 *durations, CFTimeInterval totalDuration, size_t loopCount, size_t frameCount, UInt32 width, UInt32 height, size_t bitsPerPixel, UInt32 bitmapInfo) {
          __block NSArray *infoCompletions = nil;
          __block PI_NSharedAnimatedImage *sharedAnimatedImage = nil;
          [self->_lock lockWhenCondition:PI_NAnimatedImageManagerConditionReady];
          sharedAnimatedImage = [self.animatedImages objectForKey:animatedImageData];
          [sharedAnimatedImage setInfoProcessedWithCoverImage:coverImage UUID:UUID durations:durations totalDuration:totalDuration loopCount:loopCount frameCount:frameCount width:width height:height bitsPerPixel:bitsPerPixel bitmapInfo:bitmapInfo];
          infoCompletions = sharedAnimatedImage.infoCompletions;
          sharedAnimatedImage.infoCompletions = @[];
          [self->_lock unlockWithCondition:PI_NAnimatedImageManagerConditionReady];
          
          for (PI_NAnimatedImageSharedReady infoCompletion in infoCompletions) {
            infoCompletion(coverImage, sharedAnimatedImage);
          }
        } decodedPath:^(BOOL finished, NSString *path, NSError *error) {
          __block NSArray *completions = nil;
          {
            [self->_lock lockWhenCondition:PI_NAnimatedImageManagerConditionReady];
            PI_NSharedAnimatedImage *sharedAnimatedImage = [self.animatedImages objectForKey:animatedImageData];
            
            if (path && error == nil) {
              sharedAnimatedImage.maps = [sharedAnimatedImage.maps arrayByAddingObject:[[PI_NSharedAnimatedImageFile alloc] initWithPath:path]];
            }
            sharedAnimatedImage.error = error;
            if (error) {
              sharedAnimatedImage.status = PI_NAnimatedImageStatusError;
            }
            
            completions = sharedAnimatedImage.completions;
            if (finished || error) {
              sharedAnimatedImage.completions = @[];
            }
            
            if (error == nil) {
              if (finished) {
                sharedAnimatedImage.status = PI_NAnimatedImageStatusProcessed;
              } else {
                sharedAnimatedImage.status = PI_NAnimatedImageStatusFirstFileProcessed;
              }
            }
            [self->_lock unlockWithCondition:PI_NAnimatedImageManagerConditionReady];
          }
          
          for (PI_NAnimatedImageDecodedPath completion in completions) {
            completion(finished, path, error);
          }
        }];
      });
    }
  });
}

#define HANDLE_PROCESSING_ERROR(ERROR) \
{ \
if (ERROR != nil) { \
  [errorLock lockWithBlock:^{ \
    if (processingError == nil) { \
      processingError = ERROR; \
    } \
  }]; \
\
[fileHandle closeFile]; \
[[NSFileManager defaultManager] removeItemAtPath:filePath error:nil]; \
} \
}

#define PROCESSING_ERROR \
({__block NSError *ERROR; \
[errorLock lockWithBlock:^{ \
  ERROR = processingError; \
}]; \
ERROR;}) \

+ (void)processAnimatedImage:(NSData *)animatedImageData
          temporaryDirectory:(NSString *)temporaryDirectory
              infoCompletion:(PI_NAnimatedImageInfoProcessed)infoCompletion
                 decodedPath:(PI_NAnimatedImageDecodedPath)completion
{
  NSUUID *UUID = [NSUUID UUID];
  __block NSError *processingError = nil;
  PI_NRemoteLock *errorLock = [[PI_NRemoteLock alloc] initWithName:@"animatedImage processing lock"];
  NSString *filePath = nil;
  //TODO Must handle file handle errors! Documentation says it throws exceptions on any errors :(
  NSError *fileHandleError = nil;
  NSFileHandle *fileHandle = [self fileHandle:&fileHandleError filePath:&filePath temporaryDirectory:temporaryDirectory UUID:UUID count:0];
  HANDLE_PROCESSING_ERROR(fileHandleError);
  UInt32 width;
  UInt32 height;
  UInt32 bitsPerPixel;
  UInt32 bitmapInfo;
  NSUInteger fileCount = 0;
  UInt32 frameCountForFile = 0;
  Float32 *durations = NULL;
  
#if PI_NMemMapAnimatedImageDebug
  CFTimeInterval start = CACurrentMediaTime();
#endif
  
  if (fileHandle && PROCESSING_ERROR == nil) {
    dispatch_queue_t diskWriteQueue = dispatch_queue_create("PI_NGIFAnimatedImage disk write queue", DISPATCH_QUEUE_SERIAL);
    dispatch_group_t diskGroup = dispatch_group_create();
    
    CGImageSourceRef imageSource = CGImageSourceCreateWithData((CFDataRef)animatedImageData,
                                                               (CFDictionaryRef)@{(__bridge NSString *)kCGImageSourceTypeIdentifierHint : (__bridge NSString *)kUTTypeGIF,
                                                                                  (__bridge NSString *)kCGImageSourceShouldCache : (__bridge NSNumber *)kCFBooleanFalse});
    
    if (imageSource) {
      UInt32 frameCount = (UInt32)CGImageSourceGetCount(imageSource);
      NSDictionary *imageProperties = (__bridge_transfer NSDictionary *)CGImageSourceCopyProperties(imageSource, nil);
      UInt32 loopCount = (UInt32)[[[imageProperties objectForKey:(__bridge NSString *)kCGImagePropertyGIFDictionary]
                                   objectForKey:(__bridge NSString *)kCGImagePropertyGIFLoopCount] unsignedLongValue];
      
      Float32 fileDuration = 0;
      NSUInteger fileSize = 0;
      durations = (Float32 *)malloc(sizeof(Float32) * frameCount);
      CFTimeInterval totalDuration = 0;
      PI_NImage *coverImage = nil;
      
      //Gather header file info
      for (NSUInteger frameIdx = 0; frameIdx < frameCount; frameIdx++) {
        if (frameIdx == 0) {
          CGImageRef frameImage = CGImageSourceCreateImageAtIndex(imageSource, frameIdx, (CFDictionaryRef)@{(__bridge NSString *)kCGImageSourceShouldCache : (__bridge NSNumber *)kCFBooleanFalse});
          if (frameImage == nil) {
            NSError *frameError = [NSError errorWithDomain:kPI_NAnimatedImageErrorDomain code:PI_NAnimatedImageErrorImageFrameError userInfo:nil];
            HANDLE_PROCESSING_ERROR(frameError);
            break;
          }
          
          bitmapInfo = CGImageGetBitmapInfo(frameImage);
          
          width = (UInt32)CGImageGetWidth(frameImage);
          height = (UInt32)CGImageGetHeight(frameImage);
          bitsPerPixel = (UInt32)CGImageGetBitsPerPixel(frameImage);
          
#if PI_N_TARGET_IOS
          coverImage = [UIImage imageWithCGImage:frameImage];
#elif PI_N_TARGET_MAC
          coverImage = [[NSImage alloc] initWithCGImage:frameImage size:CGSizeMake(width, height)];
#endif
          CGImageRelease(frameImage);
        }
        
        Float32 duration = [[self class] frameDurationAtIndex:frameIdx source:imageSource];
        durations[frameIdx] = duration;
        totalDuration += duration;
      }
      
      if (PROCESSING_ERROR == nil) {
        //Get size, write file header get coverImage
        dispatch_group_async(diskGroup, diskWriteQueue, ^{
          NSError *fileHeaderError = [self writeFileHeader:fileHandle width:width height:height bitsPerPixel:bitsPerPixel loopCount:loopCount frameCount:frameCount bitmapInfo:bitmapInfo durations:durations];
          HANDLE_PROCESSING_ERROR(fileHeaderError);
          if (fileHeaderError == nil) {
            [fileHandle closeFile];
            
            PI_NLog(@"notifying info");
            infoCompletion(coverImage, UUID, durations, totalDuration, loopCount, frameCount, width, height, bitsPerPixel, bitmapInfo);
          }
        });
        fileCount = 1;
        NSError *fileHandleError = nil;
        fileHandle = [self fileHandle:&fileHandleError filePath:&filePath temporaryDirectory:temporaryDirectory UUID:UUID count:fileCount];
        HANDLE_PROCESSING_ERROR(fileHandleError);
        
        dispatch_group_async(diskGroup, diskWriteQueue, ^{
          //write empty frame count
          @try {
            [fileHandle writeData:[NSData dataWithBytes:&frameCountForFile length:sizeof(frameCountForFile)]];
          } @catch (NSException *exception) {
            NSError *frameCountError = [NSError errorWithDomain:kPI_NAnimatedImageErrorDomain code:PI_NAnimatedImageErrorFileWrite userInfo:@{@"NSException" : exception}];
            HANDLE_PROCESSING_ERROR(frameCountError);
          } @finally {}
        });
        
        //Process frames
        for (NSUInteger frameIdx = 0; frameIdx < frameCount; frameIdx++) {
          if (PROCESSING_ERROR != nil) {
            break;
          }
          @autoreleasepool {
            if (fileDuration > maxFileDuration || fileSize > maxFileSize) {
              //create a new file
              dispatch_group_async(diskGroup, diskWriteQueue, ^{
                //prepend file with frameCount
                @try {
                  [fileHandle seekToFileOffset:0];
                  [fileHandle writeData:[NSData dataWithBytes:&frameCountForFile length:sizeof(frameCountForFile)]];
                  [fileHandle closeFile];
                } @catch (NSException *exception) {
                  NSError *frameCountError = [NSError errorWithDomain:kPI_NAnimatedImageErrorDomain code:PI_NAnimatedImageErrorFileWrite userInfo:@{@"NSException" : exception}];
                  HANDLE_PROCESSING_ERROR(frameCountError);
                } @finally {}
              });
              
              dispatch_group_async(diskGroup, diskWriteQueue, ^{
                PI_NLog(@"notifying file: %@", filePath);
                completion(NO, filePath, PROCESSING_ERROR);
              });
              
              diskGroup = dispatch_group_create();
              fileCount++;
              NSError *fileHandleError = nil;
              fileHandle = [self fileHandle:&fileHandleError filePath:&filePath temporaryDirectory:temporaryDirectory UUID:UUID count:fileCount];
              HANDLE_PROCESSING_ERROR(fileHandleError);
              frameCountForFile = 0;
              fileDuration = 0;
              fileSize = 0;
              //write empty frame count
              dispatch_group_async(diskGroup, diskWriteQueue, ^{
                @try {
                  [fileHandle writeData:[NSData dataWithBytes:&frameCountForFile length:sizeof(frameCountForFile)]];
                } @catch (NSException *exception) {
                  NSError *frameCountError = [NSError errorWithDomain:kPI_NAnimatedImageErrorDomain code:PI_NAnimatedImageErrorFileWrite userInfo:@{@"NSException" : exception}];
                  HANDLE_PROCESSING_ERROR(frameCountError);
                } @finally {}
              });
            }
            
            Float32 duration = durations[frameIdx];
            fileDuration += duration;
            
            dispatch_group_async(diskGroup, diskWriteQueue, ^{
              if (PROCESSING_ERROR) {
                return;
              }
              
              CGImageRef frameImage = CGImageSourceCreateImageAtIndex(imageSource, frameIdx, (CFDictionaryRef)@{(__bridge NSString *)kCGImageSourceShouldCache : (__bridge NSNumber *)kCFBooleanFalse});
              if (frameImage == nil) {
                NSError *frameImageError = [NSError errorWithDomain:kPI_NAnimatedImageErrorDomain code:PI_NAnimatedImageErrorImageFrameError userInfo:nil];
                HANDLE_PROCESSING_ERROR(frameImageError);
                return;
              }
              
              NSData *frameData = (__bridge_transfer NSData *)CGDataProviderCopyData(CGImageGetDataProvider(frameImage));
              NSAssert(frameData.length == width * height * bitsPerPixel / 8, @"data should be width * height * bytes per pixel");
              NSError *frameWriteError = [self writeFrameToFile:fileHandle duration:duration frameData:frameData];
              HANDLE_PROCESSING_ERROR(frameWriteError);
              
              CGImageRelease(frameImage);
            });
            
            frameCountForFile++;
          }
        }
      } else {
        completion(NO, nil, PROCESSING_ERROR);
      }
    }
    
    dispatch_group_wait(diskGroup, DISPATCH_TIME_FOREVER);
    if (imageSource) {
      CFRelease(imageSource);
    }
    
    //close the file handle
    PI_NLog(@"closing last file: %@", fileHandle);
    @try {
      [fileHandle seekToFileOffset:0];
      [fileHandle writeData:[NSData dataWithBytes:&frameCountForFile length:sizeof(frameCountForFile)]];
      [fileHandle closeFile];
    } @catch (NSException *exception) {
      NSError *frameCountError = [NSError errorWithDomain:kPI_NAnimatedImageErrorDomain code:PI_NAnimatedImageErrorFileWrite userInfo:@{@"NSException" : exception}];
      HANDLE_PROCESSING_ERROR(frameCountError);
    } @finally {}
  }
  
#if PI_NMemMapAnimatedImageDebug
  CFTimeInterval interval = CACurrentMediaTime() - start;
  NSLog(@"Encoding and write time: %f", interval);
#endif
  
  if (durations) {
    free(durations);
  }
  
  completion(YES, filePath, PROCESSING_ERROR);
}

//http://stackoverflow.com/questions/16964366/delaytime-or-unclampeddelaytime-for-gifs
+ (Float32)frameDurationAtIndex:(NSUInteger)index source:(CGImageSourceRef)source
{
  Float32 frameDuration = kPI_NAnimatedImageDefaultDuration;
  NSDictionary *frameProperties = (__bridge_transfer NSDictionary *)CGImageSourceCopyPropertiesAtIndex(source, index, nil);
  // use unclamped delay time before delay time before default
  NSNumber *unclamedDelayTime = frameProperties[(__bridge NSString *)kCGImagePropertyGIFDictionary][(__bridge NSString *)kCGImagePropertyGIFUnclampedDelayTime];
  if (unclamedDelayTime != nil) {
    frameDuration = [unclamedDelayTime floatValue];
  } else {
    NSNumber *delayTime = frameProperties[(__bridge NSString *)kCGImagePropertyGIFDictionary][(__bridge NSString *)kCGImagePropertyGIFDelayTime];
    if (delayTime != nil) {
      frameDuration = [delayTime floatValue];
    }
  }
    
    static dispatch_once_t onceToken;
    static Float32 maximumFrameDuration;
    dispatch_once(&onceToken, ^{
        maximumFrameDuration = 1.0 / [PI_NAnimatedImage maximumFramesPerSecond];
    });
  
  if (frameDuration < maximumFrameDuration) {
    frameDuration = kPI_NAnimatedImageDefaultDuration;
  }
  
  return frameDuration;
}

+ (NSString *)filePathWithTemporaryDirectory:(NSString *)temporaryDirectory UUID:(NSUUID *)UUID count:(NSUInteger)count
{
  NSString *filePath = [temporaryDirectory stringByAppendingPathComponent:[UUID UUIDString]];
  if (count > 0) {
    filePath = [filePath stringByAppendingString:[@(count) stringValue]];
  }
  return filePath;
}

+ (NSFileHandle *)fileHandle:(NSError **)error filePath:(NSString **)filePath temporaryDirectory:(NSString *)temporaryDirectory UUID:(NSUUID *)UUID count:(NSUInteger)count;
{
  NSString *outFilePath = [self filePathWithTemporaryDirectory:temporaryDirectory UUID:UUID count:count];
  NSError *outError = nil;
  NSFileHandle *fileHandle = nil;
  
  if (outError == nil) {
    BOOL success = [[NSFileManager defaultManager] createFileAtPath:outFilePath contents:nil attributes:nil];
    if (success == NO) {
      outError = [NSError errorWithDomain:kPI_NAnimatedImageErrorDomain code:PI_NAnimatedImageErrorFileCreationError userInfo:nil];
    }
  }
  
  if (outError == nil) {
    fileHandle = [NSFileHandle fileHandleForWritingAtPath:outFilePath];
    if (fileHandle == nil) {
      outError = [NSError errorWithDomain:kPI_NAnimatedImageErrorDomain code:PI_NAnimatedImageErrorFileHandleError userInfo:nil];
    }
  }
  
  if (error) {
    *error = outError;
  }
  
  if (filePath) {
    *filePath = outFilePath;
  }
  
  return fileHandle;
}

/**
 PI_NGIFAnimatedImage file header
 
 Header:
 [version] 2 bytes
 [width] 4 bytes
 [height] 4 bytes
 [loop count] 4 bytes
 [frame count] 4 bytes
 [bitmap info] 4 bytes
 [durations] 4 bytes * frame count
 
 */

+ (NSError *)writeFileHeader:(NSFileHandle *)fileHandle width:(UInt32)width height:(UInt32)height bitsPerPixel:(UInt32)bitsPerPixel loopCount:(UInt32)loopCount frameCount:(UInt32)frameCount bitmapInfo:(UInt32)bitmapInfo durations:(Float32*)durations
{
  NSError *error = nil;
  @try {
    UInt16 version = 2;
    [fileHandle writeData:[NSData dataWithBytes:&version length:sizeof(version)]];
    [fileHandle writeData:[NSData dataWithBytes:&width length:sizeof(width)]];
    [fileHandle writeData:[NSData dataWithBytes:&height length:sizeof(height)]];
    [fileHandle writeData:[NSData dataWithBytes:&bitsPerPixel length:sizeof(bitsPerPixel)]];
    [fileHandle writeData:[NSData dataWithBytes:&loopCount length:sizeof(loopCount)]];
    [fileHandle writeData:[NSData dataWithBytes:&frameCount length:sizeof(frameCount)]];
    [fileHandle writeData:[NSData dataWithBytes:&bitmapInfo length:sizeof(bitmapInfo)]];
    //Since we can't get the length of the durations array from the pointer, we'll just calculate it based on the frameCount.
    [fileHandle writeData:[NSData dataWithBytes:durations length:sizeof(Float32) * frameCount]];
  } @catch (NSException *exception) {
    error = [NSError errorWithDomain:kPI_NAnimatedImageErrorDomain code:PI_NAnimatedImageErrorFileWrite userInfo:@{@"NSException" : exception}];
  } @finally {}
  return error;
}

/**
 PI_NGIFAnimatedImage frame file
 [frame count(in file)] 4 bytes
 [frame(s)]
 
 Each frame:
 [duration] 4 bytes
 [frame data] width * height * 4 bytes
 */

+ (NSError *)writeFrameToFile:(NSFileHandle *)fileHandle duration:(Float32)duration frameData:(NSData *)frameData
{
  NSError *error = nil;
  @try {
    [fileHandle writeData:[NSData dataWithBytes:&duration length:sizeof(duration)]];
    [fileHandle writeData:frameData];
  } @catch (NSException *exception) {
    error = [NSError errorWithDomain:kPI_NAnimatedImageErrorDomain code:PI_NAnimatedImageErrorFileWrite userInfo:@{@"NSException" : exception}];
  } @finally {}
  return error;
}

@end

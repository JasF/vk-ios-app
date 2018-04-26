//
//  PI_NGIFAnimatedImageManager.h
//  Pods
//
//  Created by Garrett Moon on 4/5/16.
//
//

#import <Foundation/Foundation.h>

#import "PI_NAnimatedImage.h"
#import "PI_NRemoteImageMacros.h"

@class PI_NRemoteLock;
@class PI_NSharedAnimatedImage;
@class PI_NSharedAnimatedImageFile;

typedef void(^PI_NAnimatedImageSharedReady)(PI_NImage *coverImage, PI_NSharedAnimatedImage *shared);
typedef void(^PI_NAnimatedImageDecodedPath)(BOOL finished, NSString *path, NSError *error);

@interface PI_NGIFAnimatedImageManager : NSObject

+ (instancetype)sharedManager;
+ (NSString *)temporaryDirectory;
+ (NSString *)filePathWithTemporaryDirectory:(NSString *)temporaryDirectory UUID:(NSUUID *)UUID count:(NSUInteger)count;

- (void)animatedPathForImageData:(NSData *)animatedImageData infoCompletion:(PI_NAnimatedImageSharedReady)infoCompletion completion:(PI_NAnimatedImageDecodedPath)completion;

@end

@interface PI_NSharedAnimatedImage : NSObject
{
  PI_NRemoteLock *_coverImageLock;
}

//This is intentionally atomic. PI_NGIFAnimatedImageManager must be able to add entries
//and clients must be able to read them concurrently.
@property (atomic, strong, readwrite) NSArray <PI_NSharedAnimatedImageFile *> *maps;

@property (nonatomic, strong, readwrite) NSArray <PI_NAnimatedImageDecodedPath> *completions;
@property (nonatomic, strong, readwrite) NSArray <PI_NAnimatedImageSharedReady> *infoCompletions;
@property (nonatomic, weak, readwrite) PI_NImage *coverImage;

//intentionally atomic
@property (atomic, strong, readwrite) NSError *error;
@property (atomic, assign, readwrite) PI_NAnimatedImageStatus status;

- (void)setInfoProcessedWithCoverImage:(PI_NImage *)coverImage
                                  UUID:(NSUUID *)UUID
                             durations:(Float32 *)durations
                         totalDuration:(CFTimeInterval)totalDuration
                             loopCount:(size_t)loopCount
                            frameCount:(size_t)frameCount
                                 width:(uint32_t)width
                                height:(uint32_t)height
                          bitsPerPixel:(size_t)bitsPerPixel
                            bitmapInfo:(CGBitmapInfo)bitmapInfo;

@property (nonatomic, readonly) NSUUID *UUID;
@property (nonatomic, readonly) Float32 *durations;
@property (nonatomic, readonly) CFTimeInterval totalDuration;
@property (nonatomic, readonly) size_t loopCount;
@property (nonatomic, readonly) size_t frameCount;
@property (nonatomic, readonly) uint32_t width;
@property (nonatomic, readonly) uint32_t height;
@property (nonatomic, readonly) size_t bitsPerPixel;
@property (nonatomic, readonly) CGBitmapInfo bitmapInfo;

@end

@interface PI_NSharedAnimatedImageFile : NSObject
{
  PI_NRemoteLock *_lock;
}

@property (nonatomic, strong, readonly) NSString *path;
@property (nonatomic, assign, readonly) UInt32 frameCount;
@property (nonatomic, weak, readonly) NSData *memoryMappedData;

- (instancetype)initWithPath:(NSString *)path NS_DESIGNATED_INITIALIZER;

@end

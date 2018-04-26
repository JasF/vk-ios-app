//
//  PI_NRemoteImageMacros.h
//  PI_NRemoteImage
//

#import <TargetConditionals.h>

#ifndef PI_NRemoteImageMacros_h
#define PI_NRemoteImageMacros_h

#define PI_N_TARGET_IOS (TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR || TARGET_OS_TV)
#define PI_N_TARGET_MAC (TARGET_OS_MAC)

#define PI_NRemoteImageLogging                0
#if PI_NRemoteImageLogging
#define PI_NLog(args...) NSLog(args)
#else
#define PI_NLog(args...)
#endif

#if __has_include(<FLAnimatedImage/FLAnimatedImage.h>)
#define USE_FLANIMATED_IMAGE    1
#else
#define USE_FLANIMATED_IMAGE    0
#define FLAnimatedImage NSObject
#endif

#ifndef USE_PI_NCACHE
    #if __has_include(<PI_NCache/PI_NCache.h>)
    #define USE_PI_NCACHE    1
    #else
    #define USE_PI_NCACHE    0
    #endif
#endif

#ifndef PI_N_WEBP
    #if __has_include("webp/decode.h")
    #define PI_N_WEBP    1
    #else
    #define PI_N_WEBP    0
    #endif
#endif

#if PI_N_TARGET_IOS
#define PI_NImage     UIImage
#define PI_NImageView UIImageView
#define PI_NButton    UIButton
#define PI_NNSOperationSupportsBlur (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_8_0)
#elif PI_N_TARGET_MAC
#define PI_NImage     NSImage
#define PI_NImageView NSImageView
#define PI_NButton    NSButton
#define PI_NNSOperationSupportsBlur (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber10_10)
#define PI_NNSURLSessionTaskSupportsPriority (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber10_10)
#endif

#define PI_NWeakify(var) __weak typeof(var) PI_NWeak_##var = var;

#define PI_NStrongify(var)                                                                                           \
_Pragma("clang diagnostic push") _Pragma("clang diagnostic ignored \"-Wshadow\"") __strong typeof(var) var = \
PI_NWeak_##var;                                                                                           \
_Pragma("clang diagnostic pop")

#define BlockAssert(condition, desc, ...)	\
do {				\
__PRAGMA_PUSH_NO_EXTRA_ARG_WARNINGS \
if (!(condition)) {		\
[[NSAssertionHandler currentHandler] handleFailureInMethod:_cmd \
object:strongSelf file:[NSString stringWithUTF8String:__FILE__] \
lineNumber:__LINE__ description:(desc), ##__VA_ARGS__]; \
}				\
__PRAGMA_POP_NO_EXTRA_ARG_WARNINGS \
} while(0);

#endif /* PI_NRemoteImageMacros_h */

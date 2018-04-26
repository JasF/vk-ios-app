//
//  UIButton+PI_NRemoteImage.h
//  Pods
//
//  Created by Garrett Moon on 8/18/14.
//
//

#if PI_N_TARGET_IOS
#import <UIKit/UIKit.h>
#elif PI_N_TARGET_MAC
#import <Cocoa/Cocoa.h>
#endif

#import "PI_NRemoteImageManager.h"
#import "PI_NRemoteImageCategoryManager.h"

@interface PI_NButton (PI_NRemoteImage) <PI_NRemoteImageCategory>

@end

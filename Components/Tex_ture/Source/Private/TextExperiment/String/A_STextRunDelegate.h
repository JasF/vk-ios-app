//
//  A_STextRunDelegate.h
//  A_SText <https://github.com/ibireme/A_SText>
//
//  Created by ibireme on 14/10/14.
//  Copyright (c) 2015 ibireme.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import <UIKit/UIKit.h>
#import <CoreText/CoreText.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Wrapper for CTRunDelegateRef.
 
 Example:
 
 A_STextRunDelegate *delegate = [A_STextRunDelegate new];
 delegate.ascent = 20;
 delegate.descent = 4;
 delegate.width = 20;
 CTRunDelegateRef ctRunDelegate = delegate.CTRunDelegate;
 if (ctRunDelegate) {
   /// add to attributed string
   CFRelease(ctRunDelegate);
 }
 
 */
@interface A_STextRunDelegate : NSObject <NSCopying, NSCoding>

/**
 Creates and returns the CTRunDelegate.
 
 @discussion You need call CFRelease() after used.
 The CTRunDelegateRef has a strong reference to this A_STextRunDelegate object.
 In CoreText, use CTRunDelegateGetRefCon() to get this A_STextRunDelegate object.
 
 @return The CTRunDelegate object.
 */
- (nullable CTRunDelegateRef)CTRunDelegate CF_RETURNS_RETAINED;

/**
 Additional information about the the run delegate.
 */
@property (nullable, nonatomic, strong) NSDictionary *userInfo;

/**
 The typographic ascent of glyphs in the run.
 */
@property (nonatomic) CGFloat ascent;

/**
 The typographic descent of glyphs in the run.
 */
@property (nonatomic) CGFloat descent;

/**
 The typographic width of glyphs in the run.
 */
@property (nonatomic) CGFloat width;

@end

NS_ASSUME_NONNULL_END

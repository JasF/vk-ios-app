//
//  ASPanningOverriddenUITextView.m
//  vk
//
//  Created by Jasf on 02.05.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "ASPanningOverriddenUITextView.h"
#import "RSSwizzle.h"
#import <objc/runtime.h>
@import ObjectiveC;

@implementation ASPanningOverriddenUITextView (Patch)
/*
+ (void)load {
    SEL selector = @selector(setScrollEnabled:);
    [RSSwizzle
     swizzleInstanceMethod:selector
     inClass:[ASPanningOverriddenUITextView class]
     newImpFactory:^id(RSSwizzleInfo *swizzleInfo) {
         // This block will be used as the new implementation.
         return ^void(__unsafe_unretained id self, BOOL enabled){
             int (*originalIMP)(__unsafe_unretained id, SEL, int);
             originalIMP = (__typeof(originalIMP))[swizzleInfo getOriginalImplementation];
             originalIMP(self,selector,enabled);
             IMP imp = [[[self class] superclass] instanceMethodForSelector:@selector(setScrollEnabled:)];
             void (*func)(id, BOOL) = (void *)imp;
             func(self, enabled);
         };
     }
     mode:RSSwizzleModeAlways
     key:NULL];
}
*/
@end

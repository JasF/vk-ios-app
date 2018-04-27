//
//  ASInsetLayoutSpec+Utils.m
//  vk
//
//  Created by Jasf on 27.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "ASInsetLayoutSpec+Utils.h"

@implementation ASInsetLayoutSpec (Utils)
+ (instancetype)utils_with:(id<ASLayoutElement>)child {
    return [ASInsetLayoutSpec insetLayoutSpecWithInsets:UIEdgeInsetsZero child:child];
}
@end

//
//  UIViewController+Utils.h
//  vk
//
//  Created by Jasf on 10.05.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UIViewController (Utils)
@property (nonatomic) BOOL pushed;
- (void)addMenuIconWithTarget:(id)target action:(SEL)action;
@end

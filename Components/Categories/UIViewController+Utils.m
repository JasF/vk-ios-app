//
//  UIViewController+Utils.m
//  vk
//
//  Created by Jasf on 10.05.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "UIViewController+Utils.h"
#import <objc/runtime.h>

static const char *kPushedKey;
static CGFloat const kButtonSize = 44.f;

@interface InsetButtonsNavigationBar : UINavigationBar
@end

@implementation InsetButtonsNavigationBar
- (void)layoutSubviews {
    [super layoutSubviews];
    if (@available(iOS 11, *)) {
        for (UIView *view in self.subviews) {
            view.layoutMargins = UIEdgeInsetsZero;
        }
    }
}
@end

@implementation UIViewController (Utils)
- (void)addMenuIconWithTarget:(id)target action:(SEL)action {
    if (self.pushed || self.navigationItem.leftBarButtonItem) {
        return;
    }
    UIButton *button = [UIButton new];
    [button addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
    [button setImage:[UIImage imageNamed:@"menuIcon"] forState:UIControlStateNormal];
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithCustomView:button];
    button.size = CGSizeMake(kButtonSize, kButtonSize);
    CGFloat spacerWidth = -10;
    if (@available(iOS 11, *)) {
        spacerWidth = 6;
    }
    UIBarButtonItem *negativeSpacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    negativeSpacer.width = spacerWidth;
    button.size = CGSizeMake(kButtonSize, kButtonSize);
    self.navigationItem.leftBarButtonItems = @[negativeSpacer, backButton];
}

- (void)setPushed:(BOOL)pushed {
    objc_setAssociatedObject(self, kPushedKey, @(pushed), OBJC_ASSOCIATION_RETAIN);
}

- (BOOL)pushed {
    NSNumber *value = objc_getAssociatedObject(self, kPushedKey);
    return value.boolValue;
}
@end

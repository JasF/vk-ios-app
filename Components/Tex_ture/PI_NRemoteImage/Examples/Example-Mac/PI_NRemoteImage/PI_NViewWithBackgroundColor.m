//
//  PI_NViewWithBackgroundColor.m
//  PI_NRemoteImage
//
//  Created by Michael Schneider on 1/5/16.
//  Copyright © 2016 mischneider. All rights reserved.
//

#import "PI_NViewWithBackgroundColor.h"

@implementation PI_NViewWithBackgroundColor


#pragma mark - Lifecycle

- (instancetype)init
{
    self = [super init];
    if (self == nil) { return self; }
    [self initPI_NViewWithBackgroundColor];
    return self;
}


- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self == nil) { return self; }
    [self initPI_NViewWithBackgroundColor];
    return self;
}

- (void)initPI_NViewWithBackgroundColor
{
    self.wantsLayer = YES;
}


#pragma mark - NSView

- (BOOL)wantsUpdateLayer
{
    return YES;
}

- (void)updateLayer
{
    self.layer.backgroundColor = self.backgroundColor.CGColor;
}


#pragma mark - Setter

- (void)setBackgroundColor:(NSColor *)backgroundColor
{
    _backgroundColor = backgroundColor;
    [self setNeedsDisplay:YES];
}

@end

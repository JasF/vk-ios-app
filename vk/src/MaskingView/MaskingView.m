//
//  MaskingView.m
//  Horoscopes
//
//  Created by Jasf on 02.12.2017.
//  Copyright © 2017 Mail.Ru. All rights reserved.
//

#import "MaskingView.h"


@interface UIView (Horo)
- (UIImage *)utils_grabImage;
@end

@implementation UIView (Horo)
- (UIImage *)utils_grabImage {
    // Create a "canvas" (image context) to draw in.
    UIGraphicsBeginImageContext([self bounds].size);
    
    // Make the CALayer to draw in our "canvas".
    [[self layer] renderInContext:UIGraphicsGetCurrentContext()];
    
    // Fetch an UIImage of our "canvas".
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    
    // Stop the "canvas" from accepting any input.
    UIGraphicsEndImageContext();
    
    // Return the image.
    return image;
}
@end

typedef NS_ENUM(NSInteger, GradientGenerationTypes) {
    GradientHolka,
    GradientMenuCell,
    GradientGradientView
};

@interface UIImageView (Horo)
+ (UIImage *)utils_generateWithSize:(CGSize)size
                              type:(GradientGenerationTypes)type;
@end


static CGFloat const kGradientLocationFirst = 0.0f;
static CGFloat const kGradientLocationSecond = 0.012f;
static CGFloat const kGradientLocationThird = 1.f;

static CGFloat const kGradientMenuCellFirst = 0.0f;
static CGFloat const kGradientMenuCellSecond = 0.5f;
static CGFloat const kGradientMenuCellThird = 1.f;

static CGFloat const kGradientGradientViewFirst = 0.f;
static CGFloat const kGradientGradientViewSecond = 1.f;

@implementation UIImageView (Horo)
+ (UIImage *)utils_generateWithSize:(CGSize)size
                              type:(GradientGenerationTypes)type {
    static UIImage *g_GeneratedMaskImage = nil;
    static CGRect g_GeneratedMaskImageFrame = {{0.f, 0.f}, {0.f, 0.f}};
    CGRect frame = CGRectMake(0.f, 0.f, size.width, size.height);
    
    NSDictionary *typeParameters = @{
                                     @(GradientHolka) : @[@(kGradientLocationFirst), @(kGradientLocationSecond), @(kGradientLocationThird)],
                                     @(GradientMenuCell) : @[@(kGradientMenuCellFirst), @(kGradientMenuCellSecond), @(kGradientMenuCellThird)],
                                     @(GradientGradientView) : @[@(kGradientGradientViewFirst), @(kGradientGradientViewSecond)]
                                     };
    
    NSDictionary *colorParameters = @{
                                      @(GradientHolka) : @[ (id)[UIColor clearColor].CGColor,
                                                            (id)[UIColor blackColor].CGColor,
                                                            (id)[UIColor blackColor].CGColor ],
                                      @(GradientMenuCell) : @[ (id)[UIColor blackColor].CGColor,
                                                               (id)[UIColor blackColor].CGColor,
                                                               (id)[UIColor clearColor].CGColor ],
                                      @(GradientGradientView) : @[ (id)[UIColor clearColor].CGColor,
                                                                   (id)[[UIColor blackColor] colorWithAlphaComponent:0.7f].CGColor ]
                                      };
    
    // AV: Проверки на случай добавления смены ориентации
    if (!g_GeneratedMaskImage || !CGRectEqualToRect(g_GeneratedMaskImageFrame, frame)) {
        UIView *view = [[UIView alloc] initWithFrame:frame];
        CAGradientLayer *gradient = [CAGradientLayer layer];
        gradient.frame = view.bounds;
        gradient.colors = colorParameters[@(type)];
        gradient.locations = typeParameters[@(type)];
        [view.layer insertSublayer:gradient atIndex:0];
        g_GeneratedMaskImage = [view utils_grabImage];
    }
    return g_GeneratedMaskImage;
}
@end

@implementation MaskingView
- (void)didMoveToSuperview {
    self.superview.opaque = NO;
    self.superview.clearsContextBeforeDrawing = YES;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CALayer *aMaskLayer=[CALayer layer];
    UIImage *image = [UIImageView utils_generateWithSize:self.size
                                                   type:GradientHolka];
    aMaskLayer.contents=(id)image.CGImage;
    aMaskLayer.frame = CGRectMake(0,0, image.size.width, image.size.height);
    self.layer.mask=aMaskLayer;
}

@end

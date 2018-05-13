//
//  MainViewController.m
//  LGSideMenuControllerDemo
//

#import "MainViewController.h"
#import "LGSideMenuHelper.h"

@interface ViewPropertyAnimator : UIViewPropertyAnimator
@end

@implementation ViewPropertyAnimator
- (void)setFractionComplete:(CGFloat)fractionComplete {
    DDLogInfo(@"setFracomp: %f", fractionComplete);
    [super setFractionComplete:fractionComplete];
}
@end

@interface MainViewController ()

@property (assign, nonatomic) NSUInteger type;
@property (strong, nonatomic) CADisplayLink *displayLink;
@property (strong, nonatomic) dispatch_block_t displayLinkBlock;
@property (strong, nonatomic) NSDate *animationStartDate;
@property (strong, nonatomic) UIVisualEffectView *backgroundEffectView;

@end

static CGFloat const kStartDelay = 0.5f;
static CGFloat const kBlurStartDelay = 0.25f;
static CGFloat const kBlurMaximumFraction = 0.4f;

@implementation MainViewController {
    UIVisualEffectView *_backgroundEffectView;
    ViewPropertyAnimator *_animator;

}

- (CADisplayLink *)displayLink {
    if (!_displayLink) {
        _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(displayLinkObserver)];
    }
    return _displayLink;
}

- (void)startDisplayLink {
    [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
}

- (void)stopDisplayLink {
    [self.displayLink invalidate];
    _displayLink = nil;
}

- (UIViewPropertyAnimator *)animator {
    /*
    if (!_animator) {
        @weakify(self);
        UIBlurEffect *blur = (UIBlurEffect *)self.backgroundEffectView.effect;
        self.backgroundEffectView.effect = nil;
        _animator = [[ViewPropertyAnimator alloc] initWithDuration:0.5f curve:UIViewAnimationCurveLinear animations:^{
            @strongify(self);
            self.backgroundEffectView.effect = blur;
        }];
        
    }
     */
    return _animator;
}

- (UIVisualEffectView *)backgroundEffectView {
    /*
    if (!_backgroundEffectView) {
        UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleRegular];
        UIVisualEffectView *blurEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
        _backgroundEffectView = blurEffectView;
        _backgroundEffectView.frame = [UIScreen mainScreen].bounds;
        [self.view insertSubview:blurEffectView atIndex:2];
    }
     */
    return _backgroundEffectView;
}


- (void)setDisplayLinkBlock:(dispatch_block_t)displayLinkBlock {
    if (_displayLinkBlock != displayLinkBlock) {
        if (displayLinkBlock) {
            [self startDisplayLink];
        }
        _displayLinkBlock = displayLinkBlock;
    }
    if (!_displayLinkBlock) {
        [self stopDisplayLink];
    }
}

- (void)displayLinkObserver {
    if (_displayLinkBlock) {
        _displayLinkBlock();
    }
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    DDLogInfo(@"MainViewController allocation");
    return [super initWithCoder:aDecoder];
}

- (CGFloat)blurFractionFromPercentage:(CGFloat)percentage {
    if (percentage < kBlurStartDelay) {
        percentage = 0.f;
    }
    else {
        percentage -= kBlurStartDelay;
        percentage = percentage/(1.f-kBlurStartDelay);
    }
    return percentage*kBlurMaximumFraction;
}

- (void)showAnimation {
    /*
    CGFloat max = [UIScreen mainScreen].bounds.size.width * 0.746f;
    @weakify(self);
    self.displayLinkBlock = ^{
        @strongify(self);
        CGRect frame = [[self.rootViewContainer.layer presentationLayer] frame];
        CGFloat percentage = frame.origin.x / max;//max/maxdur*;
        CGFloat value = [self blurFractionFromPercentage:percentage];
        [self animator].fractionComplete = value;
        DDLogInfo(@"show value: %f", value);
        if (IsEqualFloat(value, kBlurMaximumFraction)) {
            self.displayLinkBlock = nil;
        }
    };
     */
}

- (void)showLeftViewAnimated:(BOOL)animated completionHandler:(LGSideMenuCompletionHandler)completionHandler {
    self.animationStartDate = [NSDate date];
    [self showAnimation];
    @weakify(self);
    [super showLeftViewAnimated:animated completionHandler:^{
        @strongify(self);
        [self animator].fractionComplete = kBlurMaximumFraction;
        self.displayLinkBlock = nil;
        if (completionHandler) {
            completionHandler();
        }
    }];
}

- (void)hideAnimation {
    /*
    @weakify(self);
    CGRect _frame = [[self.rootViewContainer.layer presentationLayer] frame];
    CGFloat max = [UIScreen mainScreen].bounds.size.width * 0.746f;
    self.displayLinkBlock = ^{
        @strongify(self);
        CGRect frame = [[self.rootViewContainer.layer presentationLayer] frame];
        CGFloat percentage = frame.origin.x / max;//max/maxdur*;
        CGFloat value = [self blurFractionFromPercentage:percentage];
        [self animator].fractionComplete = value;
        if (IsEqualFloat(value, 0.f)) {
            self.displayLinkBlock = nil;
        }
        DDLogInfo(@"percentage: %f; hide value: %f", percentage, value);
    };
    */
}

- (void)hideLeftViewAnimated:(BOOL)animated completionHandler:(LGSideMenuCompletionHandler)completionHandler {
    @weakify(self);
    [self hideAnimation];
    [super hideLeftViewAnimated:animated completionHandler:^{
        @strongify(self);
        [self animator].fractionComplete = 0.f;
        self.displayLinkBlock = nil;
        if (completionHandler) {
            completionHandler();
        }
    }];
}

- (UIVisualEffectView *)effectView {
    return [self backgroundEffectView];
   // MenuViewController *menuViewController = (MenuViewController *)self.leftViewController;
   // NSCAssert([menuViewController isKindOfClass:[MenuViewController class]], @"menuViewController unknown");
   // return menuViewController.backgroundEffectView;
}

//- (UIViewPropertyAnimator *)animator {
   // MenuViewController *menuViewController = (MenuViewController *)self.leftViewController;
   // NSCAssert([menuViewController isKindOfClass:[MenuViewController class]], @"menuViewController unknown");
   // return [menuViewController animator];
//}

- (void)setLeftViewController:(UIViewController *)leftViewController {
    [super setLeftViewController:leftViewController];
    @weakify(self);
    
    self.intCallback = ^(CGFloat percentage, BOOL animated) {
        @strongify(self);
        if (animated) {
            if (IsEqualFloat(percentage, 0.f)) {
                // closing after pan gesture
                [self hideAnimation];
            }
            else if (IsEqualFloat(percentage, 1.f)) {
                // opening after pan gesture
                [self showAnimation];
            }
        }
    };
    self.leftViewPercentageChanged = ^(CGFloat percentage, BOOL animated) {
        @strongify(self);
        if (IsEqualFloat(percentage, 0.f)) {
           // return;
        }
        void (^changeFraction)(CGFloat fraction) = ^void(CGFloat fraction) {
            fraction = [self blurFractionFromPercentage:fraction];
            self.animator.fractionComplete = fraction;
        };
        if (animated) {
        }
        else {
            changeFraction(percentage);
        }
        CGFloat newAlpha = percentage;
        if (percentage < kStartDelay) {
            newAlpha = 0;
        }
        else {
            CGFloat newPercentage = percentage - kStartDelay;
            newAlpha = newPercentage/(1-kStartDelay);
        }
    };
}

- (void)setupWithType:(NSUInteger)type {
    self.type = type;
    self.leftViewPresentationStyle = LGSideMenuPresentationStyleScaleFromBig;
    self.leftViewStatusBarStyle = UIStatusBarStyleLightContent;
    self.rightViewPresentationStyle = LGSideMenuPresentationStyleScaleFromBig;
    self.rightViewStatusBarStyle = UIStatusBarStyleLightContent;
}

- (void)leftViewWillLayoutSubviewsWithSize:(CGSize)size {
    [super leftViewWillLayoutSubviewsWithSize:size];

    if (!self.isLeftViewStatusBarHidden) {
        self.leftView.frame = CGRectMake(0.0, 20.0, size.width, size.height-20.0);
    }
}

- (void)rightViewWillLayoutSubviewsWithSize:(CGSize)size {
    [super rightViewWillLayoutSubviewsWithSize:size];

    if (!self.isRightViewStatusBarHidden ||
        (self.rightViewAlwaysVisibleOptions & LGSideMenuAlwaysVisibleOnPadLandscape &&
         UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad &&
         UIInterfaceOrientationIsLandscape(UIApplication.sharedApplication.statusBarOrientation))) {
        self.rightView.frame = CGRectMake(0.0, 20.0, size.width, size.height-20.0);
    }
}

- (BOOL)isLeftViewStatusBarHidden {
    if (self.type == 8) {
        return UIInterfaceOrientationIsLandscape(UIApplication.sharedApplication.statusBarOrientation) && UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone;
    }

    return super.isLeftViewStatusBarHidden;
}

- (BOOL)isRightViewStatusBarHidden {
    if (self.type == 8) {
        return UIInterfaceOrientationIsLandscape(UIApplication.sharedApplication.statusBarOrientation) && UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone;
    }

    return super.isRightViewStatusBarHidden;
}

- (void)dealloc {
    DDLogInfo(@"MainViewController deallocated");
}

@end

//
//  ProgressiveViewController.m
//  PI_NRemoteImage
//
//  Created by Michael Schneider on 1/6/16.
//  Copyright © 2016 mischneider. All rights reserved.
//

#import "ProgressiveViewController.h"

#import <PI_NRemoteImage/PI_NImageView+PI_NRemoteImage.h>
#import <PI_NRemoteImage/PI_NRemoteImageCaching.h>

@interface ProgressiveViewController ()
@property (weak) IBOutlet NSImageView *imageView;

@end

@implementation ProgressiveViewController

#pragma mark - Lifecycle

- (instancetype)init
{
    self = [super initWithNibName:NSStringFromClass(self.class) bundle:nil];
    if (self == nil) { return self; }
    return self;
}


#pragma mark - NSViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // MUST BE SET ON IMAGE VIEW TO GET PROGRESS UPDATES!
    self.imageView.pin_updateWithProgress = YES;
}

- (void)viewDidAppear
{
    [super viewDidAppear];
    
    NSURL *progressiveURL = [NSURL URLWithString:@"https://i.pinimg.com/1200x/2e/0c/c5/2e0cc5d86e7b7cd42af225c29f21c37f.jpg"];
    [[PI_NRemoteImageManager sharedImageManager] setProgressThresholds:@[@(0.1), @(0.2), @(0.3), @(0.4), @(0.5), @(0.6), @(0.7), @(0.8), @(0.9)] completion:nil];
    [[[PI_NRemoteImageManager sharedImageManager] cache] removeObjectForKey:[[PI_NRemoteImageManager sharedImageManager] cacheKeyForURL:progressiveURL processorKey:nil]];
    [self.imageView pin_setImageFromURL:progressiveURL];
    
    NSMutableArray *progress = [[NSMutableArray alloc] init];
    [[PI_NRemoteImageManager sharedImageManager]
     downloadImageWithURL:progressiveURL
     options:PI_NRemoteImageManagerDownloadOptionsNone progressImage:^(PI_NRemoteImageManagerResult *result) {
         [progress addObject:result.image];
     } completion:^(PI_NRemoteImageManagerResult *result) {
         [progress addObject:result.image];
     }];
}

@end

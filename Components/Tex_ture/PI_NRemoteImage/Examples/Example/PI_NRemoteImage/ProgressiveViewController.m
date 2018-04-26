//
//  ProgressiveViewController.m
//  PI_NRemoteImage
//
//  Created by Garrett Moon on 7/14/15.
//  Copyright (c) 2015 Garrett Moon. All rights reserved.
//

#import "ProgressiveViewController.h"

#import <PI_NRemoteImage/PI_NImageView+PI_NRemoteImage.h>
#import <PI_NRemoteImage/PI_NRemoteImageCaching.h>


@interface ProgressiveViewController ()

@end

@implementation ProgressiveViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // MUST BE SET ON IMAGE VIEW TO GET PROGRESS UPDATES!
    self.imageView.pin_updateWithProgress = YES;
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.imageView.image = nil;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
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

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end

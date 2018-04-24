//
//  ImagesViewerViewController.m
//  vk
//
//  Created by Jasf on 24.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "ImagesViewerViewController.h"
#import "Photo.h"

static NSInteger const kPreloadingBorder = 2;

@import MWPhotoBrowser;

@interface ImagesViewerViewController () <MWPhotoBrowserDelegate>
@property id<ImagesViewerViewModel> viewModel;
@property NSMutableArray *photos;
@property MWPhotoBrowser *browser;
@property BOOL updating;
@end

@implementation ImagesViewerViewController

- (instancetype)initWithViewModel:(id<ImagesViewerViewModel>)viewModel {
    NSCParameterAssert(viewModel);
    _viewModel = viewModel;
    if (self = [super init]) {
        _viewModel = viewModel;
        self.title = @"VK Images Viewer";
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    [self.viewModel getPhotos:0 completion:^(NSArray *photos) {
        dispatch_async(dispatch_get_global_queue(0, DISPATCH_QUEUE_PRIORITY_DEFAULT), ^{
            NSArray *photosObjects = [self wrapPhotosObjects:photos];
            NSArray *filteredArray = [photos filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"id == %@", @(self.viewModel.photoId)]];
            NSInteger selectedPhotoIndex = [photos indexOfObject:filteredArray.firstObject];
            if (selectedPhotoIndex == NSNotFound) {
                selectedPhotoIndex = 0;
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [self showPhotoBrowserWithPhotos:photosObjects selectedPhotoIndex:selectedPhotoIndex];
            });
        });
    }];
}

#pragma mark - Private Methods
- (void)showPhotoBrowserWithPhotos:(NSArray *)photosArray selectedPhotoIndex:(NSInteger)selectedPhotoIndex {
    BOOL displayActionButton = YES;
    BOOL displaySelectionButtons = NO;
    BOOL displayNavArrows = NO;
    BOOL enableGrid = NO;
    BOOL startOnGrid = NO;
    BOOL autoPlayOnAppear = NO;
    
    self.photos = [[NSMutableArray alloc] init];
    [self.photos addObjectsFromArray:photosArray];
    
    MWPhotoBrowser *browser = [[MWPhotoBrowser alloc] initWithDelegate:self];
    browser.displayActionButton = displayActionButton;
    browser.displayNavArrows = displayNavArrows;
    browser.displaySelectionButtons = displaySelectionButtons;
    browser.alwaysShowControls = displaySelectionButtons;
    browser.zoomPhotosToFill = YES;
    browser.enableGrid = enableGrid;
    browser.startOnGrid = startOnGrid;
    browser.enableSwipeToDismiss = YES;
    browser.autoPlayOnAppear = autoPlayOnAppear;
    [browser setCurrentPhotoIndex:selectedPhotoIndex];
    _browser = browser;
    
    [self addChildViewController:browser];
    [self.view addSubview:browser.view];
    [browser didMoveToParentViewController:self];
}

- (NSArray *)wrapPhotosObjects:(NSArray *)photosArray {
    NSMutableArray *photos = [NSMutableArray new];
    for (Photo *photo in photosArray) {
        MWPhoto *object = [MWPhoto photoWithURL:[NSURL URLWithString:photo.bigPhotoURL]];
        object.caption = photo.text;
        [photos addObject:object];
    }
    return photos;
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    _browser.view.frame = self.view.bounds;
}

#pragma mark - MWPhotoBrowserDelegate
- (NSUInteger)numberOfPhotosInPhotoBrowser:(MWPhotoBrowser *)photoBrowser {
    return _photos.count;
}

- (id <MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index {
    if (index < _photos.count)
        return [_photos objectAtIndex:index];
    return nil;
}

- (id <MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser thumbPhotoAtIndex:(NSUInteger)index {
    return nil;
}

- (MWCaptionView *)photoBrowser:(MWPhotoBrowser *)photoBrowser captionViewForPhotoAtIndex:(NSUInteger)index {
    MWPhoto *photo = [self.photos objectAtIndex:index];
    MWCaptionView *captionView = [[MWCaptionView alloc] initWithPhoto:photo];
    return captionView;
}

//- (void)photoBrowser:(MWPhotoBrowser *)photoBrowser actionButtonPressedForPhotoAtIndex:(NSUInteger)index {
//    NSLog(@"ACTION!");
//}

- (void)photoBrowser:(MWPhotoBrowser *)photoBrowser didDisplayPhotoAtIndex:(NSUInteger)index {
    NSLog(@"Did start viewing photo at index %lu", (unsigned long)index);
    if (self.updating) {
        return;
    }
    if (index >= _photos.count - kPreloadingBorder) {
        self.updating = YES;
        @weakify(self);
        [_viewModel getPhotos:_photos.count completion:^(NSArray *photos) {
            dispatch_async(dispatch_get_global_queue(0, DISPATCH_QUEUE_PRIORITY_DEFAULT), ^{
                @strongify(self);
                NSArray *photosObjects = [self wrapPhotosObjects:photos];
                dispatch_async(dispatch_get_main_queue(), ^{
                    @strongify(self);
                    self.updating = NO;
                    [self.photos addObjectsFromArray:photosObjects];
                    [self.browser reloadData];
                });
            });
        }];
    }
}

- (BOOL)photoBrowser:(MWPhotoBrowser *)photoBrowser isPhotoSelectedAtIndex:(NSUInteger)index {
    return NO;//[[_selections objectAtIndex:index] boolValue];
}

- (NSString *)photoBrowser:(MWPhotoBrowser *)photoBrowser titleForPhotoAtIndex:(NSUInteger)index {
    return [NSString stringWithFormat:@"Photo %lu", (unsigned long)index+1];
}

- (void)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index selectedChanged:(BOOL)selected {
   //[_selections replaceObjectAtIndex:index withObject:[NSNumber numberWithBool:selected]];
    NSLog(@"Photo at index %lu selected %@", (unsigned long)index, selected ? @"YES" : @"NO");
}

- (void)photoBrowserDidFinishModalPresentation:(MWPhotoBrowser *)photoBrowser {
    // If we subscribe to this method we must dismiss the view controller ourselves
    NSLog(@"Did finish modal presentation");
    //[self dismissViewControllerAnimated:YES completion:nil];
}


@end

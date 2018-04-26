//
//  ScrollViewController.m
//  PI_NRemoteImage
//
//  Created by Michael Schneider on 1/6/16.
//  Copyright © 2016 mischneider. All rights reserved.
//

#import "ScrollViewController.h"

#import <Quartz/Quartz.h>
#import <PI_NRemoteImage/PI_NRemoteImageManager.h>
#import <PI_NRemoteImage/PI_NImageView+PI_NRemoteImage.h>
#import <PI_NRemoteImage/PI_NRemoteImageCaching.h>

#import "PI_NViewWithBackgroundColor.h"
#import "Kitten.h"

@interface PI_NImageCollectionViewItem : NSCollectionViewItem

@end

@interface ScrollViewController ()
@property (weak) IBOutlet NSCollectionView *collectionView;
@property (nonatomic, strong) NSMutableArray *kittens;
@end

@implementation ScrollViewController


#pragma mark - Lifecycle

- (instancetype)init
{
    srand([[NSDate date] timeIntervalSince1970]);
    
    self = [super initWithNibName:NSStringFromClass(self.class) bundle:nil];
    if (self == nil) { return self; }
    [[[PI_NRemoteImageManager sharedImageManager] cache] removeAllObjects];
    return self;
}


#pragma mark - NSViewController

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    [self.collectionView registerNib:[[NSNib alloc] initWithNibNamed:@"PI_NImageCollectionViewItemView" bundle:nil] forItemWithIdentifier:@"ItemIdentifier"];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.kittens = [NSMutableArray new];
    [self fetchKittenImages];
}

- (void)viewWillLayout
{
    [super viewWillLayout];
    
    [self.collectionView.collectionViewLayout invalidateLayout];
}


#pragma mark - Load images

- (void)fetchKittenImages
{
    [Kitten fetchKittenForWidth:CGRectGetWidth(self.collectionView.frame) completion:^(NSArray *kittens) {
        [self.kittens addObjectsFromArray:kittens];
        [self.collectionView reloadData];
    }];
}


#pragma mark - <NSCollectionViewDataSource, NSCollectionViewDelegate>

- (NSInteger)collectionView:(NSCollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.kittens.count;
}

- (NSCollectionViewItem *)collectionView:(NSCollectionView *)collectionView itemForRepresentedObjectAtIndexPath:(NSIndexPath *)indexPath
{
    PI_NImageCollectionViewItem *item = [collectionView makeItemWithIdentifier:@"PI_NImageCollectionViewItemView" forIndexPath:indexPath];
    Kitten *kitten = [self.kittens objectAtIndex:indexPath.item];
    item.imageView.alphaValue = 0.0f;
    [((PI_NViewWithBackgroundColor *)item.view) setBackgroundColor:kitten.dominantColor];
    __weak NSCollectionViewItem *weakItem = item;

    [item.imageView pin_setImageFromURL:kitten.imageURL
                             completion:^(PI_NRemoteImageManagerResult *result) {
                                 if (result.requestDuration > 0.25) {
                                     [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context){
                                         context.duration = 0.3;
                                         context.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
                                         weakItem.imageView.animator.alphaValue = 1.0f;
                                     } completionHandler:^{
                                     }];
                                 } else {
                                     weakItem.imageView.alphaValue = 1.0f;
                                 }
                             }];
    return item;
}

- (NSSize)collectionView:(NSCollectionView *)collectionView layout:(NSCollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    Kitten *kitten = [self.kittens objectAtIndex:indexPath.item];
    return NSMakeSize(CGRectGetWidth(collectionView.frame), kitten.imageSize.height);
}

@end


@implementation PI_NImageCollectionViewItem

- (void)prepareForReuse
{
    [super prepareForReuse];
    
    self.imageView.image = nil;
}

@end

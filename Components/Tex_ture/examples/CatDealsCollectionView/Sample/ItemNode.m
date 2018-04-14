//
//  ItemNode.m
//  Tex_ture
//
//  Copyright (c) 2014-present, Facebook, Inc.  All rights reserved.
//  This source code is licensed under the BSD-style license found in the
//  LICENSE file in the /A_SDK-Licenses directory of this source tree. An additional
//  grant of patent rights can be found in the PATENTS file in the same directory.
//
//  Modifications to this file made after 4/13/2017 are: Copyright (c) 2017-present,
//  Pinterest, Inc.  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import "ItemNode.h"
#import "ItemStyles.h"
#import "PlaceholderNetworkImageNode.h"
#import <Async_DisplayKit/A_SDisplayNodeExtras.h>

const CGFloat kFixedLabelsAreaHeight = 96.0;
const CGFloat kDesignWidth = 320.0;
const CGFloat kDesignHeight = 299.0;
const CGFloat kBadgeHeight = 34.0;
const CGFloat kSoldOutGBHeight = 50.0;

@interface ItemNode() <A_SNetworkImageNodeDelegate>

@property (nonatomic, strong) ItemViewModel *viewModel;

@property (nonatomic, strong) PlaceholderNetworkImageNode *dealImageView;

@property (nonatomic, strong) A_STextNode *titleLabel;
@property (nonatomic, strong) A_STextNode *firstInfoLabel;
@property (nonatomic, strong) A_STextNode *distanceLabel;
@property (nonatomic, strong) A_STextNode *secondInfoLabel;
@property (nonatomic, strong) A_STextNode *originalPriceLabel;
@property (nonatomic, strong) A_STextNode *finalPriceLabel;
@property (nonatomic, strong) A_STextNode *soldOutLabelFlat;
@property (nonatomic, strong) A_SDisplayNode *soldOutLabelBackground;
@property (nonatomic, strong) A_SDisplayNode *soldOutOverlay;
@property (nonatomic, strong) A_STextNode *badge;

@end

@implementation ItemNode
@dynamic viewModel;

- (instancetype)initWithViewModel:(ItemViewModel *)viewModel
{
  self = [super init];
  if (self != nil) {
    self.viewModel = viewModel;
    [self setup];
    [self updateLabels];
    [self updateBackgroundColor];
    
    A_SSetDebugName(self, @"Item #%zd", viewModel.identifier);
    self.accessibilityIdentifier = viewModel.titleText;
  }
  return self;
}

+ (BOOL)isRTL {
  return [UIApplication sharedApplication].userInterfaceLayoutDirection == UIUserInterfaceLayoutDirectionRightToLeft;
}

- (void)setup {
  self.dealImageView = [[PlaceholderNetworkImageNode alloc] init];
  self.dealImageView.delegate = self;
  self.dealImageView.placeholderEnabled = YES;
  self.dealImageView.placeholderImageOverride = [ItemStyles placeholderImage];
  self.dealImageView.defaultImage = [ItemStyles placeholderImage];
  self.dealImageView.contentMode = UIViewContentModeScaleToFill;
  self.dealImageView.placeholderFadeDuration = 0.0;
  self.dealImageView.layerBacked = YES;
  
  self.titleLabel = [[A_STextNode alloc] init];
  self.titleLabel.maximumNumberOfLines = 2;
  self.titleLabel.style.alignSelf = A_SStackLayoutAlignSelfStart;
  self.titleLabel.style.flexGrow = 1.0;
  self.titleLabel.layerBacked = YES;
  
  self.firstInfoLabel = [[A_STextNode alloc] init];
  self.firstInfoLabel.maximumNumberOfLines = 1;
  self.firstInfoLabel.layerBacked = YES;
  
  self.secondInfoLabel = [[A_STextNode alloc] init];
  self.secondInfoLabel.maximumNumberOfLines = 1;
  self.secondInfoLabel.layerBacked = YES;
  
  self.distanceLabel = [[A_STextNode alloc] init];
  self.distanceLabel.maximumNumberOfLines = 1;
  self.distanceLabel.layerBacked = YES;
  
  self.originalPriceLabel = [[A_STextNode alloc] init];
  self.originalPriceLabel.maximumNumberOfLines = 1;
  self.originalPriceLabel.layerBacked = YES;
  
  self.finalPriceLabel = [[A_STextNode alloc] init];
  self.finalPriceLabel.maximumNumberOfLines = 1;
  self.finalPriceLabel.layerBacked = YES;
  
  self.badge = [[A_STextNode alloc] init];
  self.badge.hidden = YES;
  self.badge.layerBacked = YES;
  
  self.soldOutLabelFlat = [[A_STextNode alloc] init];
  self.soldOutLabelFlat.layerBacked = YES;

  self.soldOutLabelBackground = [[A_SDisplayNode alloc] init];
  self.soldOutLabelBackground.style.width = A_SDimensionMakeWithFraction(1.0);
  self.soldOutLabelBackground.style.height = A_SDimensionMakeWithPoints(kSoldOutGBHeight);
  self.soldOutLabelBackground.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.9];
  self.soldOutLabelBackground.style.flexGrow = 1.0;
  self.soldOutLabelBackground.layerBacked = YES;
  
  self.soldOutOverlay = [[A_SDisplayNode alloc] init];
  self.soldOutOverlay.style.flexGrow = 1.0;
  self.soldOutOverlay.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.5];
  self.soldOutOverlay.layerBacked = YES;
  
  [self addSubnode:self.dealImageView];
  [self addSubnode:self.titleLabel];
  [self addSubnode:self.firstInfoLabel];
  [self addSubnode:self.secondInfoLabel];
  [self addSubnode:self.originalPriceLabel];
  [self addSubnode:self.finalPriceLabel];
  [self addSubnode:self.distanceLabel];
  [self addSubnode:self.badge];
  
  [self addSubnode:self.soldOutLabelBackground];
  [self addSubnode:self.soldOutLabelFlat];
  [self addSubnode:self.soldOutOverlay];
  self.soldOutOverlay.hidden = YES;
  self.soldOutLabelBackground.hidden = YES;
  self.soldOutLabelFlat.hidden = YES;
  
  if ([ItemNode isRTL]) {
    self.titleLabel.style.alignSelf = A_SStackLayoutAlignSelfEnd;
    self.firstInfoLabel.style.alignSelf = A_SStackLayoutAlignSelfEnd;
    self.distanceLabel.style.alignSelf = A_SStackLayoutAlignSelfEnd;
    self.secondInfoLabel.style.alignSelf = A_SStackLayoutAlignSelfEnd;
    self.originalPriceLabel.style.alignSelf = A_SStackLayoutAlignSelfStart;
    self.finalPriceLabel.style.alignSelf = A_SStackLayoutAlignSelfStart;
  } else {
    self.firstInfoLabel.style.alignSelf = A_SStackLayoutAlignSelfStart;
    self.distanceLabel.style.alignSelf = A_SStackLayoutAlignSelfStart;
    self.secondInfoLabel.style.alignSelf = A_SStackLayoutAlignSelfStart;
    self.originalPriceLabel.style.alignSelf = A_SStackLayoutAlignSelfEnd;
    self.finalPriceLabel.style.alignSelf = A_SStackLayoutAlignSelfEnd;
  }
}

- (void)updateLabels {
  // Set Title text
  if (self.viewModel.titleText) {
    self.titleLabel.attributedText = [[NSAttributedString alloc] initWithString:self.viewModel.titleText attributes:[ItemStyles titleStyle]];
  }
  if (self.viewModel.firstInfoText) {
    self.firstInfoLabel.attributedText = [[NSAttributedString alloc] initWithString:self.viewModel.firstInfoText attributes:[ItemStyles subtitleStyle]];
  }
  
  if (self.viewModel.secondInfoText) {
    self.secondInfoLabel.attributedText = [[NSAttributedString alloc] initWithString:self.viewModel.secondInfoText attributes:[ItemStyles secondInfoStyle]];
  }
  if (self.viewModel.originalPriceText) {
    self.originalPriceLabel.attributedText = [[NSAttributedString alloc] initWithString:self.viewModel.originalPriceText attributes:[ItemStyles originalPriceStyle]];
  }
  if (self.viewModel.finalPriceText) {
        self.finalPriceLabel.attributedText = [[NSAttributedString alloc] initWithString:self.viewModel.finalPriceText attributes:[ItemStyles finalPriceStyle]];
  }
  if (self.viewModel.distanceLabelText) {
    NSString *format = [ItemNode isRTL] ? @"%@ •" : @"• %@";
    NSString *distanceText = [NSString stringWithFormat:format, self.viewModel.distanceLabelText];
    
    self.distanceLabel.attributedText = [[NSAttributedString alloc] initWithString:distanceText attributes:[ItemStyles distanceStyle]];
  }
  
  BOOL isSoldOut = self.viewModel.soldOutText != nil;
  
  if (isSoldOut) {
    NSString *soldOutText = self.viewModel.soldOutText;
    self.soldOutLabelFlat.attributedText = [[NSAttributedString alloc] initWithString:soldOutText attributes:[ItemStyles soldOutStyle]];
  }
  self.soldOutOverlay.hidden = !isSoldOut;
  self.soldOutLabelFlat.hidden = !isSoldOut;
  self.soldOutLabelBackground.hidden = !isSoldOut;
  
  BOOL hasBadge = self.viewModel.badgeText != nil;
  if (hasBadge) {
    self.badge.attributedText = [[NSAttributedString alloc] initWithString:self.viewModel.badgeText attributes:[ItemStyles badgeStyle]];
    self.badge.backgroundColor = [ItemStyles badgeColor];
  }
  self.badge.hidden = !hasBadge;
}

- (void)updateBackgroundColor
{
  if (self.highlighted) {
    self.backgroundColor = [[UIColor grayColor] colorWithAlphaComponent:0.3];
  } else if (self.selected) {
    self.backgroundColor = [UIColor lightGrayColor];
  } else {
    self.backgroundColor = [UIColor whiteColor];
  }
}

- (void)imageNode:(A_SNetworkImageNode *)imageNode didLoadImage:(UIImage *)image {
}

- (void)setSelected:(BOOL)selected
{
  [super setSelected:selected];
  [self updateBackgroundColor];
}

- (void)setHighlighted:(BOOL)highlighted
{
  [super setHighlighted:highlighted];
  [self updateBackgroundColor];
}

#pragma mark - superclass

- (void)displayWillStart {
  [super displayWillStart];
  [self didEnterPreloadState];
}

- (void)didEnterPreloadState {
  [super didEnterPreloadState];
  if (self.viewModel) {
    [self loadImage];
  }
}


- (A_SLayoutSpec *)layoutSpecThatFits:(A_SSizeRange)constrainedSize {

  A_SLayoutSpec *textSpec = [self textSpec];
  A_SLayoutSpec *imageSpec = [self imageSpecWithSize:constrainedSize];
  A_SOverlayLayoutSpec *soldOutOverImage = [A_SOverlayLayoutSpec overlayLayoutSpecWithChild:imageSpec overlay:[self soldOutLabelSpec]];
  
  NSArray *stackChildren = @[soldOutOverImage, textSpec];
  
  A_SStackLayoutSpec *mainStack = [A_SStackLayoutSpec stackLayoutSpecWithDirection:A_SStackLayoutDirectionVertical spacing:0.0 justifyContent:A_SStackLayoutJustifyContentStart alignItems:A_SStackLayoutAlignItemsStretch children:stackChildren];
  
  A_SOverlayLayoutSpec *soldOutOverlay = [A_SOverlayLayoutSpec overlayLayoutSpecWithChild:mainStack overlay:self.soldOutOverlay];
  
  return soldOutOverlay;
}

- (A_SLayoutSpec *)textSpec {
  CGFloat kInsetHorizontal = 16.0;
  CGFloat kInsetTop = 6.0;
  CGFloat kInsetBottom = 0.0;
  
  UIEdgeInsets textInsets = UIEdgeInsetsMake(kInsetTop, kInsetHorizontal, kInsetBottom, kInsetHorizontal);
  
  A_SLayoutSpec *verticalSpacer = [[A_SLayoutSpec alloc] init];
  verticalSpacer.style.flexGrow = 1.0;
  
  A_SLayoutSpec *horizontalSpacer1 = [[A_SLayoutSpec alloc] init];
  horizontalSpacer1.style.flexGrow = 1.0;
  
  A_SLayoutSpec *horizontalSpacer2 = [[A_SLayoutSpec alloc] init];
  horizontalSpacer2.style.flexGrow = 1.0;
  
  NSArray *info1Children = @[self.firstInfoLabel, self.distanceLabel, horizontalSpacer1, self.originalPriceLabel];
  NSArray *info2Children = @[self.secondInfoLabel, horizontalSpacer2, self.finalPriceLabel];
  if ([ItemNode isRTL]) {
    info1Children = [[info1Children reverseObjectEnumerator] allObjects];
    info2Children = [[info2Children reverseObjectEnumerator] allObjects];
  }
  
  A_SStackLayoutSpec *info1Stack = [A_SStackLayoutSpec stackLayoutSpecWithDirection:A_SStackLayoutDirectionHorizontal spacing:1.0 justifyContent:A_SStackLayoutJustifyContentStart alignItems:A_SStackLayoutAlignItemsBaselineLast children:info1Children];
  
  A_SStackLayoutSpec *info2Stack = [A_SStackLayoutSpec stackLayoutSpecWithDirection:A_SStackLayoutDirectionHorizontal spacing:0.0 justifyContent:A_SStackLayoutJustifyContentCenter alignItems:A_SStackLayoutAlignItemsBaselineLast children:info2Children];
  
  A_SStackLayoutSpec *textStack = [A_SStackLayoutSpec stackLayoutSpecWithDirection:A_SStackLayoutDirectionVertical spacing:0.0 justifyContent:A_SStackLayoutJustifyContentEnd alignItems:A_SStackLayoutAlignItemsStretch children:@[self.titleLabel, verticalSpacer, info1Stack, info2Stack]];
  
  A_SInsetLayoutSpec *textWrapper = [A_SInsetLayoutSpec insetLayoutSpecWithInsets:textInsets child:textStack];
  textWrapper.style.flexGrow = 1.0;
  
  return textWrapper;
}

- (A_SLayoutSpec *)imageSpecWithSize:(A_SSizeRange)constrainedSize {
  CGFloat imageRatio = [self imageRatioFromSize:constrainedSize.max];
  
  A_SRatioLayoutSpec *imagePlace = [A_SRatioLayoutSpec ratioLayoutSpecWithRatio:imageRatio child:self.dealImageView];
  
  self.badge.style.layoutPosition = CGPointMake(0, constrainedSize.max.height - kFixedLabelsAreaHeight - kBadgeHeight);
  self.badge.style.height = A_SDimensionMakeWithPoints(kBadgeHeight);
  A_SAbsoluteLayoutSpec *badgePosition = [A_SAbsoluteLayoutSpec absoluteLayoutSpecWithChildren:@[self.badge]];
  
  A_SOverlayLayoutSpec *badgeOverImage = [A_SOverlayLayoutSpec overlayLayoutSpecWithChild:imagePlace overlay:badgePosition];
  badgeOverImage.style.flexGrow = 1.0;
  
  return badgeOverImage;
}

- (A_SLayoutSpec *)soldOutLabelSpec {
  A_SCenterLayoutSpec *centerSoldOutLabel = [A_SCenterLayoutSpec centerLayoutSpecWithCenteringOptions:A_SCenterLayoutSpecCenteringXY sizingOptions:A_SCenterLayoutSpecSizingOptionMinimumXY child:self.soldOutLabelFlat];
  A_SCenterLayoutSpec *centerSoldOut = [A_SCenterLayoutSpec centerLayoutSpecWithCenteringOptions:A_SCenterLayoutSpecCenteringXY sizingOptions:A_SCenterLayoutSpecSizingOptionDefault child:self.soldOutLabelBackground];
  A_SBackgroundLayoutSpec *soldOutLabelOverBackground = [A_SBackgroundLayoutSpec backgroundLayoutSpecWithChild:centerSoldOutLabel background:centerSoldOut];
  return soldOutLabelOverBackground;
}


+ (CGSize)sizeForWidth:(CGFloat)width {
  CGFloat height = [self scaledHeightForPreferredSize:[self preferredViewSize] scaledWidth:width];
  return CGSizeMake(width, height);
}


+ (CGSize)preferredViewSize {
  return CGSizeMake(kDesignWidth, kDesignHeight);
}

+ (CGFloat)scaledHeightForPreferredSize:(CGSize)preferredSize scaledWidth:(CGFloat)scaledWidth {
  CGFloat scale = scaledWidth / kDesignWidth;
  CGFloat scaledHeight = ceilf(scale * (kDesignHeight - kFixedLabelsAreaHeight)) + kFixedLabelsAreaHeight;
  
  return scaledHeight;
}

#pragma mark - view operations

- (CGFloat)imageRatioFromSize:(CGSize)size {
  CGFloat imageHeight = size.height - kFixedLabelsAreaHeight;
  CGFloat imageRatio = imageHeight / size.width;
  
  return imageRatio;
}

- (CGSize)imageSize {
  if (!CGSizeEqualToSize(self.dealImageView.frame.size, CGSizeZero)) {
    return self.dealImageView.frame.size;
  } else if (!CGSizeEqualToSize(self.calculatedSize, CGSizeZero)) {
    CGFloat imageRatio = [self imageRatioFromSize:self.calculatedSize];
    CGFloat imageWidth = self.calculatedSize.width;
    return CGSizeMake(imageWidth, imageRatio * imageWidth);
  } else {
    return CGSizeZero;
  }
}

- (void)loadImage {
  CGSize imageSize = [self imageSize];
  if (CGSizeEqualToSize(CGSizeZero, imageSize)) {
    return;
  }
  
  NSURL *url = [self.viewModel imageURLWithSize:imageSize];
  
  // if we're trying to set the deal image to what it already was, skip the work
  if ([[url absoluteString] isEqualToString:[self.dealImageView.URL absoluteString]]) {
    return;
  }
  
  // Clear the flag that says we've loaded our image
  [self.dealImageView setURL:url];
}

@end

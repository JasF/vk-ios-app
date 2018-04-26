//
//  MapHandlerNode.m
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

#import "MapHandlerNode.h"
#import "CustomMapAnnotation.h"

#import <Async_DisplayKit/Async_DisplayKit.h>
#import <Async_DisplayKit/UIImage+A_SConvenience.h>

@interface MapHandlerNode () <A_SEditableTextNodeDelegate, MKMapViewDelegate>

@property (nonatomic, strong) A_SEditableTextNode *latEditableNode;
@property (nonatomic, strong) A_SEditableTextNode *lonEditableNode;
@property (nonatomic, strong) A_SEditableTextNode *deltaLatEditableNode;
@property (nonatomic, strong) A_SEditableTextNode *deltaLonEditableNode;
@property (nonatomic, strong) A_SButtonNode *updateRegionButton;
@property (nonatomic, strong) A_SButtonNode *liveMapToggleButton;
@property (nonatomic, strong) A_SMapNode *mapNode;

@end

@implementation MapHandlerNode

#pragma mark - Lifecycle

- (instancetype)init
{
  if (!(self = [super init]))
    return nil;
  
  self.automaticallyManagesSubnodes = YES;
  
  _mapNode = [[A_SMapNode alloc] init];
  _mapNode.mapDelegate = self;

  _latEditableNode      = [[A_SEditableTextNode alloc] init];
  _lonEditableNode      = [[A_SEditableTextNode alloc] init];
  _deltaLatEditableNode = [[A_SEditableTextNode alloc] init];
  _deltaLonEditableNode = [[A_SEditableTextNode alloc] init];

  _updateRegionButton  = [[A_SButtonNode alloc] init];
  _liveMapToggleButton = [[A_SButtonNode alloc] init];
  
  UIImage *backgroundImage = [UIImage as_resizableRoundedImageWithCornerRadius:5
                                                                   cornerColor:[UIColor whiteColor]
                                                                     fillColor:[UIColor lightGrayColor]];
  
  UIImage *backgroundHiglightedImage = [UIImage as_resizableRoundedImageWithCornerRadius:5
                                                                             cornerColor:[UIColor whiteColor]
                                                                               fillColor:[[UIColor lightGrayColor] colorWithAlphaComponent:0.4]
                                                                             borderColor:[UIColor lightGrayColor]
                                                                             borderWidth:2.0];
  
  [_updateRegionButton setBackgroundImage:backgroundImage forState:UIControlStateNormal];
  [_updateRegionButton setBackgroundImage:backgroundHiglightedImage forState:UIControlStateHighlighted];
  
  [_liveMapToggleButton setBackgroundImage:backgroundImage forState:UIControlStateNormal];
  [_liveMapToggleButton setBackgroundImage:backgroundHiglightedImage forState:UIControlStateHighlighted];
  
  _updateRegionButton.contentEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5);
  [_updateRegionButton setTitle:@"Update Region" withFont:nil withColor:[UIColor blueColor] forState:UIControlStateNormal];
  
  [_updateRegionButton addTarget:self action:@selector(updateRegion) forControlEvents:A_SControlNodeEventTouchUpInside];
  
  [_liveMapToggleButton setTitle:[self liveMapStr] withFont:nil withColor:[UIColor blueColor] forState:UIControlStateNormal];
  
  [_liveMapToggleButton addTarget:self action:@selector(toggleLiveMap) forControlEvents:A_SControlNodeEventTouchUpInside];
 
  return self;
}

- (void)didLoad
{
  [super didLoad];

  [self configureEditableNodes:_latEditableNode];
  [self configureEditableNodes:_lonEditableNode];
  [self configureEditableNodes:_deltaLatEditableNode];
  [self configureEditableNodes:_deltaLonEditableNode];
  
  [self updateLocationTextWithMKCoordinateRegion:_mapNode.region];
  
  // avoiding retain cycles
  __weak MapHandlerNode *weakSelf = self;
  
  self.mapNode.imageForStaticMapAnnotationBlock = ^UIImage *(id<MKAnnotation> annotation, CGPoint *centerOffset){
    MapHandlerNode *grabbedSelf = weakSelf;
    if (grabbedSelf) {
      if ([annotation isKindOfClass:[CustomMapAnnotation class]]) {
        CustomMapAnnotation *customAnnotation = (CustomMapAnnotation *)annotation;
        return customAnnotation.image;
      }
    }
    return nil;
  };
  
  [self addAnnotations];
}

/** 
 * ------------------------------------A_SStackLayoutSpec-----------------------------------
 * |  ---------------------------------A_SInsetLayoutSpec--------------------------------  |
 * |  |  ------------------------------A_SStackLayoutSpec-----------------------------  |  |
 * |  |  |  ---------------------------A_SStackLayoutSpec--------------------------  |  |  |
 * |  |  |  |  -----------------A_SStackLayoutSpec----------------                |  |  |  |
 * |  |  |  |  |  --------------A_SStackLayoutSpec-------------  |                |  |  |  |
 * |  |  |  |  |  |  A_SEditableTextNode  A_SEditableTextNode  |  |                |  |  |  |
 * |  |  |  |  |  --------------------------------------------  |                |  |  |  |
 * |  |  |  |  |  --------------A_SStackLayoutSpec-------------  |  A_SButtonNode  |  |  |  |
 * |  |  |  |  |  |  A_SEditableTextNode  A_SEditableTextNode  |  |                |  |  |  |
 * |  |  |  |  |  --------------------------------------------  |                |  |  |  |
 * |  |  |  |  --------------------------------------------------                |  |  |  |
 * |  |  |  ----------------------------------------------------------------------  |  |  |
 * |  |  |                               A_SButtonNode                               |  |  |
 * |  |  ----------------------------------------------------------------------------  |  |
 * |  ----------------------------------------------------------------------------------  |
 * |                                       A_SMapNode                                      |
 * ----------------------------------------------------------------------------------------
 *
 *  This diagram was created by setting a breakpoint on the returned `layoutSpec`
 *  and calling "po [layoutSpec asciiArtString]" in the debugger.
 */
#define SPACING 5
#define HEIGHT 30
- (A_SLayoutSpec *)layoutSpecThatFits:(A_SSizeRange)constrainedSize
{
  _latEditableNode.style.width      = A_SDimensionMake(@"50%");
  _lonEditableNode.style.width      = A_SDimensionMake(@"50%");
  _deltaLatEditableNode.style.width = A_SDimensionMake(@"50%");
  _deltaLonEditableNode.style.width = A_SDimensionMake(@"50%");

  _liveMapToggleButton.style.maxHeight = A_SDimensionMake(HEIGHT);
  
  _mapNode.style.flexGrow = 1.0;

  A_SStackLayoutSpec *lonlatSpec = [A_SStackLayoutSpec stackLayoutSpecWithDirection:A_SStackLayoutDirectionHorizontal
                                                                          spacing:SPACING
                                                                   justifyContent:A_SStackLayoutJustifyContentStart
                                                                       alignItems:A_SStackLayoutAlignItemsCenter
                                                                         children:@[_latEditableNode, _lonEditableNode]];

  A_SStackLayoutSpec *deltaLonlatSpec = [A_SStackLayoutSpec stackLayoutSpecWithDirection:A_SStackLayoutDirectionHorizontal
                                                                               spacing:SPACING
                                                                        justifyContent:A_SStackLayoutJustifyContentSpaceBetween
                                                                            alignItems:A_SStackLayoutAlignItemsCenter
                                                                              children:@[_deltaLatEditableNode, _deltaLonEditableNode]];

  A_SStackLayoutSpec *lonlatConfigSpec = [A_SStackLayoutSpec stackLayoutSpecWithDirection:A_SStackLayoutDirectionVertical
                                                                                spacing:SPACING
                                                                         justifyContent:A_SStackLayoutJustifyContentStart
                                                                             alignItems:A_SStackLayoutAlignItemsStretch
                                                                               children:@[lonlatSpec, deltaLonlatSpec]];
  
  lonlatConfigSpec.style.flexGrow = 1.0;

  A_SStackLayoutSpec *dashboardSpec = [A_SStackLayoutSpec stackLayoutSpecWithDirection:A_SStackLayoutDirectionHorizontal
                                                                             spacing:SPACING
                                                                      justifyContent:A_SStackLayoutJustifyContentStart
                                                                          alignItems:A_SStackLayoutAlignItemsStretch
                                                                            children:@[lonlatConfigSpec, _updateRegionButton]];
  
  A_SStackLayoutSpec *headerVerticalStack = [A_SStackLayoutSpec stackLayoutSpecWithDirection:A_SStackLayoutDirectionVertical
                                                                                   spacing:SPACING
                                                                            justifyContent:A_SStackLayoutJustifyContentStart
                                                                                alignItems:A_SStackLayoutAlignItemsStretch
                                                                                  children:@[dashboardSpec, _liveMapToggleButton]];
  
  dashboardSpec.style.flexGrow = 1.0;

  A_SInsetLayoutSpec *insetSpec = [A_SInsetLayoutSpec insetLayoutSpecWithInsets:UIEdgeInsetsMake(40, 10, 0, 10)
                                                                        child:headerVerticalStack];
  
  A_SStackLayoutSpec *layoutSpec = [A_SStackLayoutSpec stackLayoutSpecWithDirection:A_SStackLayoutDirectionVertical
                                                                          spacing:SPACING
                                                                   justifyContent:A_SStackLayoutJustifyContentStart
                                                                       alignItems:A_SStackLayoutAlignItemsStretch
                                                                         children:@[insetSpec, _mapNode]];
  
  return layoutSpec;
}

#pragma mark - Button Actions

- (void)updateRegion
{
  NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
  f.numberStyle = NSNumberFormatterDecimalStyle;

  double const lat = [f numberFromString:_latEditableNode.attributedText.string].doubleValue;
  double const lon = [f numberFromString:_lonEditableNode.attributedText.string].doubleValue;
  double const deltaLat = [f numberFromString:_deltaLatEditableNode.attributedText.string].doubleValue;
  double const deltaLon = [f numberFromString:_deltaLonEditableNode.attributedText.string].doubleValue;

  // TODO: check for valid latitude / longitude coordinates
    MKCoordinateRegion region = MKCoordinateRegionMake(CLLocationCoordinate2DMake(lat, lon),
                                                     MKCoordinateSpanMake(deltaLat, deltaLon));

  _mapNode.region = region;
}

- (void)toggleLiveMap
{
  _mapNode.liveMap = !_mapNode.liveMap;
  NSString * const liveMapStr = [self liveMapStr];
  [_liveMapToggleButton setTitle:liveMapStr withFont:nil withColor:[UIColor blueColor] forState:UIControlStateNormal];
  [_liveMapToggleButton setTitle:liveMapStr withFont:[UIFont systemFontOfSize:14] withColor:[UIColor blueColor] forState:UIControlStateHighlighted];
}

- (void)updateLocationTextWithMKCoordinateRegion:(MKCoordinateRegion)region
{
  _latEditableNode.attributedText = [self attributedStringFromFloat:region.center.latitude];
  _lonEditableNode.attributedText = [self attributedStringFromFloat:region.center.longitude];
  _deltaLatEditableNode.attributedText = [self attributedStringFromFloat:region.span.latitudeDelta];
  _deltaLonEditableNode.attributedText = [self attributedStringFromFloat:region.span.longitudeDelta];
}

#pragma mark - Helper Methods

- (NSAttributedString *)attributedStringFromFloat:(CGFloat)value
{
  return [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%0.3f", value]];
}

- (void)addAnnotations {
  
  MKPointAnnotation *brno = [MKPointAnnotation new];
  brno.coordinate = CLLocationCoordinate2DMake(49.2002211, 16.6078411);
  brno.title = @"Brno City";
  
  CustomMapAnnotation *atlantic = [CustomMapAnnotation new];
  atlantic.coordinate = CLLocationCoordinate2DMake(38.6442228, -29.9956942);
  atlantic.title = @"Atlantic Ocean";
  atlantic.image = [UIImage imageNamed:@"Water"];
  
  CustomMapAnnotation *kilimanjaro = [CustomMapAnnotation new];
  kilimanjaro.coordinate = CLLocationCoordinate2DMake(-3.075833, 37.353333);
  kilimanjaro.title = @"Kilimanjaro";
  kilimanjaro.image = [UIImage imageNamed:@"Hill"];
  
  CustomMapAnnotation *mtblanc = [CustomMapAnnotation new];
  mtblanc.coordinate = CLLocationCoordinate2DMake(45.8325, 6.864444);
  mtblanc.title = @"Mont Blanc";
  mtblanc.image = [UIImage imageNamed:@"Hill"];
  
  self.mapNode.annotations = @[brno, atlantic, kilimanjaro, mtblanc];
}

-(NSString *)liveMapStr
{
  return _mapNode.liveMap ? @"Live Map is ON" : @"Live Map is OFF";
}

-(void)configureEditableNodes:(A_SEditableTextNode *)node
{
  node.returnKeyType = node == _deltaLonEditableNode ? UIReturnKeyDone : UIReturnKeyNext;
  node.delegate = self;
}

#pragma mark - A_SEditableTextNodeDelegate

- (BOOL)editableTextNode:(A_SEditableTextNode *)editableTextNode shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
  if([text isEqualToString:@"\n"]) {
    if(editableTextNode == _latEditableNode)
      [_lonEditableNode becomeFirstResponder];
    else if(editableTextNode == _lonEditableNode)
      [_deltaLatEditableNode becomeFirstResponder];
    else if(editableTextNode == _deltaLatEditableNode)
      [_deltaLonEditableNode becomeFirstResponder];
    else if(editableTextNode == _deltaLonEditableNode) {
      [_deltaLonEditableNode resignFirstResponder];
      [self updateRegion];
    }
    return NO;
  }

  NSMutableCharacterSet * s = [NSMutableCharacterSet characterSetWithCharactersInString:@".-"];
  [s formUnionWithCharacterSet:[NSCharacterSet decimalDigitCharacterSet]];
  [s invert];

  NSRange r = [text rangeOfCharacterFromSet:s];
  if(r.location != NSNotFound) {
    return NO;
  }

  if([editableTextNode.attributedText.string rangeOfString:@"."].location != NSNotFound &&
      [text rangeOfString:@"."].location != NSNotFound) {
    return NO;
  }

  if ([editableTextNode.attributedText.string rangeOfString:@"-"].location != NSNotFound &&
      [text rangeOfString:@"-"].location != NSNotFound &&
      range.location > 0) {
    return NO;
  }

  return YES;
}

- (MKAnnotationView *)annotationViewForAnnotation:(id<MKAnnotation>)annotation
{
  MKAnnotationView *av;
  
  if ([annotation isKindOfClass:[CustomMapAnnotation class]]) {
    av = [[MKAnnotationView alloc] init];
    av.centerOffset = CGPointMake(21, 21);
    av.image = [(CustomMapAnnotation *)annotation image];
  } else {
    av = [[MKPinAnnotationView alloc] initWithAnnotation:nil reuseIdentifier:@""];
  }

  av.opaque = NO;
  
  return av;
}

#pragma mark - MKMapViewDelegate

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated
{
  [self updateLocationTextWithMKCoordinateRegion:mapView.region];
}

- (MKAnnotationView *)mapView:(MKMapView *)__unused mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
  return [self annotationViewForAnnotation:annotation];
}

@end

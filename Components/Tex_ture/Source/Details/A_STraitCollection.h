//
//  A_STraitCollection.h
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


#import <UIKit/UIKit.h>
#import <Async_DisplayKit/A_SBaseDefines.h>

@class A_STraitCollection;
@protocol A_SLayoutElement;
@protocol A_STraitEnvironment;

NS_ASSUME_NONNULL_BEGIN

A_SDISPLAYNODE_EXTERN_C_BEGIN

#pragma mark - A_SPrimitiveTraitCollection

typedef struct A_SPrimitiveTraitCollection {
  CGFloat displayScale;
  UIUserInterfaceSizeClass horizontalSizeClass;
  UIUserInterfaceIdiom userInterfaceIdiom;
  UIUserInterfaceSizeClass verticalSizeClass;
  UIForceTouchCapability forceTouchCapability;

  CGSize containerSize;
} A_SPrimitiveTraitCollection;

/**
 * Creates A_SPrimitiveTraitCollection with default values.
 */
extern A_SPrimitiveTraitCollection A_SPrimitiveTraitCollectionMakeDefault(void);

/**
 * Creates a A_SPrimitiveTraitCollection from a given UITraitCollection.
 */
extern A_SPrimitiveTraitCollection A_SPrimitiveTraitCollectionFromUITraitCollection(UITraitCollection *traitCollection);


/**
 * Compares two A_SPrimitiveTraitCollection to determine if they are the same.
 */
extern BOOL A_SPrimitiveTraitCollectionIsEqualToA_SPrimitiveTraitCollection(A_SPrimitiveTraitCollection lhs, A_SPrimitiveTraitCollection rhs);

/**
 * Returns a string representation of a A_SPrimitiveTraitCollection.
 */
extern NSString *NSStringFromA_SPrimitiveTraitCollection(A_SPrimitiveTraitCollection traits);

/**
 * This function will walk the layout element hierarchy and updates the layout element trait collection for every
 * layout element within the hierarchy.
 */
extern void A_STraitCollectionPropagateDown(id<A_SLayoutElement> element, A_SPrimitiveTraitCollection traitCollection);

A_SDISPLAYNODE_EXTERN_C_END

/**
 * Abstraction on top of UITraitCollection for propagation within Async_DisplayKit-Layout
 */
@protocol A_STraitEnvironment <NSObject>

/**
 * Returns a struct-representation of the environment's A_SEnvironmentDisplayTraits. This only exists as a internal
 * convenience method. Users should access the trait collections through the NSObject based asyncTraitCollection API
 */
- (A_SPrimitiveTraitCollection)primitiveTraitCollection;

/**
 * Sets a trait collection on this environment state.
 */
- (void)setPrimitiveTraitCollection:(A_SPrimitiveTraitCollection)traitCollection;

/**
 */
- (A_STraitCollection *)asyncTraitCollection;

@end

#define A_SPrimitiveTraitCollectionDefaults \
- (A_SPrimitiveTraitCollection)primitiveTraitCollection\
{\
  return _primitiveTraitCollection.load();\
}\
- (void)setPrimitiveTraitCollection:(A_SPrimitiveTraitCollection)traitCollection\
{\
  _primitiveTraitCollection = traitCollection;\
}\

#define A_SLayoutElementCollectionTableSetTraitCollection(lock) \
- (void)setPrimitiveTraitCollection:(A_SPrimitiveTraitCollection)traitCollection\
{\
  A_SDN::MutexLocker l(lock);\
\
  A_SPrimitiveTraitCollection oldTraits = self.primitiveTraitCollection;\
  [super setPrimitiveTraitCollection:traitCollection];\
\
  /* Extra Trait Collection Handling */\
\
  /* If the node is not loaded  yet don't do anything as otherwise the access of the view will trigger a load */\
  if (! self.isNodeLoaded) { return; }\
\
  A_SPrimitiveTraitCollection currentTraits = self.primitiveTraitCollection;\
  if (A_SPrimitiveTraitCollectionIsEqualToA_SPrimitiveTraitCollection(currentTraits, oldTraits) == NO) {\
    [self.dataController environmentDidChange];\
  }\
}\

#pragma mark - A_STraitCollection

A_S_SUBCLASSING_RESTRICTED
@interface A_STraitCollection : NSObject

@property (nonatomic, assign, readonly) CGFloat displayScale;
@property (nonatomic, assign, readonly) UIUserInterfaceSizeClass horizontalSizeClass;
@property (nonatomic, assign, readonly) UIUserInterfaceIdiom userInterfaceIdiom;
@property (nonatomic, assign, readonly) UIUserInterfaceSizeClass verticalSizeClass;
@property (nonatomic, assign, readonly) UIForceTouchCapability forceTouchCapability;
@property (nonatomic, assign, readonly) CGSize containerSize;

+ (A_STraitCollection *)traitCollectionWithA_SPrimitiveTraitCollection:(A_SPrimitiveTraitCollection)traits;

+ (A_STraitCollection *)traitCollectionWithUITraitCollection:(UITraitCollection *)traitCollection
                                              containerSize:(CGSize)windowSize;


+ (A_STraitCollection *)traitCollectionWithDisplayScale:(CGFloat)displayScale
                                    userInterfaceIdiom:(UIUserInterfaceIdiom)userInterfaceIdiom
                                   horizontalSizeClass:(UIUserInterfaceSizeClass)horizontalSizeClass
                                     verticalSizeClass:(UIUserInterfaceSizeClass)verticalSizeClass
                                  forceTouchCapability:(UIForceTouchCapability)forceTouchCapability
                                         containerSize:(CGSize)windowSize;


- (A_SPrimitiveTraitCollection)primitiveTraitCollection;
- (BOOL)isEqualToTraitCollection:(A_STraitCollection *)traitCollection;

@end

NS_ASSUME_NONNULL_END

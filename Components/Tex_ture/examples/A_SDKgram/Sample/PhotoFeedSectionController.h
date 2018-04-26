//
//  PhotoFeedSectionController.h
//  Sample
//
//  Created by Adlai Holler on 12/29/16.
//  Copyright © 2016 Facebook. All rights reserved.
//

#import <IGListKit/IGListKit.h>
#import <Async_DisplayKit/Async_DisplayKit.h>
#import "RefreshingSectionControllerType.h"
#import "A_SCollectionSectionController.h"

@class PhotoFeedModel;

NS_ASSUME_NONNULL_BEGIN

@interface PhotoFeedSectionController : A_SCollectionSectionController <A_SSectionController, RefreshingSectionControllerType>

@property (nonatomic, strong, nullable) PhotoFeedModel *photoFeed;

@end

NS_ASSUME_NONNULL_END

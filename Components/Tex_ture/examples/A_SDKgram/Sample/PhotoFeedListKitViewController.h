//
//  PhotoFeedListKitViewController.h
//  Sample
//
//  Created by Adlai Holler on 12/29/16.
//  Copyright © 2016 Facebook. All rights reserved.
//

#import <Async_DisplayKit/Async_DisplayKit.h>
#import "PhotoFeedControllerProtocol.h"

@interface PhotoFeedListKitViewController<A_SCollectionNode> : A_SViewController <PhotoFeedControllerProtocol>

@end

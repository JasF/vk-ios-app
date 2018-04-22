//
//  MenuScreenViewModelImpl.h
//  vk
//
//  Created by Jasf on 17.04.2018.
//  Copyright © 2018 Ebay Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MenuScreenViewModel.h"
#import "HandlersFactory.h"

@protocol PyMenuScreenViewModel
- (void)newsTapped;
- (void)dialogsTapped;
- (void)friendsTapped;
@end

@interface MenuScreenViewModelImpl : NSObject <MenuScreenViewModel>
- (id)initWithHandlersFactory:(id<HandlersFactory>)handlersFactory;
@end

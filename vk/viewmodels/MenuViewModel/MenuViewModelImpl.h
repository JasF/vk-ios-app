//
//  MenuViewModelImpl.h
//  vk
//
//  Created by Jasf on 17.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MenuViewModel.h"
#import "HandlersFactory.h"

@protocol PyMenuViewModel
- (void)lentaTapped;
- (void)newsTapped;
- (void)dialogsTapped;
- (void)friendsTapped;
- (void)photosTapped;
- (void)answersTapped;
- (void)groupsTapped;
@end

@interface MenuViewModelImpl : NSObject <MenuViewModel>
- (id)initWithHandlersFactory:(id<HandlersFactory>)handlersFactory;
@end

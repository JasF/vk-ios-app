//
//  AnswersViewModelImpl.h
//  vk
//
//  Created by Jasf on 24.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HandlersFactory.h"
#import "AnswersService.h"
#import "AnswersViewModel.h"

@protocol PyAnswersViewModel <NSObject>
- (NSDictionary *)getAnswers:(NSNumber *)offset;
- (void)menuTapped;
@end

@interface AnswersViewModelImpl : NSObject <AnswersViewModel>
- (instancetype)initWithHandlersFactory:(id<HandlersFactory>)handlersFactory
                         answersService:(id<AnswersService>)answersService;
@end

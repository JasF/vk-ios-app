//
//  AnswersViewModelImpl.m
//  vk
//
//  Created by Jasf on 24.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "AnswersViewModelImpl.h"

@interface AnswersViewModelImpl ()
@property (strong) id<PyAnswersViewModel> handler;
@property (strong) id<AnswersService> answersService;
@end

@implementation AnswersViewModelImpl

#pragma mark - Initialization
- (instancetype)initWithHandlersFactory:(id<HandlersFactory>)handlersFactory
                         answersService:(id<AnswersService>)answersService {
    NSCParameterAssert(handlersFactory);
    NSCParameterAssert(answersService);
    if (self) {
        _handler = [handlersFactory answersViewModelHandler];
        _answersService = answersService;
    }
    return self;
}

#pragma mark -
- (void)getAnswers:(NSInteger)offset
        completion:(void(^)(NSArray *answers))completion {
    dispatch_python(^{
        NSDictionary *data = [self.handler getAnswers:@(offset)];
        NSArray *result = [self.answersService parse:data];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion(result);
            }
        });
    });
}

- (void)menuTapped {
    dispatch_python(^{
        [self.handler menuTapped];
    });
}

@end

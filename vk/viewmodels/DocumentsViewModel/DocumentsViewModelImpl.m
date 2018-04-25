//
//  DocumentsViewModelImpl.m
//  vk
//
//  Created by Jasf on 25.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "DocumentsViewModelImpl.h"

@interface DocumentsViewModelImpl () <DocumentsViewModel>
@property (strong) id<PyDocumentsViewModel> handler;
@property (strong) id<DocumentsService> documentsService;
@end

@implementation DocumentsViewModelImpl

#pragma mark - Initialization
- (instancetype)initWithHandlersFactory:(id<HandlersFactory>)handlersFactory
                          documentsService:(id<DocumentsService>)documentsService
                                ownerId:(NSNumber *)ownerId {
    NSCParameterAssert(handlersFactory);
    NSCParameterAssert(documentsService);
    NSCParameterAssert(ownerId);
    if (self) {
        _handler = [handlersFactory documentsViewModelHandler:ownerId.integerValue];
        _documentsService = documentsService;
    }
    return self;
}

#pragma mark - DocumentsViewModel
- (void)getDocuments:(NSInteger)offset completion:(void(^)(NSArray *documents))completion {
    dispatch_python(^{
        NSDictionary *response = [self.handler getDocuments:@(offset)];
        NSArray *objects = [self.documentsService parse:response];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion(objects);
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


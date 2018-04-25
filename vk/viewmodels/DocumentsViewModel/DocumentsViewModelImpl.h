//
//  DocumentsViewModelImpl.h
//  vk
//
//  Created by Jasf on 25.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "DocumentsViewModel.h"
#import "DocumentsService.h"
#import "HandlersFactory.h"

@protocol PyDocumentsViewModel <NSObject>
- (NSDictionary *)getDocuments:(NSNumber *)offset;
- (void)menuTapped;
@end

@interface DocumentsViewModelImpl : NSObject <DocumentsViewModel>
- (instancetype)initWithHandlersFactory:(id<HandlersFactory>)handlersFactory
                          documentsService:(id<DocumentsService>)documentsService
                                ownerId:(NSNumber *)ownerId;
@end

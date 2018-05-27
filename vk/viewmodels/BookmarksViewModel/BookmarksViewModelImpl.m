//
//  BookmarksViewModelImpl.m
//  vk
//
//  Created by Jasf on 25.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "BookmarksViewModelImpl.h"
#import "Oxy_Feed-Swift.h"

@interface BookmarksViewModelImpl () <BookmarksViewModel>
@property (strong) id<PyBookmarksViewModel> handler;
@property (strong) id<BookmarksService> bookmarksService;
@end

@implementation BookmarksViewModelImpl

#pragma mark - Initialization
- (instancetype)initWithHandlersFactory:(id<HandlersFactory>)handlersFactory
                       bookmarksService:(id<BookmarksService>)bookmarksService {
    NSCParameterAssert(handlersFactory);
    NSCParameterAssert(bookmarksService);
    if (self) {
        _handler = [handlersFactory bookmarksViewModelHandler];
        _bookmarksService = bookmarksService;
    }
    return self;
}

#pragma mark - BookmarksViewModel
- (void)getBookmarks:(NSInteger)offset completion:(void(^)(NSArray *bookmarks, NSError *error))completion {
    dispatch_python(^{
        NSDictionary *data = [self.handler getBookmarks:@(offset)];
        NSError *error = [data utils_getError];
        NSArray* objects = [self.bookmarksService parse:data];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion(objects, error);
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

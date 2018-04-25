//
//  BookmarksViewModelImpl.h
//  vk
//
//  Created by Jasf on 25.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "BookmarksViewModel.h"
#import "BookmarksService.h"
#import "HandlersFactory.h"

@protocol PyBookmarksViewModel <NSObject>
- (NSDictionary *)getBookmarks:(NSNumber *)offset;
- (void)menuTapped;
@end

@interface BookmarksViewModelImpl : NSObject <BookmarksViewModel>
- (instancetype)initWithHandlersFactory:(id<HandlersFactory>)handlersFactory
                       bookmarksService:(id<BookmarksService>)bookmarksService;
@end

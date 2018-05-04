//
//  NewsViewModelImpl.h
//  vk
//
//  Created by Jasf on 24.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "NewsViewModel.h"
#import "HandlersFactory.h"
#import "WallService.h"

@protocol PyNewsViewModel <NSObject>
- (NSDictionary *)getNews:(NSNumber *)offset;
- (void)menuTapped;
@end

@interface NewsViewModelImpl : NSObject <NewsViewModel>
- (instancetype)initWithHandlersFactory:(id<HandlersFactory>)handlersFactory
                            wallService:(id<WallService>)wallService;
@end

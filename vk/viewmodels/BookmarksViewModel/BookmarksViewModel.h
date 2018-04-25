//
//  BookmarksViewModel.h
//  vk
//
//  Created by Jasf on 25.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol BookmarksViewModel <NSObject>
- (void)getBookmarks:(NSInteger)offset completion:(void(^)(NSArray *bookmarks))completion;
- (void)menuTapped;
@end

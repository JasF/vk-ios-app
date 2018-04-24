//
//  NewsViewModel.h
//  vk
//
//  Created by Jasf on 24.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

@protocol NewsViewModel <NSObject>
- (void)getNewsWithOffset:(NSInteger)offset completion:(void(^)(NSArray *offset))completion;
- (void)menuTapped;
@end

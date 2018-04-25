//
//  GroupsViewModel.h
//  vk
//
//  Created by Jasf on 25.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol GroupsViewModel <NSObject>
- (void)getGroups:(NSInteger)offset completion:(void(^)(NSArray *Groups))completion;
- (void)menuTapped;
@end

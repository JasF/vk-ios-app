//
//  RepostNode.h
//  vk
//
//  Created by Jasf on 27.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import <AsyncDisplayKit/AsyncDisplayKit.h>

@interface RepostNode : ASControlNode
- (instancetype)initWithRepostsCount:(NSInteger)repostsCount
                            reposted:(BOOL)reposted;
- (void)setRepostsCount:(NSInteger)reposts reposted:(BOOL)reposted;
@end

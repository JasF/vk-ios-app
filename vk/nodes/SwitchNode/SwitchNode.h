//
//  SwitchNode.h
//  vk
//
//  Created by Jasf on 25.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import <AsyncDisplayKit/AsyncDisplayKit.h>

@interface SwitchNode : ASCellNode
- (id)initWithTitle:(NSString *)title on:(BOOL)on actionBlock:(void(^)(BOOL on))actionBlock;
@end

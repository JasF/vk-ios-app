//
//  DialogNode.h
//  vk
//
//  Created by Jasf on 12.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import <AsyncDisplayKit/AsyncDisplayKit.h>

@class Dialog;
@class DialogNode;
@class User;

@protocol DialogNodeDelegate <NSObject>
- (void)dialogNode:(DialogNode *)node
    tappedWithUser:(User *)user;
@end

@interface DialogNode : ASCellNode
@property (weak, nonatomic) id<DialogNodeDelegate> delegate;
- (instancetype)initWithDialog:(Dialog *)dialog;
@end

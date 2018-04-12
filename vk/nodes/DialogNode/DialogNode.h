//
//  DialogNode.h
//  vk
//
//  Created by Jasf on 12.04.2018.
//  Copyright © 2018 Facebook. All rights reserved.
//

#import <AsyncDisplayKit/AsyncDisplayKit.h>

@class Dialog;

@interface DialogNode : ASCellNode

- (instancetype)initWithDialog:(Dialog *)dialog;

@end

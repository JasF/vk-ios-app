//
//  DialogNode.h
//  vk
//
//  Created by Jasf on 12.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import <Async_DisplayKit/Async_DisplayKit.h>

@class Dialog;

@interface DialogNode : A_SCellNode

- (instancetype)initWithDialog:(Dialog *)dialog;

@end

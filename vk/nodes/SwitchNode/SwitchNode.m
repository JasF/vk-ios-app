//
//  SwitchNode.m
//  vk
//
//  Created by Jasf on 25.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "TextStyles.h"
#import "SwitchNode.h"

@interface SwitchNode ()
@property ASDisplayNode *switcherNode;
@property ASTextNode *textNode;
@property (readonly, nonatomic) UISwitch *switcher;
@property (copy) void (^actionBlock)(BOOL on);
@end

@implementation SwitchNode

- (id)initWithTitle:(NSString *)title on:(BOOL)on actionBlock:(void(^)(BOOL on))actionBlock {
    self = [super init];
    if (self) {
        self.actionBlock = actionBlock;
        @weakify(self);
        _switcherNode = [[ASDisplayNode alloc] initWithViewBlock:^UIView * _Nonnull {
            @strongify(self);
            UISwitch *switcher = [UISwitch new];
            [switcher addTarget:self action:@selector(switcherValueChanged:) forControlEvents:UIControlEventValueChanged];
            switcher.backgroundColor = [UIColor clearColor];
            switcher.on = on;
            return switcher;
        }];
        _textNode = [[ASTextNode alloc] init];
        _textNode.attributedText = [[NSAttributedString alloc] initWithString:title attributes:[TextStyles nameStyle]];
        _textNode.truncationMode = NSLineBreakByTruncatingTail;
        [self addSubnode:_textNode];
        [self addSubnode:_switcherNode];
    }
    return self;
}

- (UISwitch *)switcher {
    ASDisplayNodeAssertMainThread();
    return (UISwitch *)self.switcherNode.view;
}

/*
- (ASLayoutSpec *)layoutSpecThatFits:(ASSizeRange)constrainedSize {
    ASLayoutSpec *spacer = [[ASLayoutSpec alloc] init];
    spacer.style.flexGrow = 1.0;
    
    ASStackLayoutSpec *topLineStack =
    [ASStackLayoutSpec
     stackLayoutSpecWithDirection:ASStackLayoutDirectionHorizontal
     spacing:5.0
     justifyContent:ASStackLayoutJustifyContentStart
     alignItems:ASStackLayoutAlignItemsCenter
     children:@[_textNode, spacer, _switcherNode]];
    topLineStack.style.alignSelf = ASStackLayoutAlignSelfStretch;
    
    return [ASInsetLayoutSpec insetLayoutSpecWithInsets:UIEdgeInsetsZero child:topLineStack];
}
*/

- (ASLayoutSpec *)layoutSpecThatFits:(ASSizeRange)constrainedSize {
    CGFloat padding = 5;
    
    CGSize progressSize = constrainedSize.max;
    progressSize.width -= padding * 2;
    progressSize.height = 2;
    
    ASLayoutSpec *spacer = [[ASLayoutSpec alloc] init];
    spacer.style.flexGrow = 1.0;
    ASStackLayoutSpec *topLineStack =
    [ASStackLayoutSpec
     stackLayoutSpecWithDirection:ASStackLayoutDirectionHorizontal
     spacing:5.0
     justifyContent:ASStackLayoutJustifyContentStart
     alignItems:ASStackLayoutAlignItemsCenter
     children:@[_textNode, spacer, _switcherNode]];
    topLineStack.style.alignSelf = ASStackLayoutAlignSelfStretch;
    
    [_switcherNode.style setPreferredSize:progressSize];
    
    return [ASInsetLayoutSpec insetLayoutSpecWithInsets:UIEdgeInsetsMake(24, padding, 24, padding) child:topLineStack];
}

#pragma mark - Observers
- (void)switcherValueChanged:(id)sender {
    if (_actionBlock) {
        _actionBlock(self.switcher.on);
    }
}

@end

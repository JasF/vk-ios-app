//
//  BaseViewController.h
//  Oxy Feed
//
//  Created by Jasf on 19.05.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import <AsyncDisplayKit/AsyncDisplayKit.h>

typedef NS_ENUM(NSInteger, ScreenType) {
    ScreenUnknown,
    ScreenWallPost,
    ScreenDetailPhoto,
    ScreenDetailVideo
};

@class BaseNode;
@protocol NodeFactory;

@protocol BaseViewControllerDataSource <NSObject>
- (void)getModelObjets:(void(^)(NSArray *objects))completion
                offset:(NSInteger)offset;
@end

@interface BaseViewController : ASViewController
@property (nonatomic) BaseNode *baseNode;
@property id<NodeFactory> nodeFactory;
@property (readonly) ScreenType screenType;
- (void)showNoConnectionAlert;
- (void)repeatTapped; // For override in superclass
@end

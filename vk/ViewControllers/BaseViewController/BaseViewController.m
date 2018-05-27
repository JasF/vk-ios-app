//
//  BaseViewController.m
//  Oxy Feed
//
//  Created by Jasf on 19.05.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "BaseViewController.h"
#import "Oxy_Feed-Swift.h"
#import "NodeFactory.h"

@interface BaseViewController ()
@property (strong, nonatomic) OfflineNode *offlineNode;
@end

@implementation BaseViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
- (ScreenType)screenType {
    NSCAssert(NO, @"Must be overriden");
    return ScreenUnknown;
}

- (void)showNoConnectionAlert {
    [self.baseNode setOverlayNode:self.offlineNode];
}

#pragma mark - Private
- (OfflineNode *)offlineNode {
    if (!_offlineNode) {
        _offlineNode =(OfflineNode *)[_nodeFactory offlineNode];
        @weakify(self);
        _offlineNode.repeatBlock = ^{
            @strongify(self);
            [self.baseNode setOverlayNode:nil];
            [self repeatTapped];
        };
    }
    return _offlineNode;
}

- (void)repeatTapped {
    
}

@end

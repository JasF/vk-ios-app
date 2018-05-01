//
//  CreatePostViewController.m
//  vk
//
//  Created by Jasf on 01.05.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "CreatePostViewController.h"
#import "vk-Swift.h"

@interface CreatePostViewController ()
@property (strong) id<CreatePostViewModel> viewModel;
@property (strong) UIButton *closeButton;
@property (strong) UIButton *sendButton;
@property CreatePostNode *contentNode;
@end

@implementation CreatePostViewController

- (id)init:(id<CreatePostViewModel>)viewModel {
    _contentNode = [CreatePostNode new];
    if (self = [super initWithNode:_contentNode]) {
        _viewModel = viewModel;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.navigationBar.barStyle = UIBarStyleBlackTranslucent;
    self.view.backgroundColor = [UIColor whiteColor];
    
    _closeButton = [UIButton new];
    _sendButton = [UIButton new];
    [_closeButton setTitle:L(@"close") forState:UIControlStateNormal];
    [_sendButton setTitle:L(@"post_send") forState:UIControlStateNormal];
    [_sendButton setTitleColor:[[UIColor whiteColor] colorWithAlphaComponent:0.5f] forState:UIControlStateDisabled];
    [_closeButton addTarget:self action:@selector(closeTapped:) forControlEvents:UIControlEventTouchUpInside];
    [_sendButton addTarget:self action:@selector(sendTapped:) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:_closeButton];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:_sendButton];
    [_closeButton sizeToFit];
    [_sendButton sizeToFit];
    _sendButton.enabled = NO;
    // Do any additional setup after loading the view.
}

- (void)closeTapped:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)sendTapped:(id)sender {
    if (!_sendButton.enabled) {
        return;
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

//
//  ChatInputBarViewController.m
//  vk
//
//  Created by Jasf on 01.05.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "ChatInputBarViewController.h"
#import "_MXRMessengerInputToolbarContainerView.h"

@interface ChatInputBarViewController () <ASTableDelegate>
@property (nonatomic, strong) NSNumber* calculatedOffsetFromInteractiveKeyboardDismissal;
@property (nonatomic, strong) MXRMessengerInputToolbar* toolbar;
@property (nonatomic, strong) MXRMessengerInputToolbarContainerView *toolbarContainerView;
@property (nonatomic, assign) CGFloat minimumBottomInset;
@property (nonatomic, assign) CGFloat topInset;
@end

@implementation ChatInputBarViewController

- (ASTableNode *)getTableNode {
    NSCParameterAssert(nil);
    return nil;
}
- (void)dealloc {
    [self stopObservingKeyboard];
    [self stopObservingAppStateChanges];
}

- (id)initWithNode:(ASDisplayNode *)node {
    if (self = [super initWithNode:node]) {
        self.hidesBottomBarWhenPushed = YES;
    }
    return self;
}

- (CGFloat)calculateTopInset {
    CGFloat t = 6.0f;
    if (!self.prefersStatusBarHidden) {
        t += [UIApplication sharedApplication].statusBarFrame.size.height;
    }
    if (self.navigationController && !self.navigationController.isNavigationBarHidden) {
        t += self.navigationController.navigationBar.frame.size.height;
    }
    return t;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    if (@available(iOS 11, *)) {
        self.getTableNode.view.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    } else {
        self.automaticallyAdjustsScrollViewInsets = NO;
    }
    
    _toolbar = [[MXRMessengerInputToolbar alloc] init];
    @weakify(self);
    self.toolbar.didChangeTextBlock = ^(NSString *text) {
        @strongify(self);
        [self inputBarDidChangeText:text];
    };
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    _toolbarContainerView = [[MXRMessengerInputToolbarContainerView alloc] initWithMessengerInputToolbar:self.toolbar constrainedSize:ASSizeRangeMake(CGSizeMake(screenWidth, 0), CGSizeMake(screenWidth, CGFLOAT_MAX))];
    _minimumBottomInset = self.toolbarContainerView.toolbarNode.calculatedSize.height;
    _topInset = [self calculateTopInset];
    [self.toolbar.defaultSendButton addTarget:self action:@selector(tapSend:) forControlEvents:ASControlNodeEventTouchUpInside];
    
    self.getTableNode.view.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.getTableNode.view.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
    self.getTableNode.contentInset = UIEdgeInsetsMake(_minimumBottomInset, 0, _topInset, 0);
    self.getTableNode.view.scrollIndicatorInsets = UIEdgeInsetsMake(_minimumBottomInset, 0, _topInset, 0);
    self.getTableNode.delegate = self;
    
    [self observeKeyboardChanges];
    [self observeAppStateChanges];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self dismissKeyboard];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self dismissKeyboard];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self becomeFirstResponder];
}

//override func inputBarDidChangeText(_ text: String) {

- (void)inputBarDidChangeText:(NSString *)text {
    
}

#pragma mark - NSNotificationCenter

- (void)observeKeyboardChanges {
    [self stopObservingKeyboard];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mxr_messenger_didReceiveKeyboardWillChangeFrameNotification:) name:UIKeyboardWillChangeFrameNotification object:nil];
}

- (void)stopObservingKeyboard {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillChangeFrameNotification object:nil];
}

- (void)observeAppStateChanges {
    [self stopObservingAppStateChanges];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mxr_messenger_applicationWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mxr_messenger_applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)stopObservingAppStateChanges {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
}

#pragma mark - Target-Action AppState

- (void)mxr_messenger_applicationWillResignActive:(id)sender {
    [self stopObservingKeyboard];
}

- (void)mxr_messenger_applicationDidBecomeActive:(id)sender {
    [self observeKeyboardChanges];
}

#pragma mark - Target-Action Keyboard

- (void)mxr_messenger_didReceiveKeyboardWillChangeFrameNotification:(NSNotification*)notification {
    if (self.isBeingDismissed || (self.navigationController && self.navigationController.topViewController != self)) {
        return;
    }
    UITableView* tableView = self.getTableNode.view;
    CGFloat keyboardEndHeight = [UIScreen mainScreen].bounds.size.height - [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue].origin.y;
    CGFloat keyboardStartHeight = tableView.contentInset.top; // this is more reliable than the startFrame in userInfo
    CGFloat changeInHeight = keyboardEndHeight - keyboardStartHeight;
    if (changeInHeight == 0) return; // e.g. when an interactive dismiss is cancelled
    if (keyboardEndHeight < self.minimumBottomInset) return; // e.g. when we present media viewer, it dismisses the toolbar
    BOOL willDismissKeyboard = changeInHeight < 0;
    CGFloat newOffset = tableView.contentOffset.y - changeInHeight;
    CGFloat offsetAtBottom = -keyboardEndHeight;
    if (fabs(newOffset - offsetAtBottom) < 400.0f) {
        newOffset = offsetAtBottom; // keep them on the most recent message when they're near it
    }
    if (tableView.isDragging && willDismissKeyboard) {
        self.calculatedOffsetFromInteractiveKeyboardDismissal = @(newOffset);
    } else {
        tableView.contentOffset = CGPointMake(0, newOffset);
    }
    tableView.contentInset = UIEdgeInsetsMake(keyboardEndHeight, 0, self.topInset, 0);
    tableView.scrollIndicatorInsets = UIEdgeInsetsMake(keyboardEndHeight, 0, self.topInset, 0);
}

- (void)dismissKeyboard {
    if ([self.toolbar.textInputNode isFirstResponder]) [self.toolbar.textInputNode resignFirstResponder];
}

#pragma mark - ASTableDelegate

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    if (self.calculatedOffsetFromInteractiveKeyboardDismissal) {
        *targetContentOffset = CGPointMake(0, self.calculatedOffsetFromInteractiveKeyboardDismissal.doubleValue);
        self.calculatedOffsetFromInteractiveKeyboardDismissal = nil;
    }
}

#pragma mark - Toolbar
- (void)tapSend:(id)sender {
    NSString* text = [self.toolbar clearText];
    if (text.length == 0) {
        return;
    }
    [self sendTappedWithText:text];
}

- (BOOL)canBecomeFirstResponder { return YES; }
- (UIView *)inputAccessoryView { return self.toolbarContainerView; }

- (void)sendTappedWithText:(NSString *)text {
    
}

@end

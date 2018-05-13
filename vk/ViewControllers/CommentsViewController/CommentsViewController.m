//
//  CommentsViewController.m
//  vk
//
//  Created by Jasf on 01.05.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "CommentsViewController.h"
#import "_MXRMessengerInputToolbarContainerView.h"
#import "Comment.h"
#import "Oxy_Feed-Swift.h"
#import "RSSwizzle.h"

static NSInteger const kNumberOfCommentsForPreload = 40;

@interface CommentsViewController () <UITableViewDelegate>
@property (nonatomic, strong) NSNumber* calculatedOffsetFromInteractiveKeyboardDismissal;
@property (nonatomic, strong) MXRMessengerInputToolbar* toolbar;
@property (nonatomic, strong) MXRMessengerInputToolbarContainerView *toolbarContainerView;
@property (nonatomic, assign) CGFloat minimumBottomInset;
@property (nonatomic, assign) CGFloat topInset;
@property (nonatomic, strong) CommentsPreloadModel *commentsPreloadModel;
@end

@implementation CommentsViewController

- (void)dealloc {
    [self stopObservingKeyboard];
    [self stopObservingAppStateChanges];
}

- (id)initWithNodeFactory:(id<NodeFactory>)nodeFactory {
    if (self = [super initWithNodeFactory:nodeFactory]) {
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
    
    if (@available(iOS 11, *)) {} else {
        self.automaticallyAdjustsScrollViewInsets = NO;
        [self updateFrames];
        self.tableNode.contentOffset = CGPointMake(0, -self.topInset);
    }
}

/*
+ (void)load {
    SEL selector = @selector(setContentOffset:);
    [RSSwizzle
     swizzleInstanceMethod:selector
     inClass:[ASTableView class]
     newImpFactory:^id(RSSwizzleInfo *swizzleInfo) {
         // This block will be used as the new implementation.
         return ^(__unsafe_unretained id self, CGPoint contentOffset){
             // You MUST always cast implementation to the correct function pointer.
             void (*originalIMP)(__unsafe_unretained id, SEL, CGPoint);
             originalIMP = (__typeof(originalIMP))[swizzleInfo getOriginalImplementation];
             // Calling original implementation.
             originalIMP(self,selector,contentOffset);
             // Returning modified return value.
             DDLogInfo(@"swizzled: %@", NSStringFromCGPoint(contentOffset));
         };
     }
     mode:RSSwizzleModeAlways
     key:NULL];
}
 */

- (CGFloat)topInset {
    if (@available(iOS 11, *)) {
        return 0.f;
    } else {
        return 64.f;
    }
}

- (void)updateFrames {
    _minimumBottomInset = self.toolbarContainerView.toolbarNode.calculatedSize.height;
    _topInset = [self calculateTopInset];
    
    self.tableNode.view.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableNode.view.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
    self.tableNode.contentInset = UIEdgeInsetsMake(self.topInset, 0, _minimumBottomInset, 0);
    self.tableNode.view.scrollIndicatorInsets = UIEdgeInsetsMake(self.topInset, 0, _minimumBottomInset, 0);
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

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    if (self.calculatedOffsetFromInteractiveKeyboardDismissal) {
        *targetContentOffset = CGPointMake(0, self.calculatedOffsetFromInteractiveKeyboardDismissal.doubleValue);
        self.calculatedOffsetFromInteractiveKeyboardDismissal = nil;
    }
}

#pragma mark - Public Methods
- (void)hideCommentsToolbar {
    [_toolbarContainerView removeFromSuperview];
    [self updateFrames];
}

- (void)showCommentsToolbar {
    if (self.toolbar) {
        return;
    }
    self.toolbar = [MXRMessengerInputToolbar new];
    MXRMessengerIconButtonNode* addPhotosBarButtonButtonNode = [MXRMessengerIconButtonNode buttonWithIcon:[[MXRMessengerPlusIconNode alloc] init] matchingToolbar:self.toolbar];
    [addPhotosBarButtonButtonNode addTarget:self action:@selector(tapAddPhotos:) forControlEvents:ASControlNodeEventTouchUpInside];
    //self.toolbar.leftButtonsNode = addPhotosBarButtonButtonNode;
    [self.toolbar.defaultSendButton addTarget:self action:@selector(tapSend:) forControlEvents:ASControlNodeEventTouchUpInside];
    
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    _toolbarContainerView = [[MXRMessengerInputToolbarContainerView alloc] initWithMessengerInputToolbar:self.toolbar constrainedSize:ASSizeRangeMake(CGSizeMake(screenWidth, 0), CGSizeMake(screenWidth, CGFLOAT_MAX))];
    
    [self updateFrames];
    
    
    [self observeKeyboardChanges];
    [self observeAppStateChanges];
    
    CGPoint contentOffset = self.tableNode.contentOffset;
    [UIView performWithoutAnimation:^{
        [self reloadInputViews];
    }];
    self.tableNode.contentOffset = contentOffset;
}

- (CommentsPreloadModel *)commentsPreloadModel {
    if (!_commentsPreloadModel) {
        _commentsPreloadModel = [[CommentsPreloadModel alloc] init:0 remaining:0];
    }
    return _commentsPreloadModel;
}

- (void)showPreloadCommentsCellWithCount:(NSInteger)count item:(id)item section:(NSMutableArray *)section {
    NSInteger remaining = count - self.objectsArray.count;
    NSInteger preload = MIN(remaining, kNumberOfCommentsForPreload);
    if ([item isKindOfClass:[WallPost class]]) {
        self.commentsPreloadModel.post = (WallPost *)item;
    }
    else if ([item isKindOfClass:[Video class]]) {
        self.commentsPreloadModel.video = (Video *)item;
    }
    else if ([item isKindOfClass:[Photo class]]) {
        self.commentsPreloadModel.photo = (Photo *)item;
    }
    self.commentsPreloadModel.loaded = self.objectsArray.count;
    [self.commentsPreloadModel set:preload remaining:remaining];
    [section addObject:self.commentsPreloadModel];
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


#pragma mark - Target-Action Keyboard

- (void)mxr_messenger_didReceiveKeyboardWillChangeFrameNotification:(NSNotification*)notification {
    if (self.isBeingDismissed || (self.navigationController && self.navigationController.topViewController != self) ||
        _toolbarContainerView.alpha == 0) {
        return;
    }
    UITableView* tableView = self.tableNode.view;
    CGFloat keyboardEndHeight = [UIScreen mainScreen].bounds.size.height - [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue].origin.y;
    CGFloat keyboardStartHeight = tableView.contentInset.top; // this is more reliable than the startFrame in userInfo
    CGFloat changeInHeight = keyboardEndHeight - keyboardStartHeight;
    if (changeInHeight == 0) return; // e.g. when an interactive dismiss is cancelled
    if (keyboardEndHeight < self.minimumBottomInset) return; // e.g. when we present media viewer, it dismisses the toolbar
    BOOL willDismissKeyboard = changeInHeight < 0;
    CGFloat newOffset = tableView.contentOffset.y + changeInHeight;
    CGFloat offsetAtBottom = -keyboardEndHeight;
    if (fabs(newOffset - offsetAtBottom) < 400.0f) {
        newOffset = offsetAtBottom; // keep them on the most recent message when they're near it
    }
    if (tableView.isDragging && willDismissKeyboard) {
        self.calculatedOffsetFromInteractiveKeyboardDismissal = @(newOffset);
    } else {
        tableView.contentOffset = CGPointMake(0, newOffset);
    }
    tableView.contentInset = UIEdgeInsetsMake(self.topInset, 0, keyboardEndHeight, 0);
    tableView.scrollIndicatorInsets = UIEdgeInsetsMake(self.topInset, 0, keyboardEndHeight, 0);
}

- (void)dismissKeyboard {
    if ([self.toolbar.textInputNode isFirstResponder]) [self.toolbar.textInputNode resignFirstResponder];
}

#pragma mark - Target-Action AppState
- (void)mxr_messenger_applicationWillResignActive:(id)sender {
    [self stopObservingKeyboard];
}

- (void)mxr_messenger_applicationDidBecomeActive:(id)sender {
    [self observeKeyboardChanges];
}

#pragma mark - Toolbar
- (BOOL)canBecomeFirstResponder { return YES; }
- (UIView *)inputAccessoryView { return self.toolbarContainerView; }

#pragma mark - Observers
- (void)tapAddPhotos:(id)sender {
    
}

- (void)tapSend:(id)sender {
    NSCParameterAssert(_commentsParentItem);
    if (!_commentsParentItem) {
        return;
    }
    NSString* text = [self.toolbar clearText];
    if (text.length == 0) {
        return;
    }
    @weakify(self);
    [self.postsViewModel sendCommentWithText:text
                                        item:self.commentsParentItem
                                  completion:^(NSInteger commentId, NSInteger ownerId, NSInteger postId, NSInteger reply_to_commentId, User *user) {
                                      @strongify(self);
                                      if (!commentId) {
                                          return;
                                      }
                                      Comment *comment = [Comment new];
                                      comment.id = commentId;
                                      comment.from_id = user.id;
                                      comment.date = [NSDate date].timeIntervalSince1970;
                                      comment.text = text;
                                      comment.user = user;
                                      NSInteger section = [self.tableNode numberOfSections] - 1;
                                      NSIndexPath *newIndexPath = [NSIndexPath indexPathForRow:self.objectsArray.count inSection:section];
                                      self.commentsPreloading = YES;
                                      [self.tableNode performBatchUpdates:^{
                                          [self.tableNode insertRowsAtIndexPaths:@[newIndexPath]
                                                                withRowAnimation:UITableViewRowAnimationFade];
                                          [self.objectsArray addObject:comment];
                                          [self numberOfCommentsDidUpdated:self.objectsArray.count];
                                          [self performBatchAnimated:YES];
                                      }
                                                               completion:^(BOOL c) {
                                                                   CGRect frame = self.tableNode.bounds;
                                                                   UIEdgeInsets inset = self.tableNode.contentInset;
                                                                   CGFloat height = frame.size.height - inset.top - inset.bottom;
                                                                   CGSize contentSize = self.tableNode.view.contentSize;
                                                                   CGFloat invisible = contentSize.height - height;
                                                                   if (invisible > 0) {
                                                                       [self.tableNode setContentOffset:CGPointMake(0, invisible)];
                                                                   }
                                                               }];
                                      
                                  }];
}

#pragma mark - UITableViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    DDLogInfo(@"scds: %@", NSStringFromCGPoint(scrollView.contentOffset));
}
@end

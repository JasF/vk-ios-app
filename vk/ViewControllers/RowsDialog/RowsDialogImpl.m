//
//  RowsDialogImpl.m
//  vk
//
//  Created by Jasf on 27.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "RowsDialogImpl.h"

@implementation RowsDialogImpl {
    id<ScreensManager> _screensManager;
}

@synthesize delegate = _delegate;

#pragma mark - Initialization
- (id)initWithScreensManager:(id<ScreensManager>)screensManager {
    NSCParameterAssert(screensManager);
    if (self = [super init]) {
        _screensManager = screensManager;
    }
    return self;
}

#pragma mark - RowsDialog
- (void)showRowsDialogWithTitles:(NSArray *)titles {
    NSCParameterAssert(_delegate);
    dispatch_async(dispatch_get_main_queue(), ^{
        UIViewController *viewController = _screensManager.topViewController;
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil
                                                                                 message:nil
                                                                          preferredStyle:UIAlertControllerStyleActionSheet];
        
        @weakify(self);
        NSInteger index = 0;
        for (NSString *title in titles) {
            UIAlertAction *button = [UIAlertAction actionWithTitle:L(title)
                                                             style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction * _Nonnull action) {
                                                                  @strongify(self);
                                                                  dispatch_async(dispatch_get_global_queue(0, DISPATCH_QUEUE_PRIORITY_DEFAULT), ^{
                                                                      @strongify(self);
                                                                      [self.delegate rowsDialog:self
                                                                                  doneWithIndex:index
                                                                                      cancelled:NO];
                                                                  });
                                                              }];
            index++;
            [alertController addAction:button];
        }
        
        
        UIAlertAction *noAction = [UIAlertAction actionWithTitle:L(@"cancel")
                                                           style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction * _Nonnull action) {
                                                             @strongify(self);
                                                             dispatch_async(dispatch_get_global_queue(0, DISPATCH_QUEUE_PRIORITY_DEFAULT), ^{
                                                                 [self.delegate rowsDialog:self
                                                                             doneWithIndex:-1
                                                                                 cancelled:YES];
                                                             });
                                                         }];
        [alertController addAction:noAction];
        
        [viewController presentViewController:alertController animated:YES completion:nil];
    });
}
@end

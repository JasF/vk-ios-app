//
//  TextFieldDialogImpl.m
//  Electrum
//
//  Created by Jasf on 25.03.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "TextFieldDialogImpl.h"

@implementation TextFieldDialogImpl {
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

#pragma mark - TextFieldDialog
- (void)showTextFieldDialogWithMessage:(NSString *)message placeholder:(NSString *)placeholder {
    NSCParameterAssert(_delegate);
    dispatch_async(dispatch_get_main_queue(), ^{
        UIViewController *viewController = _screensManager.topViewController;
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@""
                                                                                 message:L(message)
                                                                          preferredStyle:UIAlertControllerStyleAlert];
        [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
            textField.text = placeholder;
        }];
        @weakify(self);
        UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:L(@"ok")
                                                                style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * _Nonnull action) {
                                                                  @strongify(self);
                                                                  NSString *text = [[alertController textFields][0] text];
                                                                  dispatch_async(dispatch_get_global_queue(0, DISPATCH_QUEUE_PRIORITY_DEFAULT), ^{
                                                                      [self.delegate textFieldDialog:self doneWithText:text cancel:NO];
                                                                  });
                                                              }];
        
        
        UIAlertAction *noAction = [UIAlertAction actionWithTitle:L(@"cancel")
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction * _Nonnull action) {
                                                             @strongify(self);
                                                             dispatch_async(dispatch_get_global_queue(0, DISPATCH_QUEUE_PRIORITY_DEFAULT), ^{
                                                                 [self.delegate textFieldDialog:self doneWithText:nil cancel:YES];
                                                             });
                                                         }];
        
        [alertController addAction:confirmAction];
        [alertController addAction:noAction];
        [viewController presentViewController:alertController animated:YES completion:nil];
    });
}
@end

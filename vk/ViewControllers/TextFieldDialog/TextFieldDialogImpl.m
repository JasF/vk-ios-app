//
//  TextFieldDialogImpl.m
//  Electrum
//
//  Created by Jasf on 25.03.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "TextFieldDialogImpl.h"

typedef NS_ENUM(NSInteger, StyleType) {
    DialogStyleTextField,
    DialogStyleMessage,
    DialogStyleYesNo
};

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
    [self showTextFieldDialogWithMessage:message placeholder:placeholder onlyMessage:NO];
}

- (void)showWithMessage:(NSString *)message
         yesButtonTitle:(NSString *)yesButtonTitle
          noButtonTitle:(NSString *)noButtonTitle {
    
    [self showTextFieldDialogWithMessage:message
                             placeholder:@""
                                   style:DialogStyleYesNo
                          yesButtonTitle:L(yesButtonTitle)
                           noButtonTitle:L(noButtonTitle)];
}

- (void)showTextFieldDialogWithMessage:(NSString *)message placeholder:(NSString *)placeholder onlyMessage:(BOOL)onlyMessage {
    [self showTextFieldDialogWithMessage:message
                             placeholder:placeholder
                                   style:(onlyMessage)?DialogStyleMessage:DialogStyleTextField
                          yesButtonTitle:L(@"ok")
                           noButtonTitle:L(@"cancel")];
}
- (void)showTextFieldDialogWithMessage:(NSString *)message
                           placeholder:(NSString *)placeholder
                                 style:(StyleType)style
                        yesButtonTitle:(NSString *)yesButtonTitle
                         noButtonTitle:(NSString *)noButtonTitle {
    NSCParameterAssert(_delegate);
    dispatch_async(dispatch_get_main_queue(), ^{
        UIViewController *viewController = _screensManager.topViewController;
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@""
                                                                                 message:L(message)
                                                                          preferredStyle:UIAlertControllerStyleAlert];
        if (style == DialogStyleTextField) {
            [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
                textField.text = placeholder;
            }];
        }
        @weakify(self);
        UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:yesButtonTitle
                                                                style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * _Nonnull action) {
                                                                  if (style == DialogStyleMessage) {
                                                                      return;
                                                                  }
                                                                  @strongify(self);
                                                                  NSString *text = nil;
                                                                  if (style == DialogStyleTextField) {
                                                                      text = [[alertController textFields][0] text];
                                                                  }
                                                                  dispatch_async(dispatch_get_global_queue(0, DISPATCH_QUEUE_PRIORITY_DEFAULT), ^{
                                                                      [self.delegate textFieldDialog:self doneWithText:text cancel:NO];
                                                                  });
                                                              }];
        [alertController addAction:confirmAction];
        if (style == DialogStyleTextField || style == DialogStyleYesNo) {
            UIAlertAction *noAction = [UIAlertAction actionWithTitle:noButtonTitle
                                                               style:UIAlertActionStyleDefault
                                                             handler:^(UIAlertAction * _Nonnull action) {
                                                                 if (style == DialogStyleMessage) {
                                                                     return;
                                                                 }
                                                                 @strongify(self);
                                                                 dispatch_async(dispatch_get_global_queue(0, DISPATCH_QUEUE_PRIORITY_DEFAULT), ^{
                                                                     [self.delegate textFieldDialog:self doneWithText:nil cancel:YES];
                                                                 });
                                                             }];
            [alertController addAction:noAction];
        }
        
        [viewController presentViewController:alertController animated:YES completion:nil];
    });
}
@end

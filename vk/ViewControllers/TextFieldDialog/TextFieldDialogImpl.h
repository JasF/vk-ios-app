//
//  TextFieldDialogImpl.h
//  Electrum
//
//  Created by Jasf on 25.03.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "TextFieldDialog.h"
#import "ScreensManager.h"

@interface TextFieldDialogImpl : NSObject <TextFieldDialog>
- (id)initWithScreensManager:(id<ScreensManager>)screensManager;
@end

//
//  RowsDialogImpl.h
//  vk
//
//  Created by Jasf on 27.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "RowsDialog.h"
#import "ScreensManager.h"

@interface RowsDialogImpl : NSObject <RowsDialog>
- (id)initWithScreensManager:(id<ScreensManager>)screensManager;
@end

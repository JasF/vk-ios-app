//
//  DialogsService.h
//  vk
//
//  Created by Jasf on 13.04.2018.
//  Copyright © 2018 Facebook. All rights reserved.
//

#import <CoreFoundation/CoreFoundation.h>
#import "Dialog.h"

@protocol DialogsService <NSObject>
- (void)getDialogsWithOffset:(NSInteger)offset
                    completion:(void(^)(NSArray<Dialog *> *dialogs))completion;
@end

//
//  ChatListService.h
//  vk
//
//  Created by Jasf on 13.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import <CoreFoundation/CoreFoundation.h>
#import "Dialog.h"

@protocol ChatListService <NSObject>
- (NSArray<Dialog *> *)parse:(NSDictionary *)chatListData;
@end

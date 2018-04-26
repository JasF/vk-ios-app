//
//  PI_NOperationTypes.h
//  PI_NOperation
//
//  Created by Adlai Holler on 1/10/17.
//  Copyright © 2017 Pinterest. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, PI_NOperationQueuePriority) {
    PI_NOperationQueuePriorityLow,
    PI_NOperationQueuePriorityDefault,
    PI_NOperationQueuePriorityHigh,
};

//
//  PI_NOperationMacros.h
//  PI_NOperation
//
//  Created by Adlai Holler on 1/10/17.
//  Copyright © 2017 Pinterest. All rights reserved.
//

#ifndef PI_NOP_SUBCLASSING_RESTRICTED
#if defined(__has_attribute) && __has_attribute(objc_subclassing_restricted)
#define PI_NOP_SUBCLASSING_RESTRICTED __attribute__((objc_subclassing_restricted))
#else
#define PI_NOP_SUBCLASSING_RESTRICTED
#endif // #if defined(__has_attribute) && __has_attribute(objc_subclassing_restricted)
#endif // #ifndef PI_NOP_SUBCLASSING_RESTRICTED

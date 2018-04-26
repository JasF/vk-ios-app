//
//  PI_NCacheMacros.h
//  PI_NCache
//
//  Created by Adlai Holler on 1/31/17.
//  Copyright © 2017 Pinterest. All rights reserved.
//

#ifndef PI_N_SUBCLASSING_RESTRICTED
#if defined(__has_attribute) && __has_attribute(objc_subclassing_restricted)
#define PI_N_SUBCLASSING_RESTRICTED __attribute__((objc_subclassing_restricted))
#else
#define PI_N_SUBCLASSING_RESTRICTED
#endif // #if defined(__has_attribute) && __has_attribute(objc_subclassing_restricted)
#endif // #ifndef PI_N_SUBCLASSING_RESTRICTED

#ifndef PI_N_NOESCAPE
#if defined(__has_attribute) && __has_attribute(noescape)
#define PI_N_NOESCAPE __attribute__((noescape))
#else
#define PI_N_NOESCAPE
#endif // #if defined(__has_attribute) && __has_attribute(noescape)
#endif // #ifndef PI_N_NOESCAPE

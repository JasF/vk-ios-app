//
//  A_SSignpost.h
//  Tex_ture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

/// The signposts we use. Signposts are grouped by color. The SystemTrace.tracetemplate file
/// should be kept up-to-date with these values.
typedef NS_ENUM(uint32_t, A_SSignpostName) {
  // Collection/Table (Blue)
  A_SSignpostDataControllerBatch = 300,    // Alloc/layout nodes before collection update.
  A_SSignpostRangeControllerUpdate,        // Ranges update pass.
  A_SSignpostCollectionUpdate,             // Entire update process, from -endUpdates to [super perform…]
  
  // Rendering (Green)
  A_SSignpostLayerDisplay = 325,           // Client display callout.
  A_SSignpostRunLoopQueueBatch,            // One batch of A_SRunLoopQueue.
  
  // Layout (Purple)
  A_SSignpostCalculateLayout = 350,        // Start of calculateLayoutThatFits to end. Max 1 per thread.
  
  // Misc (Orange)
  A_SSignpostDeallocQueueDrain = 375,      // One chunk of dealloc queue work. arg0 is count.
  A_SSignpostCATransactionLayout,          // The CA transaction commit layout phase.
  A_SSignpostCATransactionCommit           // The CA transaction commit post-layout phase.
};

typedef NS_ENUM(uintptr_t, A_SSignpostColor) {
  A_SSignpostColorBlue,
  A_SSignpostColorGreen,
  A_SSignpostColorPurple,
  A_SSignpostColorOrange,
  A_SSignpostColorRed,
  A_SSignpostColorDefault
};

static inline A_SSignpostColor A_SSignpostGetColor(A_SSignpostName name, A_SSignpostColor colorPref) {
  if (colorPref == A_SSignpostColorDefault) {
    return (A_SSignpostColor)((name / 25) % 4);
  } else {
    return colorPref;
  }
}

#define A_S_KDEBUG_ENABLE defined(PROFILE) && __has_include(<sys/kdebug_signpost.h>)

#if A_S_KDEBUG_ENABLE

#import <sys/kdebug_signpost.h>

// These definitions are required to build the backward-compatible kdebug trace
// on the iOS 10 SDK.  The kdebug_trace function crashes if run on iOS 9 and earlier.
// It's valuable to support trace signposts on iOS 9, because A5 devices don't support iOS 10.
#ifndef DBG_MACH_CHUD
#define DBG_MACH_CHUD 0x0A
#define DBG_FUNC_NONE 0
#define DBG_FUNC_START 1
#define DBG_FUNC_END 2
#define DBG_APPS 33
#define SYS_kdebug_trace 180
#define KDBG_CODE(Class, SubClass, code) (((Class & 0xff) << 24) | ((SubClass & 0xff) << 16) | ((code & 0x3fff)  << 2))
#define APPSDBG_CODE(SubClass,code) KDBG_CODE(DBG_APPS, SubClass, code)
#endif

// Currently we'll reserve arg3.
#define A_SSignpost(name, identifier, arg2, color) \
A_S_AT_LEA_ST_IOS10 ? kdebug_signpost(name, (uintptr_t)identifier, (uintptr_t)arg2, 0, A_SSignpostGetColor(name, color)) \
: syscall(SYS_kdebug_trace, APPSDBG_CODE(DBG_MACH_CHUD, name) | DBG_FUNC_NONE, (uintptr_t)identifier, (uintptr_t)arg2, 0, A_SSignpostGetColor(name, color));

#define A_SSignpostStartCustom(name, identifier, arg2) \
A_S_AT_LEA_ST_IOS10 ? kdebug_signpost_start(name, (uintptr_t)identifier, (uintptr_t)arg2, 0, 0) \
: syscall(SYS_kdebug_trace, APPSDBG_CODE(DBG_MACH_CHUD, name) | DBG_FUNC_START, (uintptr_t)identifier, (uintptr_t)arg2, 0, 0);
#define A_SSignpostStart(name) A_SSignpostStartCustom(name, self, 0)

#define A_SSignpostEndCustom(name, identifier, arg2, color) \
A_S_AT_LEA_ST_IOS10 ? kdebug_signpost_end(name, (uintptr_t)identifier, (uintptr_t)arg2, 0, A_SSignpostGetColor(name, color)) \
: syscall(SYS_kdebug_trace, APPSDBG_CODE(DBG_MACH_CHUD, name) | DBG_FUNC_END, (uintptr_t)identifier, (uintptr_t)arg2, 0, A_SSignpostGetColor(name, color));
#define A_SSignpostEnd(name) A_SSignpostEndCustom(name, self, 0, A_SSignpostColorDefault)

#else

#define A_SSignpost(name, identifier, arg2, color)
#define A_SSignpostStartCustom(name, identifier, arg2)
#define A_SSignpostStart(name)
#define A_SSignpostEndCustom(name, identifier, arg2, color)
#define A_SSignpostEnd(name)

#endif

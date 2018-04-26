//
//  A_SBaseDefines.h
//  Tex_ture
//
//  Copyright (c) 2014-present, Facebook, Inc.  All rights reserved.
//  This source code is licensed under the BSD-style license found in the
//  LICENSE file in the /A_SDK-Licenses directory of this source tree. An additional
//  grant of patent rights can be found in the PATENTS file in the same directory.
//
//  Modifications to this file made after 4/13/2017 are: Copyright (c) 2017-present,
//  Pinterest, Inc.  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

// The C++ compiler mangles C function names. extern "C" { /* your C functions */ } prevents this.
// You should wrap all C function prototypes declared in headers with A_SDISPLAYNODE_EXTERN_C_BEGIN/END, even if
// they are included only from .m (Objective-C) files. It's common for .m files to start using C++
// features and become .mm (Objective-C++) files. Always wrapping the prototypes with
// A_SDISPLAYNODE_EXTERN_C_BEGIN/END will save someone a headache once they need to do this. You do not need to
// wrap constants, only C functions. See StackOverflow for more details:
// http://stackoverflow.com/questions/1041866/in-c-source-what-is-the-effect-of-extern-c
#ifdef __cplusplus
# define A_SDISPLAYNODE_EXTERN_C_BEGIN extern "C" {
# define A_SDISPLAYNODE_EXTERN_C_END   }
#else
# define A_SDISPLAYNODE_EXTERN_C_BEGIN
# define A_SDISPLAYNODE_EXTERN_C_END
#endif

#ifdef __GNUC__
# define A_SDISPLAYNODE_GNUC(major, minor) \
(__GNUC__ > (major) || (__GNUC__ == (major) && __GNUC_MINOR__ >= (minor)))
#else
# define A_SDISPLAYNODE_GNUC(major, minor) 0
#endif

#ifndef A_SDISPLAYNODE_INLINE
# if defined (__STDC_VERSION__) && __STDC_VERSION__ >= 199901L
#  define A_SDISPLAYNODE_INLINE static inline
# elif defined (__MWERKS__) || defined (__cplusplus)
#  define A_SDISPLAYNODE_INLINE static inline
# elif A_SDISPLAYNODE_GNUC (3, 0)
#  define A_SDISPLAYNODE_INLINE static __inline__ __attribute__ ((always_inline))
# else
#  define A_SDISPLAYNODE_INLINE static
# endif
#endif

#ifndef A_SDISPLAYNODE_HIDDEN
# if A_SDISPLAYNODE_GNUC (4,0)
#  define A_SDISPLAYNODE_HIDDEN __attribute__ ((visibility ("hidden")))
# else
#  define A_SDISPLAYNODE_HIDDEN /* no hidden */
# endif
#endif

#ifndef A_SDISPLAYNODE_PURE
# if A_SDISPLAYNODE_GNUC (3, 0)
#  define A_SDISPLAYNODE_PURE __attribute__ ((pure))
# else
#  define A_SDISPLAYNODE_PURE /* no pure */
# endif
#endif

#ifndef A_SDISPLAYNODE_CONST
# if A_SDISPLAYNODE_GNUC (3, 0)
#  define A_SDISPLAYNODE_CONST __attribute__ ((const))
# else
#  define A_SDISPLAYNODE_CONST /* no const */
# endif
#endif

#ifndef A_SDISPLAYNODE_WARN_UNUSED
# if A_SDISPLAYNODE_GNUC (3, 4)
#  define A_SDISPLAYNODE_WARN_UNUSED __attribute__ ((warn_unused_result))
# else
#  define A_SDISPLAYNODE_WARN_UNUSED /* no warn_unused */
# endif
#endif

#ifndef A_SDISPLAYNODE_WARN_DEPRECATED
# define A_SDISPLAYNODE_WARN_DEPRECATED 1
#endif

#ifndef A_SDISPLAYNODE_DEPRECATED
# if A_SDISPLAYNODE_GNUC (3, 0) && A_SDISPLAYNODE_WARN_DEPRECATED
#  define A_SDISPLAYNODE_DEPRECATED __attribute__ ((deprecated))
# else
#  define A_SDISPLAYNODE_DEPRECATED
# endif
#endif

#ifndef A_SDISPLAYNODE_DEPRECATED_MSG
# if A_SDISPLAYNODE_GNUC (3, 0) && A_SDISPLAYNODE_WARN_DEPRECATED
#   define  A_SDISPLAYNODE_DEPRECATED_MSG(msg) __deprecated_msg(msg)
# else
#   define  A_SDISPLAYNODE_DEPRECATED_MSG(msg)
# endif
#endif

#if defined (__cplusplus) && defined (__GNUC__)
# define A_SDISPLAYNODE_NOTHROW __attribute__ ((nothrow))
#else
# define A_SDISPLAYNODE_NOTHROW
#endif

#ifndef A_S_ENABLE_TIPS
#define A_S_ENABLE_TIPS 0
#endif

/**
 * The event backtraces take a static 2KB of memory
 * and retain all objects present in all the registers
 * of the stack frames. The memory consumption impact
 * is too significant even to be enabled during general
 * development.
 */
#ifndef A_S_SAVE_EVENT_BACKTRACES
# define A_S_SAVE_EVENT_BACKTRACES 0
#endif

#define ARRAY_COUNT(x) sizeof(x) / sizeof(x[0])

#ifndef __has_feature      // Optional.
#define __has_feature(x) 0 // Compatibility with non-clang compilers.
#endif

#ifndef __has_attribute      // Optional.
#define __has_attribute(x) 0 // Compatibility with non-clang compilers.
#endif

#ifndef NS_CONSUMED
#if __has_feature(attribute_ns_consumed)
#define NS_CONSUMED __attribute__((ns_consumed))
#else
#define NS_CONSUMED
#endif
#endif

#ifndef NS_RETURNS_RETAINED
#if __has_feature(attribute_ns_returns_retained)
#define NS_RETURNS_RETAINED __attribute__((ns_returns_retained))
#else
#define NS_RETURNS_RETAINED
#endif
#endif

#ifndef CF_RETURNS_RETAINED
#if __has_feature(attribute_cf_returns_retained)
#define CF_RETURNS_RETAINED __attribute__((cf_returns_retained))
#else
#define CF_RETURNS_RETAINED
#endif
#endif

#ifndef A_SDISPLAYNODE_NOT_DESIGNATED_INITIALIZER
#define A_SDISPLAYNODE_NOT_DESIGNATED_INITIALIZER() \
  do { \
    NSAssert2(NO, @"%@ is not the designated initializer for instances of %@.", NSStringFromSelector(_cmd), NSStringFromClass([self class])); \
    return nil; \
  } while (0)
#endif // A_SDISPLAYNODE_NOT_DESIGNATED_INITIALIZER

// It's hard to pass quoted strings via xcodebuild preprocessor define arguments, so we'll convert
// the preprocessor values to strings here.
//
// It takes two steps to do this in gcc as per
// http://gcc.gnu.org/onlinedocs/cpp/Stringification.html
#define A_SDISPLAYNODE_TO_STRING(str) #str
#define A_SDISPLAYNODE_TO_UNICODE_STRING(str) @A_SDISPLAYNODE_TO_STRING(str)

#ifndef A_SDISPLAYNODE_REQUIRES_SUPER
#if __has_attribute(objc_requires_super)
#define A_SDISPLAYNODE_REQUIRES_SUPER __attribute__((objc_requires_super))
#else
#define A_SDISPLAYNODE_REQUIRES_SUPER
#endif
#endif

#ifndef A_S_UNAVAILABLE
#if __has_attribute(unavailable)
#define A_S_UNAVAILABLE(message) __attribute__((unavailable(message)))
#else
#define A_S_UNAVAILABLE(message)
#endif
#endif

#ifndef A_S_WARN_UNUSED_RESULT
#if __has_attribute(warn_unused_result)
#define A_S_WARN_UNUSED_RESULT __attribute__((warn_unused_result))
#else
#define A_S_WARN_UNUSED_RESULT
#endif
#endif

#define A_SOVERLOADABLE __attribute__((overloadable))


#if __has_attribute(noescape)
#define A_S_NOESCAPE __attribute__((noescape))
#else
#define A_S_NOESCAPE
#endif

#if __has_attribute(objc_subclassing_restricted)
#define A_S_SUBCLASSING_RESTRICTED __attribute__((objc_subclassing_restricted))
#else
#define A_S_SUBCLASSING_RESTRICTED
#endif

#define A_SPthreadStaticKey(dtor) ({ \
  static dispatch_once_t onceToken; \
  static pthread_key_t key; \
  dispatch_once(&onceToken, ^{ \
    pthread_key_create(&key, dtor); \
  }); \
  key; \
})

#define A_SCreateOnce(expr) ({ \
  static dispatch_once_t onceToken; \
  static __typeof__(expr) staticVar; \
  dispatch_once(&onceToken, ^{ \
    staticVar = expr; \
  }); \
  staticVar; \
})

/// Ensure that class is of certain kind
#define A_SDynamicCast(x, c) ({ \
  id __val = x;\
  ((c *) ([__val isKindOfClass:[c class]] ? __val : nil));\
})

/// Ensure that class is of certain kind, assuming it is subclass restricted
#define A_SDynamicCastStrict(x, c) ({ \
  id __val = x;\
  ((c *) ([__val class] == [c class] ? __val : nil));\
})

/**
 * Create a new set by mapping `collection` over `work`, ignoring nil.
 */
#define A_SSetByFlatMapping(collection, decl, work) ({ \
  NSMutableSet *s = [NSMutableSet set]; \
  for (decl in collection) {\
    id result = work; \
    if (result != nil) { \
      [s addObject:result]; \
    } \
  } \
  s; \
})

/**
 * Create a new ObjectPointerPersonality NSHashTable by mapping `collection` over `work`, ignoring nil.
 */
#define A_SPointerTableByFlatMapping(collection, decl, work) ({ \
  NSHashTable *t = [NSHashTable hashTableWithOptions:NSHashTableObjectPointerPersonality]; \
  for (decl in collection) {\
    id result = work; \
    if (result != nil) { \
      [t addObject:result]; \
    } \
  } \
  t; \
})

/**
 * Create a new array by mapping `collection` over `work`, ignoring nil.
 */
#define A_SArrayByFlatMapping(collection, decl, work) ({ \
  NSMutableArray *a = [NSMutableArray array]; \
  for (decl in collection) {\
    id result = work; \
    if (result != nil) { \
      [a addObject:result]; \
    } \
  } \
  a; \
})

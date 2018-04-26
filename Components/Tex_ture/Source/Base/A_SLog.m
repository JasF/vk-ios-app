//
//  A_SLog.m
//  Tex_ture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import <Async_DisplayKit/A_SLog.h>
#import <stdatomic.h>

static atomic_bool __A_SLogEnabled = ATOMIC_VAR_INIT(NO);

void A_SDisableLogging() {
    // AV: look at __A_SLogEnabled
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    atomic_store(&__A_SLogEnabled, NO);
  });
}

A_SDISPLAYNODE_INLINE BOOL A_SLoggingIsEnabled() {
  return atomic_load(&__A_SLogEnabled);
}

os_log_t A_SNodeLog() {
  return (A_SNodeLogEnabled && A_SLoggingIsEnabled()) ? A_SCreateOnce(as_log_create("org.Tex_tureGroup.Tex_ture", "Node")) : OS_LOG_DISABLED;
}

os_log_t A_SLayoutLog() {
  return (A_SLayoutLogEnabled && A_SLoggingIsEnabled()) ? A_SCreateOnce(as_log_create("org.Tex_tureGroup.Tex_ture", "Layout")) : OS_LOG_DISABLED;
}

os_log_t A_SCollectionLog() {
  return (A_SCollectionLogEnabled && A_SLoggingIsEnabled()) ?A_SCreateOnce(as_log_create("org.Tex_tureGroup.Tex_ture", "Collection")) : OS_LOG_DISABLED;
}

os_log_t A_SDisplayLog() {
  return (A_SDisplayLogEnabled && A_SLoggingIsEnabled()) ?A_SCreateOnce(as_log_create("org.Tex_tureGroup.Tex_ture", "Display")) : OS_LOG_DISABLED;
}

os_log_t A_SImageLoadingLog() {
  return (A_SImageLoadingLogEnabled && A_SLoggingIsEnabled()) ? A_SCreateOnce(as_log_create("org.Tex_tureGroup.Tex_ture", "ImageLoading")) : OS_LOG_DISABLED;
}

os_log_t A_SMainThreadDeallocationLog() {
  return (A_SMainThreadDeallocationLogEnabled && A_SLoggingIsEnabled()) ? A_SCreateOnce(as_log_create("org.Tex_tureGroup.Tex_ture", "MainDealloc")) : OS_LOG_DISABLED;
}

////////////////////////////////////////////////////////////////////////////////
//
//  TYPHOON FRAMEWORK
//  Copyright 2015, Typhoon Framework Contributors
//  All Rights Reserved.
//
//  NOTICE: The authors permit you to use, modify, and distribute this file
//  in accordance with the terms of the license agreement accompanying it.
//
////////////////////////////////////////////////////////////////////////////////


#import <Foundation/Foundation.h>
#import "TyphoonAssembly.h"
#import "VKCoreComponents.h"

@class AppDelegate;
@class VKThemeAssembly;
@class ScreensAssembly;

/**
* This is the assembly for the PocketForecast application. We'll be bootstrapping Typhoon using the iOS way, by declaring the list of
* assemblies in the application's plist.
*
* For tests, we bootstrap Typhoon in setup.
*/
@interface VKApplicationAssembly : TyphoonAssembly
@property(nonatomic, strong, readonly) VKCoreComponents *coreComponents;
@property(nonatomic, strong, readonly) VKThemeAssembly *themeProvider;
@property(nonatomic, strong, readonly) ScreensAssembly *screensAssembly;
- (AppDelegate *)appDelegate;
@end

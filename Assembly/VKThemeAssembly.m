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

#import "VKThemeAssembly.h"

/**
* This assembly illustrates the use of factory-components & collections.
*/
@implementation VKThemeAssembly

/*
- (PFTheme *)currentTheme
{
    return [TyphoonDefinition withFactory:[self themeFactory] selector:@selector(sequentialTheme)];
}

- (PFThemeFactory *)themeFactory
{
    return [TyphoonDefinition withClass:[PFThemeFactory class] configuration:^(TyphoonDefinition *definition)
    {
        [definition useInitializer:@selector(initWithThemes:) parameters:^(TyphoonMethod *initializer)
        {
            [initializer injectParameterWith:@[
                [self cloudsOverTheCityTheme],
                [self beachTheme],
                [self lightsInTheRainTheme],
                [self sunsetTheme]
            ]];
        }];
        definition.scope = TyphoonScopeSingleton;
    }];
}

- (PFTheme *)cloudsOverTheCityTheme
{
    return [TyphoonDefinition withClass:[PFTheme class] configuration:^(TyphoonDefinition *definition)
    {
        [definition injectProperty:@selector(backgroundResourceName) with:@"bg3.png"];
        [definition injectProperty:@selector(navigationBarColor) with:[UIColor colorWithHexRGB:0x641d23]];
        [definition injectProperty:@selector(forecastTintColor) with:[UIColor colorWithHexRGB:0x641d23]];
        [definition injectProperty:@selector(controlTintColor) with:[UIColor colorWithHexRGB:0x7f9588]];
    }];
}

- (PFTheme *)lightsInTheRainTheme
{
    return [TyphoonDefinition withClass:[PFTheme class] configuration:^(TyphoonDefinition *definition)
    {
        [definition injectProperty:@selector(backgroundResourceName) with:@"bg4.png"];
        [definition injectProperty:@selector(navigationBarColor) with:[UIColor colorWithHexRGB:0xeaa53d]];
        [definition injectProperty:@selector(forecastTintColor) with:[UIColor colorWithHexRGB:0x722d49]];
        [definition injectProperty:@selector(controlTintColor) with:[UIColor colorWithHexRGB:0x722d49]];
    }];
}


- (PFTheme *)beachTheme
{
    return [TyphoonDefinition withClass:[PFTheme class] configuration:^(TyphoonDefinition *definition)
    {
        [definition injectProperty:@selector(backgroundResourceName) with:@"bg5.png"];
        [definition injectProperty:@selector(navigationBarColor) with:[UIColor colorWithHexRGB:0x37b1da]];
        [definition injectProperty:@selector(forecastTintColor) with:[UIColor colorWithHexRGB:0x37b1da]];
        [definition injectProperty:@selector(controlTintColor) with:[UIColor colorWithHexRGB:0x0043a6]];
    }];
}


- (PFTheme *)sunsetTheme
{
    return [TyphoonDefinition withClass:[PFTheme class] configuration:^(TyphoonDefinition *definition)
    {
        [definition injectProperty:@selector(backgroundResourceName) with:@"sunset.png"];
        [definition injectProperty:@selector(navigationBarColor) with:[UIColor colorWithHexRGB:0x0a1d3b]];
        [definition injectProperty:@selector(forecastTintColor) with:[UIColor colorWithHexRGB:0x0a1d3b]];
        [definition injectProperty:@selector(controlTintColor) with:[UIColor colorWithHexRGB:0x606970]];
    }];
}
*/

@end

//
//  ConfigureFile.m
//  Custom Ulife
//
//  Created by yuanx on 13-12-19.
//  Copyright (c) 2013年 yuanx. All rights reserved.
//

#import "ConfigureFile.h"

@implementation ConfigureFile

static NSDictionary* plistDictionary = nil;

+(NSString*)getImageName:(NSString*)name
{
    if (name == nil)
    {
        return nil;
    }
    return [[NSString alloc] initWithFormat:@"%s.bundle/%@", APP_NAME, name];
}

+(NSString*)getConfigString:(NSString*)name;
{
    if (name)
    {
        [self createPathIfNull];
        return [plistDictionary objectForKey:name];
    }
    else
    {
        return nil;
    }
}

+(int)getConfigNumber:(NSString*)name
{
    if (name)
    {
        [self createPathIfNull];
        NSString* target = [plistDictionary objectForKey:name];
        if (target)
        {
            return [target intValue];
        }
    }
    return 0;
}

+(UIColor*)getConfigColor:(NSString*)name
{
    if (name)
    {
        [self createPathIfNull];
        NSString* target = [plistDictionary objectForKey:name];
        if (target && target.length == 7)
        {
            UIColor* color = nil;
            unsigned int hexValue = 0;
            NSScanner* scanner = [[NSScanner alloc] initWithString:[target substringFromIndex:1]];
            [scanner scanHexInt:&hexValue];
            
            color = [self colorWithHex:hexValue alpha:1.0];
            return color;
        }
    }
    return [UIColor blackColor];
}




#pragma mark - private

+(void)createPathIfNull
{
    if (plistDictionary == nil)
    {
        NSString *plistPath = [[NSBundle mainBundle] pathForResource:@APP_NAME".bundle/config" ofType:@"plist"];
        plistDictionary = [[NSDictionary alloc] initWithContentsOfFile:plistPath];
    }
}

+ (UIColor*)colorWithHex:(NSInteger)hexValue alpha:(CGFloat)alphaValue
{
    return [UIColor colorWithRed:((float)((hexValue & 0xFF0000) >> 16))/255.0
                           green:((float)((hexValue & 0xFF00) >> 8))/255.0
                            blue:((float)(hexValue & 0xFF))/255.0 alpha:alphaValue];
}


@end

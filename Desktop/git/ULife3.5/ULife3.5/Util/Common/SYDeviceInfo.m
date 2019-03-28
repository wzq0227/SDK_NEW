//
//  SYDeviceInfo.m
//  SYDeviceInfoExample
//
//  Created by shenyuanluo on 2017/11/27.
//  Copyright © 2017年 shenyuanluo. All rights reserved.
//

#import "SYDeviceInfo.h"
#import <sys/utsname.h>
#import <sys/mount.h>
#import <ifaddrs.h>
#import <arpa/inet.h>
#import <mach/mach.h>
#import <sys/socket.h>
#import <sys/sysctl.h>
#import <net/if.h>
#import <net/if_dl.h>

#import "UICKeyChainStore.h"

@implementation SYDeviceInfo


#pragma mark --  获取当前设备的'名称'
+ (SYNameType)syDeviceName
{
    struct utsname systemInfo;
    uname(&systemInfo);
    
    NSString *code = [NSString stringWithCString:systemInfo.machine
                                        encoding:NSUTF8StringEncoding];
    
    static NSDictionary *deviceNamesByCode = nil;
    
    if (!deviceNamesByCode)
    {
        deviceNamesByCode = @{
                              @"i386"       : [NSNumber numberWithUnsignedInteger:SYName_Simulator],
                              @"x86_64"     : [NSNumber numberWithUnsignedInteger:SYName_Simulator],
                              
                              // iPod
                              @"iPod1,1"    : [NSNumber numberWithUnsignedInteger:SYName_iPod],
                              @"iPod2,1"    : [NSNumber numberWithUnsignedInteger:SYName_iPod__2],
                              @"iPod3,1"    : [NSNumber numberWithUnsignedInteger:SYName_iPod__3],
                              @"iPod4,1"    : [NSNumber numberWithUnsignedInteger:SYName_iPod__4],
                              @"iPod5,1"    : [NSNumber numberWithUnsignedInteger:SYName_iPod__5],
                              @"iPod7,1"    : [NSNumber numberWithUnsignedInteger:SYName_iPod__6],
                              
                              // iPhone
                              @"iPhone1,1"  : [NSNumber numberWithUnsignedInteger:SYName_iPhone],
                              @"iPhone1,2"  : [NSNumber numberWithUnsignedInteger:SYName_iPhone_3G],
                              @"iPhone2,1"  : [NSNumber numberWithUnsignedInteger:SYName_iPhone_3GS],
                              
                              @"iPhone3,1"  : [NSNumber numberWithUnsignedInteger:SYName_iPhone_4],
                              @"iPhone3,2"  : [NSNumber numberWithUnsignedInteger:SYName_iPhone_4],
                              @"iPhone3,3"  : [NSNumber numberWithUnsignedInteger:SYName_iPhone_4],
                              @"iPhone4,1"  : [NSNumber numberWithUnsignedInteger:SYName_iPhone_4S],
                              
                              @"iPhone5,1"  : [NSNumber numberWithUnsignedInteger:SYName_iPhone_5],
                              @"iPhone5,2"  : [NSNumber numberWithUnsignedInteger:SYName_iPhone_5],
                              @"iPhone5,3"  : [NSNumber numberWithUnsignedInteger:SYName_iPhone_5C],
                              @"iPhone5,4"  : [NSNumber numberWithUnsignedInteger:SYName_iPhone_5C],
                              @"iPhone6,1"  : [NSNumber numberWithUnsignedInteger:SYName_iPhone_5S],
                              @"iPhone6,2"  : [NSNumber numberWithUnsignedInteger:SYName_iPhone_5S],
                              
                              @"iPhone7,2"  : [NSNumber numberWithUnsignedInteger:SYName_iPhone_6],
                              @"iPhone7,1"  : [NSNumber numberWithUnsignedInteger:SYName_iPhone_6_Plus],
                              @"iPhone8,1"  : [NSNumber numberWithUnsignedInteger:SYName_iPhone_6S],
                              @"iPhone8,2"  : [NSNumber numberWithUnsignedInteger:SYName_iPhone_6S_Plus],
                              
                              @"iPhone8,4"  : [NSNumber numberWithUnsignedInteger:SYName_iPhone_SE],
                              
                              @"iPhone9,1"  : [NSNumber numberWithUnsignedInteger:SYName_iPhone_7],
                              @"iPhone9,3"  : [NSNumber numberWithUnsignedInteger:SYName_iPhone_7],
                              @"iphone9,2"  : [NSNumber numberWithUnsignedInteger:SYName_iPhone_7_Plus],
                              @"iphone9,4"  : [NSNumber numberWithUnsignedInteger:SYName_iPhone_7_Plus],
                              
                              @"iPhone10,1" : [NSNumber numberWithUnsignedInteger:SYName_iPhone_8],
                              @"iPhone10,4" : [NSNumber numberWithUnsignedInteger:SYName_iPhone_8],
                              @"iPhone10,2" : [NSNumber numberWithUnsignedInteger:SYName_iPhone_8_Plus],
                              @"iPhone10,5" : [NSNumber numberWithUnsignedInteger:SYName_iPhone_8_Plus],
                              
                              @"iPhone10,3" : [NSNumber numberWithUnsignedInteger:SYName_iPhone_X],
                              @"iPhone10,6" : [NSNumber numberWithUnsignedInteger:SYName_iPhone_X],
                              
                              // iPad
                              @"iPad1,1"    : [NSNumber numberWithUnsignedInteger:SYName_iPad],
                              @"iPad2,1"    : [NSNumber numberWithUnsignedInteger:SYName_iPad__2],
                              @"iPad2,2"    : [NSNumber numberWithUnsignedInteger:SYName_iPad__2],
                              @"iPad2,3"    : [NSNumber numberWithUnsignedInteger:SYName_iPad__2],
                              @"iPad2,4"    : [NSNumber numberWithUnsignedInteger:SYName_iPad__2],
                              
                              @"iPad3,1"    : [NSNumber numberWithUnsignedInteger:SYName_iPad__3],
                              @"iPad3,2"    : [NSNumber numberWithUnsignedInteger:SYName_iPad__3],
                              @"iPad3,3"    : [NSNumber numberWithUnsignedInteger:SYName_iPad__3],
                              
                              @"iPad3,4"    : [NSNumber numberWithUnsignedInteger:SYName_iPad__4],
                              @"iPad3,5"    : [NSNumber numberWithUnsignedInteger:SYName_iPad__4],
                              @"iPad3,6"    : [NSNumber numberWithUnsignedInteger:SYName_iPad__4],
                              
                              @"iPad6,11"   : [NSNumber numberWithUnsignedInteger:SYName_iPad__5],
                              @"iPad6,12"   : [NSNumber numberWithUnsignedInteger:SYName_iPad__5],
                              
                              // iPad Air
                              @"iPad4,1"    : [NSNumber numberWithUnsignedInteger:SYName_iPad_Air],
                              @"iPad4,2"    : [NSNumber numberWithUnsignedInteger:SYName_iPad_Air],
                              @"iPad4,3"    : [NSNumber numberWithUnsignedInteger:SYName_iPad_Air],
                              @"iPad5,3"    : [NSNumber numberWithUnsignedInteger:SYName_iPad_Air__2],
                              @"iPad5,4"    : [NSNumber numberWithUnsignedInteger:SYName_iPad_Air__2],
                              
                              // iPad mini
                              @"iPad2,5"    : [NSNumber numberWithUnsignedInteger:SYName_iPad_Mini],
                              @"iPad2,6"    : [NSNumber numberWithUnsignedInteger:SYName_iPad_Mini],
                              @"iPad2,7"    : [NSNumber numberWithUnsignedInteger:SYName_iPad_Mini],
                              
                              @"iPad4,4"    : [NSNumber numberWithUnsignedInteger:SYName_iPad_Mini__2],
                              @"iPad4,5"    : [NSNumber numberWithUnsignedInteger:SYName_iPad_Mini__2],
                              @"iPad4,6"    : [NSNumber numberWithUnsignedInteger:SYName_iPad_Mini__2],
                              
                              @"iPad4,7"    : [NSNumber numberWithUnsignedInteger:SYName_iPad_Mini__3],
                              @"iPad4,8"    : [NSNumber numberWithUnsignedInteger:SYName_iPad_Mini__3],
                              @"iPad4,9"    : [NSNumber numberWithUnsignedInteger:SYName_iPad_Mini__3],
                              
                              @"iPad5,1"    : [NSNumber numberWithUnsignedInteger:SYName_iPad_Mini__4],
                              @"iPad5,2"    : [NSNumber numberWithUnsignedInteger:SYName_iPad_Mini__4],
                              
                              // iPad Pro
                              @"iPad6,3"    : [NSNumber numberWithUnsignedInteger:SYName_iPad_Pro_9_7],
                              @"iPad6,4"    : [NSNumber numberWithUnsignedInteger:SYName_iPad_Pro_9_7],
                              
                              @"iPad7,3"    : [NSNumber numberWithUnsignedInteger:SYName_iPad_Pro_10_5],
                              @"iPad7,4"    : [NSNumber numberWithUnsignedInteger:SYName_iPad_Pro_10_5],
                              
                              @"iPad6,7"    : [NSNumber numberWithUnsignedInteger:SYName_iPad_Pro_12_9],
                              @"iPad6,8"    : [NSNumber numberWithUnsignedInteger:SYName_iPad_Pro_12_9],
                              
                              @"iPad7,1"    : [NSNumber numberWithUnsignedInteger:SYName_iPad_Pro_12_9__2],
                              @"iPad7,2"    : [NSNumber numberWithUnsignedInteger:SYName_iPad_Pro_12_9__2],
                              };
    }
    
    NSNumber *nameNumber = [deviceNamesByCode objectForKey:code];
    if(nameNumber)
    {
        return [nameNumber unsignedIntegerValue];
    }
    
    return SYName_Unknow;
}


#pragma mark -- 获取当前设备的‘类型’
+ (SYDeviceType)syDeviceType
{
    SYDeviceType deviceType = SYType_Unknow;
    
    SYNameType nameType = [self syDeviceName];
    if (SYName_Simulator == nameType)
    {
        deviceType = SYType_Simulator;
    }
    else if (SYName_iPod == nameType
             || SYName_iPod__2 == nameType
             || SYName_iPod__3 == nameType
             || SYName_iPod__4 == nameType
             || SYName_iPod__5 == nameType
             || SYName_iPod__6 == nameType)
    {
        deviceType = SYType_iPod;
    }
    else if (SYName_iPhone == nameType
             || SYName_iPhone_3G == nameType
             || SYName_iPhone_3GS == nameType
             || SYName_iPhone_4 == nameType
             || SYName_iPhone_4S == nameType
             || SYName_iPhone_5 == nameType
             || SYName_iPhone_5C == nameType
             || SYName_iPhone_5S == nameType
             || SYName_iPhone_6 == nameType
             || SYName_iPhone_6_Plus == nameType
             || SYName_iPhone_6S == nameType
             || SYName_iPhone_6S_Plus == nameType
             || SYName_iPhone_SE == nameType
             || SYName_iPhone_7 == nameType
             || SYName_iPhone_7_Plus == nameType
             || SYName_iPhone_8 == nameType
             || SYName_iPhone_8_Plus == nameType
             || SYName_iPhone_X == nameType)
    {
        deviceType = SYType_iPhone;
    }
    else if (SYName_iPad == nameType
             || SYName_iPad__2 == nameType
             || SYName_iPad__3 == nameType
             || SYName_iPad__4 == nameType
             || SYName_iPad__5 == nameType
             || SYName_iPad_Air == nameType
             || SYName_iPad_Air__2 == nameType
             || SYName_iPad_Mini == nameType
             || SYName_iPad_Mini__2 == nameType
             || SYName_iPad_Mini__3 == nameType
             || SYName_iPad_Mini__4 == nameType
             || SYName_iPad_Pro_9_7 == nameType
             || SYName_iPad_Pro_10_5 == nameType
             || SYName_iPad_Pro_12_9 == nameType
             || SYName_iPad_Pro_12_9__2 == nameType)
    {
        deviceType = SYType_iPad;
    }
    
    return deviceType;
}


#pragma mark -- 获取当前设备屏幕的‘大小’
+ (SYScreenType)syScreenType
{
    SYScreenType screenSize = SYScreen_Unknow;
    
    SYNameType nameType = [self syDeviceName];
    
    if (SYName_iPod == nameType
        || SYName_iPad__2 == nameType
        || SYName_iPad__3 == nameType
        || SYName_iPad__4 == nameType)
    {
        screenSize = SYScreen_iPod_3_5;
    }
    else if (SYName_iPod__5 == nameType
             || SYName_iPod__6 == nameType)
    {
        screenSize = SYScreen_iPod_4_0;
    }
    else if (SYName_iPhone_3G == nameType
             || SYName_iPhone_3GS == nameType
             || SYName_iPhone_4 == nameType
             || SYName_iPhone_4S == nameType)
    {
        screenSize = SYScreen_iPhone_3_5;
    }
    else if (SYName_iPhone_5 == nameType
             || SYName_iPhone_5C == nameType
             || SYName_iPhone_5S == nameType
             || SYName_iPhone_SE == nameType)
    {
        screenSize = SYScreen_iPhone_4_0;
    }
    else if (SYName_iPhone_6 == nameType
             || SYName_iPhone_6S == nameType
             || SYName_iPhone_7 == nameType
             || SYName_iPhone_8 == nameType)
    {
        screenSize = SYScreen_iPhone_4_7;
    }
    else if (SYName_iPhone_6_Plus == nameType
             || SYName_iPhone_6S_Plus == nameType
             || SYName_iPhone_7_Plus == nameType
             || SYName_iPhone_8_Plus == nameType)
    {
        screenSize = SYScreen_iPhone_5_5;
    }
    else if (SYName_iPhone_X == nameType)
    {
        screenSize = SYScreen_iPhone_5_8;
    }
    else if (SYName_iPad_Mini == nameType
             || SYName_iPad_Mini__2 == nameType
             || SYName_iPad_Mini__3 == nameType
             || SYName_iPad_Mini__4 == nameType)
    {
        screenSize = SYScreen_iPad_7_9;
    }
    else if (SYName_iPad == nameType
             || SYName_iPad__2 == nameType
             || SYName_iPad__3 == nameType
             || SYName_iPad__4 == nameType
             || SYName_iPad__5 == nameType
             || SYName_iPad_Air == nameType
             || SYName_iPad_Air__2 == nameType
             || SYName_iPad_Pro_9_7 == nameType)
    {
        screenSize = SYScreen_iPad_9_7;
    }
    else if (SYName_iPad_Pro_10_5 == nameType)
    {
        screenSize = SYScreen_iPad_10_5;
    }
    else if (SYName_iPad_Pro_12_9 == nameType
             || SYName_iPad_Pro_12_9__2 == nameType)
    {
        screenSize = SYScreen_iPad_12_9;
    }
    
    return screenSize;
}

+ (NSString*)identifierForVender{
    UICKeyChainStore *keyChain = [UICKeyChainStore keyChainStore];
    NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
    
    bool keyExist = [keyChain contains:bundleID];
    NSString *uuidStr = nil;
    if (keyExist) {
        uuidStr = [keyChain stringForKey:bundleID];
        return uuidStr;
    }
    
    uuidStr = [[[[UIDevice currentDevice] identifierForVendor] UUIDString] stringByAppendingString:bundleID];
    NSLog(@"uuidStr2:%@",uuidStr);
    
    
    [keyChain setString:uuidStr forKey:bundleID];
    return uuidStr;
}

@end

//
//  UIDevice+LWTDeviceModel.m
//  WiFi
//
//  Created by shenyuanluo on 2017/5/27.
//  Copyright © 2017年 goscam_sz. All rights reserved.
//

#import "UIDevice+LWTDeviceModel.h"
#import <sys/utsname.h>

@implementation UIDevice (LWTDeviceModel)

- (DeviceType)deviceType
{
    struct utsname systemInfo;
    uname(&systemInfo);
    
    NSString *code = [NSString stringWithCString:systemInfo.machine
                                        encoding:NSUTF8StringEncoding];
    
    static NSDictionary *deviceNamesByCode = nil;
    
    if (!deviceNamesByCode) {
        
        deviceNamesByCode = @{
                              @"i386"      : [NSNumber numberWithInteger:Device_Simulator],
                              @"x86_64"    : [NSNumber numberWithInteger:Device_Simulator],
                              
                              @"iPod1,1"   : [NSNumber numberWithInteger:Device_iPod1],
                              @"iPod2,1"   : [NSNumber numberWithInteger:Device_iPod2],
                              @"iPod3,1"   : [NSNumber numberWithInteger:Device_iPod3],
                              @"iPod4,1"   : [NSNumber numberWithInteger:Device_iPod4],
                              @"iPod5,1"   : [NSNumber numberWithInteger:Device_iPod5],
                              @"iPod7,1"   : [NSNumber numberWithInteger:Device_iPod6],
                              
                              @"iPad1,1"   : [NSNumber numberWithInteger:Device_iPad1],
                              @"iPad2,1"   : [NSNumber numberWithInteger:Device_iPad2],
                              @"iPad2,2"   : [NSNumber numberWithInteger:Device_iPad2],
                              @"iPad2,3"   : [NSNumber numberWithInteger:Device_iPad2],
                              @"iPad2,4"   : [NSNumber numberWithInteger:Device_iPad2],
                              @"iPad2,5"   : [NSNumber numberWithInteger:Device_iPadMini1],
                              @"iPad2,6"   : [NSNumber numberWithInteger:Device_iPadMini1],
                              @"iPad2,7"   : [NSNumber numberWithInteger:Device_iPadMini1],
                              @"iPad3,1"   : [NSNumber numberWithInteger:Device_iPad3],
                              @"iPad3,2"   : [NSNumber numberWithInteger:Device_iPad3],
                              @"iPad3,3"   : [NSNumber numberWithInteger:Device_iPad3],
                              @"iPad3,4"   : [NSNumber numberWithInteger:Device_iPad4],
                              @"iPad3,5"   : [NSNumber numberWithInteger:Device_iPad4],
                              @"iPad3,6"   : [NSNumber numberWithInteger:Device_iPad4],
                              @"iPad4,1"   : [NSNumber numberWithInteger:Device_iPadAir1],
                              @"iPad4,2"   : [NSNumber numberWithInteger:Device_iPadAir1],
                              @"iPad4,3"   : [NSNumber numberWithInteger:Device_iPadAir1],
                              @"iPad4,4"   : [NSNumber numberWithInteger:Device_iPadMini2],
                              @"iPad4,5"   : [NSNumber numberWithInteger:Device_iPadMini2],
                              @"iPad4,6"   : [NSNumber numberWithInteger:Device_iPadMini2],
                              @"iPad4,7"   : [NSNumber numberWithInteger:Device_iPadMini3],
                              @"iPad4,8"   : [NSNumber numberWithInteger:Device_iPadMini3],
                              @"iPad4,9"   : [NSNumber numberWithInteger:Device_iPadMini3],
                              @"iPad5,1"   : [NSNumber numberWithInteger:Device_iPadMini4],
                              @"iPad5,2"   : [NSNumber numberWithInteger:Device_iPadMini4],
                              @"iPad5,3"   : [NSNumber numberWithInteger:Device_iPadAir2],
                              @"iPad5,4"   : [NSNumber numberWithInteger:Device_iPadAir2],
                              @"iPad6,3"   : [NSNumber numberWithInteger:Device_iPadPro1],
                              @"iPad6,4"   : [NSNumber numberWithInteger:Device_iPadPro1],
                              @"iPad6,7"   : [NSNumber numberWithInteger:Device_iPadPro2],
                              @"iPad6,8"   : [NSNumber numberWithInteger:Device_iPadPro2],
                              @"iPad6,11"  : [NSNumber numberWithInteger:Device_iPad4],
                              @"iPad6,12"  : [NSNumber numberWithInteger:Device_iPad4],
                              
                              @"iPhone3,1" : [NSNumber numberWithInteger:Device_iPhone4],
                              @"iPhone3,2" : [NSNumber numberWithInteger:Device_iPhone4],
                              @"iPhone3,3" : [NSNumber numberWithInteger:Device_iPhone4],
                              @"iPhone4,1" : [NSNumber numberWithInteger:Device_iPhone4S],
                              @"iPhone5,1" : [NSNumber numberWithInteger:Device_iPhone5],
                              @"iPhone5,2" : [NSNumber numberWithInteger:Device_iPhone5],
                              @"iPhone5,3" : [NSNumber numberWithInteger:Device_iPhone5C],
                              @"iPhone5,4" : [NSNumber numberWithInteger:Device_iPhone5C],
                              @"iPhone6,1" : [NSNumber numberWithInteger:Device_iPhone5S],
                              @"iPhone6,2" : [NSNumber numberWithInteger:Device_iPhone5S],
                              @"iPhone7,1" : [NSNumber numberWithInteger:Device_iPhone6plus],
                              @"iPhone7,2" : [NSNumber numberWithInteger:Device_iPhone6],
                              @"iPhone8,1" : [NSNumber numberWithInteger:Device_iPhone6S],
                              @"iPhone8,2" : [NSNumber numberWithInteger:Device_iPhone6Splus],
                              @"iphone8,4" : [NSNumber numberWithInteger:Device_iPhoneSE],
                              @"iPhone9,1" : [NSNumber numberWithInteger:Device_iPhone7],
                              @"iphone9,2" : [NSNumber numberWithInteger:Device_iPhone7plus],
                              @"iPhone9,3" : [NSNumber numberWithInteger:Device_iPhone7],
                              @"iphone9,4" : [NSNumber numberWithInteger:Device_iPhone7plus]
                              };
    }
    
    NSString* deviceName = [deviceNamesByCode objectForKey:code];
    if(deviceName)
    {
        return [deviceName integerValue];
    }
    
    return Device_Unrecognized;
}



- (ScreenType)screenType
{
    ScreenType iPhoneScreenSize = Screen_Unknow;
    
    DeviceType currentDeviceType = [self deviceType];
    if (Device_iPhone4 == currentDeviceType
        || Device_iPhone4S == currentDeviceType)
    {
        iPhoneScreenSize = Screen_iPhone_3_5_inch;
    }
    else if (Device_iPhone5 == currentDeviceType
             || Device_iPhone5C == currentDeviceType
             || Device_iPhone5S == currentDeviceType
             || Device_iPhoneSE == currentDeviceType)
    {
        iPhoneScreenSize = Screen_iPhone_4_0_inch;
    }
    else if (Device_iPhone6 == currentDeviceType
             || Device_iPhone6S == currentDeviceType
             || Device_iPhone7 == currentDeviceType)
    {
        iPhoneScreenSize = Screen_iPhone_4_7_inch;
    }
    else if (Device_iPhone6plus == currentDeviceType
             || Device_iPhone6Splus == currentDeviceType
             || Device_iPhone7plus == currentDeviceType)
    {
        iPhoneScreenSize = Screen_iPhone_5_5_inch;
    }
    
    return iPhoneScreenSize;
}

@end

//
//  UIDevice+LWTDeviceModel.h
//  WiFi
//
//  Created by shenyuanluo on 2017/5/27.
//  Copyright © 2017年 goscam_sz. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, DeviceType) {
    Device_Unrecognized     = -1,
    Device_Simulator,
    Device_iPhone4,
    Device_iPhone4S,
    Device_iPhone5,
    Device_iPhone5C,
    Device_iPhone5S,
    Device_iPhone6,
    Device_iPhone6plus,
    Device_iPhone6S,
    Device_iPhone6Splus,
    Device_iPhoneSE,
    Device_iPhone7,
    Device_iPhone7plus,
    Device_iPad1,
    Device_iPad2,
    Device_iPad3,
    Device_iPad4,
    Device_iPad5,
    Device_iPadAir1,
    Device_iPadAir2,
    Device_iPadMini1,
    Device_iPadMini2,
    Device_iPadMini3,
    Device_iPadMini4,
    Device_iPadPro1,
    Device_iPadPro2,
    Device_iPod1,
    Device_iPod2,
    Device_iPod3,
    Device_iPod4,
    Device_iPod5,
    Device_iPod6,
};

typedef NS_ENUM(NSInteger, ScreenType) {
    Screen_Unknow           = -1,
    Screen_iPhone_3_5_inch,         // iPhone 3.5 英寸屏幕
    Screen_iPhone_4_0_inch,         // iPhone 4.0 英寸屏幕
    Screen_iPhone_4_7_inch,         // iPhone 4.7 英寸屏幕
    Screen_iPhone_5_5_inch,         // iPhone 5.5 英寸屏幕
};

@interface UIDevice (LWTDeviceModel)

/**
 获取当前设备的类型：iPhone 4s、iPhone 5s、iPhone 6s、iPhone 6s plus...

 @return 具体的设备类型, 详见‘DeviceType’
 */
- (DeviceType)deviceType;



/**
 获取屏幕尺寸大小

 @return 屏幕大小，详见‘ScreenType’
 */
- (ScreenType)screenType;

@end

//
//  ScanThreeViewController.h
//  UI——update
//
//  Created by goscam_sz on 16/6/30.
//  Copyright © 2016年 goscam_sz. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AddDeviceStyleModel.h"
#import "MediaHeader.h"

typedef NS_ENUM(NSUInteger, scanType) {
    //扫描二维码
    scanTypeQRCode = 0,
    
    //Wifi添加
    scanTypeWiFi,
    
    //设备不在线 wifiSetting
    scanTypeWiFiSetting
};

@interface ScanThreeViewController : UIViewController
@property(nonatomic,strong) NSString *UID;
@property(nonatomic,strong) NSString *devName;

@property (nonatomic,assign) GosDeviceType deviceType;  //设备类型

/**
 界面扫描形式---用于判断是哪个页面的弹窗
 */
@property(nonatomic,assign)scanType scanType;

@end

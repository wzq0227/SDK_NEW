//
//  QrcodeSetingViewController.h
//  ULife3.5
//
//  Created by goscam_sz on 2017/6/8.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DeviceDataModel.h"

@interface QrcodeSetingViewController : UIViewController

/** smart连接方式：
 0   不支持smart
 1   7601smart
 2   8188smart
 3   ap6212a
 9   不支持二维码扫描
 10  只支持二维码扫描
 11  二维码扫描+7601smart
 12  二维码扫描+8188smart
 13  二维码扫描+ap6212a
 **/

@property (nonatomic,assign) int  smartflag;   //连接方式

@property (nonatomic,copy) NSString * devId;   //设备ID；

@property (nonatomic,copy) NSString * devName; //设备名称

@property (strong, nonatomic)  DeviceDataModel *devModel;

@end

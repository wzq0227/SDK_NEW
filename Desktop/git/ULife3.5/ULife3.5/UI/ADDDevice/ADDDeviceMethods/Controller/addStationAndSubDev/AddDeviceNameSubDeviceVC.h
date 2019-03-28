//
//  AddDeviceNameSubDeviceVC.h
//  ULife3.5
//
//  Created by Goscam on 2018/3/22.
//  Copyright © 2018年 GosCam. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DeviceDataModel.h"

typedef NS_ENUM(NSUInteger, DeviceTypeEnum) {
    DeviceTypeEnumStation,
    DeviceTypeEnumWirelessCamera,
    DeviceTypeEnumDoorbell,
};

@interface AddDeviceNameSubDeviceVC : UIViewController

@property (assign, nonatomic)  DeviceTypeEnum devType;

@property (strong, nonatomic)  NSString *deviceId;

@property (nonatomic, strong)  DeviceDataModel *devModel;

@end

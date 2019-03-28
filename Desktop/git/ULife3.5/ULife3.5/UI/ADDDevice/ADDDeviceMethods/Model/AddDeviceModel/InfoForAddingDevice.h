//
//  InfoForAddingDevice.h
//  ULife3.5
//
//  Created by Goscam on 2018/4/16.
//  Copyright © 2018年 GosCam. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AddDeviceStyleModel.h"
#import "MediaHeader.h"

@interface InfoForAddingDevice : NSObject

@property (nonatomic,assign) SmartConnectStyle smartStyle;              //smart连接方式

@property (nonatomic,copy) NSString * devId;            //设备ID

@property (nonatomic,copy) NSString * devWifiPassWord;  //wifi密码

@property (nonatomic,copy) NSString * devWifiName;      //wifi名称

@property (nonatomic,copy) NSString * devName;          //设备名称

@property (nonatomic,assign)GosDeviceType deviceType;  //设备类型

@property (assign, nonatomic) AddDeviceByStyle addDeviceMode;

@property (assign, nonatomic)  BOOL supportForceUnbind;

@property (assign, nonatomic)  BOOL addedByOthers;      //是否已被别人绑定

@end

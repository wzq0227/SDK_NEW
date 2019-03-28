//
//  DeviceManagement.h
//  ULife3.5
//
//  Created by shenyuanluo on 2017/6/6.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DeviceDataModel.h"

typedef void(^RemoveAllDevBlock)(int result);


@interface DeviceManagement : NSObject

+ (DeviceManagement *)sharedInstance;


/**
 添加设备数据模型

 @param deviceModel 设备数据模型
 @return 添加是否成功；YES：成功，NO：失败
 */
- (BOOL)addDeviceModel:(DeviceDataModel *)deviceModel;


/**
 移除设备数据模型

 @param deviceModel 设备数据模型
 @return 移除是否成功；YES：成功，NO：失败
 */
- (BOOL)deleteDevcieModel:(DeviceDataModel *)deviceModel;


/**
 根据设备 ID 获取设备数据模型

 @param deviceId 设备 ID
 @return 设备数据模型
 */
- (DeviceDataModel *)getDevcieModelWithDeviceId:(NSString *)deviceId;


/**
 更新设备数据模型

 @param deviceModel 设备数据模型
 @return 更新是否成功；YES：成功，NO：失败
 */
- (BOOL)updateDeviceModel:(DeviceDataModel *)deviceModel;


/**
 移除所有的设备 model(注销账号时)

 */
- (void)removeAllDevModelResult:(RemoveAllDevBlock)result;


/**
 获取设备列表数据模型数组

 @return 列表数组
 */
- (NSMutableArray <DeviceDataModel *> *)deviceListArray;


@end

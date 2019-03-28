//
//  SensorDB.h
//  Ulife2.0
//
//  Created by goscam on 15/12/22.
//  Copyright © 2015年 goscam_sz. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FMDB.h"
#import "UserModel.h"
#import "DevicePlayManager.h"
#import "DeviceDataModel.h"
#import "PushMessageModel.h"

@interface UserDB : NSObject

+ (UserDB *)sharedInstance;

#pragma mark - 用户管理
/**
 插入用户数据 model


 @param userModel 用户数据 model
 @return 插入是否成功；YES：成功，NO：失败
 */
- (BOOL)insertUserModel:(UserModel *)userModel;


/**
 删除用户数据 model

 @param userModel 用户数据 model
 @return 删除是否成功；YES：成功，NO：失败
 */
- (BOOL)deleteUserModel:(UserModel *)userModel;


/**
 修改用户密码

 @param userModel 用户数据 model
 @return 修改是否成功；YES：成功，NO：失败
 */
- (BOOL)updateUserPassword:(UserModel *)userModel;


#pragma mark - 设备管理
/**
 插入设备数据 model

 @param deviceModel 设备数据 model
 @return 插入是否成功；YES：成功，NO：失败
 */
- (BOOL)insertDeviceModel:(DeviceDataModel *)deviceModel;


/**
 删除设备数据 model

 @param deviceModel 设备数据 model
 @return 删除是否成功；YES：成功，NO：失败
 */
- (BOOL)deleteDeviceModel:(DeviceDataModel *)deviceModel;


/**
 修改设备 昵称

 @param deviceModel 设备数据 model
 @return 修改是否成功；YES：成功，NO：失败
 */
- (BOOL)updataDeviceNikeName:(DeviceDataModel *)deviceModel;


/**
 修改设备取流密码

 @param deviceModel 设备数据 model
 @return 修改是否成功；YES：成功，NO：失败
 */
- (BOOL)updataDevicePassWord:(DeviceDataModel *)deviceModel;


/**
 获取 当前登录 email 设备列表
 
 @return 符合条件的 设备 model 数组
 */
- (NSMutableArray *)deviceListArray;


/**
 删除当前所有设备

 @return 删除是否成功；YES：成功，NO：失败
 */
- (BOOL)removeAllDevice;


#pragma mark - 推送告警消息

/* 移除子设备的所有相关推送信息 */
- (void)removePushMsgsOfSubDevice:(NSString*)subID inDevice:(NSString*)deviceId;

/**
 添加推送消息 model

 @param model 推送消息 model
 @return 添加是否成功；YES：成功，NO：失败
 */
- (BOOL)insertPushMessageModel:(PushMessageModel *)model;


/**
 删除推送消息 model

 @param pushMsgModel 推送消息 model
 @return 删除是否成功；YES：成功，NO：失败
 */
- (BOOL)deletePushMessageModel:(PushMessageModel *)pushMsgModel;


/**
 更新推送消息读状态

 @param model 推送消息 model
 @return 更新是否成功；YES：成功，NO：失败
 */
- (BOOL)updatePushMsgReadState:(PushMessageModel *)model;


/**
 获取当前登录 email 所有的推送 model

 @return 推送 model 数组
 */
- (NSMutableArray <PushMessageModel *>*)pushMessageArray;

/**
 根据设备 ID 获取设备的所有推送

 @param deviceId 设备 第
 @return 推送消息列表
 */
- (NSMutableArray <PushMessageModel *>*)pushMsgArrayWidthDevId:(NSString *)deviceId;


/**
 删除所有表
 */
- (void)deleteAllTable;

/**
 关闭数据库
 */
- (void)closeDB;


@end

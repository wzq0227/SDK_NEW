//
//  PushMessageManagement.h
//  ULife3.5
//
//  Created by shenyuanluo on 2017/6/12.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PushMessageModel.h"



@interface PushMessageManagement : NSObject

+ (instancetype)sharedInstance;


/**
 添加新推送

 @param pushMsgModel 推送消息 model
 @return 添加是否成功；YES：成功，NO：失败
 */
- (BOOL)addPushMessage:(PushMessageModel *)pushMsgModel;


/**
 删除推送消息

 @param pushMsgModel 推送消息 model
 @return 删除是否成功；YES：成功，NO：失败
 */
- (BOOL)deletePushMessage:(PushMessageModel *)pushMsgModel;

- (void)deletePushMsgsOfDevice:(NSString *)deviceID;


/**
 更新推送消息的查看状态

 @param pushMsgModel 推送消息 model
 @return 更新是否成功；YES：成功，NO：失败
 */
- (BOOL)updateReadState:(PushMessageModel *)pushMsgModel;


/**
 获取当前账号下的所有推送消息列表

 @return 推送消息列表
 */
- (NSMutableArray <PushMessageModel *>*)pushMessageArray;


/**
 根据设备 ID 获取该设备的所有推送

 @param deviceId 设备ID
 @return 推送消息列表
 */
- (NSMutableArray <PushMessageModel *>*)pushMsgArrayWithDevId:(NSString *)deviceId;




@end

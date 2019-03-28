//
//  PushMessageModel.h
//  ULife3.5
//
//  Created by shenyuanluo on 2017/6/7.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import <Foundation/Foundation.h>


/**
 *  推送消息‘读’状态
 */
typedef NS_ENUM(NSInteger, APNSMsgReadState) {
    APNSMsgReadNo               = 0,            // 未读
    APNSMsgReading,                             // 正在读
    APNSMsgReaded,                              // 已读
};


/**
 *  推送消息类型
 */
typedef NS_ENUM(NSInteger, APNSMsgType) {
    APNSMsgMove                 = 0,            // 移动侦测
    APNSMsgGuard,                               //
    APNSMsgPir,                                 // PIR 侦测
    APNSMsgTemperatureUpperLimit,               // 温度上限
    APNSMsgTemperatureLowerLimit,               // 温度下限
    APNSMsgVoice,                               // 声音
    APNSMsgBellRing,                            // 按铃
    APNSMsgLowBattery,                          // 低电量
};


@interface PushMessageModel : NSObject  <
                                            NSCopying,
                                            NSMutableCopying
                                        >
@property (nonatomic, assign) NSInteger serialNum;                  // 序号
@property (nonatomic, copy) NSString *email;                        // 当前登录账号的邮箱
@property (nonatomic, copy) NSString *deviceId;                     // 设备 ID
@property (nonatomic, copy) NSString *deviceName;                   // 设备昵称
@property (nonatomic, copy) NSString *pushUrl;                      // 推送 URL
@property (nonatomic, copy) NSString *pushTime;                     // 推送时间 yyyy-MM-dd HH:mm:ss
@property (nonatomic, assign) APNSMsgReadState apnsMsgReadState;    // 推送消息读状态
@property (nonatomic, assign) APNSMsgType apnsMsgType;              // 推送消息类型

@property (nonatomic, assign) BOOL isShowDelete;                    // 是否显示删除图标
@property (nonatomic, assign) BOOL isSelectDelete;                  // 是否选择删除

@property (nonatomic, assign) NSInteger subChannel;                 // 子设备通道号

@property (nonatomic, strong)  NSString *subDeviceID;               // 子设备ID

@end

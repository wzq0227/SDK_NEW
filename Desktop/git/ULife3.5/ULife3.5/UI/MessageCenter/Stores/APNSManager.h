//
//  APNSManager.h
//  ULife3.5
//
//  Created by shenyuanluo on 2017/6/12.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PushMessageModel.h"


#define APNS_MSG_MOVE_KEY       @"VIDEO MOTION"                     // 移动监测推送
#define APNS_MSG_MOVE_KEY1       @"Monitor MOTION Alert"                     // 移动监测推送2
#define APNS_MSG_PIR_KEY        @"PIR MOTION"                       // PIR推送
#define APNS_MSG_VOICE_KEY      @"AUDIO MOTION"                     // 声音告警
#define APNS_MSG_VOICE_KEY1     @"Monitor Audio Alert"             //声音报警
#define APNS_MSG_UP_LIMIT_KEY   @"HIGH TEMPERATURE ALARM"           // 温度上限推送
#define APNS_MSG_LOW_LIMIT_KEY  @"LOW TEMPERATURE ALARM"            // 温度下限推送
#define APNS_MSG_LOW_BATTERY_KEY  @"LOW BATTERY"                    // 低电量
#define APNS_MSG_BELL_RING_KEY  @"BELL RING"                    // 按铃

@interface APNSManager : NSObject


+ (instancetype)shareManager;


@property (nonatomic,strong)PushMessageModel *pushDeviceModel;

@property (nonatomic,strong)NSData *deviceToken;

/**
 注册 APNS
 */
- (void)registerPush;


/**
 发送设备 token 到服务器

 @param deviceToken 设备 token
 */
-(void)sendDeviceTokenToServer:(NSData *)deviceToken;


/**
 处理 APNS 消息

 @param userInfo APNS 消息
 */
- (void)handleRemoteNotification:(NSDictionary *)userInfo withClick:(BOOL)isClick;

//点击推送进入
@property(nonatomic,assign)BOOL isPushLaunch;

@end

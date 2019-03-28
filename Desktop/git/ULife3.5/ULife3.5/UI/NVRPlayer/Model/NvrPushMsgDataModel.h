//
//  NvrPushMsgDataModel.h
//  ULife3.5
//
//  Created by shenyuanluo on 2017/8/14.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PushMessageModel.h"

@interface NvrPushMsgDataModel : NSObject

/** 设备名称 使用 ‘strong’ 修饰保持更新 */
@property (nonatomic, strong) NSString *deviceName;

/** 推送消息体 */
@property (nonatomic, copy) NSString *msgContent;

/** 推送消息时间 */
@property (nonatomic, copy) NSString *pushTime;

/** 消息类型 */
@property (nonatomic, assign) APNSMsgType msgType;

@end

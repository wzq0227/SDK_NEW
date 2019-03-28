//
//  DeviceConnectModel.h
//  ULife3.5
//
//  Created by 广东省深圳市 on 2017/7/13.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DeviceDataModel.h"

/**
 连接状态Model
 */
@interface DeviceConnectModel : NSObject

/**
 连接状态的deviceID
 */
@property(nonatomic,copy)NSString *deviceID;

/**
 是否上一次连接失败
 */
@property(nonatomic,assign)BOOL isLastConnectFail;

/**
 上一次连接失败时间 --since1970的值
 */
@property(nonatomic,assign)NSUInteger lastConnectFailTime;

/**
 连接成功时候的sid 如果是wifi情况下有sid 如果是4G则是字符串4G 用来判断是否需要重新连接
 */
@property(nonatomic,copy)NSString *connectSuccessSid;

/**
 是否正在连接
 */
@property(nonatomic,assign)BOOL isConnecting;


/**
 是否需要重连
 */
@property(nonatomic,assign)BOOL isNeedReconnect;

/**
 是否连接成功
 */
@property(nonatomic,assign)BOOL isConnectingSuccess;

/**
 连接连续失败次数
 */
@property(nonatomic,assign)NSUInteger connectFailCount;


/**
 需要连接的原始deviceDataModel
 */
@property(nonatomic,strong)DeviceDataModel *deviceDataModel;

/**
 是否在线---这个是最精准的以这个为主
 */
@property(nonatomic,assign)BOOL isOnline;

@end

//
//  NetSDK.h
//  NetSDK
//
//  Created by zhuochuncai on 10/4/17.
//  Copyright © 2017年 Gospell. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NetSDK : NSObject

typedef void(^CommandBlock)(int result, NSDictionary *dict);
typedef void(^ResultBlock)(int result);


+ (id)sharedInstance;

-(void)setPort:(int)str;

-(int)getPort;

- (long)net_init;

- (long)net_unInit;

- (void)net_loginWithReqData:(NSDictionary*)data timeout:(int)timeout result:(ResultBlock)resultBlock;

- (void)net_loginWithIP:(NSString*)ip port:(int)port userName:(NSString*)userName password:(NSString*)pwd timeout:(int)timeout result:(CommandBlock)resultBlock;

- (long)net_connectToCBSWithAddress:(NSString*)address nport:(int)port resultBlock:(ResultBlock)result;

- (long)net_connectToCMSWithAddress:(NSString*)address nport:(int)port resultBlock:(ResultBlock)result;



- (long)net_closeCBSConnect;

- (long)net_startHeartBeatWithHandle:(long)lHandle data:(NSData*)data;

- (long)net_stopHeartBeatWithHandle:(long)lHandle;


- (void)net_sendBypassRequestWithUID:(NSString *)UID requestData:(NSDictionary*)data timeout:(int)timeout responseBlock:(CommandBlock)result;

- (void)net_sendCBSRequestMsgType:(NSString*)type bodyData:(NSMutableDictionary*)data timeout:(int)timeout responseBlock:(CommandBlock)result;

- (void)net_sendCBSRequestWithData:(NSDictionary*)data timeout:(int)timeout responseBlock:(CommandBlock)result;

- (void)net_sendCMSRequestWithData:(NSDictionary*)data timeout:(int)timeout responseBlock:(CommandBlock)result;


- (void)net_queryDeviceVersionWithIP:(NSString*)ip port:(int)port data:(NSData*)data responseBlock:(CommandBlock)result;

/**
 获取APP最新版本
 */
- (void)net_queryAPPVersionWithIP:(NSString*)ip port:(int)port data:(NSDictionary *)dataDict responseBlock:(CommandBlock)result;

/**
 获取CBSPort端口
 */
- (void)net_getCBSPortWithIP:(NSString*)ip port:(int)port data:(NSDictionary *)dataDict responseBlock:(CommandBlock)result;

- (void)net_sendSyncRequestWithIP:(NSString*)ip port:(int)port data:(NSData*)data timeout:(int)millisecond responseBlock:(CommandBlock)result;


/**
 设置加密key
 */
- (void)setcriptKey:(NSString *)criptKey;

/**
 加密
 */
- (NSString *)encodePassword:(NSString *)password;

/**
 设置CBS地址和端口
 */
- (void)setCBSAddress:(NSString *)address port:(int)port;


@end

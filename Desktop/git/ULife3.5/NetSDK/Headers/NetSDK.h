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

- (long)net_init;

- (long)net_unInit;

- (void)net_loginWithReqData:(NSDictionary*)data timeout:(int)timeout result:(ResultBlock)resultBlock;

- (void)net_loginWithUserName:(NSString*)userName password:(NSString*)pwd timeout:(int)timeout result:(ResultBlock)resultBlock;

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

- (void)net_sendSyncRequestWithIP:(NSString*)ip port:(int)port data:(NSData*)data timeout:(int)millisecond responseBlock:(CommandBlock)result;


@end

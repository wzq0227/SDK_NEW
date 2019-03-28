//
//  DevPushManagement.h
//  ULife3.5
//
//  Created by shenyuanluo on 2017/6/12.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DevPushManagement : NSObject


@property (nonatomic,assign)BOOL isRegisteToken;

+ (instancetype)shareDevPushManager;


/**
 注册 iOS 设备 APNS token

 @param pushToken APNS token
 @param resultBlock 注册是否成功Block回调，YES：成功，NO：失败
 */
- (void)registTutkPushWithToken:(NSString *)pushToken
                    resultBlock:(void (^) (BOOL isSuccess))resultBlock;


/**
 获取推送 token

 @return APNS token
 */
- (NSString *)getPushToken;


/**
 查询设备推送是否打开
 
 @param deviceId 设备 ID
 @return 是否打开推送，YES：打开，NO：关闭
 */
- (BOOL)isOpenPushWithDeviceId:(NSString *)deviceId;


/**
 打开设备推送
 
 这个方法具备存储设置功能

 @param deviceId 设备 ID
 @param resultBlock 打开推送是否成功Block回调，YES：成功，NO：失败
 */
- (void)openPushWithDeviceId:(NSString *)deviceId
                 resultBlock:(void (^)(BOOL isSuccess))resultBlock;


/**
 关闭设备推送
 这个方法具备存储设置功能
 @param deviceId 设备 ID
 @param resultBlock 关闭推送是否成功Block回调，YES：成功，NO：失败
 */
- (void)closePushWithDeviceId:(NSString *)deviceId
                  resultBlock:(void (^)(BOOL isSuccess))resultBlock;


/**
 删除设备推送（用于删除设备时）
这个方法具备存储设置功能
 @param deviceId 设备 ID
 @param resultBlock 删除是否成功Block回调，YES：成功，NO：失败
 */
- (void)deletePushWithDeviceId:(NSString *)deviceId
                   resultBlock:(void (^)(BOOL isSuccess))resultBlock;


/**
 保存缓存推送信息（程序退出时）
 */
- (void)savePushListCache;

@end

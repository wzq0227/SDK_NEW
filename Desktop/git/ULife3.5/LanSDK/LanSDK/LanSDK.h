//
//  LanSDK.h
//  LanSDK
//
//  Created by GOSCAM on 17/3/6.
//  Copyright © 2017年 GOSCAM. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "libUlife_API.h"
#import "UlifeDefines.h"


typedef void(^GetVideoDataBlock)(int channelid, stFrameHeader *pheader, unsigned char *pdata, int datalen, void *popt);

typedef void(^BlockGetWiFiList)(int result, SWifiInfo wifiListInfo, BOOL devResetFlag);


/**
 AP模式下传递路由器WiFi信息操作结果
 @param result 0 成功
 */
typedef void(^SetWiFiResult)(int result, DeviceInfo *devInfo);


/**
 局域网内搜索指定设备是否存在
 @param result 0 成功
 */
typedef void(^SearchDeviceResultBlock)(int result);

@interface LanSDK : NSObject


+ (LanSDK *)sharedLanSDKInstance;



/**
 搜索并连接设备，成功后返回WiFi列表
 
 @param UID 设备ID
 @param userName 用户名
 @param pwd 密码
 @param timeout 超时时间，单位秒
 @param devType 设备类型
 @param result WiFi设置结果
 */
- (void)searchAndConnectDeviceWithUID:(NSString *)UID
                             userName:(NSString *)userName
                             password:(NSString *)pwd
                              timeout:(int) timeout
                           deviceType:(NSString *)devType
                                 ssid:(NSString *)wifiSSID
                             password:(NSString *)password
                          resultBlock:(SetWiFiResult)result;


- (void)searchAndConnectDeviceWithUID:(NSString *)UID
                             userName:(NSString *)userName
                             password:(NSString *)pwd
                              timeout:(int) timeout
                           deviceType:(NSString *)devType
                        wifiListBlock:(BlockGetWiFiList)result;


- (void)searchDeviceWithUID:(NSString *)UID
                    timeout:(int) timeout
                 deviceType:(NSString *)devType
                resultBlock:(SearchDeviceResultBlock) result;


/**
 开始获取局域网视频流数据
 
 @return YES:开启成功；NO:开启失败
 */
- (BOOL)startGetLanVideoData;



/**
 停止获取局域网视频流数据
 
 @return YES:停止成功；NO:停止失败
 */
- (BOOL)stopGetLanVideoData;


/**
 修改WiFi 名称和密码
 
 @param wifiSSID WiFi 名称
 @param password WiFi 密码
 @return YES:修改成功，NO:修改失败
 */
- (BOOL)changeWifiSSID:(NSString *)wifiSSID password:(NSString *)password;


/**
 镜像垂直翻转
 */
- (BOOL)Mirrorflip;


/**
 获取WiFi列表
 @param result 回调block
 */
- (void)getWifiListWithResult:(BlockGetWiFiList)result;

@end




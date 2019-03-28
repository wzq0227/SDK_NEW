//
//  LanSDK.m
//  LanSDK
//
//  Created by GOSCAM on 17/3/6.
//  Copyright © 2017年 GOSCAM. All rights reserved.
//

#import "LanSDK.h"


/**
 *  搜索局域网设备的类型
 */
#define DEVICE_TYPE "T5600HCA" // GD845H

/**
 *  搜索局域网设备超时时间（单位：秒）
 */
#define SEARCH_TIME_OUT  (5 * 60)

/**
 *  局域网默认端口
 */
#define LAN_CHANNEL_PORT 5552

/**
 *  局域网设备 ID
 */
#define LAN_DEVICE_ID @"5WRFZJGNPNHPXUTB111A"

/**
 *  局域网用户名
 */
#define LAN_USER_NAME "admin"

/**
 *  局域网密码
 */
#define LAN_PASSWORD "goscam123"




@interface LanSDK ()
{
    /**
     *  局域网搜索到的设备数量
     */
    int _devCount;
    /**
     *  设备信息结构体
     */
    DeviceInfo _deviceInfo;
    
    /**
     *  音视频通道
     */
    int  _avChannelIndex;
    
    /**
     *  参数控制通道
     */
    int  _cmdChannelIndex;
    
    /**
     *  WiFi列表信息结构体
     */
    SWifiInfo _wifiListInfo;
    
    /**
     *  WiFi信息结构体
     */
    WifiInfoN  _wifiInfo;
    
    
}

@property (strong, nonatomic)  BlockGetWiFiList wifiListBlock;

/**
 *  局域网用户名
 */
@property (strong, nonatomic)  NSString *mLanUserName;

/**
 *  局域网密码
 */
@property (strong, nonatomic)  NSString *mLanPassword;

/**
 *  搜索局域网设备的类型
 */
@property (strong, nonatomic)  NSString *mDeviceType;

/**
 *  局域网默认端口
 */
@property (assign, nonatomic)  int  mLanPort;

/**
 *  搜索局域网设备超时时间（单位：秒）
 */
@property (assign, nonatomic)  int  mTimeout;

@end



GetVideoDataBlock _getVideoDataBlock;
static LanSDK  *shareLanSDK = nil;

@implementation LanSDK


+ (LanSDK *)sharedLanSDKInstance
{
    static dispatch_once_t token;
    if(nil == shareLanSDK)
    {
        dispatch_once(&token,^{
            
            shareLanSDK = [[LanSDK alloc] init];
        });
    }
    
    return shareLanSDK;
}


-(instancetype)init;
{
    if (self = [super init])
    {
        int initStatus = Init_Sdk();
        
        if (0 == initStatus)
        {
            NSLog(@"Lan_av_SDK 初始化成功");
            //            count           = 0;
            _cmdChannelIndex = -1;
            _avChannelIndex  = -1;
        }
    }
    return self;
}


#pragma mark -- 创建获取音视频的通道
- (int)getAvChannelIndexWithUID:(NSString*)UID userName:(NSString*)userName password:(NSString*)pwd
{
    while (1)
    {
        int popt = 0;
        _avChannelIndex = AM_CreateChannel(_deviceInfo.szDeviceIP,
                                           LAN_CHANNEL_PORT,
                                           [UID UTF8String],
                                           [userName UTF8String],
                                           [pwd UTF8String],
                                           AVDataCallback,
                                           AVMsgCallback,
                                           &popt);
        if (0 <= _avChannelIndex)
        {
            NSLog(@"音视频通道创建成功， _avChannelIndex = %d", _avChannelIndex);
            
            return _avChannelIndex;
        }
    }
}


#pragma mark -- 创建参数控制通道
- (int)getCmdChannelIndexWithPort:(int)port userName:(NSString*)userName password:(NSString*)password
{
    int ppot = 0;
    while (1)
    {
        _cmdChannelIndex = PM_CreateChannel(_deviceInfo.szDeviceIP,
                                            port,
                                            _deviceInfo.szDevID,
                                            userName.UTF8String,
                                            password.UTF8String,
                                            CmdMsgCallback,
                                            &ppot);
        
        if (0 <= _cmdChannelIndex)
        {
            NSLog(@"参数控制通道创建成功，_cmdChannelIndex = %d", _cmdChannelIndex);
            
            return _cmdChannelIndex;
        }
        [NSThread sleepForTimeInterval:3];
    }
}

- (void)searchAndConnectDeviceWithUID:(NSString *)UID
                             userName:(NSString *)userName
                             password:(NSString *)pwd
                              timeout:(int) timeout
                           deviceType:(NSString *)devType
                                 ssid:(NSString *)wifiSSID
                             password:(NSString *)password
                          resultBlock:(SetWiFiResult)result{
    //每3秒钟重复搜索一次
    int repeateCount = timeout/3000;
    _mLanUserName = userName;
    _mLanPassword = pwd;
    _mTimeout  = timeout;
    _mDeviceType = devType;
    _mLanPort = LAN_CHANNEL_PORT;
    
    DeviceInfo *devInfo = nil;
    BOOL hasFoundDevice = NO;

    for(int index=0; index < 20 ; index++)
    {
        _devCount = LanSearchDevice(3000, devType.UTF8String);
        NSLog(@"搜索到的设备总数 %d",_devCount);
        if (0 < _devCount)
        {
            for (int i=0; i< _devCount; i++) {
                devInfo = LanGetDeviceBySearch(i);
                if (devInfo != NULL && strcmp(devInfo->szDevID, UID.UTF8String)==0 )
                {
                    memcpy(&_deviceInfo, devInfo, sizeof(DeviceInfo));
                    hasFoundDevice = YES;
                    break;
                }
            }
        }
        if (hasFoundDevice) {
            break;
        }
    }
    
    SWifiInfo cmdCtrlReq;
    memset(&cmdCtrlReq, 0, sizeof(cmdCtrlReq));
    cmdCtrlReq.totalcount = 1;
    cmdCtrlReq.plist = &_wifiInfo;
    
    strcpy(_wifiInfo.wifiSsid, [wifiSSID UTF8String]);
    strcpy(_wifiInfo.password, [password UTF8String]);
    

    if (hasFoundDevice) {
        bool sendCMDSucceeded = NO;
        for(int index=0; index < repeateCount/2 ; index++)
        {
            if (_cmdChannelIndex<0)
            {
                _cmdChannelIndex = [self getCmdChannelIndexWithPort:_mLanPort userName:_mLanUserName password:_mLanPassword];
            }
            
            int setWifiInfoResult = PM_CtrlParam(_cmdChannelIndex, PCT_CMD_SET_WIFI, &cmdCtrlReq, sizeof(cmdCtrlReq));
            
            if ( setWifiInfoResult ==0 ) {
                sendCMDSucceeded = YES;
                break;
            }
        }
        result(sendCMDSucceeded ? 0 : -1, devInfo);
    }else{
        result(-1, nil);
    }
}


- (void)searchDeviceWithUID:(NSString *)UID
                    timeout:(int) timeout
                 deviceType:(NSString *)devType
                resultBlock:(SearchDeviceResultBlock) result{
    
    DeviceInfo *devInfo = nil;
    int repeateCount = timeout/3000;
    
    BOOL hasFoundDevice = NO;
    for(int index=0; index < repeateCount ; index++)
    {
        _devCount = LanSearchDevice(5000, devType.UTF8String);
        NSLog(@"搜索到的设备总数 %d",_devCount);
        if (0 < _devCount)
        {
            for (int i=0; i< _devCount; i++) {
                devInfo = LanGetDeviceBySearch(i);
                if (devInfo != NULL && strcmp(devInfo->szDevID, UID.UTF8String)==0 )
                {
                    memcpy(&_deviceInfo, devInfo, sizeof(DeviceInfo));
                    hasFoundDevice = YES;
                    break;
                }
            }
        }
        if (hasFoundDevice) {
            break;
        }
    }
    result(hasFoundDevice?0:-1);
}


#pragma mark -- 搜索并连接设备
- (void)searchAndConnectDeviceWithUID:(NSString *)UID
                             userName:(NSString *)userName
                             password:(NSString *)pwd
                              timeout:(int) timeout
                           deviceType:(NSString *)devType
                        wifiListBlock:(BlockGetWiFiList)result
{
    //每3秒钟重复搜索一次
    int repeateCount = timeout/3000;
    
    _mLanUserName = userName;
    _mLanPassword = pwd;
    _mTimeout  = timeout;
    _mDeviceType = devType;
    _mLanPort = LAN_CHANNEL_PORT;
    
    DeviceInfo *devInfo = nil;

    BOOL hasFoundDevice = NO;
    for(int index=0; index < repeateCount ; index++)
    {
        _devCount = LanSearchDevice(3000, devType.UTF8String);
        NSLog(@"搜索到的设备总数 %d",_devCount);
        if (0 < _devCount)
        {
            for (int i=0; i< _devCount; i++) {
                devInfo = LanGetDeviceBySearch(i);
                if (devInfo != NULL && strcmp(devInfo->szDevID, UID.UTF8String)==0 )
                {
                    memcpy(&_deviceInfo, devInfo, sizeof(DeviceInfo));
                    hasFoundDevice = YES;
                    break;
                }
            }
        }
        if (hasFoundDevice) {
            break;
        }
    }
    
    SWifiInfo cmdCtrlReq;
    memset(&cmdCtrlReq, 0, sizeof(cmdCtrlReq));
    
    if (hasFoundDevice) {
        result(1024,cmdCtrlReq,_deviceInfo.ybindFlag);
        
        bool sendCMDSucceeded = NO;
        for(int index=0; index < repeateCount/2 ; index++)
        {
            if (_cmdChannelIndex<0)
            {
                _cmdChannelIndex = [self getCmdChannelIndexWithPort:_mLanPort userName:_mLanUserName password:_mLanPassword];
            }
            NSLog(@"_______________________PM_CtrlParam___GET_WIFI_LIST____,%d",_cmdChannelIndex);
            int flipStatus = PM_CtrlParam(_cmdChannelIndex, PCT_CMD_GET_WIFI_LIST, &cmdCtrlReq, sizeof(cmdCtrlReq));
            if ( flipStatus ==0 ) {
                sendCMDSucceeded = YES;
                break;
            }
        }
        result(sendCMDSucceeded?0:-1,cmdCtrlReq,_deviceInfo.ybindFlag);
    }else{
        result(-1,cmdCtrlReq,_deviceInfo.ybindFlag);
    }
}


#pragma mark -- 开始获取局域网视频流数据
- (BOOL)startGetLanVideoData
{
    int openVideoState = AM_OpenVideoStream(_avChannelIndex);
    
    if (0 == openVideoState)
    {
        NSLog(@"开启视频视频成功！");
        
        return YES;
    }
    else
    {
        NSLog(@"开启视频视频失败！");
        return NO;
    }
}


#pragma mark -- 停止视频
- (BOOL)stopGetLanVideoData
{
    int stopVideoStatus = AM_CloseVideoStream(_avChannelIndex);
    if (0 == stopVideoStatus)
    {
        NSLog(@"停止视频成功！");
        
        return YES;
    }
    else
    {
        NSLog(@"停止视频失败！");
        
        return NO;
    }
}


#pragma mark -- 修改WiFi 名称和密码
- (BOOL)changeWifiSSID:(NSString *)wifiSSID password:(NSString *)password
{
    NSAssert((wifiSSID && 0 < wifiSSID.length), @"wifi-SSID 为空！");
    NSAssert((password && 0 < password.length), @"wifi-密码 为空！");
    
    if (0 > _cmdChannelIndex)
    {
        _cmdChannelIndex = [self getCmdChannelIndexWithPort:_mLanPort userName:_mLanUserName password:_mLanPassword];
    }
    _wifiListInfo.totalcount = 1;
    _wifiListInfo.plist      = &_wifiInfo;
    
    strcpy(_wifiInfo.wifiSsid, [wifiSSID UTF8String]);
    strcpy(_wifiInfo.password, [password UTF8String]);
    
    int  changeWifiStatus = PM_CtrlParam(_cmdChannelIndex, PCT_CMD_SET_AP, &_wifiListInfo, sizeof(SWifiInfo));
    
    if (0 == changeWifiStatus)
    {
        return YES;
    }
    else
    {
        return NO;
    }
}


#pragma mark -- 镜像翻转
- (BOOL)Mirrorflip
{
    if (_cmdChannelIndex<0)
    {
        _cmdChannelIndex = [self getCmdChannelIndexWithPort:_mLanPort userName:_mLanUserName password:_mLanPassword];
    }
    
    int flipStatus = PM_CtrlParam(_cmdChannelIndex, PCT_CMD_PTZ_FLIP, 0, 0);
    if (0 == flipStatus)
    {
        NSLog(@"镜像翻转成功: %d",flipStatus);
        return YES;
    }
    else
    {
        NSLog(@"镜像翻转失败: %d",flipStatus);
        return NO;
    }
}

- (void)getWifiListWithResult:(BlockGetWiFiList)result{
    if (_cmdChannelIndex<0)
    {
        _cmdChannelIndex = [self getCmdChannelIndexWithPort:_mLanPort userName:_mLanUserName password:_mLanPassword];
    }
    
    SWifiInfo cmdCtrlReq;
    memset(&cmdCtrlReq, 0, sizeof(cmdCtrlReq));
    
    int flipStatus = PM_CtrlParam(_cmdChannelIndex, PCT_CMD_GET_WIFI_LIST, &cmdCtrlReq, sizeof(cmdCtrlReq));
    result(flipStatus,cmdCtrlReq,_deviceInfo.ybindFlag);
}

#pragma mark - 回调
#pragma mark -- 音视频‘数据’回调
int AVDataCallback(int channelid, stFrameHeader *pheader, unsigned char *pdata, int datalen, void *popt)
{
    if (pheader && datalen > 0)
    {
        NSLog(@"buff 长度%d",datalen);
        _getVideoDataBlock(channelid, pheader, pdata, datalen, popt);
    }
    return 0;
}


#pragma mark -- 音视频‘消息’回调
int AVMsgCallback(int channelid,MESSAGETYPE msgtype,MESSAGESUBTYPE submsgtype, unsigned char* pdata, int datalen,void* popt)
{
    printf("MsgCallback channel id = %d,datalen = %d\n",channelid,datalen);
    return 0;
}


#pragma mark -- 参数控制‘消息’回调
int CmdMsgCallback(int channelid,MESSAGETYPE msgtype,MESSAGESUBTYPE submsgtype, unsigned char* pdata, int datalen,void* popt)
{
    printf("MsgCallback channel id = %d,datalen = %d\n",channelid,datalen);
    return 0;
}



@end


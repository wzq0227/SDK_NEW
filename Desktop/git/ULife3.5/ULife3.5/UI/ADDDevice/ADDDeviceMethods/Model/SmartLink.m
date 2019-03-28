//
//  SmartLink.m
//  QQI
//
//  Created by goscam_sz on 17/5/12.
//  Copyright © 2017年 yuanx. All rights reserved.
//

#import "SmartLink.h"
#import "cooee.h"
#import "SmartClass.h"
#import <SystemConfiguration/CaptiveNetwork.h>
#include <ifaddrs.h>
#include <arpa/inet.h>
#import "SimpleConfig.h"
#import "UlifeUdpSearcher.h"
#define PATTERN_DEF_PIN             @"57289961"
#define RTK_FAILED                  (-1)


@interface SmartLink ()

//  7601smart
@property (nonatomic, strong) SmartClass *smartconfig;

@property (nonatomic, copy)   NSString *checkCode;

@property (nonatomic, copy)   NSString *infoString;

@property (nonatomic, assign) int  icount;

//  8188smart
@property (nonatomic, strong) SimpleConfig *simpleConfig;

//  ap6212a
@property (nonatomic, assign) BOOL sendWiFi;

@property (nonatomic, assign) unsigned int ip;


@property (nonatomic, strong) UlifeUdpSearcher *localCamerSearcher;

@property (nonatomic, strong) NSTimer *searchLocalCamareTimer;

@property (nonatomic,copy) NSString * devId;            //设备ID

@property (nonatomic,copy) NSString * devWifiPassWord;  //wifi密码

@property (nonatomic,copy) NSString * devWifiName;      //wifi名称

@property (nonatomic,assign) SmartConnectStyle smartStyle;      // Smart 连接方式

@end;

@implementation SmartLink

{
    char com[128];
}
/**  smartflg 连接方式：
 0   不支持smart
 1   7601smart
 2   8188smart
 3   ap6212a
 9   不支持二维码扫描
 10  只支持二维码扫描
 11  二维码扫描+7601smart
 12  二维码扫描+8188smart
 13  二维码扫描+ap6212a
 **/

- (instancetype)initWithSmartModel:(SmartLinkModel *)smartModel;
{
    self=[super init];
    if (self) {
        
        self.devWifiName     = smartModel.wifiName;
        self.devWifiPassWord = smartModel.wifiPassword;
        self.devId           = smartModel.devUid;
        self.smartStyle      = smartModel.smartStyle;
    }
    return self;
}


//初始化smart
-(void)initMySmartClass
{
    _smartconfig = [[SmartClass alloc]init];
    _checkCode = [_smartconfig createCheckCode];
    [_smartconfig setWifiInfo:@[_devWifiName,_devWifiPassWord]];
    _infoString = [_smartconfig createInfoStrWith:_checkCode];
}

//AP模式
-(void)startSearchLocalCamre
{
    _icount =0;
    if (self.smartStyle==1 || self.smartStyle==11) {
        _icount = 0;
        if (!_smartconfig)
        {
            [self initMySmartClass];
        }
        [_smartconfig StartConnectionWith:_infoString];
    }
    //8188
    else if (self.smartStyle==2 || self.smartStyle==12){
        self.simpleConfig = [[SimpleConfig alloc] init];
        [_simpleConfig rtk_sc_set_sc_model:SC_MODEL_1 duration:-1];
        int  ret = [_simpleConfig rtk_sc_config_start:_devWifiName psw:_devWifiPassWord  pin: PATTERN_DEF_PIN];
        if (ret==RTK_FAILED)
        {
            NSLog(@"_simpleConfig is error");
            
        }
    }
    // ap6212a
    else if (self.smartStyle==3 || self.smartStyle ==13){
        _sendWiFi = YES;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
                       {
                           while (_sendWiFi)
                           {
                               struct in_addr addr;
                               inet_aton([[self getIPAddress] UTF8String], &addr);
                               _ip = CFSwapInt32BigToHost(ntohl(addr.s_addr));
                               memset(com, 0, sizeof(com));
                               sprintf(com, "%s%s%s%s%s",[_devWifiPassWord UTF8String],"\nurl=",[@"" UTF8String],"\nwpa=",[@"" UTF8String]);
                               send_cooee([_devWifiName UTF8String], (int)strlen([_devWifiName UTF8String]), com, (int)strlen(com),[@"" UTF8String], (int)strlen([@"" UTF8String]), _ip);
                           }
                       });
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getLocalDeviceIP:) name:@"localdeviceInfo" object:nil];
    if (!_localCamerSearcher)
    {
        _localCamerSearcher = [[UlifeUdpSearcher alloc]init];
    }
    if (self.delegate && [self.delegate respondsToSelector:@selector(startSmartLink)]) {
        [self.delegate startSmartLink];
    }
    [_localCamerSearcher startSearchWithTimeout:0 delegate:self andUID:_devId];
    _searchLocalCamareTimer  = [NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(searchTimerStart) userInfo:nil repeats:YES];
}

//AP搜索本地设备广播 600
-(void)searchTimerStart
{
    _icount++;
    if (_icount == 600) //600
    {
        [self destroySearchTimer];
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(SmartLinkFailure)]) {
            [self.delegate SmartLinkFailure];
        }
    }
    else if (_icount == 300)
    {
        
        if (_smartconfig)
        {
            [_simpleConfig rtk_sc_config_stop];
        }
    }
    else
    {
        if (self.smartStyle == 2 || self.smartStyle ==12)
        {
            if (_simpleConfig)
            {
                [_simpleConfig timerHandler];
            }
        }
        [_localCamerSearcher reBroadcast];
    }
}

//搜索到设备
-(void)getLocalDeviceIP:(NSNotification*)deviceInfo
{
    NSString *souceUID = deviceInfo.object[0];
    if ([souceUID isEqualToString:_devId])
    {
        if (self.delegate && [self.delegate respondsToSelector:@selector(SmartLinkSuccessful)]) {
            [self.delegate SmartLinkSuccessful];
        }
        [self destroySearchTimer];
    }
}

//停止搜索
-(void)destroySearchTimer
{
    if (_smartconfig)
    {
        [_smartconfig StopSmartConnection];
    }
    
    if (_smartconfig)
    {
        NSLog(@"rtk_sc_config_stop");
    }
    
    if (_searchLocalCamareTimer)
    {
        [_searchLocalCamareTimer invalidate];
        _searchLocalCamareTimer = nil;
        [_localCamerSearcher stopSearch];
        _localCamerSearcher=nil;
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self name:LOCALDEVICEINFO object:nil];
}


- (NSString *)getIPAddress
{
    NSLog(@"  #################### This is the getIPAddress ###################");
    NSString *address = @"error";
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    
    // retrieve the current interfaces - returns 0 on success
    success = getifaddrs(&interfaces);
    if (success == 0)
    {
        // Loop through linked list of interfaces
        temp_addr = interfaces;
        while(temp_addr != NULL)
        {
            if(temp_addr->ifa_addr->sa_family == AF_INET)
            {
                // Check if interface is en0 which is the wifi connection on the iPhone
                if([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"])
                {
                    // Get NSString from C String
                    address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                }
            }
            temp_addr = temp_addr->ifa_next;
        }
    }
    // Free memory
    freeifaddrs(interfaces);
    
    return address;
}



@end

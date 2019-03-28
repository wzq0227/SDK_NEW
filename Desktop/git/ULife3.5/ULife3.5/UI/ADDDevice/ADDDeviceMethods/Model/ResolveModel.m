//
//  ResolveModel.m
//  goscamapp
//
//  Created by goscam_sz on 17/5/12.
//  Copyright © 2017年 goscam_sz. All rights reserved.
//

#import "ResolveModel.h"


@interface ResolveModel()


@property (nonatomic,copy)  NSString * UID;

@property (nonatomic,copy)  NSString * devAction;

@property (nonatomic,assign)     int   smartflag;
@end


@implementation ResolveModel

- (instancetype)initWithResolveString:(NSString *)str
{
    self = [super init];
    if (self) {
        const char *temp =[str UTF8String];
        unsigned int length = strlen(temp);
        char * qrc_compat = NULL;
        CGQRCodeCompatV1 *qrc_v1 = NULL;
        E_QRC_VERSION qrc_ver = E_QRC_VERSION_UNKNOWN;
        goscam_qrcode_recognize_compat(temp, length, &qrc_ver, &qrc_compat);
        if(qrc_compat != NULL)
        {
            switch (qrc_ver)
            {
                case E_QRC_VERSION_V1:
                    qrc_v1 = (CGQRCodeCompatV1*) qrc_compat;
                    [self setConnectState_v100:qrc_v1 withString:str];
                    
                    break;
                case E_QRC_VERSION_V2:
                    qrc_v1 = (CGQRCodeCompatV1*) qrc_compat;
                    [self setConnectState_v200:qrc_v1 withString:str];

                    break;
                case E_QRC_VERSION_OLD:
                    qrc_v1 = (CGQRCodeCompatV1*) qrc_compat;
                    [self setOldVersionConnectState:qrc_v1 qrCodeText:str];
                    break;
            }
        }
    }
    return self;
}

//返回smart 连接方式
- (int)getSmartFlag
{
    return _smartflag;
}

- (void)setConnectState_v100:(CGQRCodeCompatV1 *)qrc_v100 withString:(NSString *)str
{
    //是否带smart
    if (qrc_v100->info.c_smart_connect_flag      == 0)    // 不支持smart 扫描
    {
        _smartflag = 0;
    }
    else if(qrc_v100->info.c_smart_connect_flag  == 1)    // 7601 smart
    {
        _smartflag = 1;
    }
    else if(qrc_v100->info.c_smart_connect_flag  == 2)    // 8188 smart
    {
        _smartflag = 2;
    }
    else if (qrc_v100->info.c_smart_connect_flag == 3)    // 上报WiFi名称和密码
    {
        _smartflag = 3;
    }
    else if (qrc_v100->info.c_smart_connect_flag == 9)    // 不支持二维码扫描
    {
        _smartflag = 9;
    }
    else if (qrc_v100->info.c_smart_connect_flag == 10)   // 只支持二维码扫描
    {
        _smartflag = 10;
    }
    else if (qrc_v100->info.c_smart_connect_flag == 11)   // 代表二维码扫描+7601smart
    {
        _smartflag = 11;
    }
    else if(qrc_v100->info.c_smart_connect_flag  == 12)   // 代表二维码扫描+8188smart
    {
        _smartflag = 12;
    }
    _devAction = [NSString stringWithFormat:@"%d",qrc_v100->qrc.nAction];
          _UID = [NSString stringWithFormat:@"%s",qrc_v100->qrc.szDevID];
      _devtype = qrc_v100->info.c_device_type;
}


- (void)setConnectState_v200:(CGQRCodeCompatV1 *)qrc_v200 withString:(NSString *)str
{
    //是否带smart
    if (qrc_v200->info2.c_smart_connect_flag      == 0)    // 不支持smart 扫描
    {
        _smartflag = 0;
    }
    else if(qrc_v200->info2.c_smart_connect_flag  == 1)    // 7601 smart
    {
        _smartflag = 1;
    }
    else if(qrc_v200->info2.c_smart_connect_flag  == 2)    // 8188 smart
    {
        _smartflag = 2;
    }
    else if (qrc_v200->info2.c_smart_connect_flag == 3)    // 上报WiFi名称和密码
    {
        _smartflag = 3;
    }
    else if (qrc_v200->info2.c_smart_connect_flag == 9)    // 不支持二维码扫描
    {
        _smartflag = 9;
    }
    else if (qrc_v200->info2.c_smart_connect_flag == 10)   // 只支持二维码扫描
    {
        _smartflag = 10;
    }
    else if (qrc_v200->info2.c_smart_connect_flag == 11)   // 代表二维码扫描+7601smart
    {
        _smartflag = 11;
    }
    else if(qrc_v200->info2.c_smart_connect_flag  == 12)   // 代表二维码扫描+8188smart
    {
        _smartflag = 12;
    }
    else if (qrc_v200->info2.c_smart_connect_flag == 13)   // 代表二维码扫描+ ap6212smart
    {
        _smartflag = 13;
    }
    else if (qrc_v200->info2.c_smart_connect_flag == 16)
    {
        _smartflag = 16;
    }
    else if (qrc_v200->info2.c_smart_connect_flag == 17)
    {
        _smartflag = 17;
    }
    _devAction = [NSString stringWithFormat:@"%d",qrc_v200->qrc.nAction];
    _UID = [NSString stringWithFormat:@"%s",qrc_v200->qrc.szDevID];
    _devtype = qrc_v200->info2.c_device_type;
}


- (void)setOldVersionConnectState:(CGQRCodeCompatV1 *)qrc_v1
                       qrCodeText:(NSString *)qrCodeText
{
    if (IS_STRING_EMPTY(qrCodeText)
        || NULL == qrc_v1)
    {
        NSLog(@"无法处理老版本二维码信息，qrCodeText = %@, qrc_v1 = %p", qrCodeText, qrc_v1);
        
        return;
    }
    
    _UID = [NSString stringWithFormat:@"%s",qrc_v1->qrc.szDevID];
    /**
     *  qrAction: 0.出厂生成的二维码;1.分享生成的二维码;
     */
    _devAction = [NSString stringWithFormat:@"%d",qrc_v1->qrc.nAction];
    
}



- (NSString *)getDevUid:(smartLinkState)state
{
    switch (state) {
        case WifiAdd:
            if (_smartflag==1 || _smartflag==2 || _smartflag==3 || _smartflag==9 || _smartflag==11 ||_smartflag==12 || _smartflag==13 ) {
                if (_devtype==101) {    //彩易设备
                    return @"caiyi";
                }
                else{
                    if (_devAction.integerValue == 0 || _devAction.integerValue == 3 || _devAction.integerValue == 4)
                    {
                        return _UID;
                    }
                }
            }
            else{
                return @"";
            }
            break;
        case ScanQrAdd:
            if (_smartflag==10 || _smartflag==11 ||_smartflag==12 || _smartflag==13 ) {
                if (_devtype==101) {    //彩易设备
                    return @"caiyi";
                }
                else{
                    if (_devAction.integerValue == 0 || _devAction.integerValue == 3 || _devAction.integerValue == 4)
                    {
                        return _UID;
                    }
                    else{
                        return @"";
                    }
                }
            }
            else{
                return @"";
            }
            break;
        case WiringAdd:
            if (_devAction.integerValue == 0 || _devAction.integerValue == 3 || _devAction.integerValue == 4)
            {
                return _UID;
            }
            else{
                return @"";
            }
            break;
        case FriendAdd:
            if (_devAction.integerValue == 1) {
                return _UID;
            }
            else{
                return @"";
            }
            break;
        default:
            break;
    }
    return _UID;
}



@end

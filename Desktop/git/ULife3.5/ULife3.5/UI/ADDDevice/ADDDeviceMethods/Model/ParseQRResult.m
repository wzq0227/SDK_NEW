//
//  ParseQRResult.m
//  ULife3.5
//
//  Created by shenyuanluo on 2017/7/26.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import "ParseQRResult.h"
#import "qrcode_tools.h"


@implementation QRParseResultModel
@end

@interface ParseQRResult ()

@property (nonatomic, strong) dispatch_queue_t parseQRStringQueue;

@property (strong, nonatomic)  QRParseResultModel *qrModel;

@end

@implementation ParseQRResult

static ParseQRResult *g_qrStrParser = nil;
+ (instancetype)shareQRParser
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        if (nil == g_qrStrParser)
        {
            g_qrStrParser = [[ParseQRResult alloc] init];
        }
    });
    return g_qrStrParser;
}


- (instancetype)init
{
    if (self = [super init])
    {
        self.parseQRStringQueue = dispatch_queue_create("ParseQRStringQueue", DISPATCH_QUEUE_CONCURRENT); //CONCURRENT=>Serial
        
    }
    return self;
}



#pragma mark -- 解析二维码串
- (void)parseWithQRString:(NSString *)qrString
            addDeviceType:(AddDeviceByStyle)addDeviceType
{
    if (!_qrModel) {
        _qrModel = [QRParseResultModel new ];
    }
    
    __weak typeof(self)weakSelf = self;
    dispatch_async(self.parseQRStringQueue, ^{
       
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (!strongSelf)
        {
            NSLog(@"对象丢失，无法解析二维码串！");
            return ;
        }
        const char *qrctext      = [qrString UTF8String];
        unsigned long length     = strlen(qrctext);
        char *qrc_compat         = NULL;
        CGQRCodeCompatV1 *qrCodeCompat = NULL;
        E_QRC_VERSION qrCodeVersion = E_QRC_VERSION_UNKNOWN;
        
        goscam_qrcode_recognize_compat((const unsigned char *)qrctext,
                                       (int)length,
                                       &qrCodeVersion,
                                       &qrc_compat);
        if (NULL == qrc_compat)
        {
            NSLog(@"扫描二维码失败");
            [self unknowDeviceType];
            return  ;
        }
        qrCodeCompat = (CGQRCodeCompatV1 *)qrc_compat;
        NSLog(@"扫描二维码成功");
        switch (qrCodeVersion)
        {
            case E_QRC_VERSION_V1:      // 能力集版本1
            {
                NSLog(@"该二维码是 能力集版本1.。。");
                [strongSelf parseNewVersionWithCompat:qrCodeCompat
                                           qrCodeText:qrString
                                        qrCodeVersion:E_QRC_VERSION_V1
                                       addDeviceStyle:addDeviceType];
            }
                
                break;
                
            case E_QRC_VERSION_V2:      // 能力集版本2
            {
                NSLog(@"该二维码是 能力集版本2.。。");
                [strongSelf parseNewVersionWithCompat:qrCodeCompat
                                           qrCodeText:qrString
                                        qrCodeVersion:E_QRC_VERSION_V2
                                       addDeviceStyle:addDeviceType];
            }
                break;
                
            case E_QRC_VERSION_OLD:     // 能力集版本：老版本
            {
                NSLog(@"该二维码是 能力集 - 老版本.。。");
                [strongSelf parseOldVersionWithCompat:qrCodeCompat
                                           qrCodeText:qrString
                                       addDeviceStyle:addDeviceType];
            }
                break;
                
            case E_QRC_VERSION_UNKNOWN: // 未知
            {
                NSLog(@"该二维码是 能力集 - 未知.。。");
                [self unknowDeviceType];
            }
                break;
                
            default:
            {
                NSLog(@"该二维码是 能力集 - 其他情况.。。");
                [self unknowDeviceType];
            }
                break;
        }
        
//        free(qrCodeCompat);

    });
}


#pragma mark -- (能力集版本1、2)二维码信息处理
- (void)parseNewVersionWithCompat:(CGQRCodeCompatV1 *)qrCodeCompat
                       qrCodeText:(NSString *)qrCodeText
                    qrCodeVersion:(E_QRC_VERSION)qrCodeVersion
                   addDeviceStyle:(AddDeviceByStyle)addDevStyle
{
    if (IS_STRING_EMPTY(qrCodeText)
        || NULL == qrCodeCompat)
    {
        NSLog(@"二维码信息无法处理， qrCodeText = %@, qrCodeCompat = %p", qrCodeText, qrCodeCompat);
        [self unknowDeviceType];
        
        return;
    }
    // 网卡判断
    BOOL isHaveEthernet  = NO;  // 是否有网卡
    BOOL isRawID = NO;  // 是否是裸 ID
    BOOL supportForceUnbind = NO;
    
    DeviceQRType devQRType = DeviceQR_Unknown;
    SmartConnectStyle smartConStyle = SmartConnectNotSurportSmart;
    GosDeviceType devType = GosDeviceUnkown;
    
    NSString *deviceId = [NSString stringWithFormat:@"%s",qrCodeCompat->qrc.szDevID];
    NSString *qrAction = [NSString stringWithFormat:@"%d",qrCodeCompat->qrc.nAction];
    
    if (E_QRC_VERSION_V1 == qrCodeVersion)          // 版本 1
    {
        devQRType = qrCodeCompat->info.c_device_type;
        smartConStyle = qrCodeCompat->info.c_smart_connect_flag;
        supportForceUnbind = qrCodeCompat->info.c_encrypted_ic_flag; //暂时表示硬解绑

        if (0 == qrCodeCompat->info.ethernet_flag)
        {
            isHaveEthernet = NO;
        }
        else
        {
            isHaveEthernet = YES;
        }
    }
    else if (E_QRC_VERSION_V2 == qrCodeVersion)     // 版本 2
    {
        devQRType = qrCodeCompat->info2.c_device_type;
        smartConStyle = qrCodeCompat->info2.c_smart_connect_flag;
        supportForceUnbind = qrCodeCompat->info2.c_encrypted_ic_flag; //暂时表示硬解绑

        printf("============********************* c_encrypted_ic_flag:%d\r\n",qrCodeCompat->info2.c_encrypted_ic_flag);
        if (0 == qrCodeCompat->info2.ethernet_flag)
        {
            isHaveEthernet = NO;
        }
        else
        {
            isHaveEthernet = YES;
        }
    }
    
    if ([deviceId isEqualToString:qrCodeText])
    {
        isRawID = YES;
    }
    else
    {
        isRawID = NO;
    }
    if (DeviceQR_NVR == devQRType)
    {
        devType = GosDeviceNVR;
    }
    else if (DeviceQR_360 == devQRType)
    {
        devType = GosDevice360;
    }
    else
    {
        devType = GosDeviceIPC;
    }
    
    _qrModel.parseSuccessfully = YES;
    _qrModel.deviceId = deviceId;
    _qrModel.qrCodeType = qrAction.intValue;
    _qrModel.deviceType = devType;
    _qrModel.smartConStyle = smartConStyle;
    _qrModel.supportForceUnbnid = supportForceUnbind;
    _qrModel.hasEthernet = isHaveEthernet;
    

    [self extractInfoWithDeviceId:deviceId
                         qrAction:qrAction
                       deviceType:devType
                     deviceQRType:devQRType
                       smartStyle:smartConStyle
                   addDeviceStyle:addDevStyle];
}


#pragma mark -- 提取扫描结果
- (void)extractInfoWithDeviceId:(NSString *)deviceId
                       qrAction:(NSString *)qrAction
                     deviceType:(GosDeviceType)deviceType
                   deviceQRType:(DeviceQRType)deviceQRType
                     smartStyle:(SmartConnectStyle)smartStyle
                 addDeviceStyle:(AddDeviceByStyle)addDevStyle
{
    if (IS_STRING_EMPTY(deviceId)
        || IS_STRING_EMPTY(qrAction))
    {
        NSLog(@"无法显示扫描结果，deviceId = %@, qrAction = %@", deviceId, qrAction);
        
        [self unknowDeviceType];
        
        return ;
    }
    if (DeviceQR_CaiYi == deviceQRType)     // 彩易设备，暂不支持
    {
        NSLog(@"'彩易'设备二维码！");
        [self unknowDeviceType];
        
        return;
    }
    switch (addDevStyle)
    {
        case AddDeviceByWiFi:           // WiFi添加
        {
            if (QRCodeGenerateByFactory ==  qrAction.integerValue
                || QRCodeGenerateBy3 == qrAction.integerValue
                || QRCodeGenerateBy4 == qrAction.integerValue)
            {
                if (g_qrStrParser.delegate
                    && [g_qrStrParser.delegate respondsToSelector:@selector(parseQRResult:)])
                {
                    [g_qrStrParser.delegate parseQRResult:_qrModel];

                }
            }
            else
            {
                [self unknowDeviceType];
                
                return;
            }
        }
            break;
            
        case AddDeviceByScanQR:         // 扫描二维码添加
        {
            if (QRCodeGenerateByFactory == qrAction.integerValue
                || QRCodeGenerateBy3 == qrAction.integerValue
                || QRCodeGenerateBy4 == qrAction.integerValue)
            {
                if (g_qrStrParser.delegate
                    && [g_qrStrParser.delegate respondsToSelector:@selector(parseQRResult:)])
                {
                    [g_qrStrParser.delegate parseQRResult:_qrModel];
                }
            }
            else
            {
                [self unknowDeviceType];
                
                return;
            }
        }
            break;
            
        case AddDeviceByWLAN:           // 网线添加
        {
            if (QRCodeGenerateByFactory == qrAction.integerValue
                || QRCodeGenerateBy3 == qrAction.integerValue
                || QRCodeGenerateBy4 == qrAction.integerValue)
            {
//                if (NO == isHaveEthernet)
//                {
//                    NSLog(@"该设备没有网卡支持！");
//                    [self unknowDeviceType];
//                    
//                    return;
//                }
//                else
                {
                    if (g_qrStrParser.delegate
                        && [g_qrStrParser.delegate respondsToSelector:@selector(parseQRResult:)])
                    {
                        [g_qrStrParser.delegate parseQRResult:_qrModel];

                    }
                }
            }
            else
            {
                [self unknowDeviceType];
                
                return;
            }
        }
            break;
            
        case AddDeviceByShare:    // 好友分享添加
        {
            if (QRCodeGenerateByShare == qrAction.integerValue)
            {
                if (g_qrStrParser.delegate
                    && [g_qrStrParser.delegate respondsToSelector:@selector(parseQRResult:)])
                {
                    [g_qrStrParser.delegate parseQRResult:_qrModel];
                }
            }
            else
            {
                [self unknowDeviceType];
                
                return;
            }
        }
            break;
            
        case AddDeviceByAll: //支持所有方式
        {
            if (g_qrStrParser.delegate
                && [g_qrStrParser.delegate respondsToSelector:@selector(parseQRResult:)])
            {
                [g_qrStrParser.delegate parseQRResult:_qrModel];
            }else{
                [self unknowDeviceType];
            }
            break;
        }
            
        default:
        {
            [self unknowDeviceType];
            
            return;
        }
            break;
    }
}


#pragma mark -- (老版本能力集）二维码信息处理
- (void)parseOldVersionWithCompat:(CGQRCodeCompatV1 *)qrc_v1
                       qrCodeText:(NSString *)qrCodeText
                   addDeviceStyle:(AddDeviceByStyle)addDevStyle
{
    if (IS_STRING_EMPTY(qrCodeText)
        || NULL == qrc_v1)
    {
        NSLog(@"无法处理老版本二维码信息，qrCodeText = %@, qrc_v1 = %p", qrCodeText, qrc_v1);
        
        return;
    }
    
    NSString *deviceId = [NSString stringWithFormat:@"%s",qrc_v1->qrc.szDevID];
    /**
     *  qrAction: 0.出厂生成的二维码;1.分享生成的二维码;
     */
    NSString *qrAction = [NSString stringWithFormat:@"%d",qrc_v1->qrc.nAction];
    
    
    _qrModel.deviceId = deviceId;
    _qrModel.deviceType = [self getDevTypeWithShareDevId:deviceId];
    _qrModel.parseSuccessfully = YES;
    _qrModel.smartConStyle = SmartConnectNotSurportSmart;
    _qrModel.hasEthernet = YES;
    _qrModel.supportForceUnbnid = NO;
    _qrModel.qrCodeType = qrAction.intValue == 0 ?QRCodeGenerateByFactory:QRCodeGenerateByShare;
    
    switch (addDevStyle)
    {
        case AddDeviceByWiFi:           // WiFi添加
        {
            if ([qrCodeText isEqualToString:deviceId]
                || QRCodeGenerateByFactory == qrAction.integerValue)
            {
                if (DEVICE_ID_LENGTH == deviceId.length)
                {
                    NSString *substr1 = [deviceId substringFromIndex:16];
                    if (![substr1 isEqual:DEVICE_ID_SUFFIX])
                    {
                        [self unknowDeviceType];
                        
                        return;
                    }
                    if (g_qrStrParser.delegate
                        && [g_qrStrParser.delegate respondsToSelector:@selector(parseQRResult:)])
                    {
                        [g_qrStrParser.delegate parseQRResult:_qrModel];
                    }
                }
                else
                {
                    [self unknowDeviceType];
                }
            }
            else
            {
                [self unknowDeviceType];
            }
        }
            break;
            
        case AddDeviceByWLAN:           // 网线添加
        {
            if (QRCodeGenerateByFactory == qrAction.integerValue)
            {
                int opt = E_QRC_OPTION_QUERY;
                goscam_qrcode_check(&qrc_v1->qrc,
                                    QRC_BIT_ETHERNET_SLOT,
                                    &opt);
                if (opt == E_QRC_OPTION_DISABLE)
                {
                    [self unknowDeviceType];
                }
                else
                {
                    if (g_qrStrParser.delegate
                        && [g_qrStrParser.delegate respondsToSelector:@selector(parseQRResult:)])
                    {
                        [g_qrStrParser.delegate parseQRResult:_qrModel];
                    }
                }
            }
            
            if([qrCodeText isEqualToString:deviceId])
            {
                if (g_qrStrParser.delegate
                    && [g_qrStrParser.delegate respondsToSelector:@selector(parseQRResult:)])
                {
                    [g_qrStrParser.delegate parseQRResult:_qrModel];
                }
            }
            else
            {
                [self unknowDeviceType];
            }
        }
            break;
            
        case AddDeviceByScanQR:         // 扫描二维码添加
        {
            if ([qrCodeText isEqualToString:deviceId]
                || QRCodeGenerateByFactory == qrAction.integerValue)
            {
                if (DEVICE_ID_LENGTH == deviceId.length)
                {
                    NSString *substr1 = [deviceId substringFromIndex:16];
                    if (![substr1 isEqual:DEVICE_ID_SUFFIX])
                    {
                        [self unknowDeviceType];
                        
                        return;
                    }
                    if (g_qrStrParser.delegate
                        && [g_qrStrParser.delegate respondsToSelector:@selector(parseQRResult:)])
                    {
                        [g_qrStrParser.delegate parseQRResult:_qrModel];
                    }
                }
                else
                {
                    [self unknowDeviceType];
                }
            }
            else
            {
                [self unknowDeviceType];
            }
        }
            break;
            
        case AddDeviceByShare:    // 好友分享添加
        {
            if ([qrCodeText isEqualToString:deviceId]
                || QRCodeGenerateByShare == qrAction.integerValue)
            {
                if (g_qrStrParser.delegate
                    && [g_qrStrParser.delegate respondsToSelector:@selector(parseQRResult:)])
                {
                    [g_qrStrParser.delegate parseQRResult:_qrModel];

                }
                else
                {
                    [self unknowDeviceType];
                }
            }
            else
            {
                [self unknowDeviceType];
            }
        }
            break;
            
        case AddDeviceByAll: //支持所有方式
        {
            if (g_qrStrParser.delegate
                && [g_qrStrParser.delegate respondsToSelector:@selector(parseQRResult:)])
            {
                
                [g_qrStrParser.delegate parseQRResult:_qrModel];

            }else{
                [self unknowDeviceType];
            }
            break;
        }
            
        default:
        {
            [self unknowDeviceType];
        }
            break;
    }
}


#pragma mark -- 通知代理位置设备类型
- (void)unknowDeviceType
{
    if (g_qrStrParser.delegate
        && [g_qrStrParser.delegate respondsToSelector:@selector(parseQRResult:)])
    {
//        _qrModel.parseSuccessfully = NO;
//        _qrModel.smartConStyle = SmartConnectNotSurportSmart;
//        _qrModel.deviceId = nil;
//        _qrModel.deviceType = GosDeviceUnkown;
//        _qrModel.qrCodeType = 0;
//        _qrModel.hasEthernet = NO;
        
        [g_qrStrParser.delegate parseQRResult:_qrModel];
    }
}


#pragma mark -- 获取分享二维码的设备类型
/** 设备类型标识
 '66' - VR360
 'E6' - NVR
 */
- (GosDeviceType)getDevTypeWithShareDevId:(NSString *)deviceId
{
    GosDeviceType deviceType = GosDeviceUnkown;
    NSString *typeStr = [deviceId substringWithRange:NSMakeRange(3, 2)];
    
    if ([typeStr isEqualToString:@"66"])
    {
        deviceType = GosDevice360;
    }
    else if ([typeStr isEqualToString:@"E6"])
    {
        deviceType = GosDeviceNVR;
    }
    else
    {
        deviceType = GosDeviceIPC;
    }
    return deviceType;
}


@end

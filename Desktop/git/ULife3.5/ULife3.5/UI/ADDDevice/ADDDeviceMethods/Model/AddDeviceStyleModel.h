//
//  AddDeviceStyleModel.h
//  ULife3.5
//
//  Created by shenyuanluo on 2017/7/26.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#ifndef AddDeviceStyleModel_h
#define AddDeviceStyleModel_h

/** 设备默认密码 */
#define DEVICE_DEFAULT_PASSWORD  @"goscam123"

/** 设备 TUTK平台 ID 串长度 */
#define DEVICE_ID_LENGTH 20


/** 设备 ID 后缀 */
#define DEVICE_ID_SUFFIX  @"111A"

/** UDP 搜索定时器时间间隔:秒 */
#define UDP_SERACH_INTERVAL 0.2f

/** UDP 搜索超时：秒 */
#define UDP_SERACH_TIME_OUT 120.0f

/** UDP 搜索总次数 */
#define UDP_SERACH_TOTAL (UDP_SERACH_TIME_OUT / UDP_SERACH_INTERVAL)

/*




/** 添加设备方式枚举 */
typedef NS_ENUM(NSInteger, AddDeviceByStyle) {
    
    AddDeviceByAll                  = 0x00,             // 支持所有的添加方式
    AddDeviceByScanQR               = 0x01,             // '扫描二维码'添加
    AddDeviceByWiFi                 = 0x02,             // 'WiFi（Smart）'添加
    AddDeviceByAPMode               = 0x03,             // 'AP模式' 添加
    AddDeviceByWLAN                 = 0x04,             // '网线'添加
    AddDeviceByShare                = 0x05,             // '好友分享'添加
    AddDeviceByVoice                = 0x06,             //声波添加
    AddDeviceByAPDoorbell           = 0x07,             // 'AP门铃' 添加

};


/** 设备（二维码）类型枚举 */
typedef NS_ENUM(NSInteger, DeviceQRType) {
    
    DeviceQR_Unknown                = -1,               // 未知
    DeviceQR_HaiEr                  = 100,              // 海尔设备
    DeviceQR_CaiYi                  = 101,              // 彩易设备
    DeviceQR_NVR                    = 200,              // NVR 设备
    DeviceQR_360                    = 300,              // 360全景设备
    DeviceQR_Zhong                  = 900,              // 中性版设备
    DeviceQR_GoSiAn                 = 901,              // 高斯安设备
};


/** Smart 连接方式 枚举 */
typedef NS_ENUM(NSInteger, SmartConnectStyle) {
    SmartConnectNotSurportSmart     = 0,                // 不支持 Smart
    SmartConnect1                   = 1,                // 7601
    SmartConnect2                   = 2,                // 8188
    SmartConnectUploadWiFi          = 3,                // 6212  上报 WiFi 名称和密码
    SmartConnect4                   = 4,
    SmartConnect5                   = 5,
    SmartConnect6                   = 6,
    SmartConnect7                   = 7,
    SmartConnect8                   = 8,
    SmartConnectNotSurportQRScan    = 9,                // 不支持二维码扫描
    SmartConnectOnlySurportQRScan   = 10,               // 只支持二维码扫描
    SmartConnect11                  = 11,               // 代表二维码扫描 +7601smart
    SmartConnect12                  = 12,               // 代表二维码扫描 +8188smart
    SmartConnect13                  = 13,               // 代表二维码扫描 +ap6212smart
    SmartConnect14                  = 14,               // 代表 AP添加
    SmartConnect15                  = 15,               // 代表 AP模式加8188smart
    SmartConnect16                  = 16,               //代表AP模式 门铃项目
    SmartConnect17                  = 17,               //代表声波配网

};

/** 解析二维码串错误码 */
typedef NS_ENUM(NSInteger, ParseQRErrorStatus) {
    ParseQRErrorFormat              = 0,                // 二维码格式错误
    ParseQRErrorCaiYi               = 1,                // 彩易的二维码
};


/** 设备连接状态枚举（连接：设备连接网络； 绑定：设备绑定账号。 设备先连接网络，添加，再绑定账号） */
typedef NS_ENUM(NSInteger, ConnectStatusStyle) {
    ConnectStatusConnecting         = 0,                // 正在连接
    ConnectStatusConnectSuccess     = 1,                // 连接成功
    ConnectStatusConnectFailure     = 2,                // 连接失败
    ConnectStatusAdding             = 3,                // 连接成功，正在添加
    ConnectStatusAddSuccess         = 4,                // 添加成功
    ConnectStatusAddFailure         = 5,                // 添加失败
    ConnectStatusBinding            = 6,                // 添加成功,正在绑定
    ConnectStatusBindSuccess        = 7,                // 绑定成功
    ConnectStatusBindFailure        = 8,                // 绑定失败
};


/** 设备生成的二维码方式标志 */
typedef NS_ENUM(NSInteger, QRCodeGenerateStyle) {
    QRCodeGenerateByFactory         = 0,                // 出厂时生成的二维码
    QRCodeGenerateByShare           = 1,                // 分享时生成的二维码
    QRCodeGenerateBy2               = 2,
    QRCodeGenerateBy3               = 3,
    QRCodeGenerateBy4               = 4,
};


/** 设备查询绑定状态 */
typedef NS_ENUM(NSInteger, DeviceBindStatus) {
    DeviceUnBind                    = 0,                // 未被绑定（可以绑定）
    DeviceOwnBind                   = 1,                // ‘主权限’绑定
    DeviceShareBind                 = 2,                // ‘分享权限’绑定
    DeviceOtherBind                 = 3,                // '其他账号'绑定
};

#endif /* AddDeviceStyleModel_h */

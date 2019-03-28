//
//  DeviceDataModel.h
//  ULife3.5
//
//  Created by shenyuanluo on 2017/6/6.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MediaHeader.h"
#import "AddDeviceStyleModel.h"
//#import "GOSObject.h"

// NVR 封面图片类
@interface NvrCovertImage : NSObject    <
                                            NSCopying,
                                            NSMutableCopying
                                        >

@property (nonatomic, strong) UIImage *topLeftImage;            // NVR 左上角 封面
@property (nonatomic, strong) UIImage *topRightImage;           // NVR 左上角 封面
@property (nonatomic, strong) UIImage *bottomLeftImage;         // NVR 左上角 封面
@property (nonatomic, strong) UIImage *bottomRightImage;        // NVR 左上角 封面

@end



/**
 设备详细类型：//36进制0-9 A-Z 未知的待补充

 - GosDetailedDeviceType_T5826HAA: <#GosDetailedDeviceType_T5826HAA description#>
 - GosDetailedDeviceType_T5886HAA: <#GosDetailedDeviceType_T5886HAA description#>
 - GosDetailedDeviceType_T5820HCA: <#GosDetailedDeviceType_T5820HCA description#>
 - GosDetailedDeviceType_T5600HCA: VR360
 - GosDetailedDeviceType_T5703GAA: <#GosDetailedDeviceType_T5703GAA description#>
 - GosDetailedDeviceType_T5880Y: <#GosDetailedDeviceType_T5880Y description#>
 - GosDetailedDeviceType_T5880HCA: <#GosDetailedDeviceType_T5880HCA description#>
 - GosDetailedDeviceType_5880HAB: <#GosDetailedDeviceType_5880HAB description#>
 - GosDetailedDeviceType_T5925HCA: <#GosDetailedDeviceType_T5925HCA description#>
 - GosDetailedDeviceType_T5922HAA: <#GosDetailedDeviceType_T5922HAA description#>
 - GosDetailedDeviceType_T5923HAA: <#GosDetailedDeviceType_T5923HAA description#>
 - GosDetailedDeviceType_T5900HAB: <#GosDetailedDeviceType_T5900HAB description#>
 - GosDetailedDeviceType_T5901HAA: <#GosDetailedDeviceType_T5901HAA description#>
 - GosDetailedDeviceType_GD6505: <#GosDetailedDeviceType_GD6505 description#>
 - GosDetailedDeviceType_GD7002: NVR
 - GosDetailedDeviceType_T5703GAB: <#GosDetailedDeviceType_T5703GAB description#>
 - GosDetailedDeviceType_T5100ZJ: WiFi门铃
 */
typedef NS_ENUM(int, GosDetailedDeviceType) {
    GosDetailedDeviceType_T5826HAA = 0x0090/16*36 +6,
    GosDetailedDeviceType_T5886HAA = 0x0080/16*36 +6,
    GosDetailedDeviceType_T5820HCA = 0x0070/16*36 +6,
    GosDetailedDeviceType_T5600HCA = 0x0060/16*36 +6,
    GosDetailedDeviceType_T5703GAA = 0x0050/16*36 +6,
    GosDetailedDeviceType_T5880Y   = 0x0040/16*36 +6,
    GosDetailedDeviceType_T5880HCA = 0x0030/16*36 +6,
    GosDetailedDeviceType_5880HAB  = 0x0020/16*36 +6,
    GosDetailedDeviceType_T5925HCA = 0x0010/16*36 +6,
    GosDetailedDeviceType_T5922HAA = 0x0000/16*36 +6,
    
    GosDetailedDeviceType_T5923HAA = 0x00A0/16*36 +6,
    GosDetailedDeviceType_T5900HAB = 0x00B0/16*36 +6,
    GosDetailedDeviceType_T5901HAA = 0x00C0/16*36 +6,
    GosDetailedDeviceType_GD6505   = 0x00D0/16*36 +6,
    GosDetailedDeviceType_GD7002   = 0x00E0/16*36 +6,

//    GosDetailedDeviceType_T5880Y   = 0x00F6,
//    GosDetailedDeviceType_T5880HCA = 0x00G6,
    GosDetailedDeviceType_T5703GAB = 618,//H6
    GosDetailedDeviceType_T5886GAB = 654,//I6
    GosDetailedDeviceType_T5705HAA = 690,   //J6
//    GosDetailedDeviceType_T5922HAA = 0x00K6,
    
    GosDetailedDeviceType_T5100ZJ = 870,    //O6
    //906, p6
    GosDetailedDeviceType_T5200HCA = 941,    //(Q-A+10)*36 + 5

};


/**
 *  设备拥有权限标识
 */
typedef NS_ENUM(NSInteger, GosDeviceOwnType) {
    GosDeviceShare              = 0,        // 分享
    GosDeviceOwner              = 1,        // 主权限
};


typedef NS_ENUM(NSInteger, GosDeviceStatus) {
    GosDeviceStatusOffLine      = 0,        // 设备处于不在线状态
    GosDeviceStatusOnLine       = 1,        // 设备处于在线状态
    GosDeviceStatusSleep        = 2,        // 设备处于睡眠状态
};


typedef NS_ENUM(NSInteger, GosDevPushStatus) {
    GosDevPushClose             = 0,        // 关闭推送
    GosDevPushOpen              = 1,        // 打开推送
};

typedef NS_ENUM(NSUInteger, UpdateStage) {
    UpdateStageBegin,
    UpdateStageDownloading,
    UpdateStageUpdating,
    UpdateStageSucceeded,
    UpdateStageFailed,
    UpdateStageCancelled,
};

/*
 获取设备列表数据返回的 JSON
 {
 "DeviceId":"T21BVYMADTB33AY4111A",
 "DeviceOwner":1,
 "DeviceName":"old",
 "DeviceType":1,
 "StreamUser":"",
 "StreamPassword":"",
 "AreaId":""
 }
 */

@interface SubDevInfoModel:NSObject<NSMutableCopying,NSCopying>

@property (strong, nonatomic)  NSString *DeviceId;

@property (strong, nonatomic)  NSString *SubId;

@property (assign, nonatomic)  int ChanNum;           //通道号

@property (nonatomic, assign) GosDeviceStatus Status;               // 子设备在线状态标识

@property (assign, nonatomic)  NSInteger Online;            //上报状态

@property (strong, nonatomic)  NSString *ChanName;

/** 主设备加子设备的ID */
@property (nonatomic, strong)  NSString *devAndSubDevID;

@end

@interface StationInfoModel:NSObject
@property (assign,nonatomic) BOOL csValid;                                      //云存储(CS)有效与否
@property (assign,nonatomic) BOOL tfCardInserted;                               //是否有插TF卡
@property (assign,nonatomic) BOOL bellRingOn;                                   //开启响铃与否
@end


//从服务端获取的设备能力集
@interface DeviceCapModel : NSObject<NSCoding,NSCopying,NSMutableCopying>

+ (instancetype)capWithString:(NSString*)capStr;

@property (nonatomic, assign) int  server_type_flag;        //平台类型

@property (nonatomic, assign) int  cloud_service_flag;      //云存储

@property (nonatomic, assign) int  full_duplex_flag;      //全双工 //0半双工 1全双工 2都支持，设备没有上传则默认为老设备的半双工

@property (nonatomic, assign) int  four_channel_flag;      //一拖四标志

- (void)setInteger:(NSInteger)intValue forKey:(nonnull NSString *)defaultName;

- (NSInteger)integerForKey:(NSString *_Nullable)defaultName;





@end


@interface DeviceDataModel : NSObject   <
                                            NSCopying,
                                            NSMutableCopying
                                        >
@property (nonatomic, copy  ) NSString          * _Nullable DeviceId;// 设备ID
@property (nonatomic, copy  ) NSString          * _Nullable DeviceName;// 设备昵称
@property (nonatomic, copy  ) NSString          * _Nullable StreamUser;// 取流用户名
@property (nonatomic, copy  ) NSString          * _Nullable StreamPassword;// 取流密码
@property (nonatomic, copy  ) NSString          * _Nullable AreaId;// 所属区域 ID

@property (nonatomic, assign) GosDeviceType     DeviceType;// 设备类型标识
@property (nonatomic, assign) GosDeviceOwnType  DeviceOwner;// 拥有者标识
@property (nonatomic, assign) GosDeviceStatus   Status;// 设备在线状态标识
@property (nonatomic, assign) GosDevPushStatus  pushStatus;// 消息推送标识
@property (nonatomic, assign) BOOL              hasCloudPlay;// 是否有云存储功能
@property (nonatomic, assign) BOOL              isHasEnthnet;//是否支持网卡
@property (nonatomic, assign) SmartConnectStyle smartStyle;//Smart方式

@property (nonatomic, strong) UIImage           * _Nullable covertImage;// IPC 封面
@property (nonatomic, strong) NvrCovertImage    * _Nullable nvrCovertImage;// NVR 封面
@property (nonatomic, copy  ) NSString          * _Nullable devWifiName;//设备连上的WiFi名称
@property (nonatomic, copy  ) NSString          * _Nullable devWifiPwd;//设备连上的WiFi密码

@property (nonatomic, copy  ) NSString          * _Nullable DeviceCap;//是否有云存储功能等能力集合


@property (nonatomic, strong) DeviceCapModel    * _Nullable  devCapModel;

@property (nonatomic, strong) StationInfoModel  * _Nullable  stationModel;

@property (nonatomic, strong)  SubDevInfoModel * _Nullable  selectedSubDevInfo;

@property (nonatomic, strong) NSMutableArray<SubDevInfoModel  *> * _Nullable SubDevice;// 子设备

/** 成功创建的 AV 通道数(NVR 设备) */
@property (nonatomic, assign) long avChnnelNum;

+ (GosDetailedDeviceType)detailedDeviceTypeWithString:(NSString*_Nullable)typeStr;
@end

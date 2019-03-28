//
//  settingMode.h
//  goscamapp
//
//  Created by goscam_sz on 17/5/8.
//  Copyright © 2017年 goscam_sz. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UISettingManagement.h"
#import "DeviceDataModel.h"

/**
 
 摄像头信息设置类型枚举
 
 */
typedef NS_ENUM(NSInteger, DeviceSettingType) {
    
    DeviceSettingAlexa ,             //Alexa
    DeviceSettingLightDuration ,             //灯照时长
    DeviceSettingBabyMusic,                 // 音乐播放
    
    DeviceSettingDBLedRemindSetting,          // Led提醒开关
    DeviceSettingDBBellRemindSetting,         // 铃声提醒开关

    DeviceSettingMotionDetection,           // 移动侦测
    DeviceSettingVoiceDetection,            // 声音检测
    DeviceSettingPIRDetection,              // PIR（红外）侦测
    DeviceSettingBatteryLevel,              // 电池电量

    DeviceSettingTempAlarmSetting,          // 温度警报

    DeviceSettingTalkingMode ,          //对讲模式
    DeviceSettingCameraSwitch ,          //摄像头开关
    DeviceSettingCameraMicrophone,          //麦克风
    DeviceSettingCellularDataAutoPause,     //移动网络自动暂停
    
    DeviceSettingCloudService,              // 云服务
    
    DeviceSettingManualRecord,              // 手动录像
    DeviceSettingPhotoAlbum,                //用户相册
    
    DeviceSettingStatusIndicator,           // 状态指示灯
    DeviceSettingRotateSemicircle,          //旋转180度
    DeviceSettingNightVersion,              //夜视
    
    DeviceSettingShareWithFriends,          // 好友分享

    DeviceSettingTimeCheck,                 // 时间校验
    DeviceSettingWiFiSetting,               // WiFi 设置
    DeviceSettingDeviceInfo,                // 设备信息
    
    DeviceSettingUnbindSubDevice,           // 解绑子设备 门铃


    DeviceSettingHorizontalFlip,            // 水平翻转
    DeviceSettingVerticalFlip,              // 垂直翻转
    DeviceSettingBatteryLife,               // 电池电量
    DeviceSettingRecordingDuration,         // 录像时长


};


@interface dataModel : NSObject

@property (nonatomic, strong)  NSString *deviceId;

@property (nonatomic, assign) DeviceSettingType deviceSettingType;
@property (nonatomic, copy  ) NSString *name;
@property (nonatomic, copy  ) NSString *image;

/** 数据存储时长3,7,30天 */
@property (assign, nonatomic)  int dataStorageTime;

@property(nonatomic,strong) NSArray *DevSettingCellTitleNames;
-(dataModel *)initDataModelWithDeviceSettingType:(DeviceSettingType)type;
@end



@interface settingMode : NSObject

@property (nonatomic,copy) NSMutableArray * data;

@property(nonatomic,strong) NSMutableArray *groupNames;

@property (nonatomic,copy) NSString       * name;

-(instancetype)init;

@property(nonatomic,assign)int shareByFriend;

/** 数据存储时长3,7,30天 */
@property (assign, nonatomic)  int dataStorageTime;

@property (strong, nonatomic)  DeviceDataModel *devModel;

- (void)refreshUIWithModel:(UISettingModel*)devAbilityModel;

@end

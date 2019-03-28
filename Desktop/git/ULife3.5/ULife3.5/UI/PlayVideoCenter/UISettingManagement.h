//
//  UiSetting.h
//  QQI
//
//  Created by goscam on 16/3/11.
//  Copyright © 2016年 yuanx. All rights reserved.
//

//unsigned int  pir_flag;				//是否有PIR传感器，0:无，1:有，下同
//unsigned int  ptz_flag;				//是否有云台
//unsigned int  mic_flag;				//是否有咪头(音频)
//unsigned int  speaker_flag;			//是否有喇叭
//unsigned int  temperature_flag;		//是否有温感探头

#import <Foundation/Foundation.h>
#import "NetSDK.h"
#import "BaseCommand.h"
#import "DeviceDataModel.h"

typedef NS_OPTIONS(unsigned int, AccessThirdPartySupport) {
    AccessThirdPartySupport_Echo = 1 << 0,
    AccessThirdPartySupport_Show = 1 << 1,
    AccessThirdPartySupport_GoogleHome = 1 << 2,
};

//0 屏蔽 NO
//1 开启 YES

@interface UISettingModel: NSObject<NSCopying,NSCoding,NSMutableCopying>

@property(nonatomic,strong) DeviceCapModel * capModel;

@property(nonatomic,copy)   NSString * ability_id;
@property(nonatomic,assign)BOOL  ability_pir;
@property(nonatomic,assign)BOOL  ability_pir_distance;
@property(nonatomic,assign)BOOL  ability_ptz;
@property(nonatomic,assign)BOOL  ability_mic;
@property(nonatomic,assign)BOOL  ability_speakr;
@property(nonatomic,assign)BOOL  ability_motion_detection;
@property(nonatomic,assign)BOOL  ability_device_type; //设备类型900中性版101彩益100海尔
@property(nonatomic,assign)BOOL  ability_resolution_0;//主码流分辨率大小 Width:高16位 Height:低16位  Ming@2016.06.14
@property(nonatomic,assign)BOOL  ability_resolution_1;	//子码流
@property(nonatomic,assign)BOOL  ability_resolution_2;	//第3路码流
@property(nonatomic,assign)BOOL  ability_encrypted_ic;	//是否有加密IC
@property(nonatomic,assign)BOOL  ability_sd;  //是否有SD卡卡槽，没有则不支持录像
@property(nonatomic,assign)BOOL  ability_temperature; //是否有温感探头
@property(nonatomic,assign)BOOL  ability_timezone;  //是否支持同步时区
@property(nonatomic,assign)BOOL  ability_night_vison;	//是否支持夜视
@property(nonatomic,assign)BOOL  ability_ethernet;	//是否带网卡0:wifi 1有线2wifi加有线
@property(nonatomic,assign)BOOL  ability_smart_connect;	//是否支持smart扫描	0代表不支持，1代表7601smart  2代表8188smart

@property(nonatomic,assign)BOOL  ability_light_flag; // 是否有设置照明灯开关
@property(nonatomic,assign)BOOL  ability_voice_detection_flag; //是否支持声音侦测报警

@property (nonatomic, assign) BOOL ability_record;  // 是否支持录像功能   安霸 T5800aav 不支持
@property (nonatomic, assign) BOOL ability_battery;  // 是否有电池   安霸：有   海思：没有
@property (nonatomic, assign) BOOL ability_record_time;  // 是否有警告录像时长
@property (nonatomic, assign) NSUInteger ability_babyMusic;  // 是否有婴儿曲
@property (assign, nonatomic) BOOL ability_led_sw_flag; //是否有状态指示灯
@property (nonatomic, assign) BOOL ability_camera_sw_flag;  // 是否有摄像头开关
@property (assign, nonatomic) BOOL ability_camera_mic_sw_flag; //是否有mic开关

@property (assign, nonatomic) BOOL ability_battery_level_flag; //是否支持电量显示
@property (assign, nonatomic) BOOL ability_netlink_signal_flag; //是否支持获取中继器和路由之间信号
@property (assign, nonatomic) BOOL ability_stream_passwd_flag; //是否支持设置摄像头密码
@property (assign, nonatomic) AccessThirdPartySupport ability_c_Alexa_Skills_Kit_flag; //Alexa 功能

@property (assign, nonatomic) BOOL ability_doorbell_ring;      //是否支持铃声提醒
@property (assign, nonatomic) BOOL ability_doorbell_led;       //是否支持LED灯提醒

@property (nonatomic, assign) BOOL ability_full_duplex_flag;  // 是否支持全双工

//

- (id)initModelWithAbilityCmd:(CMD_GetDevAbilityResp *)devAbility UID:(NSString*)UID;
@end


@interface UiSettingObject : NSObject<NSCopying,NSMutableCopying,NSCoding>
@property(nonatomic,strong)NSMutableArray *itemList;
@end

@interface UISettingManagement : NSObject

+(UISettingManagement *)sharedInstance;
-(void)addSettingModel:(UISettingModel *)model;
-(void)removeSettingModel:(NSString *)UID;
-(UISettingModel *)getSettingModel:(NSString *)UID;
@end

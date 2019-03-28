//
//  BaseCommand.h
//  ULife2
//
//  Created by zhuochuncai on 6/4/17.
//  Copyright © 2017年 zhuochuncai. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YYModel.h"
#import "AVIOCTRLDEFs.h"

@interface BaseCommand : NSObject<YYModel>
@property(nonatomic,assign)NSInteger CMDType;
-(NSDictionary*)requestCMDData;
-(void)modelSetWithDictionary:(NSDictionary*)dict;
@end


//NTP 时间校准
@interface CMD_NTPTimeParam : BaseCommand
@property (nonatomic,assign) uint     AppTimeSec;
@property (nonatomic,assign) uint     un_NtpOpen;   //ntp校时开关 (1:开启， 0:关闭)
@property (nonatomic,assign) uint     un_EuroTime;  //夏令时开关  (1:开启,  0:关闭)
@property (nonatomic,assign) uint     un_NtpRefTime;//ntp校时间隔 (单位秒)
@property (nonatomic,assign) int      un_TimeZone;  //时区 (-12~11)
@property (nonatomic,copy) NSString *a_NtpServer; //ntp校时服务器地址
@property (nonatomic,assign)  uint	un_ntp_port; 	//ntp校时服务器端口
@end

//获取NTP
@interface CMD_GetNTPTimeParamReq : BaseCommand
@end
@interface CMD_GetNTPTimeParamResp : CMD_NTPTimeParam
@end

//设置NTP
@interface CMD_SetNTPTimeParamReq : CMD_NTPTimeParam
@end
@interface CMD_SetNTPTimeParamResp : BaseCommand
@end

//设备信息
@interface CMD_DevInfo : BaseCommand
@property (nonatomic,copy)NSString *a_name;
@property (nonatomic,copy)NSString *a_type;
@property (nonatomic,copy)NSString *a_software_version;
@property (nonatomic,copy)NSString *a_hardware_version;
@property (nonatomic,copy)NSString *a_gateway_version;
@property (nonatomic,copy)NSString *a_id;
@property (nonatomic,copy)NSString *a_SSID;
@property (nonatomic,copy)NSString *a_wifi_mac;
@property (nonatomic,copy)NSString *a_line_mac;

@property(nonatomic,assign)int Hz;
@property(nonatomic,assign)int a_sd_status;     //小于0时表示没有插SD卡
@property(nonatomic,assign)int a_total_size;
@property(nonatomic,assign)int a_used_size;
@property(nonatomic,assign)int a_free_size;
@end



//获取设备属性
@interface CMD_GetDevInfoReq : BaseCommand
@end
@interface CMD_GetDevInfoResp : CMD_DevInfo
@end


//子设备信息
@interface CMD_SubDevInfo : BaseCommand
@property (nonatomic,copy)NSString *a_type;
@property (nonatomic,copy)NSString *a_software_version;
@property (nonatomic,copy)NSString *a_hardware_version;

@property(nonatomic,assign)int battery_level;     //电量
@end


//获取子设备属性
@interface CMD_GetSubDevInfoReq : BaseCommand
@property int channel;
@end
@interface CMD_GetSubDevInfoResp : CMD_SubDevInfo
@end


//设备能力集
@interface CMD_DevAbility : BaseCommand
@property (nonatomic,assign)unsigned int   c_device_type; //设备类型   900中性版     101彩益     100海尔	    901高世安
@property (nonatomic,assign)unsigned int   un_resolution_0_flag;	//主码流分辨率大小 Width:高16位 Height:低16位  Ming@2016.06.14
@property (nonatomic,assign)unsigned int   un_resolution_1_flag;	//子码流
@property (nonatomic,assign)unsigned int   un_resolution_2_flag;	//第3路码流
@property (nonatomic,assign)unsigned char  c_encrypted_ic_flag;	//是否有加密IC
@property (nonatomic,assign)unsigned char  c_pir_flag; 			//是否有PIR传感器，0:无，1:有，下同
@property (nonatomic,assign)unsigned char  c_pir_distance_flag; //是否支持PIR距离设置，门铃5200
@property (nonatomic,assign)unsigned char  c_ptz_flag; 			//是否有云台
@property (nonatomic,assign)unsigned char  c_mic_flag; 			//是否有咪头

@property (nonatomic,assign)unsigned char  c_speaker_flag; 		//是否有喇叭
@property (nonatomic,assign)unsigned char  c_sd_flag;			//是否支持SD卡，不支持则不能录像

@property (nonatomic,assign)unsigned char  c_humidity_flag;     //是否有湿感探头
@property (nonatomic,assign)unsigned char  c_temperature_flag; 	//是否有温感探头
@property (nonatomic,assign)unsigned char  c_timezone_flag;		//是否支持同步时区

@property (nonatomic,assign)unsigned char  c_night_vison_flag;	//是否支持夜视
@property (nonatomic,assign)unsigned char  ethernet_flag;	//是否带网卡0:wifi 1有线2wifi加有线
@property (nonatomic,assign)unsigned char  c_smart_connect_flag;	//是否支持smart扫描	0代表不支持，1代表7601smart  2代表8188smart
@property (nonatomic,assign)unsigned char  c_motion_detection_flag; //是否支持移动侦测

@property (nonatomic,assign)unsigned char  c_record_duration_flag; // 是否有设置录像录像时长
@property (nonatomic,assign)unsigned char  c_light_flag; // 是否有设置照明灯开关
@property (nonatomic,assign)unsigned char  c_audio_alarm_detection_flag; //是否支持声音侦测报警
@property (nonatomic,assign)unsigned int   align1;	//是否支持摇篮曲

@property (assign, nonatomic)unsigned char c_led_sw_flag; //是否有状态指示灯
@property (assign, nonatomic)unsigned char c_camera_sw_flag; //是否有摄像头开关
@property (assign, nonatomic)unsigned char c_camera_mic_sw_flag; //是否有麦克风开关

@property (assign, nonatomic)unsigned char c_battery_level_flag; //是否支持电量显示
@property (assign, nonatomic)unsigned char c_netlink_signal_flag; //是否支持获取中继器和路由之间信号
@property (assign, nonatomic)unsigned char c_stream_passwd_flag; //是否支持获取中继器和路由之间信号
@property (assign, nonatomic)unsigned char c_Alexa_Skills_Kit_flag; //是否有alexa 功能；

@property (nonatomic,assign)unsigned char c_doorbell_ring;      //铃声提醒
@property (nonatomic,assign)unsigned char c_doorbell_led;       //LED灯提醒

@property (nonatomic,assign)unsigned char c_full_duplex_flag;   //是否支持全双工

@end

//获取能力集
@interface CMD_GetDevAbilityReq : BaseCommand
@end
@interface CMD_GetDevAbilityResp : CMD_DevAbility
@end

//设备属性
@interface CMD_GetAllParamReq : BaseCommand
@end
@interface CMD_GetAllParamResp : BaseCommand

@property(nonatomic,assign)int mode;
@property(nonatomic,assign)int un_manual_record_switch;
@property(nonatomic,assign)int pir_detect_switch;
@property(nonatomic,assign)int battery_level; //电池电量
@property(nonatomic,assign)int pir_detect_sensitivity;
@property(nonatomic,assign)int audio_alarm_switch;
@property(nonatomic,assign)int audio_alarm_sensitivity;
@property(nonatomic,assign)int motion_detect_switch;
@property(nonatomic,assign)int motion_detect_sensitivity;

@property(nonatomic,assign)int device_switch;
@property(nonatomic,assign)int device_led_switch;
@property(nonatomic,assign)int device_mic_switch;

@property(nonatomic,assign)int doorbell_led;
@property(nonatomic,assign)int doorbell_ring;
@end



//设备状态
@interface CMD_SetVideoModeReq : BaseCommand
@property ENUM_VIDEO_MODE mode;
@end
@interface CMD_SetVideoModeResp : BaseCommand
@end

@interface CMD_SetPirDetectReq : BaseCommand
@property int un_switch;
@property int un_sensitivity;
@end
@interface CMD_SetPirDetectResp : BaseCommand
@end
/// 红外侦测
@interface CMD_GetPirDetectReq : BaseCommand
@property (nonatomic, assign) int channel;
@end
@interface CMD_GetPirDetectResp : BaseCommand
@property (nonatomic, assign) int un_switch;
@property (nonatomic, assign) int channel;
@end

@interface CMD_SetChannelPirDetectReq : BaseCommand
@property int channel;
@property int un_delay;                 //持续运动时间 灵敏度设置
@property int un_switch;                //开关
@property int un_sensitivity;           //距离设置
@property int un_alarm_ring;            //摄像机报警声设置 依赖于un_switch字段，只有un_switch和un_alarm_ring都为1下面才会触发报警声
@end
@interface CMD_SetChannelPirDetectResp : BaseCommand
@end


@interface CMD_GetChannelPirDetectReq : BaseCommand
@property int channel;
@end

@interface CMD_GetChannelPirDetectResp : BaseCommand
@property int un_delay;                 //持续运动时间 //1 2 3 低中高
@property int un_switch;                //开关 0-1
@property int un_sensitivity;           //距离设置 0-5...-25
@property int channel;
@property int un_alarm_ring;            //入侵报警声
@end


@interface CMD_MotionDetect : BaseCommand
@property int c_sensitivity;
@property int c_switch;
@property unsigned int un_mode;	// 手动划分坐标0 or 自动多分屏坐标1
@property unsigned int un_submode; //多分屏下1x1=0, 2x2=1, 3x3=2, 4x4=3
@property unsigned int un_enable;//根据多分屏模式下选择区域是否使能最多4x4=16;
@end

@interface CMD_SetMotionDetectReq : CMD_MotionDetect
@end
@interface CMD_SetMotionDetectResp : BaseCommand
@end

@interface CMD_GetMotionDetectReq : BaseCommand
@end
@interface CMD_GetMotionDetectResp : CMD_MotionDetect
@end


@interface CMD_SetManualRecordReq : BaseCommand
@property int manual_record_switch;
@end
@interface CMD_SetManualRecordResp : BaseCommand
@end



@interface CMD_AudioAlarm : BaseCommand
@property int  un_switch;
@property int  un_sensitivity;  //0:关闭， 1:低2:中3:高
@end

@interface CMD_SetAudioAlarmReq : CMD_AudioAlarm
@end
@interface CMD_SetAudioAlarmResp : BaseCommand
@end

@interface CMD_GetAudioAlarmReq : BaseCommand
@end
@interface CMD_GetAudioAlarmResp : CMD_AudioAlarm
@end



//SD卡信息
@interface CMD_SDCardInfo : BaseCommand
@property (nonatomic,assign)unsigned int a_total_size;	//总容量
@property (nonatomic,assign)unsigned int a_used_size;	//已用容量
@property (nonatomic,assign)unsigned int a_free_size;	//未用容量
@end

//获取SD卡信息
@interface CMD_GetSDCardInfoReq : BaseCommand
@end
@interface CMD_GetSDCardInfoResp : CMD_SDCardInfo
@end

//格式化SD卡
@interface CMD_FormatSDCardReq : BaseCommand
@end
@interface CMD_FormatSDCardResp : CMD_SDCardInfo
@end

//温度报警
@interface CMD_TempAlarm : BaseCommand
@property (nonatomic,assign)unsigned int alarm_enale;			//上下限温度报警开关， 0:上下限全部关闭， 1:上限开启，下限关闭，2:上限关闭，下限开启，3:上下限全部开启
@property (nonatomic,assign)unsigned int temperature_type;		//温度表示类型， 0:表示摄氏温度.C， 1；表示华氏温度.F
@property (nonatomic,assign)double curr_temperature_value;		//当前温度
@property (nonatomic,assign)double max_alarm_value;				//上限报警温度
@property (nonatomic,assign)double min_alarm_value;				//下限报警温度
@end

//获取温度报警
@interface CMD_GetTempAlarmReq : BaseCommand
@end
@interface CMD_GetTempAlarmResp : CMD_TempAlarm
@end

//设置温度报警
@interface CMD_SetTempAlarmReq : CMD_TempAlarm
@end
@interface CMD_SetTempAlarmResp : BaseCommand
@end




//设置设备密码
@interface CMD_SetDevicePassword : BaseCommand

@property(nonatomic,strong)NSString *newpasswd;
@property(nonatomic,strong)NSString *oldpasswd;

@end

//设置摇篮曲
@interface CMD_SetBabyMusicReq : BaseCommand
@property (nonatomic,assign)unsigned int alarm_ring_no;  //摇篮曲序号
@end


//获取摇篮曲
@interface CMD_GetBabyMusicReq : BaseCommand
@end

//打开摇篮曲
@interface CMD_openBabyMusicReq : BaseCommand
@end


//关闭摇篮曲
@interface CMD_closeBabyMusicReq : BaseCommand
@end

//查询SD卡报警数据
@interface CMD_searchSDAlarmReq : BaseCommand
@property (nonatomic, assign)  int channel;         //子设备通道号
@property (nonatomic, strong)  NSString * subId;    //子设备ID

@property (nonatomic,copy)NSString *start_time;
@property (nonatomic,copy)NSString *end_time;
@end


//查询SD卡录像数据
@interface CMD_searchSDVideoReq : BaseCommand
@property (nonatomic, strong)  NSString * subId;    //子设备ID
@property (nonatomic, assign)  int channel;         //子设备通道号
@property (nonatomic,copy)NSString *start_time;
@property (nonatomic,copy)NSString *end_time;
@end

//Wifi
@interface CMD_WifiInfo :BaseCommand
@property NSString *a_SSID;
@property NSString *a_passwd;
@end

//设置Wifi
@interface CMD_SetWifiInfoReq :CMD_WifiInfo
@end
@interface CMD_SetWifiInfoResp :BaseCommand
@end

//云台
@interface CMD_SetPTZReq : BaseCommand
@property ENUM_PTZCMD control;
@end
@interface CMD_SetPTZResp :BaseCommand
@end


//录像文件
@interface CMD_RecordFile : BaseCommand
@property NSString *a_file_name;
@property NSString *a_path;
@end

@interface CMD_GetRecFileOneMonthReq :BaseCommand
@property (assign, nonatomic)  NSInteger channel;   //设备通道号
@property (nonatomic, strong)  NSString * subId;    //子设备ID

@end
@interface CMD_GetRecFileOneMonthResp : BaseCommand
@property NSString *page_data;
@end

@interface CMD_GetRecFileOneDayReq : BaseCommand
@property NSInteger page_num;
@property NSInteger file_type;
@property NSString *a_day;

@property NSString *filename;
@property NSInteger direction; //往上:0 往下:1

@end

@interface CMD_GetRecFileOneDayResp : BaseCommand
@property NSInteger page_total_num;
@property NSString *page_data;
@end


@interface CMD_DeleteRecordFileReq : BaseCommand
@property NSString *a_file_name;
@property NSArray *file_name_list;
@end
@interface CMD_DeleteRecordFileResp : BaseCommand
@end


@interface CMD_DownloadRecordFileReq : CMD_RecordFile
@end
@interface CMD_DownloadRecordFileResp : BaseCommand
@end


@interface CMD_StopDownloadingRecFileReq : CMD_RecordFile
@end
@interface CMD_StopDownloadingRecFileResp : BaseCommand
@end



#pragma mark == NewAdded

//摄像头开关
@interface CMD_CameraSwitch : BaseCommand
@property(nonatomic,assign)int device_switch;
@end

@interface CMD_GetCameraSwitchReq :BaseCommand
@end
@interface CMD_GetCameraSwitchResp :CMD_CameraSwitch
@end

@interface CMD_SetCameraSwitchReq :CMD_CameraSwitch
@end
@interface CMD_SetCameraSwitchResp :BaseCommand
@end


//设备麦克风开关
@interface CMD_Device_Mic : BaseCommand
@property(nonatomic,assign)int device_mic_switch;
@end

@interface CMD_SetDeviceMicSwitchReq :CMD_Device_Mic
@end
@interface CMD_SetDeviceMicSwitchResp :BaseCommand
@end


//设备Led开关
@interface CMD_Device_Led : BaseCommand
@property(nonatomic,assign)int device_led_switch;
@end

@interface CMD_SetDeviceLedSwitchReq :CMD_Device_Led
@end
@interface CMD_SetDeviceLedSwitchResp :BaseCommand
@end


//设备夜视开关
@interface CMD_Device_Night : BaseCommand
@property(nonatomic,assign)int un_auto;
@property(nonatomic,assign)int un_day_night;
@end

@interface CMD_SetDeviceNightSwitchReq :CMD_Device_Night
@property (nonatomic, assign) int channel;
@end
@interface CMD_SetDeviceNightSwitchResp :BaseCommand
@end

@interface CMD_GetDeviceNightSwitchReq :BaseCommand
@property (nonatomic, assign) int channel;
@end
@interface CMD_GetDeviceNightSwitchResp :CMD_Device_Night
@end



//防闪烁
@interface CMD_Device_NTSC_PAL : BaseCommand
@property(nonatomic,assign)int Hz;
@end

@interface CMD_SetDevice_NTSC_PALReq :CMD_Device_NTSC_PAL
@end
@interface CMD_SetDevice_NTSC_PALResp :BaseCommand
@end



//门灯
@interface CMD_LightDuration : BaseCommand
@property unsigned int	un_on_hour;
@property unsigned int	un_on_min;
@property unsigned int	un_off_hour;
@property unsigned int	un_off_min;
@property unsigned int 	un_wday_switch;	//按 0~6位表示，第0位表示星期天，第1位表示星期一 0->关闭 1->打开
@end

@interface CMD_SetLightDurationReq :CMD_LightDuration
@end;

@interface CMD_GetLightDurationReq : BaseCommand
@end

@interface CMD_GetLightDurationResp : CMD_LightDuration
@end

//设置灯开关，获取通过每帧的枕头
@interface CMD_LightSwitch : BaseCommand
@property(nonatomic,assign)int un_light_switch;
@end

@interface CMD_SetLightSwitchReq :CMD_LightSwitch
@end
@interface CMD_SetLightSwitchResp :BaseCommand
@end

//开始播放报警铃声请求 只用发MessageType
@interface CMD_PlayAlarmRingReq :BaseCommand
@end
@interface CMD_PlayAlarmRingResp :BaseCommand
@end

//获取电池电量
@interface CMD_GetBatteryLevelReq :BaseCommand
@property (assign, nonatomic)  NSInteger channel;
@end
@interface CMD_GetBatteryLevelResp :BaseCommand
@property (assign, nonatomic)  int battery_level;
@end

//获取网关与路由器连接信号强度
@interface CMD_GetNetLinkSignalLevelReq :BaseCommand
@end
@interface CMD_GetNetLinkSignalLevelResp :BaseCommand
@property (assign, nonatomic)  int netlink_signal;
@end

//获取门铃设备状态
typedef NS_ENUM(NSUInteger, MYCAMEREA_STATUS) {
    MYCAMEREA_STATUS_NORMAL = 0,        //正常，已经配对并且在线,
    MYCAMEREA_STATUS_NO_ONLINE,         //配对了，但是不在线
    MYCAMEREA_STATUS_NO_PAIR,           //没有配对
    MYCAMEREA_STATUS_CHANGE_BATTERY,    //更换电池
    MYCAMEREA_STATUS_FORBID_STREAM,     //禁止拉流
    MYCAMEREA_STATUS_ERROR,             //异常

};


@interface CMD_GetDoorbellCameraStatusReq :BaseCommand
@property (assign, nonatomic)  NSInteger channel;
@end
@interface CMD_GetDoorbellCameraStatusResp :BaseCommand
@property (assign, nonatomic)  MYCAMEREA_STATUS camera_status;
@end


@interface CMD_SSIDInfo : NSObject
@property(nonatomic,strong)NSString *a_SSID;
@property(nonatomic,assign)int un_signal_level;
@end

//设备WiFi热点列表
@interface CMD_GetDeviceSSIDListReq :BaseCommand
@end

@interface CMD_GetDeviceSSIDListResp : BaseCommand
@property(nonatomic,strong)NSArray *ssid_info;
@property(nonatomic,assign)int     un_ssid_num;
@end



//升级
@interface CMD_UpdateDeviceReq :BaseCommand
@property(nonatomic,strong)NSString *a_ipaddr;
@property(nonatomic,assign)int      un_port;
@property(nonatomic,assign)int      cancelFlag;
@end
@interface CMD_UpdateDeviceResp : BaseCommand
@property(nonatomic,assign)int     result;
@end

//取消升级
@interface CMD_CancelUpdateDeviceReq :BaseCommand
@property(nonatomic,strong)NSString *a_ipaddr;
@property(nonatomic,assign)int      un_port;
@property(nonatomic,assign)int      cancelFlag;
@end
@interface CMD_CancelUpdateDeviceResp : BaseCommand
@property(nonatomic,assign)int     result;
@end



//5100 门铃解绑子设备（通过中继，从中继删除）
@interface CMD_DeleteSubDeviceReq :BaseCommand
@end
@interface CMD_DeleteSubDeviceResp : BaseCommand
@end


//门铃设置bell提醒开关
@interface CMD_SetDBBellRemindReq :BaseCommand
@property (assign, nonatomic)  int doorbell_ring;
@end
@interface CMD_SetDBBellRemindResp : BaseCommand
@end


//门铃设置Led提醒开关
@interface CMD_SetDBLedRemindReq :BaseCommand
@property (assign, nonatomic)  int doorbell_led;

@end
@interface CMD_SetDBLedRemindResp : BaseCommand
@end

//通知中继添加子设备成功
@interface CMD_NotifyAddSubDevSuccessfullyReq:BaseCommand
@property (assign, nonatomic)  NSInteger channel;
@end

@interface CMD_NotifyAddSubDevSuccessfullyResp:BaseCommand
@end


//通知中继删除子设备成功
@interface CMD_NotifyDeleteSubDevReq:BaseCommand
@property (assign, nonatomic)  NSInteger channel;
@end

@interface CMD_NotifyDeleteSubDevResp:BaseCommand
@end

// 中继获取音量大小
@interface CMD_GetDBBellVolumeReq : BaseCommand
@end
@interface CMD_GetDBBellVolumeResp : BaseCommand
@property (assign, nonatomic)  int Volume;
@end

// 中继设置音量大小
@interface CMD_SetDBBellVolumeReq : BaseCommand
@property (assign, nonatomic)  int Volume;
@end
@interface CMD_SetDBBellVolumeResp : BaseCommand
@property (assign, nonatomic)  int Volume;
@end


// 删除TFCard文件
// "list":[{"start_time":100,"end_time":100},{"start_time":101,"end_time":101}]
@interface CMD_DeleteTFFileReq : BaseCommand
@property NSArray *list;
@end
@interface CMD_DeleteTFFileResp : BaseCommand
@end

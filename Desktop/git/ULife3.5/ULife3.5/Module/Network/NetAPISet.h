//
//  NetAPISet.h
//  NetProDemo
//
//  Created by zhuochuncai on 15/2/17.
//  Copyright © 2017年 zhuochuncai. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FileModel.h"
#import "NetPro.h"
#import "GosFrameHeadDef.h"



extern NSString *const ADDeviceConnectStatusNotification;
extern NSString *const ADDevicePwdErrorNotification;

//typedef struct
//{
//    unsigned int utctime;            //请求时间
//    int type;                //0 是获取预览图 1是开始回放视频2剪接视频
//    int duration;                //剪接时长
//}SMsgAVIoctrlPlayRecordReq;


typedef struct
{
    unsigned int  pir_flag;				//是否有PIR传感器，0:无，1:有，下同
    unsigned int  ptz_flag;				//是否有云台
    unsigned int  mic_flag;				//是否有咪头
    unsigned int  speaker_flag;			//是否有喇叭
    unsigned int  temperature_flag;		//是否有温感探头
    unsigned int  resolution_0_flag;    //主码流分辨率大小 width:高16位 Height:低16位
    unsigned int  resolution_1_flag;
    unsigned int  reserver[6];
}SMsgAVIoctrlGetDeviceAbility;

typedef struct
{
    unsigned int   c_device_type; //设备类型900中性版101彩益100海尔
    unsigned int   un_resolution_0_flag;	//主码流分辨率大小 Width:高16位 Height:低16位  Ming@2016.06.14
    unsigned int   un_resolution_1_flag;	//子码流
    unsigned int   un_resolution_2_flag;	//第3路码流
    unsigned char  c_encrypted_ic_flag;	//是否有加密IC
    unsigned char  c_pir_flag; 			//是否有PIR传感器，0:无，1:有，下同
    unsigned char  c_ptz_flag; 			//是否有云台
    unsigned char  c_mic_flag; 			//是否有咪头
    unsigned char  c_speaker_flag; 		//是否有喇叭
    unsigned char  c_sd_flag;			//是否有SD卡
    unsigned char  c_temperature_flag; 	//是否有温感探头
    unsigned char  c_timezone_flag;		//是否支持同步时区
    unsigned char  c_night_vison_flag;	//是否支持夜视
    
    unsigned char  ethernet_flag;	//是否带网卡
    unsigned char  c_smart_connect_flag;	//是否支持smart扫描	0代表不支持，1代表7601smart  2代表8188smart
    unsigned char  c_motion_detection_flag; //是否支持移动侦测
    
    unsigned char  c_record_duration_flag; // 是否有设置录像录像时长
    unsigned char  c_light_flag; // 是否有设置照明灯开关
    unsigned char  c_voice_detection_flag; //是否支持声音侦测报警
    unsigned char  align1;	 // 用来字节对齐
    unsigned char  reserver_default_off[32]; // 预留能力集默认关闭
    unsigned char  reserver_default_on[32]; // 预留能力集默认开启
}DEVICE_ABILITY_INFO2;

typedef struct
{
    unsigned int   c_device_type; //设备类型900中性版101彩益100海尔
    unsigned int   un_resolution_0_flag;	//主码流分辨率大小 Width:高16位 Height:低16位  Ming@2016.06.14
    unsigned int   un_resolution_1_flag;	//子码流
    unsigned int   un_resolution_2_flag;	//第3路码流
    unsigned char  c_encrypted_ic_flag;	//是否有加密IC
    unsigned char  c_pir_flag; 			//是否有PIR传感器，0:无，1:有，下同
    unsigned char  c_ptz_flag; 			//是否有云台
    unsigned char  c_mic_flag; 			//是否有咪头
    unsigned char  c_speaker_flag; 		//是否有喇叭
    unsigned char  c_sd_flag;			//是否有SD卡
    unsigned char  c_temperature_flag; 	//是否有温感探头
    unsigned char  c_timezone_flag;		//是否支持同步时区
    unsigned char  c_night_vison_flag;	//是否支持夜视
    
    unsigned char  ethernet_flag;	//是否带网卡
    unsigned char  c_smart_connect_flag;	//是否支持smart扫描	0代表不支持，1代表7601smart  2代表8188smart
    unsigned char  c_motion_detection_flag; //是否支持移动侦测
    unsigned char  c_record_duration_flag;
}DEVICE_ABILITY_INFO1;

typedef struct
{
    unsigned int 	AppTimeSec;			//App端的时间 (以秒数下发)
    unsigned int	NtpOpen;			//ntp校时开关 (1:开启， 0:关闭， 默认为开启)
    unsigned int	EuroTime;			//夏令时开关  (1:开启,  0:关闭， 默认为关闭)
    unsigned int	NtpRefTime;			//ntp校时间隔 (单位秒, 默认为300s)
    int				TimeZone;			//时区 (-12~11， 默认为 8)
    char     		NtpServer[64];		//ntp校时服务器地址
    unsigned int	NtpPort; 			//ntp校时服务器端口
    unsigned int	reserved[2];
}NETTimeParam;



/**
 *  获取时间校验参数
 *
 *  @param result   result < 0,命令请求或者发送失败,result=0,命令请求或者发送成功
 *
 */
typedef void(^BlockGetTimeParamResult)(int result,NETTimeParam resp);



/**
 *  返回设备密码信息请求
 *
 *  @param result   result < 0,命令请求或者发送失败,result=0,命令请求或者发送成功
 *  @param passWord 返回密码
 *  @param cmd      对应的请求命令类型(CmdModelType)
 */
typedef void(^BlockDevicePWDReqResult)(int result,NSString* passWord,int cmd);



/**
 *  返回发送或者请求命令后状态
 *
 *  @param result   result < 0,命令请求或者发送失败,result=0,命令请求或者发送成功
 *  @param state    操作结果
 *  @param cmd      返回命令类型 CmdModelType
 */
typedef void(^BlockCommandReqResult)(int result,int state,int cmd);



//unsigned int total_size;	//总容量
//unsigned int used_size;		//已用容量
//unsigned int free_size;		//未用容量
typedef void(^BlockSDInfoResult)(int result,int total_size,int used_size,int free_size);



/**
 *  获取设备的控制状态
 *
 *    result                            result < 0,命令请求或者发送失败,result >=0,命令请求或者发送成功
 *    video_mirror_mode                //镜像 & 翻转模式 (0:none,1:horizontal,2:vertical,3:horizonta+vertical)
 *    manual_record_switch;			//手动录像开关   (关: 0,  开: 1)
 *    motion_detect_sensitivity;	    //移动侦测等级   (关: 0,  低: 30  中: 60  高: 90)
 *    pir_detect_switch;			    //红外侦测开关	   (关: 0,  开: 1)
 *    video_quality;				    //码流质量       (高清: 0, 流畅: 1)
 *    audio_alarm_sensitivity;         //移动侦测等级   (关: 0,  低: 1  中: 2  高: 3)
 */
typedef void (^BlockDeviceControlStateResult)(int result,unsigned int  video_mirror_mode,unsigned int  manual_record_switch,unsigned int  motion_detect_sensitivity, unsigned int  pir_detect_switch,unsigned int  video_quality,unsigned int  audio_alarm_sensitivity);



/**
 *  获取温度报警参数
 * result                            result < 0,命令请求或者发送失败,result >=0,命令请求或者发送成功
 unsigned int                      alarm_enale;			//上下限温度报警开关， 0:上下限全部关闭， 1:上限开启，下限关闭，2:上限关闭，下限开启，3:上下限全部开启
 unsigned int                      temperature_type;		//温度表示类型， 0:表示摄氏温度.C， 1；表示华氏温度.F
 double double                          curr_temperature_value;		//当前温度
 double                            max_alarm_value;				//上限报警温度
 double                            min_alarm_value;				//下限报警温度
 unsigned char reserved[16];			//
 */
typedef  void(^BlockTemperatureAlarmStateReult)(int result,unsigned int alarm_enale,unsigned int temperature_type,double curr_temperature_value,double  max_alarm_value ,double  min_alarm_value);



/**
 *     result
 *     unsigned int  pir_flag;				//是否有PIR传感器，0:无，1:有，下同
 *  	unsigned int  ptz_flag;				//是否有云台
 *     unsigned int  mic_flag;				//是否有咪头
 *  	unsigned int  speaker_flag;			//是否有喇叭
 *     unsigned int  temperature_flag;		//是否有温感探头
 *     unsigned int  resolution_0_flag;    //主码流分辨率大小 width:高16位 Height:低16位
 *     unsigned int  resolution_1_flag;
 */


typedef void (^BlockGetDeviceAbilityResult)(int result,SMsgAVIoctrlGetDeviceAbility *GetDeviceAbility);

/**
 unsigned int   c_device_type; //设备类型   900中性版     101彩益     100海尔	    901高世安
 unsigned int   un_resolution_0_flag;	//主码流分辨率大小 Width:高16位 Height:低16位  Ming@2016.06.14
 unsigned int   un_resolution_1_flag;	//子码流
 unsigned int   un_resolution_2_flag;	//第3路码流
 unsigned char  c_encrypted_ic_flag;	//是否有加密IC
 unsigned char  c_pir_flag; 			//是否有PIR传感器，0:无，1:有，下同
 unsigned char  c_ptz_flag; 			//是否有云台
 unsigned char  c_mic_flag; 			//是否有咪头
 
 unsigned char  c_speaker_flag; 		//是否有喇叭
 unsigned char  c_sd_flag;			//是否有SD卡
 unsigned char  c_temperature_flag; 	//是否有温感探头
 unsigned char  c_timezone_flag;		//是否支持同步时区
 
 unsigned char  c_night_vison_flag;	//是否支持夜视
 unsigned char  ethernet_flag;	//是否带网卡0:wifi 1有线2wifi加有线
 unsigned char  c_smart_connect_flag;	//是否支持smart扫描	0代表不支持，1代表7601smart  2代表8188smart
 unsigned char  c_motion_detection_flag; //是否支持移动侦测
 
 unsigned char  c_record_duration_flag; // 是否有设置录像录像时长
 unsigned char  c_light_flag; // 是否有设置照明灯开关
 unsigned char  c_voice_detection_flag; //是否支持声音侦测报警
 unsigned char  align1;	 // 用来字节对齐
 unsigned char  reserver_default_off[32]; // 预留能力集默认关闭
 unsigned char  reserver_default_on[32]; // 预留能力集默认开启
 **/


typedef void (^BlockGetDeviceAbilityResult3)(int result,DEVICE_ABILITY_INFO2*device_abilty_info2);

/**
 *  获取设备的能力
 *
 *  	unsigned int   c_device_type;           //设备类型900中性版101彩益100海尔
 *  	unsigned int   un_resolution_0_flag;	//主码流分辨率大小 Width:高16位 Height:低16位  Ming@2016.06.14
 *  	unsigned int   un_resolution_1_flag;    //子码流
 *  	unsigned int   un_resolution_2_flag;	//第3路码流
 *  	unsigned char  c_encrypted_ic_flag;	    //是否有加密IC
 *  	unsigned char  c_pir_flag; 			    //是否有PIR传感器，0:无，1:有，下同
 *  	unsigned char  c_ptz_flag; 			    //是否有云台
 *  	unsigned char  c_mic_flag; 			    //是否有咪头
 *  	unsigned char  c_speaker_flag; 		    //是否有喇叭
 *  	unsigned char  c_sd_flag;			    //是否有SD卡
 *  	unsigned char  c_temperature_flag; 	    //是否有温感探头
 *  	unsigned char  c_timezone_flag;		    //是否支持同步时区
 *  	unsigned char  c_night_vison_flag;	    //是否支持夜视
 *  	unsigned char  ethernet_flag;	//是否带网卡
 *  	unsigned char  c_smart_connect_flag;	//是否支持smart扫描	0代表不支持，1代表7601smart  2代表8188smart
 *  	unsigned char  c_motion_detection_flag; //是否支持移动侦测
 *  	unsigned char  c_record_duration_flag;
 */
typedef void (^BlockGetDeviceAbilityResult2)(int result,DEVICE_ABILITY_INFO1 *device_abilty_info);



/**
 *  获取设备的信息
 *
 *  @param result    result < 0,命令请求或者发送失败,result >=0,命令请求或者发送成功
 *  @param device_id 设备的UID
 *  @param macaddr   mac地址
 *  @param soft_ver  软件版本
 *  @param firm_ver  硬件版本
 *  @param model_num //设备型号
 *  @param Wifi      设备连接路由器的wifi名称
 */
typedef void(^BlockDeviceInfoResult)(int result,NSString *device_id,NSString *macaddr,NSString *soft_ver,NSString *firm_ver,NSString *model_num,NSString *Wifi);



typedef void (^BlockDeviceSetting)(int result,int pir_flag,int ptz_flag,int mic_flag,int speaker_flag,int temperature_falg);



//(0:获取录像列表成功, 1:获取录像列表失败 , 2:录像列表为空，即为无录像, 3:无卡)
typedef void(^BlockVideoInfoResult)(int result,int cmd,NSArray *listArray);

//(0:获取录像列表成功, )
typedef void(^BlockOneDayRecFileResult)(int result,int totalNum,int curNum,NSArray *listArray);


/**开始下载
 @param result    result < 0,命令请求或者发送失败,result =0,命令请求或者发送成功,result = 2下载停止
 @param progress  写文件的进度值
 */
typedef void(^BlockVideoStartDownLoad)(int result,float progress,NSString *uid);

typedef void(^BlockGetVideoData)(int result, int state);


/** NVR 获取视频流状态 */
typedef NS_ENUM(NSInteger, NvrGetDataStatus) {
    NvrGetDataSuccess                   = 0,            // 拉流成功
    NvrGetDataFailure                   = -1,           // 拉流失败
    NvrGetDataOffLine                   = -2,           // 设备不在线
    NvrGetDataConnFailure               = -3,           // 设备连接失败
    NvrGetDataParamError                = -4,           // 参数错误
};


typedef void(^NvrGetVideoDataBlock)(NvrGetDataStatus retStatus, NSString *nvrDeviceId, long avChannel);

typedef void(^NvrStopVideoDataBlock)(BOOL isSuccess, NSString *nvrDeviceId, long avChannel);



#pragma mark - NVR 相关 Block __ Start
#pragma mark -- 创建 NVR 支持的 AV 通道结果处理 Block
/**
 创建 NVR 支持的 AV 通道结果处理 Block

 @param isSuccess           是否创建成功
 @param channelNum          成功创建 AV 通道数
 */
typedef void(^NvrCreateAvChannelBlock)(BOOL isSuccess, long channelNum);


#pragma mark -- 获取 NVR 录像列表 Block
/**
 获取 NVR 录像列表 Block

 @param isSuccess           是否成功
 @param nvrDeviceId         NVR 设备 ID
 @param fileName            文件名（路径）
 @param startTime           起始时间
 @param endTime             结束时间
 @param length              文件时长
 @param frames              文件总帧数
 @param channelMask         频道
 @param recordType          类型
 @param fileTotalNumbers    录像文件总数量
 */
typedef void(^NvrRecordListBlock)(BOOL isSuccess, NSString *nvrDeviceId, NSString *fileName, NSString *startTime, NSString *endTime, unsigned int length, unsigned int frames, unsigned short channelMask, unsigned short recordType, unsigned int fileTotalNumbers);


/**
 *  NVR 录像文件操作命令 枚举
 */
typedef NS_ENUM(NSInteger, NVRRecordFilePlayType) {
    NVRRecordFilePlayStart = 0,     // 开始播放
    NVRRecordFilePlayPause,         // 暂停播放
    NVRRecordFilePlayResume,        // 回放播放
    NVRRecordFilePlayStop,          // 停止播放
    NVRRecordFilePlaySeek,          // 定点播放（从某个时间点开始请求播放，用于拖拽进度条）
    NVRRecordFilePlayEnd,           // 播放结束、播放出错
};

/**
 *  录像回放文件播放相关请求结果处理 Block
 *
 *  @param isSuccess                YES,请求播放成功,   NO,请求播放失败
 *  @param nvrRecordFilePlayType    请求命令
 *  @param avIndex                  用于播放的 avIndex
 */
typedef void(^NvrRecordPlayCtrlBlock)(BOOL isSuccess, NVRRecordFilePlayType nvrRecordFilePlayType, int avIndex);


#pragma mark - NVR 相关 Block __ End

/**
 请求的控制类型
 */
typedef enum CmdModelType
{
    CmdModel_Camera_PtzCommand_TYPE = 0,  //云台控制
    CmdModel_Camera_VIDEOQUALITY,          //码流切换,图片质量
    CmdModel_Camera_MOVEMONITOR,          //设置移动检测
    CmdModel_Camera_VIDEOMODE,            //设置水平和垂直
    CmdModel_Camera_RINGPLAY_TYPE,        //设置铃声播放类型
    CmdModel_Camera_RINGPLAY_STATE,        //设置铃声播放
    CmdModel_Camera_MANUAL_RECORD,         //设置手动录像
    //                                                    {
    //                                                        //    0：开启或关闭录像成功
    //                                                        //    1: 开启或关闭录像失败
    //                                                        //    2：无卡，不允许录像
    //                                                        //    3: 卡出错，不允许录像
    //                                                        //    4: 卡剩余容量不足，不允许录像
    //                                                        //    5: 正在录像中，不允许录像
    //                                                        //    6: 操作太频繁
    //                                                    }
    CmdModel_Camera_PIR_DETECT_SWITCH,    //设置红外侦测
    CmdModel_Camera_FORMAT_STORAGE,       //格式化SID
    CmdModel_Camera_DEVICE_CONTROL_STATE,   //获取设备所有的控制状态
    CmdModel_CONTROL_REQ,                 //设置一键布防
    CmdModel_DEVICEPWD,                   //设置设备密码
    CmdModel_DEVICESETTING,                //设置设备界面
    CMDModel_VIDEO,                       //音视频对讲操作
    cmdModel_VIDEOLIST,                 //录像列表
    cmdModel_DEVICEABILITY,             //获取设备能力
    cmdModel_Temperature,            //获取设备温度参数
    cmdModel_SET_TEMPERATUREDATA,    //设置设备温度参数
    cmdModel_GET_TimeParam,          //获取时间校验参数
    cmdModel_SET_TimeParam,          //设置时间校验参数
    cmdModel_SET_VoiceDetection,     //设置声音报警参数
}
CmdModelType;

/**
 获取音视频对讲数据类型
 */
typedef enum SendDataType
{
    VideoType,          //视频
    AudioType,          //语音
    SpeakerType,         //对讲
    VideoBuffering,      //视频开始接收数据
    AudioTypeBuffering,  //语音开始接收数据
    SpeakerSendDataFinish, //对讲数据发送数据结束
    VideoDataTimeout,       //视频获取数据失败
    VideoDrop,            //视频掉线
    AudioDrop,            //音频掉线
    CloseStream,
    CloseConn,
    Reconnect,
}
SendDataType;

/**
 请求的控制类型对应的属性
 */
typedef enum CameraCommandType
{
    Camera_PtzCommand_TURN_TO_LEFT = 0,	    //云台向左
    Camera_PtzCommand_TURN_TO_RIGHT,		//云台向右
    Camera_PtzCommand_TURN_TO_UP,			//云台向上
    Camera_PtzCommand_TURN_TO_DOWN,		    //云台向下
    
    Camera_PtzCommand_TURN_TO_KEEP_DOWN,    //云台连续向下
    Camera_PtzCommand_TURN_TO_KEEP_LEFT,     //云台连续向左
    Camera_PtzCommand_TURN_TO_KEEP_RIGHT,
    Camera_PtzCommand_TURN_TO_KEEP_UP,
    Camera_PtzCommand_TURN_TO_KEEP_STOP,    //停止
    
    Camera_VIDEOQUALITY_MAX,               //高清
    Camera_VIDEOQUALITY_HIGH,               //流畅
    
    Camera_MOVEMONITOR_CLOSE,              //移动检测关
    Camera_MOVEMONITOR_LOW,                //移动监测低
    Camera_MOVEMONITOR_MIDDELE,            //移动监测中
    Camera_MOVEMONITOR_HIGH,               //移动监测高
    
    Camera_VIDEOMODE_NORMAL,            //正常
    Camera_VIDEOMODE_FLIP,              //翻转
    Camera_VIDEOMODE_MIRROR,            //水平
    Camera_VIDEOMODE_FLIP_MIRROR,       //水平和垂直
    
    Camera_RINGPLAY_TYPE_DEFAULT,         //默认铃声 0
    Camera_RINGPLAY_TYPE_Custom,          //自定义   1
    Camera_RINGPLAY_TYPE_Sea,              //大海铃声 2
    Camera_RINGPLAY_TYPE_rain,             //下雨    3
    Camera_RINGPLAY_TYPE_nature,           //自然    4
    
    Camera_RINGPLAY_STATESTART,         //播放开始
    Camera_RINGPLAY_STATESTOP,          //播放结束
    
    Camera_PIR_DETECT_SWITCH_ON,       //红外侦测开
    Camera_PIR_DETECT_SWITCH_OFF,       //红外侦测关
    
    Camera_MANUAL_RECORD_ON,          //手动录像开
    Camera_MANUAL_RECORD_OFF,         //手动录像关
    
    Camera_FORMAT_STORAGE,           //格式化SD卡片
    
    Camera_Defalut,          //默认无效
    Camera_ONEOPEN,           //一键布防开
    Camera_ONECLOSE,          //一键布防关
    
    Camera_VIDEOLIST_MONTH_EVENT_LIST_REQ, //获取某月录像事件列表请求
    Camera_VIDEOLIST_DAY_EVENT_LIST_REQ,//获取获取某天录像事件列表请求
    Camera_VIDEOLIST_DOWNLOADFILE_START_REQ,//开始下载指定录像文件请求
    Camera_VIDEOLIST_DEL_RECORDFILE_REQ,//删除指定录像文件请求
    
    Camera_DeviceTemperature_REQ,  //获取温度报警参数请求；
    
    
    //用于内部调用，外部不需要调用
    Camera_IPCAM_START,     //视频开启
    Camera_IPCAM_STOP,     //视频停止
    Camera_AUDIOSTART,    //音频开启
    Camera_AUDIOSTOP,     //音频结束
    Camera_SPEAKERSTART,  //对讲开始
    Camera_SPEAKERSTOP   //对讲结束
}
CameraCommandType;

typedef enum NotificationType
{
    NotificationTypeDisconnect = -1, //连接失败
    NotificationTypeConnected = 0,	//连接成功
    NotificationTypeRunning = 1,   //正在连接
    NotificationTypeDevNotOnline, //摄像头不在线
    NotificationTypeRequestTimedout, //请求超时
    NotificationTypeNetworkError,   //网络断开连接
    NotificationTypeDeviceOFFLINE,   //服务器找不到设备或者设备不在线
    NotificationTypeClientPWD,   //创建连接密码错误
    NotificationTypeDefault
}
NotificationType;


typedef enum SendIOCtrlType
{
    IPCAM_STOP,  //视频流停止
    IPCAM_START, //视频开启
    AUDIOSTOP,   //语音停止
    AUDIOSTART,  //语音开始
    SPEAKERSTOP, //对讲停止
    SPEAKERSTART,//对讲开始
    PTZ_COMMAND,//云台控制
    SETSTREAMCTRL_REQ, //码流切换
    TIMEOUT_DISCONNECT, //连接超时,需要重新连接
    IOCTRL_AV_ER_INVALID_SID,//连接失败,无效的SID
    IPCM_AV_ER_DATA_NOREADY//获取视频数据延迟
}
SendIOCtrlType;


@protocol GDNetworkStateDelegate <NSObject>
/**
 *  开始绑定连接时返回的消息类型
 *
 *  @param UID       UID
 *  @param type      返回连接的状态
 *  @param error_ret error_ret< 0：连接失败,error_ret >=0:连接成功
 */
-(void)ConnectState:(NSString *)UID stateFlag:(NotificationType)type error_ret:(int)error_ret;

/**
 *  心跳包,检查设备当前的连接状态
 *
 *  @param UID  UID
 *  @param type 返回消息类型
 *  @param error_ret  错误码：error_ret< 0：连接失败,error_ret >=0:连接成功
 */
-(void)CheckNetworkState:(NSString*)UID stateFlag:(NotificationType)type andState:(int)error_ret;

-(void)showDeviceInfo:(NSString*)UID andRemoteIP:(NSString *) ip andPort:(int)port andMode:(NSString *)Mode;

-(void)didFinishRefreshingOnlineStatus;
@end




@protocol GDNetworkSourceDelegate <NSObject>

/**
 获取视频数据
 
 @param pContentBuffer 数据内容
 @param length 数据长度
 @param timeStamp 时间戳
 @param framNO 帧序号
 @param frameRate 帧率
 @param isIFrame 是否是 I 帧
 @param deviceId 设备 ID
 @param avChannel 对应的 AV 通道号
 */
- (void)getVideoData:(unsigned char *)pContentBuffer
          dataLength:(int)length
           timeStamp:(int)timeStamp
              framNo:(unsigned int)framNO
           frameRate:(int)frameRate
            isIFrame:(BOOL)isIFrame
            deviceID:(NSString *)deviceId
           avChannel:(int)avChannel;


/**
 *  获取音频数据
 *
 *  @param buffer 缓冲区
 *  @param len    长度
 *  @param framNO 帧号
 *  @param UID    设备UID
 *  @param frameType 帧类型 AAC/G711
 */
-(void)sendAudioData:(Byte *)buffer len:(int)len framNo:(unsigned int)framNO andUID:(NSString *)UID frameType:(gos_codec_type_t)frameType;

/**
 *  发送类型状态判断
 *
 *  @param type    发送数据的类型
 *  @param UID    UID
 *  @param errno_t error为0,表示发送成功，< 0,表示有错误
 */
-(void)sendDataTypeState:(SendDataType)type andUID:(NSString *)UID errno_ret:(int)error_t;

-(void)SendIOCtrlTypeState:(SendIOCtrlType)type andUID:(NSString *)UID errno_ret:(int)error_t;

/**
 *  对讲创建通道连接状态
 *
 *  @param error 错误码，error < 0
 *  @param UID  <#UID description#>
 */
-(void) SpeakerConnectState:(int)error andUID:(NSString *)UID;


#pragma mark - NVR 相关代理
#pragma mark -- 获取 NVR 设备支持通道数代理

/**
 获取 NVR 录像设备支持通道数回调

 @param channelNum 支持通道数
 @param nvrDeviceId NVR 设备 ID
 */
- (void)channelNumber:(long)channelNum
          nvrDeviceId:(NSString *)nvrDeviceId;

@end



@interface NetAPISet : NSObject

@property(nonatomic,assign)int connectingCount;
@property(nonatomic,assign)BOOL isConnecting;
@property (nonatomic,assign ) long downloadFileSize;

+(instancetype)sharedInstance;



@property(nonatomic,weak)id<GDNetworkStateDelegate>networkDelegate;
@property(nonatomic,weak)id<GDNetworkSourceDelegate>sourceDelegage;

- (void)stopPlayWithUID:(NSString *)UID  streamType:(kNetStreamType)streamType;



/**
 *  添加客户端,同时开始进行连接绑定
 *
 *  @param UID 设备ID
 */
-(long)addClient:(NSString *)UID andpassword:(NSString *)password;


// 对摄像头列表逐个检查其状态
-(void)CheckState;


- (void)checkSessionConnStateWithUID:(NSString*)uid;

/**
 *  打开调试日志开关
 *
 *  @param logState YES:打开,NO:关闭
 */

-(void)setOpenDebugLog:(BOOL)logState;


/**
 *  删除指定的UID
 *
 *  @param UID 设备ID
 */
-(void)DeleteClient:(NSString *)UID;

/**
 *  停止某个设备的连接
 *
 *  @param UID 设备UID
 */
-(long)stopClientConnect:(NSString *)UID;

-(long)ReconnectAndCloseOldStreamLaterWithUID:(NSString*)uid resultBlock:(BlockCommandReqResult)resultBlock;

/**
 *  停止所有设备的连接
 */
-(void)stopConnect;

/**
 *  连接失败时,重新连接
 *
 *  @param uid  设备UID
 */
-(void)reconnect:(NSString *)uid andBlock:(BlockCommandReqResult)result;

/**
 *  开始启动视频线程，发送数据,如果return<0,i表示的通讯没有联接
 *
 *  @param UID
 *
 *  @return 返回连接状态,
 */


-(BOOL)startSendVideoData:(NSString *)UID andBlock:(BlockCommandReqResult)result;

/**
 *  开始启动音频线程
 *
 *  @param UID    <#UID description#>
 *  @param result <#result description#>
 */
-(void)startAudioData:(NSString *)UID andBlock:(BlockCommandReqResult)result;

/**
 *  停止音频线程
 *
 *  @param UID    <#UID description#>
 *  @param result <#result description#>
 *
 *  @return <#return value description#>
 */
-(int)stopAudioData:(NSString *)UID andBlock:(BlockCommandReqResult)result;

/**
 *  停止启动音频和视频线程，停止发送数据
 *  @param UID
 */
-(void)stopSendVideoData:(NSString *)UID andBlock:(BlockCommandReqResult)result;
/**
 *  控制对讲操作
 *
 *  @param SpeakState SpeakState为YES,发送对讲数据；SpeakState为NO,无法发生对讲数据；
 */
-(bool)setSpeakState:(BOOL)SpeakState withUID:(NSString*)uid resultBlock:(BlockCommandReqResult)result;
/**
 *  启动对讲线程
 *
 *  @param UID      设备UID
 *  @param filePath 传入对讲的文件路径
 */
-(void)startSpeakThread:(NSString *)UID andFilePath:(NSString *)filePath;

-(void)sendTalkDataWithUID:(NSString*)UID data:(NSData*)data;

/**
 *  发送音频数据给设备
 *
 *  @param UID      <#UID description#>
 *  @param filePath <#filePath description#>
 *  @param result   <#result description#>
 */
-(void)startAudioFile:(NSString *)UID andFilePath:(NSString *)filePath andBlock:(BlockCommandReqResult)result;
/**
 *  发送设备控制命令
 *
 *  @param cmdModel      控制的类型
 *  @param CameraCommand 控制类型对应的数据
 *  @param UID           传入UID
 *  @param channel       默认传入O就可以了
 *  @param result        返回值,返回当前命令的发送的状态
 *
 */

#pragma mark - NewAdded
/* 设置拉流的通道号，一个主设备连接ID相同；子设备通过通道号区分 */
- (void)setStreamChannel:(int)channel;

//typedef enum
//{
//    kNETPRO_STREAM_VIDEO        = 0,    // 视频流
//    kNETPRO_STREAM_AUDIO,                // 音频流
//    kNETPRO_STREAM_ALL            = 0x02,    // 所有流
//    kNETPRO_STREAM_Live            = 0x03,    // Live直播流
//    kNETPRO_STREAM_ReC            = 0x04,    // 传递录像流
//}kNetStreamType; videoType

- (void)startGettingVideoDataWithUID:(NSString*)uid videoType:(int)videoType resultBlock:(BlockGetVideoData)videoDataBlock;

-(int)sendCmd:(CmdModelType)cmdModel andParam:(CameraCommandType )type andUID:(NSString *)UID andChannel:(int)channel andBlock:(BlockCommandReqResult)result;

-(void)setPtzMove:(CmdModelType)cmdModel andParam:(CameraCommandType )CameraCommand andUID:(NSString *)UID andBlock:(BlockCommandReqResult)result;

//设置视频的播放模式
-(void)getVideoQuality:(NSString *)UID andBlock:(BlockCommandReqResult)result;

// 0 预览图 1开始回放视频 2是剪切视频
- (int)sendSDCardControlWithType:(int)type deviceId:(NSString *)uid sudId:(NSString*)subId startTime:(unsigned int)startTime duration:(int)duration;

//关闭SD卡历史流
- (int)sendStopSDCardCammand:(NSString *)uid;

//仅仅对历史流生效，暂停接收音视频数据 nPasueFlag = 1 暂停接收， nPasueFlag = 0 恢复接收
- (int)pasueRecvStream:(int)nPasueFlag deviceId:(NSString *)uid;


/**
 *  获取设备的详细信息以及对应控制操作状态
 *
 *  @param cmdModel 控制的类型
 *  @param UID      设备ID
 *  @param result   返回控制状态
 *  @param devInfoResult   返回设备的详细信息
 *
 */
-(void)getDeviceAll:(CmdModelType)cmdModel andUID:(NSString *)UID andBlock:(BlockDeviceControlStateResult)result andDevice:(BlockDeviceInfoResult)devInfoResult;

/**
 *  设置设备的密码
 *
 *  @param cmdModel CmdModelType 设置请求控制类型
 *  @param pwd      传入设置密码,密码需要设置成“字母和数字结合8位以上”
 *  @param UID      传入对应的设备的UID
 *  @param result   返回结果
 *
 */



-(void)setDevicePassWord:(CmdModelType)cmdModel andPWD:(NSString *)pwd andUID:(NSString *)UID andBlock:(BlockCommandReqResult)result;



/**
 *  设置设备温度报警参数；
 *
 *  @param cmdModel             CmdModelType 设置请求控制类型
 *  @param alarm_enale          上下限温度报警开关， 0:上下限全部关闭， 1:上限开启，下限关闭，2:上限关闭，下限开启，3:上下限全部开启
 *  @param temperature_type     温度表示类型， 0:表示摄氏温度.C， 1；表示华氏温度.F
 *  @param max_alarm_value      上限报警温度
 *  @param min_alarm_value      下限报警温度
 *  @param UID                   传入对应的设备的UI
 *  @param result               返回结果
 *
 *  @return 0；
 */

-(void)setTemperatureData:(CmdModelType)cmdModel andalarm_enale:(int )alarm_enale andtemperature_type:(int)temperature_type   andmax_alarm_value:(double)max_alarm_value andmin_alarm_value:(double)min_alarm_value andUID:(NSString *)UID andBlock:(BlockCommandReqResult)result;



/**
 *  获取设备的密码
 *
 *  @param cmdModel CmdModelType 设置请求控制类型
 *  @param UID      传入设置设备的UID
 *  @param result   返回结果
 *
 *  @return 0
 */
-(void)getDevicePassWord:(CmdModelType)cmdModel andUID:(NSString *)UID andBlock:(BlockDevicePWDReqResult)result;

-(void)getDeviceability:(CmdModelType)cmdModel andUID:(NSString *)UID andBlock:(BlockGetDeviceAbilityResult)result andNewBlock:(BlockGetDeviceAbilityResult2)NewResult newerBlock:(BlockGetDeviceAbilityResult3)abilityResultBlock3;

-(void)getEveryDayVideoList:(CmdModelType)cmdModel andParam:(CameraCommandType )CameraCommand andUID:(NSString *)UID andBlock:(BlockVideoInfoResult)result;

/*
 *  获取音视频某天的录像
 *  @param cmdModel CmdModelType 设置请求控制类型
 *  @param UID      传入设置设备的UID
 *  @param result   返回结果
 *
 *  @return 0
 
 */
-(void)getOneDayVideoFileList:(CmdModelType)cmdModel andParam:(CameraCommandType )CameraCommand andUID:(NSString *)UID withDayVideo:(NSString*)dayvideo withType:(int)type andBlock:(BlockOneDayRecFileResult)result;


/*
 *  请求开始下载录像
 *  @param cmdModel CmdModelType 设置请求控制类型
 *  @param UID        传入设置设备的UID
 *  @param filename   传入下载的文件名
 *  @param filePath   传入文件路径
 *  @param result     返回结果
 *
 *  @return 0
 */

-(void)StartVideoListFileDownload:(CmdModelType)cmdModel andParam:(CameraCommandType )CameraCommand andUID:(NSString *)UID andFileName:(NSString *)filename andFilePath:(NSString *)filePath andBlock:(BlockVideoStartDownLoad)result;

-(long)StopVideoListFileDownload:(CmdModelType)cmdModel andParam:(CameraCommandType )CameraCommand andUID:(NSString *)UID;

/*
 *  请求开始删除指定文件
 *  @param cmdModel CmdModelType 设置请求控制类型
 *  @param UID      传入设置设备的UID
 *  @param result   返回结果
 *
 *  @return 0
 */

-(void)deleteVideoListFileName:(CmdModelType)cmdModel andParam:(CameraCommandType )CameraCommand andUID:(NSString *)UID withFileName:(NSString *)filename andBlock:(BlockCommandReqResult)result;

-(void)getStorageInfoWithUID:(NSString *)UID andBlock:(BlockSDInfoResult)result;

-(void)SetWifiReqWithUID:(NSString *)UID andSSID:(NSString *)SSID andPassWord:(NSString *)Password andBlock:(BlockCommandReqResult)result;

/*
 *  获取温度报警参数
 *  @param cmdModel CmdModelType 设置请求控制类型
 *  @param UID      传入设置设备的UID
 *  @param result   返回结果
 *
 *  @return 0
 */
-(void)getDeviceTemperatureData:(CmdModelType)cmdModel andUID:(NSString *)UID andBlock:(BlockTemperatureAlarmStateReult)result;



/*
 *  获取时间校准参数
 *  @param cmdModel CmdModelType 设置请求控制类型
 *  @param UID      传入设置设备的UID
 *  @param result   返回结果
 *
 *  @return 0
 */
-(void)getDeviceTimeParamData:(CmdModelType)cmdModel andUID:(NSString *)UID andBlock:(BlockGetTimeParamResult)result;




/*
 *  设置时间校准参数
 *  @param cmdModel CmdModelType 设置请求控制类型
 *  @param UID      传入设置设备的UID
 *  @param result   返回结果
 *
 *  @return 0
 */

-(void)setDeviceTimeParamData:(CmdModelType)cmdModel and:(NETTimeParam)req  andUID:(NSString *)UID andBlock:(BlockCommandReqResult)result;

/*
 *  设置声音报警参数
 *  @param cmdModel CmdModelType 设置请求控制类型
 *  @param UID      传入设置设备的UID
 *  @param result   返回结果
 *
 *  @return 0
 */

-(void)setVoiceDetection:(CmdModelType)cmdModel andun_switch:(int)un_switch andUID:(NSString *)UID andBlock:(BlockCommandReqResult)result;



/**
 升级设备命令

 @param UID 设备ID
 @param ip 升级服务器IP
 @param port 升级服务器断开
 @param result 回调Block
 */
- (void)updateDeviceWithUID:(NSString*)UID IP:(NSString *)ip Port:(int)port resultBlock:(BlockCommandReqResult)result;



/**
 获取灯开关

 @param deviceID 设备ID
 @param result 灯状态回调Block
 */
- (void)getLightSwitchStateWithDeviceId:(NSString*)deviceID resultBlock:(BlockCommandReqResult)result;


#pragma mark - NVR 相关
#pragma mark -- 开始获取视频流

/**
 获取 nvr 视频流数据

 @param deviceId 设备 ID
 @param avChannel AV 通道
 @param playViewNum 画面的数量（用于NVR 码流设置，四画面传 4 ——> 设置主码率， 单画面传 1 ——> 设置子码率）
 @param nvrGetVideoDataBlock 结果处理 Block
 */
- (void)nvrStartGetVideoDataWithDeviceId:(NSString*)deviceId
                               avChannel:(long)avChannel
                             playViewNum:(long)playViewNum
                    nvrGetVideoDataBlock:(NvrGetVideoDataBlock)nvrGetVideoDataBlock;



#pragma mark -- 停止获取视频流
/**
 停止 nvr 视频流数据

 @param deviceId 设备 ID
 @param avChannel AV 通道
 @param nvrStopVideoDataBlock 结果处理 Block
 */
- (void)nvrStopGetVideoDataWithDeviceId:(NSString*)deviceId
                              avChannel:(long)avChannel
                  nvrStopVideoDataBlock:(NvrStopVideoDataBlock)nvrStopVideoDataBlock;


#pragma mark -- 删除 NVR 设备
/**
 删除指定的 NVR 设备

 @param nvrDeviceId NVR 设备 ID
 @param avChannelNum 成功创建的 AV 通道数
 @return 是否删除成功, YES:删除成功，NO:删除失败
 */
- (BOOL)nvrDeleteWithDeviceId:(NSString *)nvrDeviceId
                 avChannelNum:(long)avChannelNum;


#pragma mark -- 获取 NVR 录像文件列表
/**
 获取 NVR 录像文件列表
 
 @param nvrDeviceId             设备 ID
 *  @param channelMask          查询的频道（0、1、2、3）
 *  @param date                 查询的日期（2017-03-17）
 *  @param startTime            查询的起始时间（00:00）
 *  @param endTime              查询的结束时间(23:59)
 *  @param recordListBlock      结果回调 Block
 */
- (void)nvrGetVideoListWithDeviceId:(NSString *)nvrDeviceId
                        channelMask:(uint32_t)channelMask
                           typeMask:(uint32_t)typeMask
                               date:(NSString *)date
                          startTime:(NSString *)startTime
                            endTime:(NSString *)endTime
                        resultBlock:(NvrRecordListBlock)recordListBlock;


#pragma mark -- 开启 NVR 录像回放

/**
 开启 NVR 录像回放d
 
 @param nvrDeviceId             设备 ID
 @param filePath                录像文件路径
 @param playCtrlBlock      结果回调 Block
 */
- (void)nvrPBPlayWithDevId:(NSString *)nvrDeviceId
                  filePath:(NSString *)filePath
             playCtrlBlock:(NvrRecordPlayCtrlBlock)playCtrlBlock;


#pragma mark -- NVR 录像回放播放控制
/**
 NVR 录像回放播放控制
 
 @param nvrDeviceId             设备 ID
 @param avChannel               AV 通道
 @param netRecCtrlType          播放控制类型，参见‘kNetRecCtrlType’
 @param seekSecond              用于定点播放时的：秒数，其他操作传0
 */
- (void)nvrRecordPlayCtrlWithDeviceId:(NSString *)nvrDeviceId
                            avChannel:(int)avChannel
                         playCtrlType:(kNetRecCtrlType)netRecCtrlType
                           seekSecond:(long)seekSecond;


/**
 是否连接成功
 */
- (bool)isDeviceConnectedWithUID:(NSString*)uid;


/**
 是否正在连接
 */
//- (bool)isDeviceConnectingWithUID:(NSString*)uid;

/**
 断开所有连接
 */
- (void)stopAllConnect;


@end

//
//
//  iRouterTest
//
//  Created by goscam on 16/8/4.
//  Copyright © 2016年 goscam. All rights reserved.
//

//error code


//error code
//成功
#define IROUTER_NO_ERROR              0

#define IROUTER_USER_NOEXIST           -10099   //账号不存在
#define IROUTER_LOGIN_USERNAME_ERROR   -10100   //用户名错误
#define IROUTER_RECORD_NOT_EXIST       -10106   //查询记录不存在
#define IROUTER_LOGIN_PASSWORD_ERROR   -10110   //登录密码错误

#define IROUTER_CHANGE_PASSWORD_ERROR  -10097  //修改密码失败
#define IROUTER_USER_EXIST             -10030  //账号已存在

#define IROUTER_DEVICE_DUPLICATED      -10091   //设备已经存在(被自己绑定)
#define IROUTER_DEVICE_BIND_ERROR      -10092   //绑定失败
#define IROUTER_DEVICE_UNBIND_ERROR    -10094   //解绑失败
#define IROUTER_DEVICE_NOT_EXIST       -10095   //设备不存在

#define IROUTER_DEVICE_EDIT_ERROR      -10096   //修改名称等属性失败
#define IROUTER_DEVICE_BIND_NOEXIST     -10098    //表示未绑定

#define IROUTER_VERIFY_CODE_ERROR       -80009      //验证码错误
#define IROUTER_VERIFY_CODE_TIMEOUT     -80010      //验证码失效过期
#define IROUTER_VERIFY_CODE_GETCODE_FIRST -80012      //请先获取验证码

#define IROUTER_NETWORK_TIMEOUT         8888    //网络请求超时


#define IROUTER_DEVCIE_NETWORK_ERROR   -300000    //网络连接失败
#define IROUTER_MSG_VERIFY_CODE_ERROR  -300002  //验证码错误
#define IROUTER_REGISTER_ERROR         -300003  //注册账号失败
#define IROUTER_LOGIN_ERROR            -300004  //登录失败

#define IROUTER_DEVICE_GETDEVICE_ERROR -300010   //获取设备列表数据失败
#define IROUTER_DEVICE_INUSE_ERROR     -300014  //设备以及存在(并别人以管理者绑定)

#define IROUTER_DEVICE_BIND_DUPLICATED  -300015    //已被本帐号绑定
#define IROUTER_DEVICE_BIND_INUSE       -300016     //被其他帐号绑定
#define IROUTER_DEVCIE_FIND_ERROR       -300018    //搜索失败



#define IROUTERSVR_DSTPORT	11111
#define IROUTERDEV_DSTPORT	7007
#define MAX_STREAM_COUNT	4


#import <Foundation/Foundation.h>

@interface iDeviceModel : NSObject<NSCopying,NSMutableCopying,NSCoding>
@property(nonatomic,copy)NSString *account;
@property(nonatomic,copy)NSString *password;
@property(nonatomic,copy)NSString *nikeName;
@property(nonatomic,copy)NSString *uid;
@property(nonatomic,copy)NSString *ip;
@property(nonatomic,assign)int port;
@property(nonatomic,copy)NSString *mode;
/**
 *  isConnectState :
 -6 密码错误
 -5 设备不在线
 -4 网络断开
 -3 请求超时
 -2 表示找不到服务器
 -1：表示连接失败
 0：表示连接成功
 1：表示正在连接
 2：表示开始绑定
 */
@property(nonatomic,assign)int ConnectState;
@property(nonatomic,assign)BOOL isOnline;
@property(nonatomic,assign)int pushFlag;//0 开始推送    1结束推送
@property(nonatomic,assign)int sharePermission; //0 是添加 1是分享
@property(nonatomic,assign)int existFlag;// 0:存在 1:不存在

-(void)descriptionPrint;
@end

@interface NTPParamData: NSObject
@property(nonatomic,strong)NSString* NtpOpen;			//ntp校时开关 (open->开;close->关， 默认为开启)
@property(nonatomic,strong)NSString* EuroTime;			//夏令时开关  (open->开;close->关， 默认为关闭)
@property(nonatomic,strong)NSString* NtpRefTime;			//ntp校时间隔 (单位秒, 默认为300s)
@property(nonatomic,strong)NSString* TimeZone;			//时区 (-12~11， 默认为 8)
@property(nonatomic,strong)NSString* NtpServer;          //ntp校时服务器地址
@property(nonatomic,strong)NSString* NtpPort; 			//ntp校时服务器端口
- (id)initWithDictionary:(NSDictionary*)dict;
@end

typedef NS_ENUM(NSUInteger, SDFileOperationType) {
    SDFileOperationTypeCreate,
    SDFileOperationTypeDelete,
};

typedef NS_ENUM(NSUInteger, UpgradeDeviceOpType) {
    UpgradeDeviceOpUpgrade,
    UpgradeDeviceOpCancelUpgrade,
};

typedef enum : NSUInteger {
    OperationResultStateOK,
    OperationResultStateError,
} OperationResultState;

typedef NS_ENUM(NSUInteger, RetrieveFileType) {
    RetrieveFileTypeMp4,
    RetrieveFileTypeJPG,
    RetrieveFileType264,
    RetrieveFileTypeAll
};

typedef NS_ENUM(NSUInteger, RetrieveFileMode) {
    RetrieveFileModeByAll,
    RetrieveFileModeByDay,
    RetrieveFileModeByDuration,
};

typedef NS_ENUM(NSUInteger,RetrieveFileResult){
    RetrieveFileResultOk,
    RetrieveFileResultFailed,
    RetrieveFileResultNone
};

typedef NS_ENUM(NSUInteger, DeviceAtrribute) {
    DeviceAtrributeMotion,          //移动侦测
    DeviceAtrributeVerMir,          //垂直镜像
    DeviceAtrributeHorMir,          //水平镜像
    DeviceAtrributeManualRecord,    //手动录制
    DeviceAtrributePIR              //红外侦测
};

typedef NS_ENUM(NSUInteger, AtrributeStatus) {
    AtrributeStatusOff,
    AtrributeStatusOn,
    AtrributeStatusHigh,
    AtrributeStatusMiddle,
    AtrributeStatusLow
};

typedef NS_ENUM(NSUInteger, VideoQuality) {
    
    VideoQualityNormal,
    VideoQualityHigh,
};

typedef NS_ENUM(NSUInteger, AudioState) {
    AudioStateON,
    AudioStateOFF,
};

typedef NS_ENUM(NSUInteger, OneKeyAlarmState) {
    OneKeyAlarmStateOFF,
    OneKeyAlarmStateON,
};

typedef NS_ENUM(NSUInteger, CommandResult) {
    
    CommandResult_LoginFailed_TryAgain,
    CommandResult_LoginOK,
};

typedef enum
{
    ANC_PTZ_UP=					1,	//云台上
    ANC_PTZ_DOWN=				2,	//云台下
    ANC_PTZ_LEFT=					3,	//云台左
    ANC_PTZ_RIGHT=				4,	//云台右
    ANC_PTZ_FOCUSADD=			5,	//聚焦+
    ANC_PTZ_FOCUSSUB=			6,	//聚焦-
    ANC_PTZ_IRISADD=				7,	//光圈+
    ANC_PTZ_IRISSUB=				8,	//光圈-
    ANC_PTZ_ZOOMADD=			9,	//变倍+
    ANC_PTZ_ZOOMSUB=			10,	//变倍-
    ANC_PTZ_AUTOOPEN=			11,	//自动开
    ANC_PTZ_AUTOCLOSE=			12,	//自动关
    ANC_PTZ_LAMPOPEN=			13,	//灯光开
    ANC_PTZ_LAMPCLOSE=			14,	//灯光关
    ANC_PTZ_BRUSHOPEN=			15,	//雨刮开
    ANC_PTZ_BRUSHCLOSE=			16,	//雨刮关
    ANC_PTZ_WATEROPEN=			17,	//放水开
    ANC_PTZ_WATERCLOSE=			18,	//放水关
    ANC_PTZ_PRESET=				19,	//预置 + 号
    ANC_PTZ_CALL=					20,	//调用 + 号
    ANC_PTZ_STOP=				21,	//停止
    ANC_PTZ_UP_STOP=				30,	//云台上-停
    ANC_PTZ_DOWN_STOP=			31,	//云台下-停
    ANC_PTZ_LEFT_STOP=			32,	//云台左-停
    ANC_PTZ_RIGHT_STOP=			33,	//云台右-停
    ANC_PTZ_FOCUSADD_STOP=		34,	//聚焦+ -停
    ANC_PTZ_FOCUSSUB_STOP=		35,	//聚焦- -停
    ANC_PTZ_IRISADD_STOP=		36,	//光圈+ -停
    ANC_PTZ_IRISSUB_STOP=		37,	//光圈- -停
    ANC_PTZ_ZOOMADD_STOP=		38,	//变倍+ -停
    ANC_PTZ_ZOOMSUB_STOP=		39,	//变倍- -停
    ANC_PTZ_MENU_SET=			40,	//设置
    ANC_PTZ_CENTER=				41,	//置中
    ANC_PTZ_LEFT_RIGHT=			42, // 左右
    ANC_PTZ_LEFT_RIGHT_STOP=		43,	//左右停
    ANC_PTZ_TOP_DOWN=			44, // 上下
    ANC_PTZ_TOP_DOWN_STOP=		45,	//上下停
    ANC_PTZ_ROTATE_VERTICAL=	46,	//垂直
    ANC_PTZ_ROTATE_HORIZONTAL=	47,	//水平
    ANC_PTZ_IRCUT_ON=				48, //红外打开
    ANC_PTZ_IRCUT_OFF=				49	//红外关闭
}ANC_PTZ_ControlType;

typedef NS_ENUM(NSUInteger, iAlarmType) {
    at_unknow = 0,
    at_video_motion,
    at_pir_motion,
    at_pir_video_motion,
    at_audio_motion,
    at_io_alarm,
    at_low_temp_alarm,
    at_high_temp_alarm,
    at_low_hum_alarm,
    at_high_hum_alarm,
    at_low_wbgt_alarm,
    at_high_wbgt_alarm,
    at_calling,
    at_key_long_press,
    at_key_short_press,
    at_wifi_cnnt,
    at_wifi_discnnt,
};

typedef NS_ENUM(NSInteger,ConnectionStatus)
{
    ConnectionStatusDisconnect = -1, //连接失败
    ConnectionStatusConnected = 0,	//连接成功
    ConnectionStatusRunning = 1,   //正在连接
    ConnectionStatusDevNotOnline, //摄像头不在线
    ConnectionStatusRequestTimedout, //请求超时
    ConnectionStatusNetworkError,   //网络断开连接
    ConnectionStatusDeviceOFFLINE,   //服务器找不到设备或者设备不在线
    ConnectionStatusClientPWD,   //创建连接密码错误
    ConnectionStatusDefault
};

typedef void(^BlockState)(int state);
typedef void(^DevcieListBlock)(NSArray *,int error);


typedef void(^OpStateBlock)(int state);
typedef void(^CMDResultBlock)(CommandResult cmdResult);
typedef void(^ProgressBlock)(int state, float progress);
typedef void(^AlarmStateBlock)(int result,OneKeyAlarmState state);
typedef void(^OnlineStatusBlock)(int state, NSString *uid);
typedef void(^NTPParamBlock) (int result,NTPParamData *param);

@interface iDeviceAbilityInfo : NSObject
@property(nonatomic,assign)NSUInteger   DEVICETYPE; //设备类型900中性版101彩益100海尔

@property(nonatomic,assign)NSUInteger  ENCRYPTED_IC;	//是否有加密IC
@property(nonatomic,assign)NSUInteger  PIR; 			//是否有PIR传感器，0:无，1:有，下同
@property(nonatomic,assign)NSUInteger  PTZ; 			//是否有云台
@property(nonatomic,assign)NSUInteger  MIC; 			//是否有咪头
@property(nonatomic,assign)NSUInteger  HORN; 		//是否有喇叭
@property(nonatomic,assign)NSUInteger  SD_CARD;			//是否有SD卡
@property(nonatomic,assign)NSUInteger  TEMP;       //是否有温感探头
@property(nonatomic,assign)NSUInteger  TIMEZONE;		//是否支持同步时区
@property(nonatomic,assign)NSUInteger  NIGHT_VISION;	//是否支持夜视

@property(nonatomic,copy)NSDictionary*   RESOLUTION;	//主、子、第3路码流分辨率大小
@property(nonatomic,copy)NSString*  NETCARD;	//是否带网卡
@property(nonatomic,copy)NSString*  SMART;      //是否支持smart扫描	0代表不支持，1代表7601smart  2代表8188smart
@property(nonatomic,assign)NSUInteger  MOTION;     //是否支持移动侦测

@property(nonatomic,assign)NSUInteger  RECORDDURATION; // 是否有设置录像录像时长
@property(nonatomic,assign)NSUInteger  LIGHTSWITCH; // 是否有设置照明灯开关
@property(nonatomic,assign)NSUInteger  AUDIOALARM; //是否支持声音侦测报警
- (id)initWithDictionary:(NSDictionary*)dict;
@end

@interface iFileModel : NSObject
@property (nonatomic,copy)NSString *fileName;
@property(nonatomic,copy)NSString *fileTime;
@property(nonatomic,copy)NSString *fileSizeName;
@property(nonatomic,copy)NSString *filePath;
@property(nonatomic,copy)NSString *fileSize;
@property(nonatomic,assign)RetrieveFileType fileType;
@property(nonatomic,assign)NSInteger fileDownLoadState;
@end

#define stringFromEnum(x) ([@#x substringFromIndex:8])



/**
 *  获取设备的信息
 *
 *  @param result    result < 0,命令请求或者发送失败,result >=0,命令请求或者发送成功
 *  @param serial_id 设备的UID
 *  @param macaddr   mac地址
 *  @param soft_ver  软件版本
 *  @param firm_ver  硬件版本
 *  @param model_num //设备型号
 *  @param Wifi      设备连接路由器的wifi名称
 */
typedef void(^DeviceInfoResultBlock)(int result,NSString *device_name,NSString *device_id,NSString *macaddr,NSString *soft_ver,NSString *firm_ver);

typedef void (^DeviceAttriResultBlock)(int result,AtrributeStatus motion,AtrributeStatus verMir,AtrributeStatus horMir,AtrributeStatus pir_flag,AtrributeStatus manualRec);

typedef void (^SDCardInfoBlock)(int result, NSString *used, NSString *free);

typedef void (^WifiConfigBlock)(int result, NSString *ssid, NSString *passwd);

typedef void (^RetrieveFileBlock)(int result, NSArray *fileList );

typedef void (^DeviceAbilityBlock)(int result, iDeviceAbilityInfo *deviceAbilitiy);

typedef void (^VideoQualityBlock)(int result, VideoQuality vQuality);

@interface iTempAlarmSetting : NSObject
@property(nonatomic,assign)NSUInteger max_alarm_enable;     //上限温度报警开关
@property(nonatomic,assign)NSUInteger min_alarm_enable;     //下限温度报警开关
@property(nonatomic,assign)NSUInteger temperature_type;     //温度表示类型， 0:表示摄氏温度.C， 1；表示华氏温度.F
@property(nonatomic,assign)float cur_temp_value;       //当前温度
@property(nonatomic,assign)float max_alarm_value;      //上限报警温度
@property(nonatomic,assign)float min_alarm_value;      //下限报警温度
- (id)initWithDictionary:(NSDictionary*)dict;
- (NSDictionary*)dictionaryFromProperties;
@end


//result < 0,命令请求或者发送失败,result >=0,命令请求或者发送成功
typedef  void(^TemperatureAlarmResultBlock)(int result,iTempAlarmSetting *tempAlarmSetting);


@interface iRouterInterface : NSObject

@property(nonatomic,copy)CMDResultBlock cmdResultBlock;

+ (iRouterInterface *)sharedInstance;


- (void)iRouterSetAAAHostParamWithDomain:(NSString*)domain port:(NSString*)port timeout:(NSInteger)time;


-(void)CreateNetworkMode:(NSString *)ip
                 andport:(NSString *)port
               andDomain:(NSString*)domainid
                andblcok:(BlockState)block;



-(int)iRouterCreateAccount:(NSString *)accountname
                   andMail:(NSString *)mail
                  andUsird:(char *)usrid
                   andCode:(char *)pszcode;



-(int)iRouterInputVRFCode:(const char *)usrid
                  andCode:(const char *)vrfcode;



-(int)iRouterCreateAccountPwd:(const char *)usrid
                       andPwd:(NSString*)newpswd;



-(int)iRouterLogin:(NSString *)usrname
            andPwd:(NSString*)pswd;



-(int)iRouterResetPswd:(NSString *)accountname
              andusird:(char *)usrid
               andCode:(char *)pszcode;



-(bool)iRouterLogOut;



-(int)iRouterEditDeviceName:(NSString *)deviceId
                    andName:(NSString *)deviceName;



-(int)iRouterUpdateDeviceName:(NSString *)deviceId
                      andName:(NSString *)deviceName;



-(int)iRouterAddDevice:(NSString *)deviceID
         andDevcieName:( NSString *)deviceNam
          andDevciepwd:(NSString *)devicepwd;



-(int)iRouterChangePwd:(NSString *)newPwd;



-(int) iRouterUnBindDevice:(NSString *)deviceID
                  andShare:(int)allshare;



//allshare 0:跟自己账户解绑 1:解绑其他账户
-(int) iRouterBindDevice:(NSString *)deviceID
                andShare:(int)allshare;



-(int)iRouterFindDeviceState:(NSString *)deviceID
                    andShare:(int)allshare;



-(int) GetDevcieList:(DevcieListBlock)block;



#pragma mark - Command

////ANC_NET_NOTIFY_CONFIGURE_SCRIPT

/**
 以下命令C++端暂未实现
 
 get-wifi-config
 */
- (bool)sendCommandWithDictionary:(NSDictionary*)cmdDict ;

//op-sd-file
- (void)operateSDFileWithOperationType:(SDFileOperationType)fileOperationType isFolder:(bool)isFolder path:(NSString*)path stateBlock:(OpStateBlock)stateBlock;

//upgrade-dev
- (void)upgradeDeviceWithOperationType:(UpgradeDeviceOpType)type url:(NSString*)url stateBlock:(OpStateBlock)stateBlock;

//config-wifi
- (void)configureWifiWithSSID:(NSString*)ssid password:(NSString *)pwd stateBlock:(OpStateBlock)stateBlock;

//get-wifi-config
- (void)getWifiConfigurationWithResultBlock:(WifiConfigBlock)resultBlock;

//format-sd
- (void)formatSDCardWithStateBlock:(OpStateBlock)stateBlock;

//get-sd-info
- (void)getSDCardInfoWithBlock:(SDCardInfoBlock)resultBlock;


//retrieve-file
- (void)retrieveFileByAllWithFileType:(RetrieveFileType)type resultBlock:(RetrieveFileBlock)resultBlock ;

- (void)retrieveFileByDayWithFileType:(RetrieveFileType)type day:(NSString*)day resultBlock:(RetrieveFileBlock)resultBlock ;
//nvr
- (void)retrieveFileByDurationWithFileType:(RetrieveFileType)type
                                 startDate:(NSString*)startDate
                                   endDate:(NSString*)endDate
                                 startTime:(NSString*)startTime
                                   endTime:(NSString*)endTime
                               resultBlock:(RetrieveFileBlock)resultBlock ;

- (bool)downloadFileWithLocalFilePath:(NSString*)localFilePath remoteFilePath:(NSString*)remoteFilePath progressBlock:(ProgressBlock)progressBlock;

- (bool)stopDownloadingFileFromServer;

//set-dev-time
- (void)setDeviceTimeWithDate:(NSString*)date time:(NSString*)time stateBlock:(OpStateBlock)stateBlock;

//set-basic-attr
- (void)setDeviceAtrributeWithAttribute:(DeviceAtrribute)attribute status:(AtrributeStatus )status stateBlock:(OpStateBlock)stateBlock;

//get-basic-attr
- (void)getDeviceAttributeWithResultBlock:(DeviceAttriResultBlock)resultBlock;

//get-dev-info
- (void)getDeviceInfoWithResultBlock:(DeviceInfoResultBlock)resultBlock;

//ptz
- (bool)sendPTZCommandWithType:(NSString*)type stateBlock:(OpStateBlock)stateBlock;

//get-temp-alarm
- (void)getTemperatureAlarmWithBlock:(TemperatureAlarmResultBlock)resultBlock;

//set-temp-alarm
- (void)setTemperatureAlarmWithSetting:(iTempAlarmSetting*)tempAlarmSetting stateBlock:(OpStateBlock)stateBlock;

//get-dev-ability
- (void)getDeviceAbilityInfoWithResultBlock:(DeviceAbilityBlock)resultBlock;

//get-dev-quality
- (void)getVideoQualityWithResultBlock:(VideoQualityBlock)resultBlock;

//set-dev-quality
- (void)setVideoQualityWithValue:(VideoQuality)quality stateBlock:(OpStateBlock)stateBlock;

- (void)setAudioStateWithState:(AudioState)state returningBlock:(OpStateBlock)block;

//set-get-onekey-alarm
- (void)setOneKeyAlarmStateWithState:(OneKeyAlarmState)alarmState returningBlock:(OpStateBlock)block;

- (void)getOneKeyAlarmStateWithResultBlock:(AlarmStateBlock)block;

- (void)getNTPParamWithResultBlock:(NTPParamBlock)block;

- (void)setNTPParamWithParam:(NTPParamData*)param stateBlock:(OpStateBlock)stateBlock;

- (void)anc_registerPushNotificationWithToken:(NSString*)token stateBlock:(OpStateBlock)stateBlock;

- (void)anc_unregisterPushNotificationWithToken:(NSString*)token stateBlock:(OpStateBlock)stateBlock;

- (bool)ancQueryDeviceOnlineStatusWithDeviceModel:(iDeviceModel*)model resultBlock:(OnlineStatusBlock) block;

//ANC_CMD_ALARM_RISE
+ (NSString*)alarmTypeStringFromAlarmTypeEnum:(iAlarmType)type ;

#pragma mark - Stream
typedef struct _ancframeheader
{
    unsigned int nStreamType; // VIDEO, AUDIO, DATA
    unsigned int nFrameType; // I-FRAME, P-FRAME, etc.
    
    unsigned int  nFrameRate;	//帧率
    unsigned long long   nTimeStamp;
    
    unsigned int nFrameLength; //数据长度.
    
    unsigned int  nWidth;  //图象宽度
    unsigned int  nHeight; //图象高度
    unsigned int nSequence; //序列号
    // 音频才有的数据
    unsigned int nChannels;
    unsigned int nBitsPerSample;
    unsigned int nSamplesPerSecond;
    
}AncFrameHeader;


typedef int (*StreamCallback)(AncFrameHeader *header,unsigned char* pdata,int datalen);

- (void) anc_client_init;
- (void) anc_client_uninit;

- (bool) anc_client_loginByServer:(bool)byServer ip:(const char*)ip port:(int)port deviceID:(const char *)deviceID userName:(const char *)userName password:(const char *)password;

- (void) anc_client_logout;
- (bool) anc_client_playVideoWithDeviceId:(const char *)deviceId deviceName:(const char *)deviceName callBack:(StreamCallback) streamCallback;
- (void) anc_client_stopVideoWithDeviceId:(const char*) deviceId;

- (bool) anc_client_talkStartWithDeviceId:(const char*)deviceId deviceName:(const char*)deviceName;

- (bool) anc_client_talkSpeakWithData:(const char*)speekData length:(int)length;
- (bool) anc_client_talkStop;
@end

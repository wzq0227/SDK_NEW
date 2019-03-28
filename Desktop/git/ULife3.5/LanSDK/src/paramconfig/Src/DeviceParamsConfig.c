#include "DeviceParamsConfig.h"
#include "Tlib_Cmddefine.h"
#include "Tlib_ProtocolAX.h"
#include "QuickSocket.h"
#include "DebugPrint.h"

#include <string.h>
#include <stdio.h>
#include <stdlib.h>

enum ESDEventType{
	sd_query_list_of_day_has_video = 0, //获取包含视频列表的天
	sd_query_day_eventlist ,		//获取某天事件列表
	sd_download_vedio,				//下载音视频
	sd_stop_download_vedio,			//中止下载音视频
	sd_get_image_color,				//获取图像颜色
	sd_set_image_color,				//设置图像颜色
	sd_get_resolution,				//获取分辨率，码率，帧率
	sd_set_resolution,				//设置分辨率，码率，帧率
	sd_query_wifi,					//查询wifi
	sd_set_wifi,					//设置wifi
	sd_get_worken,					//工作环境
	sd_set_worken,					//工作环境
	sd_query_daylogs,				//查询某天的日志
	sd_set_default_color,			//设置默认图像颜色
	sd_get_rtsp_audio_switch,		//获取rtsp音频开关
	sd_set_rtsp_audio_switch,		//设置rtsp音频开关
	sd_get_noise_lvl,				//获取降噪等级
	sd_set_noise_lvl,				//设置降噪等级
	ptz_left,		//左
	ptz_right,		//右
	ptz_up,			//上
	ptz_down,		//下
	ptz_zoon_in,	//放大
	ptz_zoon_out,	//缩小
	ptz_h_scan, //水平扫描
	ptz_v_scan, //垂直扫描
	ptz_auto_sacn, //自动扫描
	ptz_stop_scan, //停止扫描
	ptz_mirror, //镜像
	ptz_flip, //翻转
	ptz_keep_left, //连续左
	ptz_keep_right, //连续右
	ptz_keep_up, //连续上
	ptz_keep_down, //连续下
	set_ap_info,	//设置AP模式ssid,psw
	get_cur_temp_hum,
	enable_motion,
	reset_factory,
	trans_cmd,
	set_song,
	play_or_stop_song,
	start_speak,
	send_speak_data,
	stop_speak,
	get_device_attr,
	set_surveillance,
	delete_file,
	set_pwm3,
	get_pwm3,
	ack_sys_req_record,
	ack_sys_req_shutdown,
	sys_req_led,
	set_wifi_new,
	sd_event_count,
};

enum ETransmitRlt{
	TRANSMIT_OK = 0,
	QUERY_DAY_EVENT_ERROR,
	STOP_DOWNLOAD_AVEDIO_ERROR,
	GET_RESOLUTION_ERROR,
	SET_RESOLUTION_ERROR,
	GET_IMAGE_COLOR_ERROR,
	SET_IMAGE_COLOR_ERROR,
	GET_WIFI_ERROR,
	SET_WIFI_ERROR,
	SET_DEFAULT_COLOR_ERR,
	SET_NOISE_LVL_ERR,
	SET_RTSP_AUDIO_SWITCH_ERR,
};

#define NOT_CURRENT_CMD_TYPE		-1000
#define MAX_RECV_LEN						8192

char cmdPtzLeft[]												= "1"; //左
char cmdPtzRight[]											= "2"; //右
char cmdPtzUp[]												= "3"; //上
char cmdPtzDown[]											= "4"; //下
char cmdPtzZoonin[]										= "5"; //放大
char cmdPtzZoonOut[]										= "6"; //缩小
char cmdPtzHscan[]											= "7"; //水平扫描
char cmdPtzVscan[]											= "8"; //垂直扫描
char cmdPtzAutoScan[]									= "9"; //自动扫描
char cmdPtzStopScan[]									= "10"; //停止扫描
////////////////////////////////////////////////////
char cmdPtzXStep[]											= "11"; //设置水平方向的步进
char cmdPtzYStep[]											= "12"; //设置垂直方向的步进
char cmdPtzReset[]											= "13"; //复位
char cmdPtzXYPos[]											= "14"; //X、Y位置坐标值
//////////////////////////////////////////////////////////////////////////
char cmdPtzMirror[]											= "15"; //镜像
char cmdPtzFlip[]												= "16"; //翻转
////////////////////////////////////////////////////
char cmdPtzFocusIn[]										= "17"; //聚焦加
char cmdPtzFocusOut[]									= "18"; //聚焦减  
char cmdPtzApertureIn[]									= "19"; //光圈加
char cmdPtzApertureOut[]								= "20"; //光圈减
char cmdPtzSetPrest[]										= "21"; //云台预置位设置 0xa1~0xa8
char cmdPtzCallPrest[]										= "22"; //云台预置位调用 0xb1~0xb8
char cmdPtzAgingTest[]									= "23"; //云台老化测试 
//////////////////////////////////////////////////////////////////////////
char cmdPtzKeepLeft[]										= "24"; //连续左
char cmdPtzKeepRight[]									= "25"; //连续右
char cmdPtzKeepUp[]										= "26"; //连续上
char cmdPtzKeepDown[]									= "27"; //连续下
////////////////////////////////////////////////////
char cmdAlertGetState[]									= "100"; //
char cmdAlertSet[]											= "101"; //
char cmdAvqGetState[]									= "102"; //
char cmdAvqSet[]												= "103"; //
//////////////////////////////////////////////////////////////////////////
char cmdQueryDayLog[]									= "200";	//查询日志
char cmdQueryDayLogACK[]							= "201";	//查询日志 ACK
////////////////////////////////////////////////////
char cmdRtcTest[]												= "2004"; //RTC时钟测试，用于产测工具测试，同步本地时间
char cmdRtcTestAck[]										= "2005"; //
char cmdWriteId[]												= "2008"; // 烧写ID(用于生产烧写id号)
char cmdWriteIdAck[]										= "2009"; //
char cmdWriteMac[]											= "2010"; // 烧写有线MAC(用于生产烧写mac地址)
char cmdWriteMacAck[]									= "2011"; 
char cmdForceNightVision[]								= "2012"; //用于产测工具测试夜视，Night 必有属性，0:表示自动切换 1:表示手动强制打开夜视，2表示强制启动白天
char cmdForceNightVisionAck[]						= "2013"; //
char cmdGetAdc[]											= "2014"; // 开始获取光敏电阻的值
char cmdGetAdcAck[]										= "2015"; //
char cmdStopGetAdc[]										= "2018"; //停止获取光敏电阻的值	
char cmdStopGetAdcAck[]								= "2019"; 
char cmdWriteWirelessMac[]							= "2016"; // 烧写无线MAC(用于生产烧写mac地址)
char cmdWriteWirelessMacAck[]						= "2017"; //
char cmdWifiThroughputReq[]							= "2020"; //WIFI吞吐量测试
char cmdWifiThroughputAck[]							= "2021"; //

char cmdProtocolIntercomData[]						= "3000"; //发送音频数据
char cmdProtocolIntercomDataAck[]				= "2997"; //发送音频数据的命令回复
char cmdStopIntercomReq[]								= "2998"; // 停止音频对讲，返回ret的值为1表示成功，为0表示失败
char cmdStopIntercomAck[]								= "2999"; //停止音频对讲的回复
char cmdProtocolIntercom[]								= "3001"; //开启音频
char cmdProtocolReplyIntercom[]						= "3002"; //开启音频应答
char cmdProtocolPlayYelp[]								= "3003"; //播放当前警铃，播放当前摇篮曲
char cmdProtocolReplyPlayYelp[]						= "3004"; //播放当前警铃，播放当前摇篮曲ACK
char cmdDefaultYelpReq[]								= "3005"; //设置警铃,设置摇篮曲
char cmdDefaultYelpAck[]								= "3006"; //
char cmdStopYelp[]											= "3007"; //停止播放当前摇篮曲
char cmdStopYelpAck[]									= "3008";
char cmdGetHisTempHum[]								= "3200"; //获取历史温度
char cmdGetHisTempHumAck[]						= "3201"; //
//////////////////////////////////////////////////////////////////////////
char cmdGetCurTemp[]									= "3202"; //获取实时温度
char cmdGetCurTempAck[]								= "3203"; //获取实时温度ACK
////////////////////////////////////////////////////

/**
*强行设置密码，需要提示客户一直按住合路器的对码键，POELOCKPWD:字符串型 ，必有属性,四位纯数字密码，如1234
*/
char cmdPoelockSetPwdReq[]							= "3204";

/**
* Ret：字符型，必有属性。1：表示成功，0表示失败。 ErrorInfo：字符串型，可选属性。如果Ret属性值为0，那么此属性指出错误
* communicationError表示合路器故障，holdError表示对码键未按住
*/
char cmdPoelockSetPwdAck[]							= "3205"; //

/**
* 修改开锁密码，需要给出旧密码和新密码，POELOCKPWD1:字符串型 ，必有属性,旧密码。POELOCKPWD2:字符串型 ，必有属性,新密码。
*/
char cmdPoelockResetPwdReq[]						= "3206"; 

/**
* Ret：字符型，必有属性。1：表示成功，0表示失败。 ErrorInfo：字符串型，可选属性。如果Ret属性值为0，那么此属性指出错误
* communicationError表示合路器故障，PWDError表示密码不匹配
*/
char cmdPoelockResetPwdAck[]						= "3207";
char cmdPoelockUnlockingReq[]						= "3208"; //开锁，POELOCKPWD:字符串型 ，必有属性，客户自己设置的4位密码

/**
* Ret：字符型，必有属性。1：表示成功，0表示失败。 ErrorInfo：字符串型，可选属性。如果Ret属性值为0，那么此属性指出错误
* communicationError表示合路器故障，PWDError表示密码校验失败
*/
char cmdPoelockUnlockingAck[]						= "3209";

char cmdGetAudioEncType[]								= "3982"; //查询audio编码格式
char cmdGetAudioEncTypeAck[]						= "3983"; //查询audio格式返回
char cmdSetAudioEncType[]								= "3984"; //设置audio格式
char cmdSetAudioEncTypeAck[]						= "3985"; //设置audio格式返回
//////////////////////////////////////////////////////////////////////////
char cmdSetRtspAudioSwitch[]							= "4004";	//设置rtsp音频开关
char cmdSetRtspAudioSwitchACK[]					= "4005";	//设置rtsp音频开关ACK
char cmdSetNoiseLvl[]										= "4006";	//设置低噪度降噪等级
char cmdSetNoiseLvlACK[]								= "4007";	//设置低噪度降噪等级ACK
char cmdGetRtspAudioSwitch[]						= "4008";	//获取rtsp音频开关
char cmdGetRtspAudioSwitchACK[]					= "4009";	//获取rtsp音频开关ACK
char cmdGetNoiseLvl[]										= "4010";	//获取低噪度降噪等级
char cmdGetNoiseLvlACK[]								= "4011";	//获取低噪度降噪等级ACK
char cmdSetDefaultColor[]								= "4012";	//恢复默认图像颜色
char cmdSetDefaultColorACK[]							= "4013";	//恢复默认图像颜色ACK
////////////////////////////////////////////////////
char cmdTimeZoneReq[]									= "4014"; //设置时区
char cmdTimeZoneAck[]									= "4015"; //
char cmdGetDeviceInfo[]									= "4016"; //获取设备信息
char cmdGetDeviceInfoAck[]							= "4017"; //获取设备信息
char cmdVideoRecordManual[]							= "4018"; //通过客户端手动录像 开始：Record=Start,停止：Record=Stop

/**
* Ret：字符型，必有属性。1：表示成功，0表示失败。 ErrorInfo：字符串型，可选属性。如果Ret属性值为0，那么此属性指出错误
* Record=Start 开始，Record=Stop停止
*/
char cmdVideoRecordManualAck[]					= "4019"; 

char cmdMediaFormat[]									= "4022"; // 格式化设备端TF卡，客户端得给客户二次提醒// Format=on,Format=off

/**
* Ret：字符型，必有属性。1：表示成功，0表示失败。
*ErrorInfo：字符串型，可选属性。如果Ret属性值为0，那么此属性指出错误
*/
char cmdMediaFormatAck[]								= "4023";

/**
* 对文件解锁// Lock=true,Lock=false，单个：FileName:如0ab20140603113223120.mp4 加锁或解锁
*/
char cmdMediaLock[]										= "4024";

/**
* Ret：字符型，必有属性。1：表示成功，0表示失败。
*ErrorInfo：字符串型，可选属性。如果Ret属性值为0，那么此属性指出错误
*/
char cmdMediaLockAck[]									= "4025";

/**
* 对文件删除// FileName= 0ab20140603113223120.mp4 (文件名字就删除这个文件、目录名字就删除这个目录)
*/
char cmdMediaDeleteReq[]								= "4026";

/**
* Ret：字符型，必有属性。1：表示成功，0表示失败。
*ErrorInfo：字符串型，可选属性。如果Ret属性值为0，那么此属性指出错误
*/
char cmdMediaDeleteAck[]								= "4027";
//////////////////////////////////////////////////////////////////////////
char cmdGetMonthEventList[]							= "4028"; //获取所有有录像的天的目录
char cmdGetMonthEventListAck[]					= "4029"; //ACK
char cmdGetDayEventList[]								= "4030";	//获取某天事件列表,比如录像事件,
char cmdGetDayEventListACK[]						= "4031";	//获取某天事件列表,比如录像事件, ACK
char cmdDownloadEvent[]								= "4032";	//下载音视频命令
char cmdDownloadEventACK[]							= "4033";	//下载音视频命令 ACK
char cmdStopDownloadEvent[]							= "4034";	//中止下载音视频命令
char cmdStopDownloadEventACK[]					= "4035";	//中止下载音视频命令 ACK

////////////////////////////////////////////////////
char cmdMediaSpace[]										= "4036"; //查看TF卡容量，首先判断有无SD卡

/**
**  TotalSize :总的空间大小。 FreeSize  :剩余空间大小   UsedSize :已用空间大小 Ret: 0 表示无SD卡   1 表示有SD卡，返回容量信息
**/
char cmdMediaSpaceAck[]								= "4037";
char cmdGetSchedules[]									= "4047"; // 获取计划录像信息，包含是否有卡，录像时长及8个录像计划

/**
* Ret：字符型，必有属性。1：表示成功，0表示失败。
*ErrorInfo：字符串型，可选属性。如果Ret属性值为0，那么此属性指出错误
*SCHEDULES:字符串型，如0@300@0@0@0@0@0@0@0@0@0@0@0@0@0@0@0@0@0@0@0@0@0@0@0@0@0@0@0@0@0@0@0@0@0@0@0@0@0@0@0@0@0@0@0@0@0@0@0@0
*/
char cmdGetSchedulesAck[]								= "4048";

/**
* 设置计划录像信息，包含录像时长及8个录像计划
*SCHEDULES:字符串型，如0@300@0@0@0@0@0@0@0@0@0@0@0@0@0@0@0@0@0@0@0@0@0@0@0@0@0@0@0@0@0@0@0@0@0@0@0@0@0@0@0@0@0@0@0@0@0@0@0@0
*/
char cmdSetSchedule[]										= "4049";

/**
* Ret：字符型，必有属性。1：表示成功，0表示失败。
*ErrorInfo：字符串型，可选属性。如果Ret属性值为0，那么此属性指出错误
*/
char cmdSetScheduleAck[]								= "4050";
char cmdCliToDeviceUploadReq[]						= "4051";
char cmdCliToDeviceUploadAck[]						= "4052";
char cmdCliToDeviceUploadDataReq[]				= "4053";
char cmdCliToDeviceUploadDataAck[]				= "4054";
char cmdAllSafetyReq[]										= "4055"; //一键设防 AllSafety: 字符串型，必有属性。1 开启，0 关闭
char cmdAllSafetyAck[]										= "4056";
char cmdLoopVideoReq[]									= "4057"; //循环录像，  LoopVideo:字符串型，必有属性 。1 开启，0 关闭
char cmdLoopVideoAck[]									= "4058"; //
char cmdRecordDurationReq[]							= "4059"; //录像时长，  Duration:字符串型 ，必有属性。例如20   	单位为秒
char cmdRecordDurationAck[]							= "4060";
char cmdChangeDeviceName[]							= "4061"; //更改摄像头名称
char cmdChangeDeviceNameAck[]					= "4062"; 
char cmdWdrReq[]											= "4063"; //强光照射型，  WDR:字符串型，必有属性 。1 开启，0 关闭
char cmdWdrAck[]											= "4064"; //
char cmdTimeReq[]											= "4069"; //  时间设定，  Time:字符串型，必有属性。如Date:20150507表示2015年05月07日 Time:162525,表示16时25分25秒
char cmdTimeAck[]											= "4070"; 
char cmdNoiseReq[]											= "4085"; //噪声侦测，  Noise 字符串型，必有属性。1 开启，0 关闭
char cmdNoiseAck[]											= "4086";
char cmdNightVision[]										= "4089"; //夜视开关，  Night 字符串型，必有属性。1 开启，0 关闭
char cmdNightVisionAck[]								= "4090"; //
char cmdAudioState[]										= "4091"; //音乐播放状态，  Night 字符串型，必有属性。1 开启，0 关闭
char cmdAudioStateAck[]									= "4092"; //
//////////////////////////////////////////////////////////////////////////
char cmdEnableMotion[]									= "4087"; //开启关闭移动侦测
char cmdEnableMotionAck[]								= "4088"; //开启关闭移动侦测ack

char cmdGetImageColor[]									= "5000";	//获取图像颜色
char cmdGetImageColorACK[]							= "5001";	//获取图像颜色 ACK
char cmdSetImageColor[]									= "5002";	//设置图像颜色
char cmdSetImageColorACK[]							= "5003";	//设置图像颜色 ACK
char cmdGetResolution[]									= "5004";	//获取分辨率
char cmdGetResolutionACK[]							= "5005";	//获取分辨率 ACK
char cmdSetResolution[]									= "5006";	//设置分辨率
char cmdSetResolutionACK[]							= "5007";	//设置分辨率 ACK
char cmdGetWifiList[]										= "5008";	//获取wifi列表
char cmdGetWifiListACK[]									= "5009";	//获取wifi列表 ACK
char cmdSetWifi[]												= "5010";	//设置wifi
char cmdSetWifiACK[]										= "5011";	//设置wifi ACK
char cmdGetWorkEn[]										= "5012";	//设置工作环境
char cmdGetWorkEnACK[]								= "5013";	//设置工作环境 ACK
char cmdSetWorkEn[]										= "5014";	//设置工作环境
char cmdSetWorkEnACK[]								= "5015";	//设置工作环境 ACK
////////////////////////////////////////////////////
char cmdSnapShotReq[]									= "5016"; //
char cmdSnapShotAck[]									= "5017"; //
char cmdTransmisionReq[]								= "5018"; //
char cmdTransmisionAck[]								= "5019"; //
char cmdTransmisionBackAck[]							= "5020"; //
char cmdAbilityReq[]											= "5021"; //获取能力集
char cmdAbilityAck[]											= "5022"; //能力集1回复命令
char cmdAbility2Ack[]										= "5028"; //能力集2回复命令
char cmdUpgradeServerAddressChange[]			= "5023"; //
char cmdUpgradeServerAddressChangeAck[]	= "5024"; //
char cmdPirAlarm[]											= "5027"; //pir报警
char cmdSetLightReq[]										= "5029"; //打开关闭照明灯请求
char cmdSetLightAck[]										= "5030"; //
char cmdSetDnsName[]									= "5040"; 
char cmdSetDnsNameAck[]								= "5041";
char cmdGetDnsName[]									= "5042";
char cmdGetDnsNameAck[]								= "5043";
//////////////////////////////////////////////////////////////////////////
char cmdResetFactory[]									= "5045"; //回复出厂设置
char cmdResetFactoryAck[]								= "5046"; //回复出厂设置ACK
char cmdSetApInfo[]										= "5047";	//设置ap模式SSID,密码
char cmdSetApInfoAck[]									= "5048";	//设置ap模式SSID,密码ACK
char cmdSetSurveillance[]									= "5049"; //设置相关侦测参数
char cmdSetSurveillanceACK[]							= "5050"; //
//5052, 推送，设备端主动发送给client
char cmdEnablePush[]										= "5053"; //开启推送
char cmdEanblePushAck[]									= "5054";
char cmdSetPwm3[]											= "5057"; //set pwm3
char cmdSetPwm3Ack[]									= "5058"; //set pwm3 ack
char cmdGetPwm3[]											= "5059"; //get pwm3
char cmdGetPwm3Ack[]									= "5060"; //get pwm3 ack
//by liwo
char cmdTakePhoto[]										= "5061";  //take photo
char cmdTakePhotoAck[]									= "5062";  //take photo ack
//////////////////////////////////////////////////////////////////////////

char cmdSysReqRecord[]									= "5063"; //请求拍照或者录像,设备端->app, 在音视频流中接收
char cmdSysReqRecordAck[]							= "5064"; //ACK
char cmdSysReqShutdown[]								= "5065"; //请求关机 ,设备端->app, 在音视频中接收
char cmdSysReqShutdownAck[]						= "5066"; //
char cmdSysReqLed[]										= "5067"; //请求闪灯
char cmdSysReqLedAck[]									= "5068"; //ACK

char cmdSetWifiNew[]										= "5069"; //SSetWifiInfo
char cmdSetWifiNewAck[]								= "5070"; //

static int FindSubstringCounts(char* src,char* sub,int *subcounts, int *maxlenbetweensub);
static int FindWifiCounts(char* pContext);
static int ParseWifiInfo(SPCtrlData* pspctrldata,char* pContext);

static int ConnectDevice(SPCtrlData* pspctrldata,const char* ipaddr,int port);
static int DisconnectDevice(SPCtrlData* pspctrldata);

static int SendCmd(SPCtrlData* pspctrldata,TlibFieldAx *ptlibfield,int dwCmdDest);
static int RecvDataAndProcess(SPCtrlData* pspctrldata,int dwDataType);

static int DoDealWithACK(SPCtrlData* pspctrldata);
static int DoDealWithReq(SPCtrlData* pspctrldata,int reqCmd,int type,const char * addParam);

static int ControlParams(SPCtrlData* pspctrldata,int cmd,void* param,int paramlen);
static int SetErrInfo(SPCtrlData* pspctrldata,char* perrinfo);
static int SetDayEventList(SPCtrlData* pspctrldata,char* daylist);
static int SetDayLogs(SPCtrlData* pspctrldata,char* daylog);
static void ClearWifiList(SPCtrlData* pspctrldata);
static void ClearAVResolution(SPCtrlData* pspctrldata);

int Ptz(SPCtrlData* pspctrldata,int cmd);
char* FindListofDayHasVideo(SPCtrlData* pspctrldata, const char * strTime);
char* FindSdVedioList(SPCtrlData* pspctrldata, const char * strTime);
void SetDownloadSavePath(SPCtrlData* pspctrldata, const char* strPath );
int StartDownLoadSdVedio(SPCtrlData* pspctrldata,const char * strFilePath);
int StopDownLoadSdVedio(SPCtrlData* pspctrldata,const char * strFilePath);
int QueryImageColor(SPCtrlData* pspctrldata);
void GetImageColor(SPCtrlData* pspctrldata,int *brightness,int *contrast, int *saturation,int *hue);
int SetImageColor(SPCtrlData* pspctrldata, int brightness,int contrast, int saturation,int hue );
int QueryResolution(SPCtrlData* pspctrldata );
int SetResolution(SPCtrlData* pspctrldata);
int QueryWorkEnvironment(SPCtrlData* pspctrldata);
int SetWorkEnvironment( SPCtrlData* pspctrldata,int nType );
int QueryRtspSwitchStatus(SPCtrlData* pspctrldata);
int SetRtspSwicthStatus(SPCtrlData* pspctrldata, int bOn );
int QueryNoiseLvl(SPCtrlData* pspctrldata);
int SetNoiseLvl(SPCtrlData* pspctrldata, int noiseLvl );
int QueryDayLog( SPCtrlData* pspctrldata,const char * strTime );
int QueryWifiList( SPCtrlData* pspctrldata);
int SetWifiInfo( SPCtrlData* pspctrldata,WifiInfoN *wifiInfo );
int SetApInfo( SPCtrlData* pspctrldata,WifiInfoN *wifiInfo );
int GetCurTempHum(SPCtrlData* pspctrldata);
int EnableMotion(SPCtrlData* pspctrldata,SSwitchMotion *motion);
int ResetFactory(SPCtrlData* pspctrldata);
int TransparentCmd(SPCtrlData* pspctrldata,const char *cmd);
int FindCurHumTemp(SCurTempHum* curHum,char *curTempStr);
int FindCount(char *pSrc,char* pFind);
int ParseDayEventList(SSdcardRecQuery *query,char *pSrc,int bDay);
int SetCurrentSong(SPCtrlData* pspctrldata,SAlarmRing* pRing);
int PlayOrStopOneSong(SPCtrlData* pspctrldata,int play);
int StartSpeak(SPCtrlData* pspctrldata);
int SendSpeakData(SPCtrlData* pspctrldata,SSpeakData *data);
int StopSpeak(SPCtrlData* pspctrldata);
int GetDeviceAttr(SPCtrlData* pspctrldata);
int SetSurveillance(SPCtrlData* pspctrldata,SSurveillance* pSur);
int DoVerifyDevice(SPCtrlData* pspctrldata );
int GetDownProcess(SPCtrlData* pspctrldata ,SDownProcess* sdproc);
int DeleteFile(SPCtrlData* pspctrldata , char* filename);
int ParseWifiInfoNew(SPCtrlData* pspctrldata,char* pContext);
int SetPwm3(SPCtrlData* pspctrldata , SPwm3 *pwm);
int GetPwm3(SPCtrlData* pspctrldata);
int AckSysReqRecord(SPCtrlData* pspctrldata,SysReqCmdAck *pAck);
int AckSysReqShutdown(SPCtrlData* pspctrldata,SysReqCmdAck *pAck);
int SysReqCmdLed(SPCtrlData* pspctrldata, SysReqCmd *pCmd);
//by liwo
int TakePhoto(SPCtrlData* pspctrldata, int cmd);
int SetTime(SPCtrlData* pspctrldata, SetTime_S* pTime);
int __ReconnectDev(SPCtrlData* pspctrldata);
/////////////////////////////////////////////////////////////////////////
void FISET_TEST(SPCtrlData* pspctrldata)
{
	const char* ptest = "30@TP-LINK_Donyj@63@lll@57@fuxf@45@5818Y@45@abc518@53@"
		"ChinaNet-Code@69@txh@49@@45@yezhong@37@ChinaNet-QijD@35@XunmeiFactory@29@GD8713A@44@@45@DaSheng@69@qaz@47@guoys123@36@TP-LINK_E56D94@42@360免费WiFi-C9@46@TP-LINK_57D3@58@Batman@46@bazi@45@guming@51@yao@@45@Hi-Spider@53@Xiaomi_xzl@51@  小米共享WiFi_CB36@55@ACC_@_1@63@@39@GosNVR_GTF@57@MERCURY_FEF616_ZL@44";
	int wificount = FindWifiCounts(ptest);
	ClearWifiList(pspctrldata);
	pspctrldata->wificount = wificount;
	ParseWifiInfoNew(pspctrldata,ptest);

}
SPCtrlData* PCTRL_Create(const char* ipaddr,int port)
{
	SPCtrlData* pctrldata = (SPCtrlData*)malloc(sizeof(SPCtrlData));
	if (pctrldata == NULL)
	{
		return NULL;
	}
	memset(pctrldata,0,sizeof(SPCtrlData));
	pctrldata->nSockTrans	= -1;
	pctrldata->pAcks = (char*)malloc(MAX_RECV_LEN);
	pctrldata->m_curTemp = (SCurTempHum*)malloc(sizeof(SCurTempHum));
	pctrldata->m_devAtrr = (SDevAttr*)malloc(sizeof(SDevAttr));
	pctrldata->m_SdcardRecQuery = (SSdcardRecQuery*)malloc(sizeof(SSdcardRecQuery));
#ifndef WIN32
	pthread_mutex_init(&pctrldata->m_mutex,NULL);
#endif
	//FISET_TEST(pctrldata);
	if(ConnectDevice(pctrldata,ipaddr,port) != 0)
	{
		PCTRL_Destroy(pctrldata);
		return NULL;
	}

	return pctrldata;
}

void PCTRL_Destroy(SPCtrlData* pspctrldata)
{
	if(pspctrldata)
	{
		DisconnectDevice(pspctrldata);

		ClearAVResolution(pspctrldata);
		ClearWifiList(pspctrldata);
		if(pspctrldata->pAcks)
		{
			free(pspctrldata->pAcks);
			pspctrldata->pAcks = NULL;
		}
		if (pspctrldata->m_curTemp)
		{
			free(pspctrldata->m_curTemp);
			pspctrldata->m_curTemp = NULL;
		}
		if (pspctrldata->m_devAtrr)
		{
			free(pspctrldata->m_devAtrr);
			pspctrldata->m_devAtrr = NULL;
		}
		if (pspctrldata->m_SdcardRecQuery)
		{
			free(pspctrldata->m_SdcardRecQuery);
			pspctrldata->m_SdcardRecQuery = NULL;
		}
#ifndef WIN32
		pthread_mutex_destroy(&pspctrldata->m_mutex);
#endif

		free(pspctrldata);
	}
}

int PCTRL_CtrlParam(SPCtrlData* pspctrldata,int cmd,void* param,int paramlen)
{
	if (pspctrldata)
	{
		int rlt = -1;
#ifndef WIN32
// 		pthread_mutex_lock(&pspctrldata->m_mutex);
		rlt = ControlParams(pspctrldata,cmd,param,paramlen);
// 		pthread_mutex_unlock(&pspctrldata->m_mutex);
#else
		rlt = ControlParams(pspctrldata,cmd,param,paramlen);
#endif
		return rlt;
	}
	return -1;
}

char* PCTRL_GetErrorInfo(SPCtrlData* pspctrldata)
{
	if(pspctrldata)
		return pspctrldata->strErrorInfo;
	else
		return NULL;
}

///////////////////////////////////////////////////////////////
int ConnectDevice(SPCtrlData* pspctrldata,const char* ipaddr,int port)
{
	if(pspctrldata)
	{
		memset(pspctrldata->ipaddr,0,sizeof(pspctrldata->ipaddr));
		memcpy(pspctrldata->ipaddr,ipaddr,strlen(ipaddr));
		pspctrldata->port = port;
		pspctrldata->nSockTrans = QuickConnectToTCP(port,ipaddr,5000);
		if(pspctrldata->nSockTrans == -1)
			return -1;
		//DoVerifyDevice(pspctrldata);
		return 0;
	}
	return -1;
}

int DisconnectDevice(SPCtrlData* pspctrldata)
{
	if(pspctrldata)
	{
		StopSocket(pspctrldata->nSockTrans);
		pspctrldata->nSockTrans = -1;
	}
	return 0;
}

int __ReconnectDev(SPCtrlData* pspctrldata)
{
	if(pspctrldata->nSockTrans == -1)
	{
		char pIp[64] = {0};
		int port = pspctrldata->port;
		int len = strlen(pspctrldata->ipaddr);
		len = len > sizeof(pIp) ? sizeof(pIp) : len;
		strncpy(pIp,pspctrldata->ipaddr,len);
		if(ConnectDevice(pspctrldata,pIp,port) != 0)
		{
			SetErrInfo(pspctrldata, "connect to remote failed\n");
			return -1;
		}
	}

	return 0;
}

int FindSubstringCounts(char* src,char* sub,int *subcounts, int *maxlenbetweensub)
{
	int len = 0;
	int count = 0;
	char* pfind = NULL;
	char* ptempsrc = src;

	if(src == NULL || sub == NULL || maxlenbetweensub == NULL)
		return -1;

	do 
	{
		pfind = strstr(ptempsrc,sub);
		if(pfind == NULL)
		{
			len = strlen(ptempsrc);
		}
		else
		{
			len = pfind - ptempsrc;
			ptempsrc = pfind + 1;
		}

		count++;
		*maxlenbetweensub = *maxlenbetweensub < len ? len : *maxlenbetweensub;
	} while (pfind != NULL);

	*subcounts = count;

	return 0;
}

int ParseWifiInfoNew(SPCtrlData* pspctrldata,char* pContext)
{
	////pContext = 2@ChinaNet-test@94@yao@100
	int rlt = 0;
	do 
	{
		int realwificount = 0;
		char* ptempcontext = NULL;
		char* pfind = NULL;
		char plevel[256] = {0};
		int len = strlen(pContext);

		if (pspctrldata == NULL || pContext == NULL)
			break;
		pspctrldata->arrWifi = (WifiInfoN*)malloc(pspctrldata->wificount*sizeof(WifiInfoN));
		memset(pspctrldata->arrWifi,0,pspctrldata->wificount*sizeof(WifiInfoN));
		ptempcontext = pContext;

		//去掉代表wifi总数的字段
		pfind = strstr(ptempcontext,"@");
		if (pfind == NULL)
			break;
		ptempcontext = pfind + 1;

		while(ptempcontext - pContext < len)
		{
			pfind = strstr(ptempcontext,"@");
			if(pfind == NULL)
			{
				break;
			}
			if (*(pfind+1) == '@')
			{
				memcpy(pspctrldata->arrWifi[realwificount].wifiSsid+strlen(pspctrldata->arrWifi[realwificount].wifiSsid),ptempcontext,pfind-ptempcontext);
				ptempcontext = pfind + 1;
				memcpy(pspctrldata->arrWifi[realwificount].wifiSsid+strlen(pspctrldata->arrWifi[realwificount].wifiSsid),"@",1);
				ptempcontext += 1;
				continue;
			}

			if(pfind-ptempcontext > 0)
			{
				memcpy(pspctrldata->arrWifi[realwificount].wifiSsid+strlen(pspctrldata->arrWifi[realwificount].wifiSsid),ptempcontext,pfind-ptempcontext);
			}
			ptempcontext = pfind + 1;

			pfind = strstr(ptempcontext,"@");
			if(pfind == NULL)
			{
				if(ptempcontext < pContext+len)
				{
					pspctrldata->arrWifi[realwificount].signalLevel = atoi(ptempcontext);
				}
				realwificount++;
				break;
			}
			else
			{
				memset(plevel,0,sizeof(plevel));
				memcpy(plevel,ptempcontext,pfind-ptempcontext);
				ptempcontext = pfind + 1;
				pspctrldata->arrWifi[realwificount].signalLevel = atoi(plevel);
			}
			realwificount++;
			if (pspctrldata->wificount <= realwificount)
			{
				break;
			}
		}
		pspctrldata->wificount = realwificount;
	} while (0);

	return rlt;
}

int ParseWifiInfo(SPCtrlData* pspctrldata,char* pContext)
{
	////pContext = 2@ChinaNet-test@94@yao@100
	int rlt = 0;
	do 
	{
		int realwificount = 0;
		char* ptempcontext = NULL;
		char* pfind = NULL;
		char plevel[256] = {0};
		int len = strlen(pContext);

		if (pspctrldata == NULL || pContext == NULL)
			break;
		pspctrldata->arrWifi = (WifiInfoN*)malloc(pspctrldata->wificount*sizeof(WifiInfoN));
		memset(pspctrldata->arrWifi,0,pspctrldata->wificount*sizeof(WifiInfoN));
		ptempcontext = pContext;
		
		//去掉代表wifi总数的字段
		pfind = strstr(ptempcontext,"@");
		if (pfind == NULL)
			break;
		ptempcontext = pfind + 1;

		while(ptempcontext - pContext < len)
		{
			pfind = strstr(ptempcontext,"@");
			if(pfind == NULL)
				break;
			memcpy(pspctrldata->arrWifi[realwificount].wifiSsid,ptempcontext,pfind-ptempcontext);
			ptempcontext = pfind + 1;

			pfind = strstr(ptempcontext,"@");
			if(pfind == NULL)
			{
				if(ptempcontext < pContext+len)
				{
					pspctrldata->arrWifi[realwificount].signalLevel = atoi(ptempcontext);
				}
				realwificount++;
				break;
			}
			else
			{
				memset(plevel,0,sizeof(plevel));
				memcpy(plevel,ptempcontext,pfind-ptempcontext);
				ptempcontext = pfind + 1;
				pspctrldata->arrWifi[realwificount].signalLevel = atoi(plevel);
			}
			realwificount++;
		}
		pspctrldata->wificount = realwificount;
	} while (0);

	return rlt;
}

int FindWifiCounts(char* pContext)
{
	int wificount = 0;
	if (pContext)
	{
		char* pfind = strstr(pContext,"@");
		if(pfind != NULL)
		{
			char pTemp[256] = {0};
			memcpy(pTemp,pContext,pfind-pContext);
			wificount = atoi(pTemp);
		}
	}
	return wificount;
}

int SetErrInfo(SPCtrlData* pspctrldata,char* perrinfo)
{
	if (pspctrldata && perrinfo)
	{
		int len = strlen(perrinfo);
		
		if (len >= 1024)
		{
			int len = strlen(perrinfo);
			memset(pspctrldata->strErrorInfo,0,sizeof(pspctrldata->strErrorInfo));
			len = len > sizeof(pspctrldata->strErrorInfo) ? sizeof(pspctrldata->strErrorInfo) : len;
			strncpy(pspctrldata->strErrorInfo,perrinfo,len);
		}
		else if ( len < 0)
		{
			return -1;
		}
		else
		{
			memset(pspctrldata->strErrorInfo,0,sizeof(pspctrldata->strErrorInfo));
			strcpy(pspctrldata->strErrorInfo,perrinfo);
		}
// 		if (pspctrldata->strErrorInfo != NULL)
// 		{
// 			free(pspctrldata->strErrorInfo);
// 			pspctrldata->strErrorInfo = NULL;
// 		}
// 		pspctrldata->strErrorInfo = (char*)malloc(len);
// 		memset(pspctrldata->strErrorInfo,0,len);
// 		strcpy(pspctrldata->strErrorInfo,perrinfo);
		return 0;
	}
	return -1;
}

int SetDayEventList(SPCtrlData* pspctrldata,char* daylist)
{
	if (pspctrldata)
	{
		int len = strlen(daylist) + 1;
		if (pspctrldata->dayEventAck != NULL)
		{
			free(pspctrldata->dayEventAck);
			pspctrldata->dayEventAck = NULL;
		}
		pspctrldata->dayEventAck = (char*)malloc(len);
		memset(pspctrldata->dayEventAck,0,len);
		strcpy(pspctrldata->dayEventAck,daylist);
		return 0;
	}
	return -1;
}

int SetDayLogs(SPCtrlData* pspctrldata,char* daylog)
{
	if (pspctrldata)
	{
		int len = strlen(daylog) + 1;
		if (pspctrldata->daylogs != NULL)
		{
			free(pspctrldata->daylogs);
			pspctrldata->daylogs = NULL;
		}
		pspctrldata->daylogs = (char*)malloc(len);
		memset(pspctrldata->daylogs,0,len);
		strcpy(pspctrldata->daylogs,daylog);
		return 0;
	}
	return -1;
}

int SendCmd( SPCtrlData* pspctrldata,TlibFieldAx *ptlibfield,int dwCmdDest)
{
	int sendedlen = 0;
	if(pspctrldata == NULL || ptlibfield == NULL || pspctrldata->nSockTrans == -1)
		return -1;

	pr_debug("start SendCmd\n");
	Tlib_DoBuildString(ptlibfield);

	pr_debug("send buffer = %s\n",ptlibfield->szpCmdBuf);
	sendedlen = ForceSend(pspctrldata->nSockTrans,ptlibfield->szpCmdBuf,ptlibfield->dwBufLen,2000,0,NULL) ;
	if (sendedlen <= 0)
	{
		DisconnectDevice(pspctrldata);
	}
	pr_debug("end SendCmd\n");
	return sendedlen;
}

void ClearWifiList(SPCtrlData* pspctrldata)
{
	if(pspctrldata && pspctrldata->arrWifi)
	{
		free(pspctrldata->arrWifi);
		pspctrldata->arrWifi = NULL;
		pspctrldata->wificount = 0;
	}
}

void ClearAVResolution(SPCtrlData* pspctrldata)
{
	if (pspctrldata && pspctrldata->arrAVResolution)
	{
		free(pspctrldata->arrAVResolution);
		pspctrldata->arrAVResolution = NULL;
		pspctrldata->rescount = 0;
	}
}

int DoDealWithACK(SPCtrlData* pspctrldata)
{
	TlibFieldAx *ptlibfield = NULL;
	char* lpAckString = NULL;
	int rlt = 1;

	if(pspctrldata == NULL)
		return -1;

	lpAckString = pspctrldata->pAcks;
	pr_debug("recv lpAckString: %s\n",lpAckString);

	ptlibfield = Tlib_CreateFiled();
	pr_debug("create decode %p\n",ptlibfield);
	if(pspctrldata->m_cmdType == trans_cmd)
	{
		memset(pspctrldata->transcmd,0,sizeof(pspctrldata->transcmd));
		if(lpAckString != NULL)
			memcpy(pspctrldata->transcmd,lpAckString,strlen(lpAckString));
	}
	
	pr_debug("decoding string\n");
	Tlib_DoDecodeString(ptlibfield,lpAckString);
	pr_debug("decoding string end\n");

	do 
	{
		Field *pLg=NULL;
		int bOk = 0;
		int bRetAudio = 0;

 		//如果是推送或PIR报警，直接返回不处理，需要重新接收，
 		if (strstr(lpAckString,"Command_Param5052") != NULL || strstr(lpAckString,"Command_Param5027") != NULL)
 		{
 			rlt = NOT_CURRENT_CMD_TYPE;
 			break;
 		}


		pLg= Tlib_GetFieldInfoByName(ptlibfield,"Ret") ;
		if ( pLg != NULL)
		{
#ifdef WIN32
			bOk = stricmp((char*)pLg->pszFieldContent,"1") == 0;
#else
			bOk = strcasecmp((char*)pLg->pszFieldContent,"1") == 0;
#endif
			if ( !bOk )
			{
				pLg = Tlib_GetFieldInfoByName(ptlibfield,"ErrorInfo") ;
				if (pLg != NULL)
				{
					SetErrInfo(pspctrldata,pLg->pszFieldContent);
				}
				pLg = NULL ;
			}
			else
			{
				SetErrInfo(pspctrldata,"ok");
			}
		}
		else
		{
			char pRet[2][20] = {"RetAudio","RetYELP"};
			int nCount = 0;
			while (1)
			{
				pLg= Tlib_GetFieldInfoByName(ptlibfield,pRet[nCount++]) ;
				if (pLg)
				{
					bRetAudio = 1;
					break;
				}
				if (nCount >= 2)
				{
					break;
				}
			}
		}

		if (!bOk && !bRetAudio)
		{
			rlt = 0;
			break;
		}

		switch(ptlibfield->dwCommand)
		{
		case COMMAND_S_C_TRANSMIT_ACK:
			{
				pLg = Tlib_GetFieldInfoByName(ptlibfield,"Command_Param");
				if(pLg != NULL && pLg->pszFieldContent && pLg->dwFieldContentLen>0)
				{

					if(strcmp(pLg->pszFieldContent,cmdGetMonthEventListAck) == 0)
					{
						pLg = Tlib_GetFieldInfoByName(ptlibfield,"Month");
						if(pLg != NULL && pLg->pszFieldContent && pLg->dwFieldContentLen>0)
						{
							SetDayEventList(pspctrldata,pLg->pszFieldContent);
						}
					}
					else if (strcmp(pLg->pszFieldContent,cmdGetPwm3Ack) == 0)
					{
						pLg = Tlib_GetFieldInfoByName(ptlibfield,"pwm3");
						if(pLg != NULL && pLg->pszFieldContent && pLg->dwFieldContentLen>0)
						{
							pspctrldata->m_pwm3Type = atoi(pLg->pszFieldContent);
						}
					}
					else if(strcmp(pLg->pszFieldContent,cmdGetDayEventListACK) == 0)
					{
						pLg = Tlib_GetFieldInfoByName(ptlibfield,"Day");
						if(pLg != NULL && pLg->pszFieldContent && pLg->dwFieldContentLen>0)
						{
							pr_debug("day..........:%s\n", pLg->pszFieldContent);
							SetDayEventList(pspctrldata,pLg->pszFieldContent);
						}
					}
					else if(strcmp(pLg->pszFieldContent,cmdGetCurTempAck) == 0)
					{
						pLg = Tlib_GetFieldInfoByName(ptlibfield,"TaRHValue");
						if(pLg != NULL && pLg->pszFieldContent && pLg->dwFieldContentLen>0)
						{
							pr_debug("CMD : parse cmdGetCurTempAck, temp = %p,%s\n",pspctrldata->m_curTemp,pLg->pszFieldContent);
							FindCurHumTemp(pspctrldata->m_curTemp,pLg->pszFieldContent);
						}
						pLg = Tlib_GetFieldInfoByName(ptlibfield,"TemperatureType");
						if(pLg != NULL && pLg->pszFieldContent && pLg->dwFieldContentLen>0)
						{
							pr_debug("111 CMD : parse cmdGetCurTempAck, temp = %p,%s\n",pspctrldata->m_curTemp,pLg->pszFieldContent);
							if (pspctrldata->m_curTemp)
							{
								pspctrldata->m_curTemp->tempType = atoi(pLg->pszFieldContent);
							}
						}
					}
					else if(strcmp(pLg->pszFieldContent,cmdDownloadEventACK) == 0)
					{
						pLg = Tlib_GetFieldInfoByName(ptlibfield,"fileLength");
						if(pLg != NULL && pLg->pszFieldContent && pLg->dwFieldContentLen>0)
						{
							int len = 0;
							sscanf(pLg->pszFieldContent,"%d",&len);
							pspctrldata->fileLenBase = pspctrldata->fileLen = len;
							if (pspctrldata->stroedFile == NULL)
							{
								pspctrldata->stroedFile = fopen(pspctrldata->strdownloadsavePath,"wb+");
							}
							if(pspctrldata->stroedFile == NULL)
							{
								pspctrldata->bDownloading = 0;
								break;
							}
						}

						pLg = Tlib_GetFieldInfoByName(ptlibfield,"Data");
						if(pLg != NULL && pLg->pszFieldContent && pLg->dwFieldContentLen>0 && pspctrldata->stroedFile != NULL)
						{
							if(pspctrldata->stroedFile != NULL)
							{
								fwrite(pLg->pszFieldContent,pLg->dwFieldContentLen,1,pspctrldata->stroedFile);
							}
							pspctrldata->fileLen -= pLg->dwFieldContentLen;

							if(pspctrldata->fileLen <= 0)
							{
								if(pspctrldata->stroedFile != NULL)
								{
									fclose(pspctrldata->stroedFile);
									pspctrldata->stroedFile = NULL;
								}

								pspctrldata->bDownloading = 0;
							}
							break;
						}
					}
					else if(strcmp(pLg->pszFieldContent,cmdGetImageColorACK) == 0)
					{
						pLg = Tlib_GetFieldInfoByName(ptlibfield,"Brightness");
						if(pLg != NULL && pLg->pszFieldContent && pLg->dwFieldContentLen>0)
						{
							pspctrldata->brightness = atoi(pLg->pszFieldContent);;
						}
						pLg = Tlib_GetFieldInfoByName(ptlibfield,"Contrast");
						if(pLg != NULL && pLg->pszFieldContent && pLg->dwFieldContentLen>0)
						{
							pspctrldata->contrast = atoi(pLg->pszFieldContent);;
						}
						pLg = Tlib_GetFieldInfoByName(ptlibfield,"Saturation");
						if(pLg != NULL && pLg->pszFieldContent && pLg->dwFieldContentLen>0)
						{
							pspctrldata->saturation = atoi(pLg->pszFieldContent);;
						}

						pLg = Tlib_GetFieldInfoByName(ptlibfield,"Hue");
						if(pLg != NULL && pLg->pszFieldContent && pLg->dwFieldContentLen>0)
						{
							pspctrldata->hue = atoi(pLg->pszFieldContent);
						}
					}
					else if(strcmp(pLg->pszFieldContent,cmdSetImageColorACK) == 0)
					{
						
					}
					else if(strcmp(pLg->pszFieldContent,cmdGetWifiListACK)==0)
					{
						pLg = Tlib_GetFieldInfoByName(ptlibfield,"WifiListInfo");
						if(pLg != NULL && pLg->pszFieldContent && pLg->dwFieldContentLen>0)
						{
							//2@ChinaNet-test@94@yao@100
							//count@wifissid@level...
							int wificount = FindWifiCounts(pLg->pszFieldContent);
							ClearWifiList(pspctrldata);
							pspctrldata->wificount = wificount;
							ParseWifiInfoNew(pspctrldata,pLg->pszFieldContent);
						}
					}
					else if(strcmp(pLg->pszFieldContent,cmdGetResolutionACK) == 0)
					{
						pLg = Tlib_GetFieldInfoByName(ptlibfield,"AVedioResolution");
						if(pLg != NULL && pLg->pszFieldContent && pLg->dwFieldContentLen>0)
						{
							//strTemp 形如这样的字符串:2@720P(1280X720)@15@1024@3@720P(640X480)@8@200@3
							char* sep = "@";
							int nIndex = 0;
							int rescount = 0;
							int i = 0;
							int width,height,fps,bps,igap;
							char* ptempcontext = pLg->pszFieldContent;
							char* pfind  = strstr(ptempcontext,sep);
							if(pfind != NULL)
							{
								char ptemprescount[20] = {0};
								memcpy(ptemprescount,ptempcontext,pfind-ptempcontext);
								ptempcontext = pfind+1;
								rescount = atoi	(ptemprescount);

								ClearAVResolution(pspctrldata);
								pspctrldata->rescount = rescount;
								pspctrldata->arrAVResolution = (AVResolutionN*)malloc(rescount*sizeof(AVResolutionN));
								memset(pspctrldata->arrAVResolution,0,rescount*sizeof(AVResolutionN));

								for ( i = 0; i < rescount; i++)
								{
									AVResolutionN* pAVR = pspctrldata->arrAVResolution+i;
									pfind = strstr(ptempcontext,sep);
									if(pfind)
									{
										char tempF[40] = {0};
										memcpy(pAVR->resName,ptempcontext,pfind-ptempcontext);
										sscanf(pAVR->resName,"%[^(](%dX%d)",tempF,&width,&height);
										ptempcontext = pfind + 1;
									}
									else
										break;

									pfind = strstr(ptempcontext,sep);
									if(pfind)
									{
										char temp[20] = {0};
										memcpy(temp,ptempcontext,pfind-ptempcontext);
										ptempcontext = pfind + 1;
										fps = atoi(temp);
									}
									else
										break;

									pfind = strstr(ptempcontext,sep);
									if(pfind)
									{
										char temp[20] = {0};
										memcpy(temp,ptempcontext,pfind-ptempcontext);
											ptempcontext = pfind + 1;
										bps = atoi(temp);
									}
									else
										break;

									pfind = strstr(ptempcontext,sep);
									if(pfind)
									{
										char temp[20] = {0};
										memcpy(temp,ptempcontext,pfind-ptempcontext);
											ptempcontext = pfind + 1;
										igap = atoi(temp);
									}
									else
									{
										igap = atoi(ptempcontext);
									}

									pAVR->width = width;
									pAVR->height = height;
									pAVR->frameRate = fps;
									pAVR->bitRate = bps;
									pAVR->iGap = igap;
								}
							}
		
						}	
					}
					else if(strcmp(pLg->pszFieldContent,cmdSetResolutionACK) == 0)
					{
						//::PostMessage(m_pWnd->GetSafeHwnd(),WM_SET_RESOLUTION_ACK,0,0);
					}
					else if(strcmp(pLg->pszFieldContent,cmdSetWifiACK) == 0)
					{
						//::PostMessage(m_pWnd->GetSafeHwnd(),WM_SET_WIFI_ACK,0,0);
						pLg = Tlib_GetFieldInfoByName(ptlibfield,"Ret");
						if(pLg)
							pspctrldata->m_setWifi = atoi((char*)pLg->pszFieldContent);
					}
					else if(strcmp(pLg->pszFieldContent,cmdSetApInfoAck) == 0)
					{
						//::PostMessage(m_pWnd->GetSafeHwnd(),WM_SET_WIFI_ACK,0,0);
						pLg = Tlib_GetFieldInfoByName(ptlibfield,"Ret");
						if(pLg)
							pspctrldata->m_setAp = atoi((char*)pLg->pszFieldContent);
					}
					else if(strcmp(pLg->pszFieldContent,cmdGetWorkEnACK) == 0)
					{
						pLg = Tlib_GetFieldInfoByName(ptlibfield,"SensorMode");
						if(pLg)
							pspctrldata->workEnType = atoi((char*)pLg->pszFieldContent);
					}
					else if(strcmp(pLg->pszFieldContent,cmdQueryDayLogACK) == 0)
					{
						if(pLg->dwFieldContentLen > 0)
							SetDayLogs(pspctrldata,pLg->pszFieldContent);
					}
					else if(strcmp(pLg->pszFieldContent,cmdSetDefaultColorACK) == 0)
					{
						pLg = Tlib_GetFieldInfoByName(ptlibfield,"Brightness");
						if(pLg != NULL && pLg->pszFieldContent && pLg->dwFieldContentLen>0)
						{
							pspctrldata->brightness = atoi(pLg->pszFieldContent);
						}
						pLg = Tlib_GetFieldInfoByName(ptlibfield,"Contrast");
						if(pLg != NULL && pLg->pszFieldContent && pLg->dwFieldContentLen>0)
						{
							pspctrldata->contrast = atoi(pLg->pszFieldContent);
						}
						pLg = Tlib_GetFieldInfoByName(ptlibfield,"Saturation");
						if(pLg != NULL && pLg->pszFieldContent && pLg->dwFieldContentLen>0)
						{
							pspctrldata->saturation = atoi(pLg->pszFieldContent);
						}

						pLg = Tlib_GetFieldInfoByName(ptlibfield,"Hue");
						if(pLg != NULL && pLg->pszFieldContent && pLg->dwFieldContentLen>0)
						{
							pspctrldata->hue = atoi(pLg->pszFieldContent);
						}
					}
					else if(strcmp(pLg->pszFieldContent,cmdGetRtspAudioSwitchACK) == 0)
					{
						pLg = Tlib_GetFieldInfoByName(ptlibfield,"RtspAudioSwitch");
						if(pLg != NULL && pLg->pszFieldContent && pLg->dwFieldContentLen>0)
						{
							pspctrldata->bRtspOn = atoi(pLg->pszFieldContent);
						}
					}
					else if(strcmp(pLg->pszFieldContent,cmdGetNoiseLvlACK) == 0)
					{
						pLg = Tlib_GetFieldInfoByName(ptlibfield,"LowLightNoiseLvl");
						if(pLg != NULL && pLg->pszFieldContent && pLg->dwFieldContentLen>0)
						{
							pspctrldata->noiseLvl = atoi(pLg->pszFieldContent);
						}
					}
					else if(strcmp(pLg->pszFieldContent,cmdProtocolIntercomDataAck) == 0)
					{
						pLg = Tlib_GetFieldInfoByName(ptlibfield,"RetAudio");
						if(pLg != NULL && pLg->pszFieldContent && pLg->dwFieldContentLen>0)
						{
							int len = strlen(pLg->pszFieldContent);
							len = len > sizeof(pspctrldata->m_RetAudio) ? sizeof(pspctrldata->m_RetAudio) : len;
							memset(&pspctrldata->m_RetAudio,0,sizeof(pspctrldata->m_RetAudio));
							strncpy(pspctrldata->m_RetAudio,pLg->pszFieldContent,len);
						}
					}
					else if(strcmp(pLg->pszFieldContent,cmdProtocolReplyIntercom) == 0)
					{
						pLg = Tlib_GetFieldInfoByName(ptlibfield,"RetAudio");
						if(pLg != NULL && pLg->pszFieldContent && pLg->dwFieldContentLen>0)
						{
							int len = strlen(pLg->pszFieldContent);
							len = len > sizeof(pspctrldata->m_RetAudio) ? sizeof(pspctrldata->m_RetAudio) : len;
							memset(&pspctrldata->m_RetAudio,0,sizeof(pspctrldata->m_RetAudio));
							strncpy(pspctrldata->m_RetAudio,pLg->pszFieldContent,len);
						}
					}
					else if(strcmp(pLg->pszFieldContent,cmdProtocolReplyPlayYelp) == 0)
					{
						pLg = Tlib_GetFieldInfoByName(ptlibfield,"RetYELP");
						if(pLg != NULL && pLg->pszFieldContent && pLg->dwFieldContentLen>0)
						{
							SetErrInfo(pspctrldata,pLg->pszFieldContent);
						}
					}
					else if(strcmp(pLg->pszFieldContent,cmdGetDeviceInfoAck) == 0)
					{
						pr_debug("pspctrldata->m_devAtrr = %p\n",pspctrldata->m_devAtrr);
						if(pspctrldata->m_devAtrr)
						{
							pr_debug("pspctrldata->m_devAtrr = %p 1111111111111\n",pspctrldata->m_devAtrr);
							pLg = Tlib_GetFieldInfoByName(ptlibfield,"DeviceName");
							if(pLg != NULL && pLg->pszFieldContent && pLg->dwFieldContentLen>0)
							{
								int len = strlen(pLg->pszFieldContent);
								len = len > sizeof(pspctrldata->m_devAtrr->devName) ? sizeof(pspctrldata->m_devAtrr->devName) : len;
								strncpy(pspctrldata->m_devAtrr->devName,pLg->pszFieldContent,len);
							}

							pLg = Tlib_GetFieldInfoByName(ptlibfield,"DeviceUid");
							if(pLg != NULL && pLg->pszFieldContent && pLg->dwFieldContentLen>0)
							{
								int len = strlen(pLg->pszFieldContent);
								len = len > sizeof(pspctrldata->m_devAtrr->devId) ? sizeof(pspctrldata->m_devAtrr->devId) : len;
								strncpy(pspctrldata->m_devAtrr->devId,pLg->pszFieldContent,len);
							}

							pLg = Tlib_GetFieldInfoByName(ptlibfield,"WifiMac");
							if(pLg != NULL && pLg->pszFieldContent && pLg->dwFieldContentLen>0)
							{
								int len = strlen(pLg->pszFieldContent);
								len = len > sizeof(pspctrldata->m_devAtrr->wifiMac) ? sizeof(pspctrldata->m_devAtrr->wifiMac) : len;
								strncpy(pspctrldata->m_devAtrr->wifiMac,pLg->pszFieldContent,len);
							}

							pLg = Tlib_GetFieldInfoByName(ptlibfield,"LineMac");
							if(pLg != NULL && pLg->pszFieldContent && pLg->dwFieldContentLen>0)
							{
								int len = strlen(pLg->pszFieldContent);
								len = len > sizeof(pspctrldata->m_devAtrr->lineMac) ? sizeof(pspctrldata->m_devAtrr->lineMac) : len;
								strncpy(pspctrldata->m_devAtrr->lineMac,pLg->pszFieldContent,len);
							}

							pLg = Tlib_GetFieldInfoByName(ptlibfield,"Fw");
							if(pLg != NULL && pLg->pszFieldContent && pLg->dwFieldContentLen>0)
							{
								int len = strlen(pLg->pszFieldContent);
								len = len > sizeof(pspctrldata->m_devAtrr->fw) ? sizeof(pspctrldata->m_devAtrr->fw) : len;
								strncpy(pspctrldata->m_devAtrr->fw,pLg->pszFieldContent,len);
							}

							pLg = Tlib_GetFieldInfoByName(ptlibfield,"Hw");
							if(pLg != NULL && pLg->pszFieldContent && pLg->dwFieldContentLen>0)
							{
								int len = strlen(pLg->pszFieldContent);
								len = len > sizeof(pspctrldata->m_devAtrr->hw) ? sizeof(pspctrldata->m_devAtrr->hw) : len;
								strncpy(pspctrldata->m_devAtrr->hw,pLg->pszFieldContent,len);
							}

							pLg = Tlib_GetFieldInfoByName(ptlibfield,"DevType");
							if(pLg != NULL && pLg->pszFieldContent && pLg->dwFieldContentLen>0)
							{
								int len = strlen(pLg->pszFieldContent);
								len = len > sizeof(pspctrldata->m_devAtrr->devType) ? sizeof(pspctrldata->m_devAtrr->devType) : len;
								strncpy(pspctrldata->m_devAtrr->devType,pLg->pszFieldContent,len);
							}

							pLg = Tlib_GetFieldInfoByName(ptlibfield,"RecordDuration");
							if(pLg != NULL && pLg->pszFieldContent && pLg->dwFieldContentLen>0)
							{
								int len = strlen(pLg->pszFieldContent);
								len = len > sizeof(pspctrldata->m_devAtrr->recordDuration) ? sizeof(pspctrldata->m_devAtrr->recordDuration) : len;
								strncpy(pspctrldata->m_devAtrr->recordDuration,pLg->pszFieldContent,len);
							}

							pLg = Tlib_GetFieldInfoByName(ptlibfield,"AllSafety");
							if(pLg != NULL && pLg->pszFieldContent && pLg->dwFieldContentLen>0)
							{
								pspctrldata->m_devAtrr->allSafety = atoi(pLg->pszFieldContent);
							}

							pLg = Tlib_GetFieldInfoByName(ptlibfield,"LoopVideo");
							if(pLg != NULL && pLg->pszFieldContent && pLg->dwFieldContentLen>0)
							{
								pspctrldata->m_devAtrr->loopVideo = atoi(pLg->pszFieldContent);
							}

							pLg = Tlib_GetFieldInfoByName(ptlibfield,"WDR");
							if(pLg != NULL && pLg->pszFieldContent && pLg->dwFieldContentLen>0)
							{
								pspctrldata->m_devAtrr->wdr = atoi(pLg->pszFieldContent);
							}

							pLg = Tlib_GetFieldInfoByName(ptlibfield,"Motion");
							if(pLg != NULL && pLg->pszFieldContent && pLg->dwFieldContentLen>0)
							{
								pspctrldata->m_devAtrr->motion = atoi(pLg->pszFieldContent);
							}

							pLg = Tlib_GetFieldInfoByName(ptlibfield,"Noise");
							if(pLg != NULL && pLg->pszFieldContent && pLg->dwFieldContentLen>0)
							{
								pspctrldata->m_devAtrr->noise = atoi(pLg->pszFieldContent);
							}

							pLg = Tlib_GetFieldInfoByName(ptlibfield,"Night");
							if(pLg != NULL && pLg->pszFieldContent && pLg->dwFieldContentLen>0)
							{
								pspctrldata->m_devAtrr->night = atoi(pLg->pszFieldContent);
							}

							pLg = Tlib_GetFieldInfoByName(ptlibfield,"Alarmtone");
							if(pLg != NULL && pLg->pszFieldContent && pLg->dwFieldContentLen>0)
							{
								pspctrldata->m_devAtrr->alarmtone = atoi(pLg->pszFieldContent);
							}

							pLg = Tlib_GetFieldInfoByName(ptlibfield,"MotionSensitivity");
							if(pLg != NULL && pLg->pszFieldContent && pLg->dwFieldContentLen>0)
							{
								pspctrldata->m_devAtrr->MotionSensitivity = atoi(pLg->pszFieldContent);
							}
							pLg = Tlib_GetFieldInfoByName(ptlibfield,"AudioSensitivity");
							if(pLg != NULL && pLg->pszFieldContent && pLg->dwFieldContentLen>0)
							{
								pspctrldata->m_devAtrr->AudioSensitivity = atoi(pLg->pszFieldContent);
							}
							pLg = Tlib_GetFieldInfoByName(ptlibfield,"TemperatureAlarm");
							if(pLg != NULL && pLg->pszFieldContent && pLg->dwFieldContentLen>0)
							{
								pspctrldata->m_devAtrr->TemperatureAlarm = atoi(pLg->pszFieldContent);
							}
							pLg = Tlib_GetFieldInfoByName(ptlibfield,"Upperlimit");
							if(pLg != NULL && pLg->pszFieldContent && pLg->dwFieldContentLen>0)
							{
								pspctrldata->m_devAtrr->Upperlimit = atof(pLg->pszFieldContent);
							}
							pLg = Tlib_GetFieldInfoByName(ptlibfield,"Lowerlimit");
							if(pLg != NULL && pLg->pszFieldContent && pLg->dwFieldContentLen>0)
							{
								pspctrldata->m_devAtrr->Lowerlimit = atof(pLg->pszFieldContent);
							}
							pLg = Tlib_GetFieldInfoByName(ptlibfield,"TemperatureType");
							if(pLg != NULL && pLg->pszFieldContent && pLg->dwFieldContentLen>0)
							{
								pspctrldata->m_devAtrr->tempType = atof(pLg->pszFieldContent);
							}
							pLg = Tlib_GetFieldInfoByName(ptlibfield,"LowBattery");
							if(pLg != NULL && pLg->pszFieldContent && pLg->dwFieldContentLen>0)
							{
								pspctrldata->m_devAtrr->lowbatery = atof(pLg->pszFieldContent);
							}
							pLg = Tlib_GetFieldInfoByName(ptlibfield,"PlayCradlesong");
							if(pLg != NULL && pLg->pszFieldContent && pLg->dwFieldContentLen>0)
							{
								pspctrldata->m_devAtrr->PlayCradlesong = atof(pLg->pszFieldContent);
							}
							pLg = Tlib_GetFieldInfoByName(ptlibfield,"apSsid");
							if(pLg != NULL && pLg->pszFieldContent && pLg->dwFieldContentLen>0)
							{
								strcpy(pspctrldata->m_devAtrr->apSsid,pLg->pszFieldContent);
							}
							pLg = Tlib_GetFieldInfoByName(ptlibfield,"apPwd");
							if(pLg != NULL && pLg->pszFieldContent && pLg->dwFieldContentLen>0)
							{
								strcpy(pspctrldata->m_devAtrr->apPsw,pLg->pszFieldContent);
							}
							pr_debug("pspctrldata->m_devAtrr = %p 22222222222\n",pspctrldata->m_devAtrr);
						}
					}
					else if(strcmp(pLg->pszFieldContent,cmdSysReqLedAck) == 0)
					{
						
					}
					else if(strcmp(pLg->pszFieldContent, cmdTakePhotoAck) == 0)
					{
						pLg = Tlib_GetFieldInfoByName(ptlibfield,"Ret");
						if(pLg)
						{
							pr_debug("take photo ack ret=%d\n", atoi(pLg->pszFieldContent));
						}
					}
				}
			}
			break;

		case COMMAND_S_C_TRANSMIT_DATA_ACK:
			{

			}
			break;
		}

	} while (0);

	Tlib_DestroyFiled(ptlibfield);

	return rlt;
}

int ControlParams(SPCtrlData* pspctrldata,int cmd,void* param,int paramlen)
{
	int rlt = 0;

	if(pspctrldata == NULL || (param == NULL && paramlen != 0))
		return -1;


	if(pspctrldata->nSockTrans == -1)
	{
		char pIp[64] = {0};
		int port = pspctrldata->port;
		int len = strlen(pspctrldata->ipaddr);
		len = len > sizeof(pIp) ? sizeof(pIp) : len;
		strncpy(pIp,pspctrldata->ipaddr,len);
		if(ConnectDevice(pspctrldata,pIp,port) != 0)
			return -1;
	}

	pr_debug("ControlParams start, cmd = %d\n",cmd);

	switch(cmd)
	{
	case PCT_CMD_SET_WIFI_NEW:
		{
			rlt = DoDealWithReq(pspctrldata,COMMAND_C_S_TRANSMIT_REQ,set_wifi_new,(const char*)param);
		}
		break;
	case PCT_CMD_PTZ_LEFT:
	case PCT_CMD_PTZ_RIGHT:
	case PCT_CMD_PTZ_UP:
	case PCT_CMD_PTZ_DOWN:
	case PCT_CMD_PTZ_ZOON_IN:
	case PCT_CMD_PTZ_ZOON_OUT:
	case PCT_CMD_PTZ_H_SCAN:
	case PCT_CMD_PTZ_V_SCAN:
	case PCT_CMD_AUTO_SCAN:
	case PCT_CMD_STOP_SCAN:
	case PCT_CMD_PTZ_MIRROR:
	case PCT_CMD_PTZ_FLIP:
	case PCT_CMD_PTZ_KEEP_LEFT:
	case PCT_CMD_PTZ_KEEP_RIGHT:
	case	PCT_CMD_PTZ_KEEP_UP:
	case PCT_CMD_PTZ_KEEP_DOWN:
		{
			Ptz(pspctrldata,cmd - PCT_CMD_PTZ_LEFT + ptz_left);
		}
		break;
	case PCT_CMD_TAKE_PHOTO:
		{
			pr_debug("PCT_CMD_TAKE_PHOTO, cmd = %d\n",cmd);
			TakePhoto(pspctrldata, cmd);
		}
		break;
	case PCT_CMD_SET_TIME:
		{
			pr_debug("PCT_CMD_SET_TIME, cmd=%d\n", cmd);
			SetTime(pspctrldata, (SetTime_S*)param);
		}
		break;
	case PCT_CMD_GET_LIST_OF_DAY_HAS_VIDEO:
		{
			//201705030052|201705040378|
			//20170503->某天;0052->文件个数
			SSdcardRecQuery* temp = (SSdcardRecQuery*)param;
			char* pRlt = NULL;
			//pspctrldata->m_SdcardRecQuery = temp;
			memcpy(pspctrldata->m_SdcardRecQuery,temp,sizeof(SSdcardRecQuery));
			pRlt = FindListofDayHasVideo(pspctrldata,temp->ptime);
			if (pRlt == NULL)
			{
				printf("get list of day failed!\n");
				temp->plist = NULL;
				rlt = -1;
			}
			else
			{
				printf("list:   %s\n",pRlt);
				ParseDayEventList(temp,pRlt,0);
			}
		}
		break;
	case PCT_CMD_GET_VIDEO_LIST:
		{
			//
			SSdcardRecQuery* temp = (SSdcardRecQuery*)param;
			char* pRlt = NULL;
			pspctrldata->m_SdcardRecQuery = temp;
			pRlt = FindSdVedioList(pspctrldata,temp->ptime);
			if (pRlt == NULL)
			{
				temp->plist = NULL;
				rlt = -1;
			}
			else
			{
				ParseDayEventList(temp,pRlt,1);
			}
		}
		break;
	case PCT_CMD_START_DOWNLOAD_VIDEO:
		{
			SSdcardRecDownload* temp = (SSdcardRecDownload*)param;
			SetDownloadSavePath(pspctrldata,temp->savepath);
			rlt = StartDownLoadSdVedio(pspctrldata,temp->filename);
		}
		break;
	case PCT_CMD_STOP_DOWNLOAD_VIDEO:
		{
			SSdcardRecDownload* temp = (SSdcardRecDownload*)param;
			rlt = StopDownLoadSdVedio(pspctrldata,temp->filename);
		}
		break;
	case PCT_CMD_GET_IMAGE_COLOR:
		{
			SImageColor* temp = (SImageColor*)param;
			rlt = QueryImageColor(pspctrldata);
			GetImageColor(pspctrldata,&(temp->brightness),&(temp->contrast),&(temp->saturation),&(temp->hue));
		}
		break;
	case PCT_CMD_SET_IMAGE_COLOR:
		{
			SImageColor* temp = (SImageColor*)param;
			rlt = SetImageColor(pspctrldata,temp->brightness,temp->contrast,temp->saturation,temp->hue);
		}
		break;
	case PCT_CMD_GET_RESOLUTION:
		{
			SResolution* temp = (SResolution*)param;
			rlt = QueryResolution(pspctrldata);
			if(rlt == 0)
			{
				if (pspctrldata->rescount == 2)
				{
					memcpy(&(temp->major),pspctrldata->arrAVResolution,sizeof(AVResolutionN));
					memcpy(&(temp->minor),pspctrldata->arrAVResolution+1,sizeof(AVResolutionN));
				}
				else if (pspctrldata->rescount == 1)
				{
					memcpy(&(temp->major),pspctrldata->arrAVResolution,sizeof(AVResolutionN));
				}
			}
		}
		break;
	case PCT_CMD_SET_RESOLUTION:
		{
			SResolution* temp = (SResolution*)param;
			ClearAVResolution(pspctrldata);
			pspctrldata->rescount = 2;
			pspctrldata->arrAVResolution = (AVResolutionN*)malloc(sizeof(AVResolutionN)*pspctrldata->rescount);
			memset(pspctrldata->arrAVResolution,0,sizeof(AVResolutionN)*pspctrldata->rescount);
			memcpy(pspctrldata->arrAVResolution,&(temp->major),sizeof(AVResolutionN));
			memcpy(pspctrldata->arrAVResolution+1,&(temp->minor),sizeof(AVResolutionN));
			rlt = SetResolution(pspctrldata);
		}
		break;
	case PCT_CMD_GET_WORK_ENVIRONMENT:
		{
			SWorkEn* temp = (SWorkEn*)param;
			if((rlt = QueryWorkEnvironment(pspctrldata)) == 0)
				temp->type = pspctrldata->workEnType;
		}
		break;
	case PCT_CMD_SET_WORK_ENVIRONMENT:
		{
			SWorkEn* temp = (SWorkEn*)param;
			rlt = SetWorkEnvironment(pspctrldata,temp->type);
		}
		break;
	case PCT_CMD_GET_RTSP_SWITCH_STUS:
		{
			SRtspSwitch* temp = (SRtspSwitch*)param;
			if ((rlt = QueryRtspSwitchStatus(pspctrldata)) == 0)
			{
				temp->status = pspctrldata->bRtspOn;
			}
		}
		break;
	case PCT_CMD_SET_RTSP_SWITCH_STUS:
		{
			SRtspSwitch* temp = (SRtspSwitch*)param;
			rlt = SetRtspSwicthStatus(pspctrldata,temp->status);
		}
		break;
	case PCT_CMD_GET_NOISE_LEVEL:
		{
			SNoiseLevel* temp = (SNoiseLevel*)param;
			if((rlt = QueryNoiseLvl(pspctrldata))== 0)
				temp->level = pspctrldata->noiseLvl;
		}
		break;
	case PCT_CMD_SET_NOISE_LEVEL:
		{
			SNoiseLevel* temp = (SNoiseLevel*)param;
			rlt = SetNoiseLvl(pspctrldata,temp->level);
		}
		break;
	case PCT_CMD_QUERY_DAY_LOG:
		{
			SDaylogs* temp = (SDaylogs*)param;
			if(QueryDayLog(pspctrldata,temp->ptime) == 0)
				temp->pszlog =  pspctrldata->daylogs;
			if(temp->pszlog == NULL)
				rlt = -1;
		}
		break;
	case PCT_CMD_GET_WIFI_LIST:
		{
			SWifiInfo* temp = (SWifiInfo*)param;
			rlt = QueryWifiList(pspctrldata);
			if(rlt == 0)
			{
				temp->plist = pspctrldata->arrWifi;
				temp->totalcount = pspctrldata->wificount;
			}
		}
		break;
	case PCT_CMD_SET_WIFI:
		{
			SWifiInfo* temp = (SWifiInfo*)param;
			rlt = SetWifiInfo(pspctrldata,temp->plist);
		}
		break;
	case PCT_CMD_SET_AP:
		{
			SWifiInfo* temp = (SWifiInfo*)param;
			rlt = SetApInfo(pspctrldata,temp->plist);
		}
		break;
	case PCT_CMD_DEBUG_FOR_GET_LAST_ACK:
		{
			if (pspctrldata->pAcks)
			{
				SPmDebug *temp = (SPmDebug*)param;
				if (temp)
				{
					if (strlen(pspctrldata->pAcks) >= 1024)
					{
						memcpy(temp->info,pspctrldata->pAcks,sizeof(temp->info) - 1);
						temp->info[sizeof(temp->info) - 1] = '\0';
					}
					else
					{
						int len = strlen(pspctrldata->pAcks);
						len = len > sizeof(temp->info) ? sizeof(temp->info) : len;
						strncpy(temp->info,pspctrldata->pAcks,len);
					}
					rlt = 0;
				}
				else
				{
					rlt = -1;
				}
			}
			else
			{
				rlt = -1;
			}
		}
		break;
	case PCT_CMD_GET_PM_CONTROL_ERROR_INFO:
		{
			SPmErrorInfo *temp = (SPmErrorInfo*)param;
			char* perror = PCTRL_GetErrorInfo(pspctrldata);
			if(perror)
			{
				int len = strlen(perror);
				len = len > sizeof(temp->info) ? sizeof(temp->info) : len;
				strncpy(temp->info,perror,len);
			}
			else
				strcpy(temp->info,"no error informations");
			rlt = 0;
		}
		break;
	case PCT_CMD_GET_CUR_TEMP_HUM:
		{
			SCurTempHum* temp = (SCurTempHum*)param;
			memset(pspctrldata->m_curTemp,0,sizeof(SCurTempHum));
			pr_debug("CMD : PCT_CMD_GET_CUR_TEMP_HUM, temp = %p\n",pspctrldata->m_curTemp);
			rlt = GetCurTempHum(pspctrldata);
			memcpy(temp,pspctrldata->m_curTemp,sizeof(SCurTempHum));
			pr_debug("CMD : PCT_CMD_GET_CUR_TEMP_HUM END");
		}
		break;
	case PCT_CMD_SET_MOTION_SWITCH:
		{
			SSwitchMotion* temp = (SSwitchMotion*)param;
			rlt = EnableMotion(pspctrldata,temp);
		}
		break;
	case PCT_CMD_RESET_FACTORY:
		{
			rlt = ResetFactory(pspctrldata);
		}
		break;
	case PCT_CMD_TRANSPANRENT_CMD:
		{
			STransCmd *temp = (STransCmd*)param;
			memset(pspctrldata->transcmd,0,sizeof(pspctrldata->transcmd));
			rlt = TransparentCmd(pspctrldata,temp->pcmd);
			memset(temp->pcmd,0,sizeof(temp->pcmd));
			memcpy(temp->pcmd,pspctrldata->transcmd,sizeof(pspctrldata->transcmd));
		}
		break;
	case PCT_CMD_SET_DEFAULT_ALARM_RING:
		{
			SAlarmRing* temp = (SAlarmRing*)param;
			rlt = SetCurrentSong(pspctrldata,temp);
		}
		break;
	case PCT_CMD_PLAY_OR_STOP_CUR_ALARM_RING:
		{
			SAlarmRingPlay* temp = (SAlarmRingPlay*)param;
			rlt = PlayOrStopOneSong(pspctrldata,temp->play);
		}
		break;
	case PCT_CMD_START_SPEAK:
		{
			rlt = StartSpeak(pspctrldata);
			
			if (pspctrldata)
			{
				if(strcmp(pspctrldata->m_RetAudio,"1") == 0)
					rlt = 0;
				else
					rlt = -1;
			}
		}
		break;
	case PCT_CMD_SEND_SPEAK_DATA:
		{
			SSpeakData* temp = (SSpeakData*)param;
			rlt = SendSpeakData(pspctrldata,temp);
			if (pspctrldata)
			{
				if(strcmp(pspctrldata->m_RetAudio,"1") == 0)
					rlt = 0;
				else
					rlt = -1;
			}
		}
		break;
	case PCT_CMD_STOP_SPEAK:
		{
			rlt = StopSpeak(pspctrldata);
		}
		break;
	case PCT_CMD_GET_DEVICE_ATRRIBUTE:
		{
			if(pspctrldata->m_devAtrr)
			{
				memset(pspctrldata->m_devAtrr,0,sizeof(SDevAttr));
				pr_debug("start PCT_CMD_GET_DEVICE_ATRRIBUTE, %p\n",pspctrldata->m_devAtrr);
			}
			rlt = GetDeviceAttr(pspctrldata);
			if(param && pspctrldata->m_devAtrr)
				memcpy(param,pspctrldata->m_devAtrr,sizeof(SDevAttr));
			pr_debug("end PCT_CMD_GET_DEVICE_ATRRIBUTE, %p\n",pspctrldata->m_devAtrr);
		}
		break;
	case PCT_CMD_SET_SURVEILLANCE:
		{
			SSurveillance* temp = (SSurveillance*)param;
			rlt = SetSurveillance(pspctrldata,temp);
		}
		break;
	case PCT_CMD_GET_DOWNLOAD_PROCESS:
		{
			SDownProcess* temp = (SDownProcess*)param;
			rlt = GetDownProcess(pspctrldata,temp);
		}
		break;
	case PCT_CMD_DELETE_FILE:
		{
			SDelFile *temp = (SDelFile*)param;
			rlt = DeleteFile(pspctrldata,temp->pfile);
		}
		break;
	case PCT_CMD_SET_PWM3:
		{
			SPwm3 *temp = (SPwm3*)param;
			rlt = SetPwm3(pspctrldata,temp);
		}
		break;
	case PCT_CMD_GET_PWM3:
		{
			SPwm3 *temp = (SPwm3*)param;
			rlt = GetPwm3(pspctrldata);
			if(temp)
				temp->type = pspctrldata->m_pwm3Type;
		}
		break;
	case PCT_CMD_ACK_SYS_REQ_RECORD:
		{
			SysReqCmdAck* temp = (SysReqCmdAck*)param;
			rlt = AckSysReqRecord(pspctrldata,temp);
		}
		break;
	case PCT_CMD_ACK_SYS_REQ_SHUTDOWN:
		{
			SysReqCmdAck* temp = (SysReqCmdAck*)param;
			rlt = AckSysReqShutdown(pspctrldata,temp);
		}
		break;
	case PCT_CMD_SYS_REQ_LED:
		{
			SysReqCmd* temp = (SysReqCmd*)param;
			rlt = SysReqCmdLed(pspctrldata,temp);
		}
		break;
	}
	
	pr_debug("ControlParams End, cmd = %d\n",cmd);

	return rlt;
}
//////////////////////////////////////////////////////////////////////////
char* FindListofDayHasVideo(SPCtrlData* pspctrldata, const char * strTime)
{
	if(DoDealWithReq(pspctrldata,COMMAND_C_S_TRANSMIT_REQ,sd_query_list_of_day_has_video,strTime) == 0)
	{
		return pspctrldata->dayEventAck;
	}
	else
	{
		return NULL;
	}
}

char* FindSdVedioList(SPCtrlData* pspctrldata, const char * strTime )
{
	if(DoDealWithReq(pspctrldata,COMMAND_C_S_TRANSMIT_REQ,sd_query_day_eventlist,strTime) == 0)
	{
		return pspctrldata->dayEventAck;
	}
	else
	{
		return NULL;
	}
}

int StartDownLoadSdVedio(SPCtrlData* pspctrldata,const char * strFilePath)
{
	if(DoDealWithReq(pspctrldata,COMMAND_C_S_TRANSMIT_REQ,sd_download_vedio,strFilePath) == 0)
		return 0;
	else
		return -1;
}

int StopDownLoadSdVedio(SPCtrlData* pspctrldata,const char * strFilePath)
{
	if(DoDealWithReq(pspctrldata,COMMAND_C_S_TRANSMIT_REQ,sd_stop_download_vedio,strFilePath) == 0)
		return 0;
	else
		return -1;
}

int RecvDataAndProcess( SPCtrlData* pspctrldata, int dwDataType )
{
	int sWorkSock = 0;
	if(pspctrldata == NULL || pspctrldata->nSockTrans == -1 || pspctrldata->pAcks == NULL)
		return -1;
	sWorkSock = pspctrldata->nSockTrans;
	
	if(14 == ForceRecv(sWorkSock,pspctrldata->pAcks,14,30000,0,NULL) )
	{
		int  nDataLen = 0 ;
		char pHead[14] = {0};
		sscanf(pspctrldata->pAcks+8,"%06X",&nDataLen);
		if(nDataLen>=0x4ffff || nDataLen<0)
			return 0 ;
		
		if (nDataLen > MAX_RECV_LEN)
		{
			pr_debug("nDataLen > 8192,malloc\n");
			memcpy(pHead,pspctrldata->pAcks,14);
			free(pspctrldata->pAcks);
			pspctrldata->pAcks = NULL;
			pspctrldata->pAcks = (char*)malloc(nDataLen+14+1);
		}
		if( nDataLen == ForceRecv(sWorkSock,pspctrldata->pAcks+14,nDataLen,10000,0,NULL) )
		{
			int rlt = 0;
			if (nDataLen > MAX_RECV_LEN)
			{
				memcpy(pspctrldata->pAcks,pHead,14);
			}
					
			pspctrldata->pAcks[14+nDataLen] = 0 ;
			rlt = DoDealWithACK(pspctrldata) ;
			if (nDataLen > MAX_RECV_LEN)
			{
				pr_debug("nDataLen > 8192, free\n");
				free(pspctrldata->pAcks);
				pspctrldata->pAcks = NULL;
				pspctrldata->pAcks = (char*)malloc(MAX_RECV_LEN);
			}
 			while (rlt == NOT_CURRENT_CMD_TYPE)
 			{
 				rlt = RecvDataAndProcess(pspctrldata,dwDataType);
 			}
			return rlt;
		}
		else
		{
			DisconnectDevice(pspctrldata);
		}
	}
	else
	{
		DisconnectDevice(pspctrldata);
	}

	return 0 ;
}

int DoDealWithReq( SPCtrlData* pspctrldata, int reqCmd,int type ,const char * addParam)
{
	int dwConError = 0;
	TlibFieldAx *pTlibfiled = NULL;
	int i = 0;

	if(pspctrldata == NULL)
	{
		pr_debug("DoDealWithReq pspctrldata param is NULL\n");
		return -1;
	}


	if(pspctrldata->nSockTrans == -1)
	{
		char pIp[64] = {0};
		int port = pspctrldata->port;
		int len = strlen(pspctrldata->ipaddr);
		len = len > sizeof(pIp) ? sizeof(pIp) : len;
		strncpy(pIp,pspctrldata->ipaddr,len);
		if(ConnectDevice(pspctrldata,pIp,port) != 0)
		{
			SetErrInfo(pspctrldata, "connect to remote failed\n");
			return -1;
		}
	}

	pTlibfiled = Tlib_CreateFiled();
	if(pTlibfiled == NULL)
		return -1;
	Tlib_SetCommand(pTlibfiled,reqCmd);
	pspctrldata->m_cmdType = type;
	switch(type)
	{
	case trans_cmd:
		{
			if(ForceSend(pspctrldata->nSockTrans,(void*)addParam,strlen(addParam),1000,0,NULL)  <= 0)
			{
				dwConError = -2 ;
				SetErrInfo(pspctrldata,"send cmd failed,trans_cmd failed!");
				break;
			}
			if(RecvDataAndProcess(pspctrldata,1) != 1)
			{
				dwConError = -2 ;
				//SetErrInfo(pspctrldata,"recv data failed , trans_cmd failed!");
			}
		}
		break;
	case set_wifi_new:
		{
			SSetWifiInfo *pWifininfo = (SSetWifiInfo*)addParam;
			Tlib_AddNewFiledVoid(pTlibfiled,"Command_Param",cmdSetWifiNew,0,0);
			if ( pWifininfo->type == 0 ) //wifi
			{
				Tlib_AddNewFiledVoid(pTlibfiled,"WifiType","WIFI",0,0);
			}
			else if (pWifininfo->type == 1) //ap
			{
				Tlib_AddNewFiledVoid(pTlibfiled,"WifiType","AP",0,0);
			}
			Tlib_AddNewFiledVoid(pTlibfiled,"WifiSSID",pWifininfo->info.wifiSsid,0,0);
			Tlib_AddNewFiledVoid(pTlibfiled,"WifiPWD",pWifininfo->info.password,0,0);
			Tlib_AddNewFiledVoid(pTlibfiled,"Wait","1",0,0);

			if(SendCmd(pspctrldata,pTlibfiled,1) <= 0)
			{
				dwConError = -2 ;
				SetErrInfo(pspctrldata,"send cmd failed,set wifi/ap failed!");
				break;
			}
			if(RecvDataAndProcess(pspctrldata,1) != 1)
			{
				dwConError = 3;
				//设置之后，断网, 也算成功
				SetErrInfo(pspctrldata,"if network is break,set success");
			}
		}
		break;
	case enable_motion:
		{
			int Sensitivity[3] = {30,60,90};
			Tlib_AddNewFiledVoid(pTlibfiled,"Command_Param",cmdEnableMotion,0,0);
			Tlib_AddNewFiledInt(pTlibfiled,"Motion",pspctrldata->m_motion.motion,0,0);
			//int level; //0->高,1->中,2->低,对应设备端Sensitivity为30->高,60->中,90->低,100->关
			if (pspctrldata->m_motion.level > 3 || pspctrldata->m_motion.level < 0)
			{
				SetErrInfo(pspctrldata,"Motion invalid param, level must in [0-2]");
				dwConError = -2 ;
				break;
			}
			else
			{
				if(pspctrldata->m_motion.motion == 0)
					Tlib_AddNewFiledInt(pTlibfiled,"Sensitivity",100,0,0);
				else
					Tlib_AddNewFiledInt(pTlibfiled,"Sensitivity",Sensitivity[pspctrldata->m_motion.level],0,0);
			}

			//Tlib_AddNewFiledVoid(pTlibfiled,"Motion",addParam,0,0);
			Tlib_AddNewFiledVoid(pTlibfiled,"Wait","1",0,0);

			if(SendCmd(pspctrldata,pTlibfiled,1) <= 0)
			{
				dwConError = -2 ;
				SetErrInfo(pspctrldata,"send cmd failed,enable_motion failed!");
				break;
			}
			if(RecvDataAndProcess(pspctrldata,1) != 1)
			{
				dwConError = -2 ;
				//SetErrInfo(pspctrldata,"recv data failed , enable_motion failed!");
			}
		}
		break;
	case reset_factory:
		{
			Tlib_AddNewFiledVoid(pTlibfiled,"Command_Param",cmdResetFactory,0,0);
			Tlib_AddNewFiledVoid(pTlibfiled,"Wait","1",0,0);

			if(SendCmd(pspctrldata,pTlibfiled,1) <= 0)
			{
				dwConError = -2 ;
				SetErrInfo(pspctrldata,"send cmd failed,reset_factory failed!");
				break;
			}
			if(RecvDataAndProcess(pspctrldata,1) != 1)
			{
				dwConError = -2 ;
				//SetErrInfo(pspctrldata,"recv data failed , reset_factory failed!");
			}
		}
		break;
	case get_cur_temp_hum:
		{
			Tlib_AddNewFiledVoid(pTlibfiled,"Command_Param",cmdGetCurTemp,0,0);
			Tlib_AddNewFiledVoid(pTlibfiled,"Wait","1",0,0);

			if(SendCmd(pspctrldata,pTlibfiled,1) <= 0)
			{
				dwConError = -2 ;
				SetErrInfo(pspctrldata,"send cmd failed,get_cur_temp_hum failed!");
				break;
			}
			pr_debug("start recv cmdgetcurtmep\n");
			if(RecvDataAndProcess(pspctrldata,1) != 1)
			{
				dwConError = -2 ;
				//SetErrInfo(pspctrldata,"recv data failed , get_cur_temp_hum failed!");
			}
			pr_debug("end recv cmdgetcurtmep\n");
		}
		break;
	case sd_query_list_of_day_has_video:
	case sd_query_day_eventlist:
		{
			if(sd_query_list_of_day_has_video == type)
				Tlib_AddNewFiledVoid(pTlibfiled,"Command_Param",cmdGetMonthEventList,0,0);
			else
			{
				Tlib_AddNewFiledVoid(pTlibfiled,"Command_Param",cmdGetDayEventList,0,0);
				if(pspctrldata->m_SdcardRecQuery)
					Tlib_AddNewFiledInt(pTlibfiled,"Type",pspctrldata->m_SdcardRecQuery->filetype,0,0);
			}
			Tlib_AddNewFiledVoid(pTlibfiled,"Date",(char*)addParam,0,0);
			Tlib_AddNewFiledVoid(pTlibfiled,"Wait","1",0,0);

			if(SendCmd(pspctrldata,pTlibfiled,1) <= 0)
			{
				dwConError = -2 ;
				if(sd_query_list_of_day_has_video == type)
					SetErrInfo(pspctrldata,"send cmd failed,query day eventlist failed!");
				else
					SetErrInfo(pspctrldata,"send cmd failed,query month eventlist failed!");
				break;
			}
			if(RecvDataAndProcess(pspctrldata,1) != 1)
			{
				dwConError = -2 ;
// 				if(sd_query_list_of_day_has_video == type)
// 					SetErrInfo(pspctrldata,"query day eventlist failed!");
// 				else
// 					SetErrInfo(pspctrldata,"query month eventlist failed!");
			}
		}
		break;
	case sd_download_vedio:
		{
			Tlib_AddNewFiledVoid(pTlibfiled,"Command_Param",cmdDownloadEvent,0,0);
			Tlib_AddNewFiledVoid(pTlibfiled,"FileName",(char*)addParam,0,0);
			Tlib_AddNewFiledVoid(pTlibfiled,"Wait","1",0,0);
			if(SendCmd(pspctrldata,pTlibfiled,1) <= 0)
			{
				dwConError = -2 ;
				SetErrInfo(pspctrldata,"send cmd failed,download failed!");
				break;
			}
			pspctrldata->bDownloading = 1;
			while (pspctrldata->bDownloading)
			{
				if (RecvDataAndProcess(pspctrldata,1) != 1)
				{
					char perrinfo[256] = {0};
					dwConError = -2 ;
					sprintf(perrinfo,"download failed!,filelen = %d,leftlen = %d",pspctrldata->fileLenBase,pspctrldata->fileLen);
					SetErrInfo(pspctrldata, perrinfo);
					break;
				}
			}
		}
		break;
	case sd_stop_download_vedio:
		{
			Tlib_AddNewFiledVoid(pTlibfiled,"Command_Param",cmdStopDownloadEvent,0,0);
			Tlib_AddNewFiledVoid(pTlibfiled,"FileName",(char*)addParam,0,0);
			Tlib_AddNewFiledVoid(pTlibfiled,"Wait","1",0,0);
			if(SendCmd(pspctrldata,pTlibfiled,1) <= 0)
			{
				dwConError = -2 ;
				SetErrInfo(pspctrldata, "send cmd failed,stop download failed!");
				break;
			}
			if(RecvDataAndProcess(pspctrldata,1) >= 0)
			{
				pspctrldata->bDownloading = 0;
				if(pspctrldata->stroedFile != NULL)
					fclose(pspctrldata->stroedFile);
			}
			else
			{
				dwConError = -2;
				SetErrInfo(pspctrldata,"stop download failed!");
			}

		}
		break;
	case sd_get_image_color:
		{	
			Tlib_AddNewFiledVoid(pTlibfiled,"Command_Param",cmdGetImageColor,0,0);
			Tlib_AddNewFiledVoid(pTlibfiled,"Wait","1",0,0);
			if(SendCmd(pspctrldata,pTlibfiled,1) <= 0)
			{
				dwConError = -2 ;
				SetErrInfo(pspctrldata,"send cmd failed,get image color failed!");
				break;
			}
			if(RecvDataAndProcess(pspctrldata,1) != 1)
			{
				dwConError = -2 ;
				//SetErrInfo(pspctrldata, "get image color failed!");
			}
		}
		break;
	case sd_set_image_color:
		{
			Tlib_AddNewFiledVoid(pTlibfiled,"Command_Param",cmdSetImageColor,0,0);
			Tlib_AddNewFiledInt(pTlibfiled,"Brightness",pspctrldata->brightness,0,0);
			Tlib_AddNewFiledInt(pTlibfiled,"Contrast",pspctrldata->contrast,0,0);
			Tlib_AddNewFiledInt(pTlibfiled,"Saturation",pspctrldata->saturation,0,0);
			Tlib_AddNewFiledInt(pTlibfiled,"Hue",pspctrldata->hue,0,0);
			Tlib_AddNewFiledVoid(pTlibfiled,"Wait","1",0,0);
			if(SendCmd(pspctrldata,pTlibfiled,1) <= 0 )
			{
				dwConError = -2 ;
				SetErrInfo(pspctrldata, "send cmd failed,set image color failed!");
				break;
			}
			if(RecvDataAndProcess(pspctrldata,1) != 1)
			{
				dwConError = -2 ;
				//SetErrInfo(pspctrldata, "set image color failed!");
			}
		}
		break;
	case sd_get_resolution:
		{
			Tlib_AddNewFiledVoid(pTlibfiled,"Command_Param",cmdGetResolution,0,0);
			Tlib_AddNewFiledVoid(pTlibfiled,"Wait","1",0,0);
			if(SendCmd(pspctrldata,pTlibfiled,1) <= 0)
			{
				dwConError = -2 ;
				SetErrInfo(pspctrldata,"send cmd failed,get resolution failed!");
				break;
			}
			ClearAVResolution(pspctrldata);
			if(RecvDataAndProcess(pspctrldata,1) != 1)
			{
				dwConError = -2 ;
				//SetErrInfo(pspctrldata,"get resolution failed!");
			}
		}
		break;
	case sd_set_resolution:
		{
			char psend[1024] = {0};
			int count = pspctrldata->rescount;
			char pTemp[256] = {0};

			Tlib_AddNewFiledVoid(pTlibfiled,"Command_Param",cmdSetResolution,0,0);
#ifdef WIN32
			_snprintf(pTemp,256,"%d@",count);
#else
			snprintf(pTemp,256,"%d@",count);
#endif
			strcat(psend,pTemp);
			for (i = 0; i < count; i++)
			{
				memset(pTemp,0,sizeof(pTemp));
#ifdef WIN32
				_snprintf(pTemp,256,"%s(%dX%d)@%d@%d@%d",pspctrldata->arrAVResolution[i].resName,pspctrldata->arrAVResolution[i].width,pspctrldata->arrAVResolution[i].height,pspctrldata->arrAVResolution[i].frameRate,pspctrldata->arrAVResolution[i].bitRate,pspctrldata->arrAVResolution[i].iGap);
#else
				snprintf(pTemp,256,"%s(%dX%d)@%d@%d@%d",pspctrldata->arrAVResolution[i].resName,pspctrldata->arrAVResolution[i].width,pspctrldata->arrAVResolution[i].height,pspctrldata->arrAVResolution[i].frameRate,pspctrldata->arrAVResolution[i].bitRate,pspctrldata->arrAVResolution[i].iGap);
#endif
				strcat(psend,pTemp);

				if(i  != count - 1)
				{
					strcat(psend,"@");
				}
			}
			Tlib_AddNewFiledVoid(pTlibfiled,"AVedioResolution",psend,0,0);
			Tlib_AddNewFiledVoid(pTlibfiled,"Wait","1",0,0);
			if(SendCmd(pspctrldata,pTlibfiled,1) <= 0)
			{
				dwConError = -2 ;
				SetErrInfo(pspctrldata,"send failed,set resolution failed!");
				break;
			}
			if(RecvDataAndProcess(pspctrldata,1) != 1)
			{
				dwConError = -2 ;
				//SetErrInfo(pspctrldata, "set resolution failed!");
			}
		}
		break;
	case sd_query_wifi:
		{
			Tlib_AddNewFiledVoid(pTlibfiled,"Command_Param",cmdGetWifiList,0,0);
			Tlib_AddNewFiledVoid(pTlibfiled,"Wait","1",0,0);
			if(SendCmd(pspctrldata,pTlibfiled,1) <= 0)
			{
				dwConError = -2 ;
				SetErrInfo(pspctrldata, "send cmd failed,query wifi failed!");
				break;
			}
			if(RecvDataAndProcess(pspctrldata,1) != 1)
			{
				dwConError = -2 ;
				//SetErrInfo(pspctrldata, "query wifi failed!");
			}
		}
		break;
	case sd_set_wifi:
	case set_ap_info:
		{
			if(type == sd_set_wifi)
				Tlib_AddNewFiledVoid(pTlibfiled,"Command_Param",cmdSetWifi,0,0);
			else if (type == set_ap_info)
				Tlib_AddNewFiledVoid(pTlibfiled,"Command_Param",cmdSetApInfo,0,0);
			if(pspctrldata->wificount > 0)
			{
				char psend[1024] = {0};
				char pSSid[128] = {0};
				char pPwd[128] = {0};
				//用@@表示@符号；@表示分隔符
				int iI = 0,iJ = 0;
				while (pspctrldata->arrWifi->wifiSsid[iI] != '\0')
				{
					if (pspctrldata->arrWifi->wifiSsid[iI] == '@')
					{
						pSSid[iJ++] = '@';
						pSSid[iJ++] = '@';
					}
					else
					{
						pSSid[iJ++] = pspctrldata->arrWifi->wifiSsid[iI];
					}
					iI++;
				}
				strcat(psend,pSSid);
				strcat(psend,"@");
				iI = 0;
				iJ = 0;
				while (pspctrldata->arrWifi->password[iI] != '\0')
				{
					if (pspctrldata->arrWifi->password[iI] == '@')
					{
						pPwd[iJ++] = '@';
						pPwd[iJ++] = '@';
					}
					else
					{
						pPwd[iJ++] = pspctrldata->arrWifi->password[iI];
					}
					iI++;
				}
				strcat(psend,pPwd);
				strcat(psend,"@");
				if(type == sd_set_wifi)
				{
					Tlib_AddNewFiledVoid(pTlibfiled,"WifiListInfo",psend,0,0);
					Tlib_AddNewFiledVoid(pTlibfiled,"WifiSsid",pSSid,0,0);
					Tlib_AddNewFiledVoid(pTlibfiled,"WifiPwd",pPwd,0,0);
				}
				else if (type == set_ap_info)
				{
					Tlib_AddNewFiledVoid(pTlibfiled,"ApInfo",psend,0,0);
				}
			}
			Tlib_AddNewFiledVoid(pTlibfiled,"Wait","1",0,0);
			if (SendCmd(pspctrldata,pTlibfiled,1) <= 0)
			{
				dwConError = -2;
				if(type == sd_set_wifi)
					SetErrInfo(pspctrldata, "send failed,set wifi failed!");
				else if (type == set_ap_info)
					SetErrInfo(pspctrldata, "send failed,set ap failed!");
				break;
			}

			if(RecvDataAndProcess(pspctrldata,1) != 1)
			{
				dwConError = 3;
				if(type == sd_set_wifi)
					SetErrInfo(pspctrldata,"if network is break,set success");
				else if (type == set_ap_info) //ap设置之后，断网
					SetErrInfo(pspctrldata,"if network is break,set success");
			}
			else
			{
				if ((type == sd_set_wifi && pspctrldata->m_setWifi) || (type == set_ap_info && pspctrldata->m_setAp) )
				{
					dwConError = 0;
				}
				else
				{
					dwConError = -2;
				}
			}
		}
		break;
	case sd_get_worken:
		{
			Tlib_AddNewFiledVoid(pTlibfiled,"Command_Param",cmdGetWorkEn,0,0);
			Tlib_AddNewFiledVoid(pTlibfiled,"Wait","1",0,0);
			if(SendCmd(pspctrldata,pTlibfiled,1) <= 0)
			{
				dwConError = -2;
				SetErrInfo(pspctrldata,"send failed, get worken failed!");
				break;
			}
			if(RecvDataAndProcess(pspctrldata,1) != 1)
			{
				dwConError = -2;
				//SetErrInfo(pspctrldata,"get worken failed!");
			}
		}	
		break;
	case sd_set_worken:
		{
			Tlib_AddNewFiledVoid(pTlibfiled,"Command_Param",cmdSetWorkEn,0,0);
			Tlib_AddNewFiledVoid(pTlibfiled,"SensorMode",(char*)addParam,0,0);
			Tlib_AddNewFiledVoid(pTlibfiled,"Wait","1",0,0);
			if(SendCmd(pspctrldata,pTlibfiled,1) <= 0)
			{
				dwConError = -2;
				SetErrInfo(pspctrldata,"send failed, set worken failed!");
				break;
			}

			if(RecvDataAndProcess(pspctrldata,1) != 1)
			{
				dwConError = -2;
				//SetErrInfo(pspctrldata,"set worken failed!");
			}
		}
		break;
	case sd_query_daylogs:
		{
			Tlib_AddNewFiledVoid(pTlibfiled,"Command_Param",cmdQueryDayLog,0,0);
			Tlib_AddNewFiledVoid(pTlibfiled,"Wait","1",0,0);
			if(SendCmd(pspctrldata,pTlibfiled,1) <= 0)
			{
				dwConError = -2;
				SetErrInfo(pspctrldata, "send failed, query day logs failed!");
				break;
			}

			if(RecvDataAndProcess(pspctrldata,1) != 1)
			{
				dwConError = -2;
				//SetErrInfo(pspctrldata,"query day logs failed!");
			}
		}
		break;
	case sd_set_default_color:
		{
			Tlib_AddNewFiledVoid(pTlibfiled,"Command_Param",cmdSetDefaultColor,0,0);
			Tlib_AddNewFiledVoid(pTlibfiled,"Wait","1",0,0);
			if(SendCmd(pspctrldata,pTlibfiled,1) <= 0)
			{
				dwConError = -2;
				SetErrInfo(pspctrldata,"send failed, set_default_color failed!");
				break;
			}

			if(RecvDataAndProcess(pspctrldata,1) != 1)
			{
				dwConError = -2;
				//SetErrInfo(pspctrldata, "set_default_color failed!");
			}
		}
		break;
	case sd_get_rtsp_audio_switch:
		{
			Tlib_AddNewFiledVoid(pTlibfiled,"Command_Param",cmdGetRtspAudioSwitch,0,0);
			Tlib_AddNewFiledVoid(pTlibfiled,"Wait","1",0,0);
			if(SendCmd(pspctrldata,pTlibfiled,1) <= 0)
			{
				dwConError = -2;
				SetErrInfo(pspctrldata,"send failed, get_rtsp_audio_switch failed!");
				break;
			}

			if(RecvDataAndProcess(pspctrldata,1) != 1)
			{
				dwConError = -2;
				//SetErrInfo(pspctrldata,"get_rtsp_audio_switch failed!");
			}
		}
		break;
	case sd_set_rtsp_audio_switch:
		{
			Tlib_AddNewFiledVoid(pTlibfiled,"Command_Param",cmdSetRtspAudioSwitch,0,0);
			Tlib_AddNewFiledInt(pTlibfiled,"RtspAudioSwitch",pspctrldata->bRtspOn,0,0);
			Tlib_AddNewFiledVoid(pTlibfiled,"Wait","1",0,0);
			if(SendCmd(pspctrldata,pTlibfiled,1) <= 0)
			{
				dwConError = -2;
				SetErrInfo(pspctrldata, "send failed, set_rtsp_audio_switch failed!");
				break;
			}

			if(RecvDataAndProcess(pspctrldata,1) != 1)
			{
				dwConError = -2;
				//SetErrInfo(pspctrldata,"set_rtsp_audio_switch failed!");
			}
		}
		break;
	case sd_get_noise_lvl:
		{
			Tlib_AddNewFiledVoid(pTlibfiled,"Command_Param",cmdGetNoiseLvl,0,0);
			Tlib_AddNewFiledVoid(pTlibfiled,"Wait","1",0,0);
			if(SendCmd(pspctrldata,pTlibfiled,1) <= 0)
			{
				dwConError = -2;
				SetErrInfo(pspctrldata,"send failed, get_noise_lvl failed!");
				break;
			}

			if(RecvDataAndProcess(pspctrldata,1) != 1)
			{
				dwConError = -2;
				//SetErrInfo(pspctrldata,"get_noise_lvl failed!");
			}
		}
		break;
	case sd_set_noise_lvl:
		{
			Tlib_AddNewFiledVoid(pTlibfiled,"Command_Param",cmdSetNoiseLvl,0,0);
			Tlib_AddNewFiledInt(pTlibfiled,"LowLightNoiseLvl",pspctrldata->noiseLvl,0,0);
			Tlib_AddNewFiledVoid(pTlibfiled,"Wait","1",0,0);
			if(SendCmd(pspctrldata,pTlibfiled,1) <= 0)
			{
				dwConError = -2;
				SetErrInfo(pspctrldata, "send failed, set_noise_lvl failed!");
				break;
			}

			if(RecvDataAndProcess(pspctrldata,1) != 1)
			{
				dwConError = -2;
				//SetErrInfo(pspctrldata, "set_noise_lvl failed!");
			}
		}
		break;
	case set_song:
		{
			Tlib_AddNewFiledVoid(pTlibfiled,"Command_Param",cmdDefaultYelpReq,0,0);
			Tlib_AddNewFiledVoid(pTlibfiled,"Alarmtone",(char*)addParam,0,0);
			Tlib_AddNewFiledVoid(pTlibfiled,"Wait","1",0,0);
			if(SendCmd(pspctrldata,pTlibfiled,1) <= 0)
			{
				dwConError = -2;
				SetErrInfo(pspctrldata, "send failed, set alarm ring failed!");
				break;
			}

			if(RecvDataAndProcess(pspctrldata,1) != 1)
			{
				dwConError = -2;
				//SetErrInfo(pspctrldata, "set alarm ring failed!");
			}
		}
		break;
	case play_or_stop_song:
		{
			if (strcmp(addParam,"0") == 0)
			{
				Tlib_AddNewFiledVoid(pTlibfiled,"Command_Param",cmdStopYelp,0,0);
			}
			else
			{
				Tlib_AddNewFiledVoid(pTlibfiled,"Command_Param",cmdProtocolPlayYelp,0,0);
			}
			Tlib_AddNewFiledVoid(pTlibfiled,"Wait","1",0,0);
			if(SendCmd(pspctrldata,pTlibfiled,1) <= 0)
			{
				dwConError = -2;
				SetErrInfo(pspctrldata, "send failed, play_or_stop_song failed!");
				break;
			}

			if(RecvDataAndProcess(pspctrldata,1) != 1)
			{
				dwConError = -2;
				//SetErrInfo(pspctrldata, "play_or_stop_song failed!");
			}
			dwConError = 3;
		}
		break;
	case start_speak:
	case stop_speak:
		{
			if(type == start_speak)
				Tlib_AddNewFiledVoid(pTlibfiled,"Command_Param",cmdProtocolIntercom,0,0);
			else
				Tlib_AddNewFiledVoid(pTlibfiled,"Command_Param",cmdStopIntercomReq,0,0);
			Tlib_AddNewFiledVoid(pTlibfiled,"Wait","1",0,0);
			if(SendCmd(pspctrldata,pTlibfiled,1) <= 0)
			{
				dwConError = -2;
				SetErrInfo(pspctrldata, "send failed, start_speak failed!");
				break;
			}

			if(RecvDataAndProcess(pspctrldata,1) != 1)
			{
				dwConError = -2;
				//SetErrInfo(pspctrldata, "start_speak failed!");
			}
		}
		break;
	case send_speak_data:
		{
			SSpeakData* data = (SSpeakData*)addParam;

			Tlib_AddNewFiledVoid(pTlibfiled,"Command_Param",cmdProtocolIntercomData,0,0);
			Tlib_AddNewFiledVoid(pTlibfiled,"audiodata",data->data,strlen("audiodata"),data->len);
			Tlib_AddNewFiledVoid(pTlibfiled,"Wait","1",0,0);
			if(SendCmd(pspctrldata,pTlibfiled,1) <= 0)
			{
				dwConError = -2;
				SetErrInfo(pspctrldata, "send failed, send_speak_data failed!");
				break;
			}

			if(RecvDataAndProcess(pspctrldata,1) != 1)
			{
				dwConError = -2;
				//SetErrInfo(pspctrldata, "send_speak_data failed!");
			}
		}
		break;
	case get_device_attr:
		{
			Tlib_AddNewFiledVoid(pTlibfiled,"Command_Param",cmdGetDeviceInfo,0,0);
			Tlib_AddNewFiledVoid(pTlibfiled,"Wait","1",0,0);
			if(SendCmd(pspctrldata,pTlibfiled,1) <= 0)
			{
				dwConError = -2;
				SetErrInfo(pspctrldata, "send failed, get_device_attr failed!");
				break;
			}

			if(RecvDataAndProcess(pspctrldata,1) != 1)
			{
				dwConError = -2;
				//SetErrInfo(pspctrldata, "get_device_attr failed!");
			}
		}
		break;
	case delete_file:
		{
			Tlib_AddNewFiledVoid(pTlibfiled,"Command_Param",cmdMediaDeleteReq,0,0);
			Tlib_AddNewFiledVoid(pTlibfiled,"FileName",(void*)addParam,0,0);
			Tlib_AddNewFiledVoid(pTlibfiled,"Wait","1",0,0);
			if(SendCmd(pspctrldata,pTlibfiled,1) <= 0)
			{
				dwConError = -2;
				SetErrInfo(pspctrldata, "send failed, delete_file failed!");
				break;
			}

			if(RecvDataAndProcess(pspctrldata,1) != 1)
			{
				dwConError = -2;
			}
		}
		break;
	case set_surveillance:
		{
			SSurveillance* sparam = (SSurveillance*)addParam;
			Tlib_AddNewFiledVoid(pTlibfiled,"Command_Param",cmdSetSurveillance,0,0);
			if (sparam->type == 1)
			{
				int sensitivity[3] = {3,2,1};
				if(sparam->nswitch == 0)
					Tlib_AddNewFiledInt(pTlibfiled,"Sensitivity",0,0,0);
				else
					Tlib_AddNewFiledInt(pTlibfiled,"Sensitivity",sensitivity[sparam->sensitivity],0,0);
			}
			else if (sparam->type == 2)
			{
				Tlib_AddNewFiledInt(pTlibfiled,"TemperatureType",sparam->tempType,0,0);
				Tlib_AddNewFiledVoid(pTlibfiled,"Upperlimit",sparam->upperlimit,0,0);
				Tlib_AddNewFiledVoid(pTlibfiled,"Lowerlimit",sparam->lowerlimit,0,0);
			}
			Tlib_AddNewFiledInt(pTlibfiled,"Switch",sparam->nswitch,0,0);
			Tlib_AddNewFiledInt(pTlibfiled,"Type",sparam->type,0,0);
			Tlib_AddNewFiledVoid(pTlibfiled,"Wait","1",0,0);
			if(SendCmd(pspctrldata,pTlibfiled,1) <= 0)
			{
				dwConError = -2;
				SetErrInfo(pspctrldata, "send failed, set_surveillance failed!");
				break;
			}

			if(RecvDataAndProcess(pspctrldata,1) != 1)
			{
				dwConError = -2;
				//SetErrInfo(pspctrldata, "set_surveillance failed!");
			}
		}
		break;
	case set_pwm3:
		{
			Tlib_AddNewFiledVoid(pTlibfiled,"Command_Param",cmdSetPwm3,0,0);
			Tlib_AddNewFiledVoid(pTlibfiled,"pwm3",addParam,0,0);
			Tlib_AddNewFiledVoid(pTlibfiled,"Wait","1",0,0);
			if(SendCmd(pspctrldata,pTlibfiled,1) <= 0)
			{
				dwConError = -2;
				SetErrInfo(pspctrldata, "send failed, set pwm3 failed!");
				break;
			}

			if(RecvDataAndProcess(pspctrldata,1) != 1)
			{
				dwConError = -2;
			}
		}
		break;
	case get_pwm3:
		{
			Tlib_AddNewFiledVoid(pTlibfiled,"Command_Param",cmdGetPwm3,0,0);
			Tlib_AddNewFiledVoid(pTlibfiled,"Wait","1",0,0);
			if(SendCmd(pspctrldata,pTlibfiled,1) <= 0)
			{
				dwConError = -2;
				SetErrInfo(pspctrldata, "send failed, get pwm3 failed!");
				break;
			}

			if(RecvDataAndProcess(pspctrldata,1) != 1)
			{
				dwConError = -2;
			}
		}
		break;
	case ack_sys_req_record:
		{
			SysReqCmdAck *sysack = (SysReqCmdAck*)addParam;
			Tlib_AddNewFiledVoid(pTlibfiled,"Command_Param",cmdSysReqRecordAck,0,0);
			Tlib_AddNewFiledInt(pTlibfiled,"Ret",sysack->ret,0,0);
			Tlib_AddNewFiledInt(pTlibfiled,"Type",sysack->type,0,0);
			Tlib_AddNewFiledVoid(pTlibfiled,"Wait","1",0,0);
			if(SendCmd(pspctrldata,pTlibfiled,1) <= 0)
			{
				dwConError = -2;
				SetErrInfo(pspctrldata, "send failed, ack sys_req_record failed!");
				break;
			}
		}
		break;
	case ack_sys_req_shutdown:
		{
			SysReqCmdAck *sysack = (SysReqCmdAck*)addParam;
			Tlib_AddNewFiledVoid(pTlibfiled,"Command_Param",cmdSysReqShutdownAck,0,0);
			Tlib_AddNewFiledInt(pTlibfiled,"Ret",sysack->ret,0,0);
			Tlib_AddNewFiledVoid(pTlibfiled,"Wait","1",0,0);
			if(SendCmd(pspctrldata,pTlibfiled,1) <= 0)
			{
				dwConError = -2;
				SetErrInfo(pspctrldata, "send failed, ack sys_req_shutdown failed!");
				break;
			}
		}
		break;
	case sys_req_led:
		{
			SysReqCmd* cmdtmp = (SysReqCmd*)addParam;
			Tlib_AddNewFiledVoid(pTlibfiled,"Command_Param",cmdSysReqLed,0,0);
			Tlib_AddNewFiledInt(pTlibfiled,"Led",cmdtmp->led,0,0);
			Tlib_AddNewFiledVoid(pTlibfiled,"Wait","1",0,0);
			if(SendCmd(pspctrldata,pTlibfiled,1) <= 0)
			{
				dwConError = -2;
				SetErrInfo(pspctrldata, "send failed, sys_req_led failed!");
				break;
			}

			if(RecvDataAndProcess(pspctrldata,1) != 1)
			{
				dwConError = -2;
			}
		}
		break;
	}

	pr_debug("Tlib_DestroyFiled(pTlibfiled) = %p\n",pTlibfiled);
	Tlib_DestroyFiled(pTlibfiled);

	if (dwConError == 3)
	{
		dwConError = 0;
	}
	
	pr_debug("DoDealWithReq END!\n");

	return dwConError;
}

void SetDownloadSavePath(SPCtrlData* pspctrldata, const char* strPath )
{
	if(pspctrldata->strdownloadsavePath != NULL)
	{
		free(pspctrldata->strdownloadsavePath);
		pspctrldata->strdownloadsavePath = NULL;
	}

	pspctrldata->strdownloadsavePath = (char*)malloc(strlen(strPath) + 1);
	memset(pspctrldata->strdownloadsavePath,0,strlen(strPath) + 1);
	strcpy(pspctrldata->strdownloadsavePath,strPath);
}

void GetImageColor(SPCtrlData* pspctrldata,int *brightness,int *contrast, int *saturation,int *hue)
{
	*brightness = pspctrldata->brightness;
	*contrast = pspctrldata->contrast;
	*saturation = pspctrldata->saturation;
	*hue = pspctrldata->hue;
}

int SetImageColor(SPCtrlData* pspctrldata, int brightness,int contrast, int saturation,int hue )
{
	pspctrldata->brightness = brightness;
	pspctrldata->contrast = contrast;
	pspctrldata->saturation = saturation;
	pspctrldata->hue = hue;

	return DoDealWithReq(pspctrldata,COMMAND_C_S_TRANSMIT_REQ,sd_set_image_color,NULL);
}

int QueryResolution(SPCtrlData* pspctrldata )
{
	ClearAVResolution(pspctrldata);
	return DoDealWithReq(pspctrldata,COMMAND_C_S_TRANSMIT_REQ,sd_get_resolution,NULL);
}

int SetResolution(SPCtrlData* pspctrldata)
{
 	return DoDealWithReq(pspctrldata,COMMAND_C_S_TRANSMIT_REQ,sd_set_resolution,NULL);
}

int QueryWifiList( SPCtrlData* pspctrldata)
{
	ClearWifiList(pspctrldata);
 	return DoDealWithReq(pspctrldata,COMMAND_C_S_TRANSMIT_REQ,sd_query_wifi,NULL);
}

int SetApInfo( SPCtrlData* pspctrldata,WifiInfoN *wifiInfo )
{
	ClearWifiList(pspctrldata);
	pspctrldata->wificount = 1;

	pspctrldata->arrWifi = (WifiInfoN*)malloc(sizeof(WifiInfoN));
	memset(pspctrldata->arrWifi,0,sizeof(WifiInfoN));
	memcpy(pspctrldata->arrWifi,wifiInfo,sizeof(WifiInfoN));
	pspctrldata->m_setAp = 0;

	return DoDealWithReq(pspctrldata,COMMAND_C_S_TRANSMIT_REQ,set_ap_info,NULL);
}

int SetWifiInfo( SPCtrlData* pspctrldata,WifiInfoN *wifiInfo )
{
	ClearWifiList(pspctrldata);
	pspctrldata->wificount = 1;

	pspctrldata->arrWifi = (WifiInfoN*)malloc(sizeof(WifiInfoN));
	memset(pspctrldata->arrWifi,0,sizeof(WifiInfoN));
	memcpy(pspctrldata->arrWifi,wifiInfo,sizeof(WifiInfoN));
	pspctrldata->m_setWifi = 0;

 	return DoDealWithReq(pspctrldata,COMMAND_C_S_TRANSMIT_REQ,sd_set_wifi,NULL);
}

int QueryImageColor(SPCtrlData* pspctrldata)
{
	return DoDealWithReq(pspctrldata,COMMAND_C_S_TRANSMIT_REQ,sd_get_image_color,NULL);
}

int SetWorkEnvironment( SPCtrlData* pspctrldata,int nType )
{
	pspctrldata->workEnType = nType;
	return DoDealWithReq(pspctrldata,COMMAND_C_S_TRANSMIT_REQ,sd_set_worken,NULL);
}

int QueryWorkEnvironment(SPCtrlData* pspctrldata)
{
	return DoDealWithReq(pspctrldata,COMMAND_C_S_TRANSMIT_REQ,sd_get_worken,NULL);
}

int QueryDayLog( SPCtrlData* pspctrldata,const char * strTime )
{
	return DoDealWithReq(pspctrldata,COMMAND_C_S_TRANSMIT_REQ,sd_query_daylogs,strTime);
}

int SetDefaultImageColor(SPCtrlData* pspctrldata)
{
	return DoDealWithReq(pspctrldata,COMMAND_C_S_TRANSMIT_REQ,sd_set_default_color,NULL);
}

int QueryRtspSwitchStatus(SPCtrlData* pspctrldata)
{
	return DoDealWithReq(pspctrldata,COMMAND_C_S_TRANSMIT_REQ,sd_get_rtsp_audio_switch,NULL);
}

int SetRtspSwicthStatus(SPCtrlData* pspctrldata, int bOn )
{
	pspctrldata->bRtspOn = bOn;
	return DoDealWithReq(pspctrldata,COMMAND_C_S_TRANSMIT_REQ,sd_set_rtsp_audio_switch,NULL);
}

int QueryNoiseLvl(SPCtrlData* pspctrldata)
{
	return DoDealWithReq(pspctrldata,COMMAND_C_S_TRANSMIT_REQ,sd_get_noise_lvl,NULL);
}

int SetNoiseLvl(SPCtrlData* pspctrldata, int noiseLvl )
{
	pspctrldata->noiseLvl = noiseLvl;
	return DoDealWithReq(pspctrldata,COMMAND_C_S_TRANSMIT_REQ,sd_set_noise_lvl,NULL);
}

int VerifyByDevice(SPCtrlData* pspctrldata)
{
	TlibFieldAx* plibfield = NULL;
	if(pspctrldata == NULL)
		return -1;
	plibfield = Tlib_CreateFiled();
	if(plibfield == NULL)
		return 0;

	Tlib_SetCommand(plibfield,COMMAND_C_S_TRANSMIT_LOGIN_REQ);
	Tlib_AddNewFiledVoid(plibfield,"UserName",pspctrldata->username,0,0);
	Tlib_AddNewFiledVoid(plibfield,"Password",pspctrldata->password,0,0);		
	Tlib_AddNewFiledVoid(plibfield,"DeviceSerial",pspctrldata->devid,0,0);
	SendCmd(pspctrldata,plibfield,1);

	Tlib_DestroyFiled(plibfield);
	plibfield = NULL;

	return 0;
}

int Ptz( SPCtrlData* pspctrldata,int cmd )
{
	TlibFieldAx* plibfield = NULL;
	if(pspctrldata == NULL)
		return -1;
	plibfield = Tlib_CreateFiled();
	if(plibfield == NULL)
		return 0;

	Tlib_SetCommand(plibfield,COMMAND_C_S_TRANSMIT_REQ);
	switch (cmd)
	{
	case ptz_left:
		Tlib_AddNewFiledVoid(plibfield,"Command_Param",cmdPtzLeft,0,0);
		break;
	case ptz_right:
		Tlib_AddNewFiledVoid(plibfield,"Command_Param",cmdPtzRight,0,0);
		break;
	case ptz_up:
		Tlib_AddNewFiledVoid(plibfield,"Command_Param",cmdPtzUp,0,0);
		break;
	case ptz_down:
		Tlib_AddNewFiledVoid(plibfield,"Command_Param",cmdPtzDown,0,0);
		break;
	case ptz_zoon_in:
		Tlib_AddNewFiledVoid(plibfield,"Command_Param",cmdPtzZoonin,0,0);
		break;
	case ptz_zoon_out:
		Tlib_AddNewFiledVoid(plibfield,"Command_Param",cmdPtzZoonOut,0,0);
		break;
	case ptz_h_scan:
		Tlib_AddNewFiledVoid(plibfield,"Command_Param",cmdPtzHscan,0,0);
		break;
	case ptz_v_scan:
		Tlib_AddNewFiledVoid(plibfield,"Command_Param",cmdPtzVscan,0,0);
		break;
	case ptz_auto_sacn:
		Tlib_AddNewFiledVoid(plibfield,"Command_Param",cmdPtzAutoScan,0,0);
		break;
	case ptz_stop_scan:
		Tlib_AddNewFiledVoid(plibfield,"Command_Param",cmdPtzStopScan,0,0);
		break;
	case ptz_mirror:
		Tlib_AddNewFiledVoid(plibfield,"Command_Param",cmdPtzMirror,0,0);
		break;
	case ptz_flip:
		Tlib_AddNewFiledVoid(plibfield,"Command_Param",cmdPtzFlip,0,0);
		break;
	case ptz_keep_left:
		Tlib_AddNewFiledVoid(plibfield,"Command_Param",cmdPtzKeepLeft,0,0);
		break;
	case ptz_keep_right:
		Tlib_AddNewFiledVoid(plibfield,"Command_Param",cmdPtzKeepRight,0,0);
		break;
	case ptz_keep_up:
		Tlib_AddNewFiledVoid(plibfield,"Command_Param",cmdPtzKeepUp,0,0);
		break;
	case ptz_keep_down:
		Tlib_AddNewFiledVoid(plibfield,"Command_Param",cmdPtzKeepDown,0,0);
		break;
	}
	SendCmd(pspctrldata,plibfield,1);

	Tlib_DestroyFiled(plibfield);
	plibfield = NULL;

	return 0;
}

//by liwo
int TakePhoto(SPCtrlData* pspctrldata, int cmd)
{
	TlibFieldAx* plibfield = NULL;
	if(pspctrldata == NULL)
		return -1;

	if(__ReconnectDev(pspctrldata))
	{
		return -2;
	}

	plibfield = Tlib_CreateFiled();
	if(plibfield == NULL)
		return 0;

	Tlib_SetCommand(plibfield, COMMAND_C_S_TRANSMIT_REQ);

	Tlib_AddNewFiledVoid(plibfield, "Command_Param", cmdTakePhoto, 0, 0);

	SendCmd(pspctrldata,plibfield,1);

	Tlib_DestroyFiled(plibfield);
	plibfield = NULL;

	pr_debug("send take photo:%s\n", cmdTakePhoto);

	if(RecvDataAndProcess(pspctrldata,1) != 1)
	{
	}

	return 0;
}

//by liwo
int SetTime(SPCtrlData* pspctrldata, SetTime_S* pTime)
{
	TlibFieldAx* plibfield = NULL;

	if(pspctrldata == NULL || pTime == NULL)
	{
		return -1;
	}

	if(__ReconnectDev(pspctrldata))
	{
		return -2;
	}

	plibfield = Tlib_CreateFiled();
	if(!plibfield)
	{
		return -3;
	}

	Tlib_SetCommand(plibfield, COMMAND_C_S_TRANSMIT_REQ);
	Tlib_AddNewFiledVoid(plibfield, "Command_Param", cmdTimeReq, 0, 0);
	Tlib_AddNewFiledVoid(plibfield, "Date", pTime->date, 0, 0);
	Tlib_AddNewFiledVoid(plibfield, "Time", pTime->time, 0, 0);
	SendCmd(pspctrldata, plibfield, 1);
	if(plibfield)
	{
		Tlib_DestroyFiled(plibfield);
		plibfield = NULL;
	}

	if(RecvDataAndProcess(pspctrldata, 1) != 1)
	{
		pr_debug("receive set time ack error\n");
	}
	return 0;
}

int GetCurTempHum( SPCtrlData* pspctrldata )
{
	return DoDealWithReq(pspctrldata,COMMAND_C_S_TRANSMIT_REQ,get_cur_temp_hum,NULL);
}

int EnableMotion( SPCtrlData* pspctrldata,SSwitchMotion * motion )
{
	if (motion && pspctrldata)
	{
		memcpy(&pspctrldata->m_motion,motion,sizeof(SSwitchMotion));
	}
	return DoDealWithReq(pspctrldata,COMMAND_C_S_TRANSMIT_REQ,enable_motion,NULL);
}

int ResetFactory( SPCtrlData* pspctrldata )
{
	return DoDealWithReq(pspctrldata,COMMAND_C_S_TRANSMIT_REQ,reset_factory,NULL);
}

int TransparentCmd( SPCtrlData* pspctrldata,const char *cmd )
{
	return DoDealWithReq(pspctrldata,COMMAND_C_S_TRANSMIT_REQ,trans_cmd,cmd);
}

int FindCurHumTemp(SCurTempHum* curHum,char *curTempStr)
{
	if (curTempStr && curHum)
	{
		char curTime[32] = {0};
		char *pFind = NULL;
		char *tempStr = NULL;
		memset(curHum->curHum,0,sizeof(curHum->curHum));
		memset(curHum->curTemp,0,sizeof(curHum->curTemp));
 		if ((pFind = strstr(curTempStr,"@")) != NULL)
 		{
			if(pFind-curTempStr > 32 || pFind-curTempStr <= 0)
				return -1;
			//pr_debug("curTime,curTempStr,pFind-curTempStr %s,%s,%d\n",curTime,curTempStr,pFind-curTempStr);
			memcpy(curTime,curTempStr,pFind-curTempStr);
			curHum->curtime = atoi(curTime);
			pFind += 1;
			tempStr = pFind;
			if ((pFind = strstr(tempStr,"@")) != NULL)
			{
				if(pFind-tempStr > 32 || pFind-curTempStr <= 0)
					return -1;
				//pr_debug("curHum->curTemp,tempStr,pFind-tempStr %s,%s,%d\n",curHum->curTemp,tempStr,pFind-tempStr);
				memcpy(curHum->curTemp,tempStr,pFind-tempStr);
				pFind += 1;
				tempStr = pFind;
				if ((pFind = strstr(tempStr,"@")) != NULL)
				{
					if(pFind-tempStr > 32 || pFind-curTempStr <= 0)
						return -1;
					//pr_debug("curHum->curHum,tempStr,pFind-tempStr %s,%s,%d\n",curHum->curHum,tempStr,pFind-tempStr);
					memcpy(curHum->curHum,tempStr,pFind-tempStr);
				}
				else
				{
					int len = strlen(tempStr);
					pr_debug("curHum->curHum,tempStr %s,%s\n",curHum->curHum,tempStr);
					len = len > sizeof(curHum->curHum) ? sizeof(curHum->curHum) : len;
					strncpy(curHum->curHum,tempStr,len);
				}
			}
 		}
		return 0;
	}
	return -1;
}

int FindCount(char *pSrc,char* pFind)
{
	if (pSrc == NULL || pFind == NULL)
	{
		return 0;
	}
	else
	{
		int nCount = 0;
		char *pTemp = pSrc;
		char* pLeft = NULL;
		while ((pLeft = strstr(pTemp,pFind)) != NULL)
		{
			pTemp = pLeft + 1;
			nCount++;
		}
		return nCount;
	}
}

int ParseDayEventList(SSdcardRecQuery *query,char *pSrc,int bDay)
{
	if (query == NULL || pSrc == NULL)
	{
		return -1;
	}
	else
	{
		//解析出录像文件列表
		char* pFind = NULL;
		char* pLeft = pSrc;
		int nIndex = 0;
		int totallen = strlen(pSrc);
		int nCount = FindCount(pSrc,"|");
		query->subCount = nCount;
		if(nCount <= 0)
			return 0;
		query->plist = (SSdcardRecQuerySub *)malloc(nCount*sizeof(SSdcardRecQuerySub));
		while( (pFind = strstr(pLeft,"|")) != NULL)
		{
			if (bDay)
			{
				char pTmp[256] = {0};
				char *pFind2 = NULL;
				memcpy(pTmp,pLeft,pFind-pLeft);
				pFind2 = strstr(pTmp,"@");
				if (pFind2)
				{
					char* pTmpFind = NULL;
					memset(query->plist[nIndex].file,0,sizeof(query->plist[nIndex].file));
					memcpy(query->plist[nIndex].file,pTmp,pFind2-pTmp);
					while ((pTmpFind = strstr(pFind2+1," ")) != NULL)
					{
						pFind2 = pTmpFind+1;
					}
					query->plist[nIndex].size = atof(pFind2);
				}
				else
				{
					memset(query->plist[nIndex].file,0,sizeof(query->plist[nIndex].file));
					memcpy(query->plist[nIndex].file,pLeft,pFind-pLeft);
				}
			}
			else
			{
				char tmp[5] = {0};
				int n0 = 0;
				memset(query->plist[nIndex].day,0,sizeof(query->plist[nIndex].day));
				if(pFind-pLeft - 4 > 0)
				{
					if(pFind-pLeft - 4 > 10)
						memcpy(query->plist[nIndex].day,pLeft,8);
					else
						memcpy(query->plist[nIndex].day,pLeft,pFind-pLeft - 4);
				}
				else
				{
					if(nIndex == 0)
					{
						if (query->plist)
						{
							free(query->plist);
						}
						query->subCount = 0;
						return -1;
					}
					query->subCount = nIndex;
					break;
				}
				memcpy(tmp,pLeft+8,4);
				query->plist[nIndex].count = (tmp[0] - '0')*1000 + (tmp[1] - '0')*100 + (tmp[2] - '0')*10 + (tmp[3] - '0');
			}
			pLeft = pFind+1;
			nIndex++;
			if (pLeft >= pSrc+totallen)
			{
				break;
			}
		}
		return 0;
	}
}

int SetCurrentSong(SPCtrlData* pspctrldata,SAlarmRing* pRing)
{
	if (pspctrldata && pRing)
	{
		char pAdd[10] = {0};
		sprintf(pAdd,"%d",pRing->ringNum);
		return DoDealWithReq(pspctrldata,COMMAND_C_S_TRANSMIT_REQ,set_song,pAdd);
	}
	return -1;
}

int PlayOrStopOneSong(SPCtrlData* pspctrldata,int play)
{
	if (pspctrldata)
	{
		char pPlay[20] = {0};
		sprintf(pPlay,"%d",play);
		return DoDealWithReq(pspctrldata,COMMAND_C_S_TRANSMIT_REQ,play_or_stop_song,pPlay);
	}
	return -1;
}

int StartSpeak(SPCtrlData* pspctrldata)
{
	if (pspctrldata)
	{
		return DoDealWithReq(pspctrldata,COMMAND_C_S_TRANSMIT_REQ,start_speak,NULL);
	}
	return -1;
}

int SendSpeakData(SPCtrlData* pspctrldata,SSpeakData *data)
{
	if (pspctrldata == NULL || data == NULL)
	{
		return -1;
	}
	if (data->data == NULL || data->len == 0)
	{
		return 0;
	}
	return DoDealWithReq(pspctrldata,COMMAND_C_S_TRANSMIT_REQ,send_speak_data,(const char*)data);
}

int StopSpeak(SPCtrlData* pspctrldata)
{
	if (pspctrldata)
	{
		return DoDealWithReq(pspctrldata,COMMAND_C_S_TRANSMIT_REQ,stop_speak,NULL);
	}
	return -1;
}

int GetDeviceAttr(SPCtrlData* pspctrldata)
{
	if (pspctrldata)
	{
		return DoDealWithReq(pspctrldata,COMMAND_C_S_TRANSMIT_REQ,get_device_attr,NULL);
	}
	return -1;
}

int SetSurveillance(SPCtrlData* pspctrldata,SSurveillance* pSur)
{
	if (pspctrldata && pSur)
	{
		return DoDealWithReq(pspctrldata,COMMAND_C_S_TRANSMIT_REQ,set_surveillance,(const char*)pSur);
	}
	return -1;
}

int DeleteFile(SPCtrlData* pspctrldata , char* filename)
{
	if (pspctrldata && filename)
	{
		return DoDealWithReq(pspctrldata,COMMAND_C_S_TRANSMIT_REQ,delete_file,(const char*)filename);
	}
	return -1;
}

int SetPwm3(SPCtrlData* pspctrldata , SPwm3 *pwm)
{
	if (pspctrldata && pwm)
	{
		char ptmp[10] = {0};
		sprintf(ptmp,"%d",pwm->type);
		return DoDealWithReq(pspctrldata,COMMAND_C_S_TRANSMIT_REQ,set_pwm3,(const char*)ptmp);
	}
	return -1;
}

int GetPwm3(SPCtrlData* pspctrldata)
{
	if (pspctrldata)
	{
		return DoDealWithReq(pspctrldata,COMMAND_C_S_TRANSMIT_REQ,get_pwm3,NULL);
	}
	return -1;
}

int AckSysReqRecord(SPCtrlData* pspctrldata,SysReqCmdAck *pAck)
{
	if (pspctrldata)
	{
		return DoDealWithReq(pspctrldata,COMMAND_S_C_TRANSMIT_ACK,ack_sys_req_record,(const char*)pAck);
	}
	return -1;
}

int AckSysReqShutdown(SPCtrlData* pspctrldata,SysReqCmdAck *pAck)
{
	if (pspctrldata)
	{
		return DoDealWithReq(pspctrldata,COMMAND_S_C_TRANSMIT_ACK,ack_sys_req_shutdown,(const char*)pAck);
	}
	return -1;
}

int SysReqCmdLed(SPCtrlData* pspctrldata, SysReqCmd *pCmd)
{
	if (pspctrldata)
	{
		return DoDealWithReq(pspctrldata,COMMAND_C_S_TRANSMIT_REQ,sys_req_led,(const char*)pCmd);
	}
	return -1;
}

int GetDownProcess(SPCtrlData* pspctrldata ,SDownProcess* sdproc)
{
	if (pspctrldata && sdproc)
	{
		if (pspctrldata->fileLenBase > 0 && pspctrldata->fileLen >= 0)
		{
			sdproc->process = (pspctrldata->fileLenBase - pspctrldata->fileLen)*1.0 / pspctrldata->fileLenBase;
		}
		return 0;
	}
	return -1;
}

int DoVerifyDevice(SPCtrlData* pspctrldata )
{
	TlibFieldAx* plibfield = NULL;
	plibfield = Tlib_CreateFiled();
	if(plibfield == NULL)
		return 0;

	Tlib_SetCommand(plibfield,COMMAND_C_S_TRANSMIT_LOGIN_REQ);
	Tlib_AddNewFiledVoid(plibfield,"UserName",pspctrldata->username,0,0);
	Tlib_AddNewFiledVoid(plibfield,"Password",pspctrldata->password,0,0);		
	Tlib_AddNewFiledVoid(plibfield,"DeviceSerial",pspctrldata->devid,0,0);
	SendCmd(pspctrldata,plibfield,1);

	Tlib_DestroyFiled(plibfield);
	plibfield = NULL;

	return 0;
}
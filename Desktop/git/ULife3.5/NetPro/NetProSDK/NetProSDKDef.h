#ifndef _NETPRO_SDK_DEF_H_
#define _NETPRO_SDK_DEF_H_

#if (defined _WIN32) || (defined _WIN64)
#include "StdAfx.h"
#else
//typedef unsigned long       DWORD;
#ifndef	__stdcall
#define __stdcall
#endif
#endif


// 定义协议类型 begin
typedef enum
{
	NETPRO_USE_TUTK				= 0,	// TUTK 协议
	NETPRO_USE_4_0				= 1,	// 4.0
}eNetProType;
// 定义协议类型 end

// 定义协议类型 begin
typedef enum
{
	NETPRO_ENABLE_ALL			= 0,	// 启用所有
	NETPRO_ONLY_P2P,					// 只打洞
	NETPRO_ONLY_RELAY,					// 只转发
}eNetProTransportProType;
// 定义协议类型 end

// 定义设备码流类型 begin
typedef enum
{
	NETPRO_STREAM_HD			= 0x00,	// 高清
	NETPRO_STREAM_SD			= 0x01,	// 标清
}eNetVideoStreamType;
// 定义设备码流类型 end

// 定义设备连接类型 begin
typedef enum
{
	NETPRO_CONNECT_TUTK			= 0x01,	// TUTK
	NETPRO_CONNECT_4_0_P2P		= 0x02,	// 4.0 p2p
	NETPRO_CONNECT_4_0_TCP		= 0x03,	// 4.0 tcp
}eNetConnType;
// 定义设备连接类型 end

// 定义获取设备流类型 begin
typedef enum
{
	NETPRO_STREAM_VIDEO			= 0x00,	// 视频流
	NETPRO_STREAM_AUDIO			= 0x01,	// 音频流
	NETPRO_STREAM_ALL			= 0x02,	// 音视频流
	NETPRO_STREAM_LIVE			= 0x03, // 直播流 4.0
	NETPRO_STREAM_REC			= 0x04, // 历时流
}eNetStreamType;
// 定义获取设备流类型 end

// 定义历史流控制 begin
typedef enum
{
	NETPRO_RECSTREAM_PAUSE		= 0x00,	// 暂停
	NETPRO_RECSTREAM_RESUME		= 0x01,	// 恢复播放
	NETPRO_RECSTREAM_SEEK		= 0x02,	// 定点播放
	NETPRO_RECSTREAM_STOP		= 0x03,	// 停止播放
}eNetRecCtrlType;
// 定义历史流 end



// 定义参数控制命令 begin
typedef enum 
{	
	// 事件类型  ********************************************
	NETPRO_EVENT_CONN_SUCCESS	= 0,	// 连接设备成功

	NETPRO_EVENT_CONN_ERR,				// 连接设备失败

	NETPRO_EVENT_OPENSTREAM_RET,		// 打开流状态

	NETPRO_EVENT_CLOSESTREAM_RET,		// 关闭流状态

	NETPRO_EVENT_REC_DOWNLOAD_RET,		// 开始下载状态 回调lRet=0 开始下载成功，lRet > 0返回下载文件的总长度， else对应错误码:NetProErr_DOWNLOADERR 取lData值 -1 没有该文件， -2 其他用户正在下载中

	NETPRO_EVENT_REC_DOWNLOADING,		// 下载中，回调lRet返回下载进度

	NETPRO_EVENT_REC_DOWNLOAD_SUCCESS,	// 下载完成

	NETPRO_EVENT_SET_STREAM,			// 切换码流 回调lRet返回0 成功

	NETPRO_EVENT_DEL_REC,				// 删除录像文件 回调lRet返回0 成功

	NETPRO_EVENT_TALK,					// 对讲  lRet 0打开对讲成功,  else对应错误码 

	NETPRO_EVENT_TALK_SENDFILE_SUCCESS, // 对讲 发送文件成功事件

	NETPRO_EVENT_LOSTCONNECTION,		// 设备掉线

	NETPRO_EVENT_RET_DEVCHN_NUM,		// 返回设备通道数， lRet 返回通道个数

	NETPRO_EVENT_CREATE_REC_PLAYCHN,	// 创建录像回放通道， lRet 返回通道 else对应错误码

	NETPRO_PARAM_CTRLT_NVR_REC,			// NVR录像控制事件  SMsgAVIoctrlPlayRecordResp
	
	NETPRO_EVENT_GET_LIGHTSTATE,		// 门灯状态, lRet 返回 

	NETPRO_EVENT_UPLOAD_AUDIOFILE,		// (上传自定义报警铃声)返回上传文件进度, lRet 返回，小于 0 对应错误码

	
	// 参数类型  ********************************************  设置参数 通过回调lRet判断是否成功 0 成功
	NETPRO_PARAM_GET_ANDROIDALARM = 100,// 安卓报警推送		SMsgAVIoctrlSendAndriodAlarmMsg

	NETPRO_PARAM_GET_DEVCAP	,			// 设备能力集		回调中lRet=101第一版能力集SMsgAVIoctrlGetDeviceAbilityResp, lRet=102第二版能力集T_SDK_DEVICE_ABILITY_INFO1, lRet=103第三版能力集T_SDK_DEVICE_ABILITY_INFO2

	NETPRO_PARAM_GET_DEVINFO,			// 设备信息			SMsgAVIoctrlGetAllParamResq

	NETPRO_PARAM_GET_DEVPWD,			// 获取设备密码		SMsgAVIoctrlGetDeviceAuthenticationInfoResp

	NETPRO_PARAM_SET_DEVPWD,			// 设置设备密码		SMsgAVIoctrlGetDeviceAuthenticationInfoResp

	NETPRO_PARAM_PTZ,					// 云台控制			SMsgAVIoctrlPtzCmd

	NETPRO_PARAM_GET_STREAMQUALITY,		// 获取视频质量		回调返回 eNetVideoStreamType

	NETPRO_PARAM_SET_REC,				// 设置录像			SMsgAVIoctrlManualRecordReq

	NETPRO_PARAM_GET_VIDEOMODE,			// 获取视频模式		SMsgAVIoctrlSetVideoModeReq

	NETPRO_PARAM_SET_VIDEOMODE,			// 设置视频模式		SMsgAVIoctrlSetVideoModeReq

	NETPRO_PARAM_GET_MOTIONDETECT,		// 获取移动侦测		SMsgAVIoctrlSetMotionDetectReq

	NETPRO_PARAM_SET_MOTIONDETECT,		// 设置移动侦测		SMsgAVIoctrlSetMotionDetectReq

	NETPRO_PARAM_GET_PIRDETECT,			// 获取红外侦测		SMsgAVIoctrlSetPirDetectReq

	NETPRO_PARAM_SET_PIRDETECT,			// 设置红外侦测		SMsgAVIoctrlSetPirDetectReq

	NETPRO_PARAM_SET_AUDIOALARM,		// 设置声音报警		SMsgAVIoctrlSetAudioAlarmReq   获取，通过能力集返回

	NETPRO_PARAM_GET_ALARMCONTROL,		// 获取一键布防		SMsgAVIoctrlSetAlarmControlReq

	NETPRO_PARAM_SET_ALARMCONTROL,		// 设置一键布防		SMsgAVIoctrlSetAlarmControlReq

	NETPRO_PARAM_GET_RECMONTHLIST,		// 获取录像日期列表 参数：SMsgAVIoctrlGetMonthEventListReq，返回：SMsgAVIoctrlGetMonthEventListResp

	NETPRO_PARAM_GET_RECLIST,			// 获取某日录像列表 参数：SMsgAVIoctrlGetDayEventListReq， 返回：SMsgAVIoctrlGetDayEventListResp

	NETPRO_PARAM_GET_NVR_REC,			// 获取NVR录像		参数：GOS_V_SearchFileRequest， 返回：GOS_V_FileCountInfo+GOS_V_FileInfo

	NETPRO_PARAM_GET_SDINFO,			// 获取SD卡信息		SMsgAVIoctrlGetStorageInfoResp

	NETPRO_PARAM_SET_SDFORMAT,			// 格式化SD卡		SMsgAVIoctrlFormatStorageReq

	NETPRO_PARAM_GET_WIFIINFO,			// 获取WIFI参数		SMsgAVIoctrlGetWifiResp

	NETPRO_PARAM_SET_WIFIINFO,			// 设置WIFI参数		SMsgAVIoctrlSetWifiReq

	NETPRO_PARAM_GET_TEMPERATURE,		// 获取温度报警参数 SMsgAVIoctrlGetTemperatureAlarmParamResp

	NETPRO_PARAM_SET_TEMPERATURE,		// 设置温度报警参数 SMsgAVIoctrlSetTemperatureAlarmParamReq

	NETPRO_PARAM_GET_TIMEINFO,			// 获取设备时间参数 SMsgAVIoctrlGetTimeParamResp

	NETPRO_PARAM_SET_TIMEINFO,			// 设置设备时间参数 SMsgAVIoctrlSetTimeParamReq

	NETPRO_PARAM_SET_UPDATE,			// 设置升级  SMsgAVIoctrlSetUpdateReq

	NETPRO_PARAM_SET_LIGHT,				// 设置灯开关    SMsgAVIoctrlSetLightReq

	NETPRO_PARAM_GET_LIGHTTIME,			// 获取灯亮时间	 SMsgAVIoctrlGetLightTimeResp

	NETPRO_PARAM_SET_LIGHTTIME,			// 设置灯亮时间	 SMsgAVIoctrlSetLightTimeReq

	NETPRO_PARAM_DEV_RESET,				// 恢复出厂设置  NULL

	NETPRO_PARAM_SET_MOBILE_CLENT_TYPE, // 安卓手机客户端置位请求 SMsgAVIoctrlSetAndriodAlarmMsgReq 

	NETPRO_PARAM_GET_CAMEREA_STATUS,	// 获取门铃状态

	NETPRO_PARAM_SET_LOCAL_STORE_CFG,	// 云存储本地存储控制 SMsgAVIoctrlPlayRecordReq, 返回：SMsgAVIoctrlPlayPreviewResp

	NETPRO_PARAM_SET_LOCAL_STORE_STOP,  // 停止预览历史流播放

	NETPRO_PRRAM_GET_AI_INFO,			// 获取AI参数 SAiInfo

	NETPRO_PRRAM_TEST_AI_SERVER,
}eNetProParam;
// 定义参数控制命令 end



// 定义错误码 begin
typedef enum
{
	NetProErr_Success			= 0,			// 成功
	NetProErr_Param				= -1000,		// 参数错误
	NetProErr_Init				= -1001,		// 初始化失败
	NetProErr_UnInit			= -1002,		// 未初始化
	NetProErr_Pro				= -1003,		// 协议错误
	NetProErr_GetChannel		= -1004,		// 获取空闲通道错误
	NetProErr_Conn				= -1005,		// 连接错误
	NetProErr_NoConn			= -1006,		// 未连接设备
	NetProErr_OpenStream		= -1007,		// 打开流失败
	NetProErr_CloseStream		= -1008,		// 关闭流失败
	NetProErr_PARAMTYPE			= -1009,		// 参数类型错误
	NetProErr_GETPARAM			= -1010,		// 获取参数错误
	NetProErr_SETPARAM			= -1011,		// 设置参数错误
	NetProErr_OPENFILE			= -1012,		// 下载录像打开文件失败
	NetProErr_GETMODE			= -1013,		// 获取连接方式失败
	NetProErr_DOWNLOADTimeOut	= -1014,		// 开始下载录像超时
	NetProErr_DOWNLOADERR		= -1015,		// 开始下载失败
	NetProErr_DOWNLOADINGERR	= -1016,		// 下载中失败
	NetProErr_DOWNLOADING		= -1017,		// 已经在下载录像
	NetProErr_OPENTALKERR		= -1018,		// 打开对讲失败
	NetProErr_TALKERR			= -1019,		// 对讲失败
	NetProErr_OPENVIDEO			= -1020,		// 打开视频失败
	NetProErr_OPENAUDIO			= -1021,		// 打开音频失败
	NetProErr_UnKnowCHNNun		= -1022,		// 未知通道数
	NetProErr_CreateCHN			= -1023,		// 创建通道失败
	NetProErr_UseErrChn			= -1024,		// 使用了未打通通道
	NetProErr_CreateRecPlyChn	= -1025,		// 创建录像回放通道失败,可能是文件名字错误或其他错误
	NetProErr_NoFreeChannel		= -1026,		// 创建录像回放通道, 没有空闲通道
	NetProErr_CtrlRecStream		= -1027,		// 历史流控制失败
	NetProErr_CreateRecPlyChnING= -1028,		// 正在创建录像回放通道
	NetProErr_OpenStreamPwdErr	= -1029,		// 打开流密码错误
	NetProErr_TransPortCreateErr= -1030,		// 连接TURN服务器失败或未连接
	NetProErr_TransPortCreate	= -1031,		// 连接TURN服务器未连接
	NetProErr_HasConnect		= -1032,		// 已连接
	NetProErr_NoConnChn			= -1033,		// 通道未连接
	NetProErr_NotConnStreamServer=-1034,		// 流服务未连接
	NetProErr_SetAlarmAudio		 =-1035,		// 设置报警铃声失败
	NetProErr_TUTKMaxConn		 =-1036,		// tutk超出最大连接
}eNetProErr;
// 定义错误码 end

#endif
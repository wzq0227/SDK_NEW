//
//  NetPro.h
//  NetPro
//
//  Created by zhuochuncai on 9/2/17.
//  Copyright © 2017年 zhuochuncai. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NetPro : NSObject

#if defined(__arm__) //debug++
typedef unsigned long       DWORD;
#elif defined(__arm64__)
typedef unsigned int      DWORD;
#endif

// 定义协议类型 begin
typedef enum
{
    kNETPRO_USE_TUTK            = 0,	// TUTK 协议
}kNetProType;
// 定义协议类型 end


// 定义设备流类型 begin
typedef enum
{
    kNETPRO_STREAM_VIDEO		= 0,	// 视频流
    kNETPRO_STREAM_AUDIO,				// 音频流
    kNETPRO_STREAM_ALL			= 0x02,	// 所有流
}kNetStreamType;
// 定义设备流类型 end


// 定义历史流控制 begin
typedef enum
{
    kNETPRO_RECSTREAM_PAUSE		= 0x00,	// 暂停
    kNETPRO_RECSTREAM_RESUME	= 0x01,	// 恢复播放
    kNETPRO_RECSTREAM_SEEK		= 0x02,	// 定点播放
}kNetRecCtrlType;
// 定义历史流 end


// 定义参数控制命令 begin
typedef enum
{
    // 事件类型  ********************************************
    kNETPRO_EVENT_CONN_SUCCESS	= 0,	// 连接设备成功
    
    kNETPRO_EVENT_CONN_ERR,				// 连接设备失败
    
    kNETPRO_EVENT_OPENSTREAM_RET,		// 请求流状态 回调lRet=0打开成功, else 对应错误码
    
    kNETPRO_EVENT_CLOSESTREAM_RET,		// 关闭流状态
    
    kNETPRO_EVENT_REC_DOWNLOAD_RET,      //下载 回调lRet=0 开始下载成功， else对应错误码
    
    kNETPRO_EVENT_REC_DOWNLOADING,		// 下载中，回调lRet返回下载进度
    
    kNETPRO_EVENT_REC_DOWNLOAD_SUCCESS,	// 下载完成
    
    kNETPRO_EVENT_SET_STREAM,			// 切换码流 回调lRet返回0 成功
    
    kNETPRO_EVENT_DEL_REC,				// 删除录像文件 回调lRet返回0 成功
    
    kNETPRO_EVENT_TALK,					// 对讲  lRet 0打开对讲成功
    
    kNETPRO_EVENT_TALK_SENDFILE_SUCCESS, // 对讲 发送文件成功事件
    
    kNETPRO_EVENT_LOSTCONNECTION,		// 设备掉线
    
    kNETPRO_EVENT_RET_DEVCHN_NUM,		// 返回设备通道数， lRet 返回通道个数
    
    kNETPRO_EVENT_CREATE_REC_PLAYCHN,	// 创建录像回放通道， lRet 返回通道 else对应错误码
    
    kNETPRO_PARAM_CTRLT_NVR_REC,			// NVR录像控制事件  SMsgAVIoctrlPlayRecordResp
    
    kNETPRO_EVENT_GET_LIGHTSTATE,		// 门灯状态, lRet 返回
    
    // 参数类型  ********************************************
    kNETPRO_PARAM_GET_ANDROIDALARM = 100,// 安卓报警推送		SMsgAVIoctrlSendAndriodAlarmMsg
    
    kNETPRO_PARAM_GET_DEVCAP		= 101,	// 设备能力集		回调中lRet=101第一版能力集SMsgAVIoctrlGetDeviceAbilityResp, lRet=102第二版能力集T_SDK_DEVICE_ABILITY_INFO1, lRet=103第三版能力集T_SDK_DEVICE_ABILITY_INFO2
    
    kNETPRO_PARAM_GET_DEVINFO,			// 设备信息			SMsgAVIoctrlGetAllParamResq
    
    kNETPRO_PARAM_GET_DEVPWD,			// 获取设备密码		SMsgAVIoctrlGetDeviceAuthenticationInfoResp
    
    kNETPRO_PARAM_SET_DEVPWD,			// 设置设备密码		SMsgAVIoctrlSetDeviceAuthenticationInfoResp
    
    kNETPRO_PARAM_PTZ,					// 云台控制			SMsgAVIoctrlPtzCmd
    
    kNETPRO_PARAM_GET_STREAMQUALITY,		// 获取视频质量		SMsgAVIoctrlGetStreamCtrlReq
    
    kNETPRO_PARAM_SET_REC,				// 设置录像			SMsgAVIoctrlManualRecordReq
    
    kNETPRO_PARAM_GET_VIDEOMODE,			// 获取视频模式		SMsgAVIoctrlSetVideoModeReq
    
    kNETPRO_PARAM_SET_VIDEOMODE,			// 设置视频模式		SMsgAVIoctrlSetVideoModeReq
    
    kNETPRO_PARAM_GET_MOTIONDETECT,		// 获取移动侦测		SMsgAVIoctrlSetMotionDetectReq
    
    kNETPRO_PARAM_SET_MOTIONDETECT=111,		// 设置移动侦测		SMsgAVIoctrlSetMotionDetectReq
    
    kNETPRO_PARAM_GET_PIRDETECT,			// 获取红外侦测		SMsgAVIoctrlSetPirDetectReq
    
    kNETPRO_PARAM_SET_PIRDETECT,			// 设置红外侦测		SMsgAVIoctrlSetPirDetectReq
    
    kNETPRO_PARAM_SET_AUDIOALARM,		// 设置声音报警		SMsgAVIoctrlSetAudioAlarmReq
    
    kNETPRO_PARAM_GET_ALARMCONTROL,		// 获取一键布防		SMsgAVIoctrlSetAlarmControlReq
    
    kNETPRO_PARAM_SET_ALARMCONTROL,		// 设置一键布防		SMsgAVIoctrlSetAlarmControlReq
    
    kNETPRO_PARAM_GET_RECMONTHLIST,		// 获取录像日期列表 参数：SMsgAVIoctrlGetMonthEventListReq，返回：SMsgAVIoctrlGetMonthEventListResp
    
    kNETPRO_PARAM_GET_RECLIST,			// 获取某日录像列表 参数：SMsgAVIoctrlGetDayEventListReq， 返回：SMsgAVIoctrlGetMonthEventListResp
    
    kNETPRO_PARAM_GET_NVR_REC,          // 获取NVR录像		参数：GOS_V_SearchFileRequest
    
    kNETPRO_PARAM_GET_SDINFO,			// 获取SD卡信息		SMsgAVIoctrlGetStorageInfoResp
    
    kNETPRO_PARAM_SET_SDFORMAT,			// 格式化SD卡
    
    kNETPRO_PARAM_GET_WIFIINFO=122,			// 获取WIFI参数		SMsgAVIoctrlGetWifiResp
    
    kNETPRO_PARAM_SET_WIFIINFO,			// 设置WIFI参数		SMsgAVIoctrlSetWifiReq
    
    kNETPRO_PARAM_GET_TEMPERATURE,		// 获取温度报警参数 SMsgAVIoctrlGetTemperatureAlarmParamResp
    
    kNETPRO_PARAM_SET_TEMPERATURE,		// 设置温度报警参数 SMsgAVIoctrlSetTemperatureAlarmParamReq
    
    kNETPRO_PARAM_GET_TIMEINFO,			// 获取设备时间参数 SMsgAVIoctrlGetTimeParamResp
    
    kNETPRO_PARAM_SET_TIMEINFO,			// 设置设备时间参数 SMsgAVIoctrlSetTimeParamReq
    
    kNETPRO_PARAM_SET_UPDATE,			// 设置升级  SMsgAVIoctrlSetUpdateReq
    
    kNETPRO_PARAM_SET_LIGHT,				// 设置灯开关    SMsgAVIoctrlSetLightReq
    
    kNETPRO_PARAM_GET_LIGHTTIME,			// 获取灯亮时间	 SMsgAVIoctrlGetLightTimeResp
    
    kNETPRO_PARAM_SET_LIGHTTIME,			// 设置灯亮时间	 SMsgAVIoctrlSetLightTimeReq
    
    kNETPRO_PARAM_DEV_RESET,				// 恢复出厂设置  NULL
    
    kNETPRO_PARAM_SET_MOBILE_CLENT_TYPE, // 安卓手机客户端置位请求 SMsgAVIoctrlSetAndriodAlarmMsgReq
}kNetProParam;
// 定义参数控制命令 end


// 定义错误码 begin
typedef enum
{
    kNetProErr_Success			= 0,			// 成功
    kNetProErr_Param				= -1000,		// 参数错误
    kNetProErr_Init				= -1001,		// 初始化失败
    kNetProErr_UnInit			= -1002,		// 未初始化
    kNetProErr_Pro				= -1003,		// 协议错误
    kNetProErr_GetChannel		= -1004,		// 获取空闲通道错误
    kNetProErr_Conn				= -1005,		// 连接错误
    kNetProErr_NoConn			= -1006,		// 未连接设备
    kNetProErr_OpenStream		= -1007,		// 打开流失败
    kNetProErr_CloseStream		= -1008,		// 关闭流失败
    kNetProErr_PARAMTYPE			= -1009,		// 参数类型错误
    kNetProErr_GETPARAM			= -1010,		// 获取参数错误
    kNetProErr_SETPARAM			= -1011,		// 设置参数错误
    kNetProErr_OPENFILE			= -1012,		// 下载录像打开文件失败
    kNetProErr_GETMODE			= -1013,		// 获取连接方式失败
    kNetProErr_DOWNLOADTimeOut	= -1014,		// 开始下载录像超时
    kNetProErr_DOWNLOADERR		= -1015,		// 开始下载失败
    kNetProErr_DOWNLOADINGERR	= -1016,		// 下载中失败
    kNetProErr_DOWNLOADING		= -1017,		// 已经在下载录像
    kNetProErr_OPENTALKERR		= -1018,		// 打开对讲失败
    kNetProErr_TALKERR			= -1019,		// 对讲失败
    kNetProErr_OPENVIDEO			= -1020,		// 打开视频失败
    kNetProErr_OPENAUDIO			= -1021,		// 打开音频失败
    kNetProErr_UnKnowCHNNun		= -1022,		// 未知通道数
    kNetProErr_CreateCHN			= -1023,		// 创建通道失败
    kNetProErr_UseErrChn			= -1024,		// 使用了未打通通道
    kNetProErr_CreateRecPlyChn	= -1025,		// 创建录像回放通道失败,可能是文件名字错误或其他错误
    kNetProErr_NoFreeChannel		= -1026,		// 创建录像回放通道, 没有空闲通道
    kNetProErr_CtrlRecStream		= -1027,		// 历史流控制失败
    kNetProErr_CreateRecPlyChnING= -1028,		// 正在创建录像回放通道
}kNetProErr;
// 定义错误码 end


// 事件回调
typedef long (* EventCallBackFunc)(long lHandle, int nDevChn,  kNetProParam eParam, long lRet, long lData, long lUserParam);

// 音视频流回调
typedef long (* StreamCallBackFunc)(long lHandle, int nDevChn,unsigned char* pStreamData, DWORD dwSize, long lUserParam);
// 初始化
/*
	初始化时 确定要用的协议， 或者登录服务器时  根据服务器地址自动判断该用哪种协议  或其他
 */

- (long)NetPro_InitWithType:(kNetProType) eType;

// 反初始化
- (long)NetPro_UnInit;

// 登录（连接设备）
- (long)NetPro_ConnDevWithDevID:(NSString*)pUID
                       username:(NSString*)pUser
                       password:(NSString*)pPwd
                        timeout:(int )nTimeOut
                       connType:(int )connType
                       callback:( EventCallBackFunc )eventCB
                      userParam:(long) lUserParam;

// 登出 (关闭连接)
- (long)NetPro_CloseDevWithHandle:(long) lConnHandle;

// 打开音视频流(是否同时打开音频、视频流)
- (long)NetPro_OpenStreamWithHandle:(long) lConnHandle
                            channel:(long) nChannel
                         streamType:(kNetStreamType) eType
                            seconds:(long) seconds
                           timeZone:(long) zone
                           callback:(StreamCallBackFunc)streamCB
                          userParam:(long) lUserParam;

// 关闭音视频流
- (long)NetPro_CloseStreamWithHandle:(long)lConnHandle channel:(int)nChannel streamType:(kNetStreamType) eType
;


// 设置参数   事件回调返回 相同类型的事件  根据事件做对应处理
- (long)NetPro_SetParamWithHandle:(long)lConnHandle channel:(int)nChannel cmdParam:(kNetProParam) param data:( NSData*) lData;

// 获取参数
- (long)NetPro_GetParamWithHandle:(long)lConnHandle channel:(int)nChannel cmdParam:(kNetProParam) param data:( NSData*) lData;

//检查设备Session状态
- (long)NetPro_checkSessionConnStateWithHandle:(long)lConnHandle channel:(int)nChannel;

//设置 检查设备在线状态间隔
- (long)NetPro_SetCheckConnStateTimeIntervalWithHandle:(long)lConnHandle channel:(int)nChannel interval:(int)milliseconds;

//停止下载
- (long)NetPro_StopDownloadWithHandle:(long)lConnHandle channel:(int)nChannel;

// 开始对讲
- (long)NetPro_TalkStartWithHandle:(long)lConnHandle channel:(int)nChannel;

// 发送对讲文件
- (long)NetPro_TalkSendWithHandle:(long)lConnHandle channel:(int)nChannel filePath:(NSString*) filePath;

// 发送对讲数据
- (long)NetPro_TalkSendWithHandle:(long)lConnHandle channel:(int)nChannel data:(NSData *)data;

// 结束对讲
- (long)NetPro_TalkStopWithHandle:(long)lConnHandle channel:(int)nChannel;

// 录像下载
- (long)NetPro_RecDownloadWithHandle:(long)lConnHandle channel:(int)nChannel localPath:(NSString*)path fileNameInServer:(NSString*)fileName;


#pragma mark - NVR 相关
#pragma mark -- 获取设备支持的通道数
/**
 获取 NVR 设备支持的通道数
 
 @param lConnHandle         设备操作 句柄
 @return                    通道数
 */
- (long)NetPro_GetNvrChannelNumWithHandle:(long)lConnHandle;


#pragma mark -- 创建 NVR 支持的 AV 通道

/**
 创建 NVR 支持的 AV 通道
 
 @param lConnHandle         设备操作句柄
 @param channelNum          支持的通道数
 @return                    创建成功的通道数
 */
- (long)NetPro_CreateAVChannelWithHandle:(long)lConnHandle
                              channelNum:(int)channelNum;


#pragma mark -- 获取 NVR 录像文件列表
/**
 获取 NVR 录像文件列表
 
 @param lConnHandle         设备操作句柄
 *  @param channelMask      查询的频道（0、1、2、3）
 *  @param date             查询的日期（2017-03-17）
 *  @param startTime        查询的起始时间（00:00）
 *  @param endTime          查询的结束时间(23:59)
 */
- (void)NetPro_GetNvrVideoListWithHandle:(long)lConnHandle
                             channelMask:(uint32_t)channelMask
                                    date:(NSString *)date
                               startTime:(NSString *)startTime
                                 endTime:(NSString *)endTime;


#pragma mark -- 创建 NVR 录像回放 av 通道
/**
 创建 NVR 录像回放 av 通道
 
 @param lConnHandle         设备操作句柄
 @param filePath            文件路径
 */
- (void)NetPro_CreateRecordAVChannelWithHanle:(long)lConnHandle
                                     filePath:(NSString *)filePath;


#pragma mark -- 释放 NVR 录像回放 AV 通道

/**
 释放 NVR 录像回放 AV 通道
 
 @param lConnHandle         设备操作句柄
 @param avChannel           AV 通道
 */
- (void)NetPro_ReleaseRecordAVChannelWithHanle:(long)lConnHandle
                                     avChannel:(int)avChannel;


#pragma mark -- NVR 录像回放播放控制
/**
 NVR 录像回放播放控制
 
 @param lConnHandle         设备操作句柄
 @param avChannel           AV 通道
 @param netRecCtrlType      播放控制类型，参见‘kNetRecCtrlType’
 @param seekSecond          用于定点播放时的：秒数，其他操作传0
 */
- (void)NetPro_CtrlNvrRecordFileWithHandle:(long)lConnHandle
                                 avChannel:(int)avChannel
                              playCtrlType:(kNetRecCtrlType)netRecCtrlType
                                seekSecond:(long)seekSecond;

@end



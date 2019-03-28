/*
NetProSDKAPI.h		
2017.1.17		
wwei
高斯贝尔家居跨平台网络协议SDK API
*/
#ifndef	_NET_PRO_SDK_API_H_
#define _NET_PRO_SDK_API_H_

#if (defined _WIN32) || (defined _WIN64)
#ifdef NETPROSDK_EXPORTS
#define NETPROSDK_API __declspec(dllexport)
#else
#define NETPROSDK_API __declspec(dllimport)
#endif
#elif (defined __APPLE_CPP__) || (defined __APPLE_CC__)
#if defined(__arm__) //debug++
typedef unsigned long       DWORD;
#elif defined(__arm64__)
typedef unsigned int        DWORD;
#endif
#ifdef NETPROSDK_EXPORTS
#define NETPROSDK_API extern "C"
#else
#define NETPROSDK_API
#endif
#else
typedef unsigned long       DWORD; //debug++
#define NETPROSDK_API //extern "C"
#endif	
#define NETPROSDK_VERSION	"V1.0.3.8-20181218"

#include "NetProSDKDef.h"
#include "AVIOCTRLDEFs.h"

// 事件回调
typedef long (__stdcall* EventCallBack)(long lHandle, int nDevChn, eNetProParam eParam, long lRet, long lData, long lUserParam);

// 音视频流回调
typedef long (__stdcall* StreamCallBack)(long lHandle, int nDevChn, unsigned char* pStreamData, DWORD dwSize, long lUserParam);

// 初始化
/*
	初始化时 确定要用的协议， 或者登录服务器时  根据服务器地址自动判断该用哪种协议  或其他
*/
NETPROSDK_API	long	NetPro_Init();

// 反初始化
NETPROSDK_API	long	NetPro_UnInit();

// pServerAddr负载均衡分派服务器地址，多个地址以分号间隔
// 例如 服务器1:服务器1端口; 服务器2:服务器2端口, 192.168.0.1:9999; 192.168.0.2:9999;
NETPROSDK_API	long	NetPro_SetTransportProType(eNetProTransportProType eProType, char* pServerAddr);

// 登录（连接设备）nProjectType  0.默认  1.门灯项目 
NETPROSDK_API	long	NetPro_ConnDev(const char* pUID, const char* pUser, const char* pPwd, int nTimeOut, int nProjectType, eNetConnType eConnType, EventCallBack eventCB, long lUserParam);

// 登出 (关闭连接)
NETPROSDK_API	long	NetPro_CloseDev(long lConnHandle);

// 获取NVR通道数
NETPROSDK_API	long	NetPro_GetDevChnNum(long lConnHandle);

// 为NVR创建 nNum个通道， 返回创建的通道数
NETPROSDK_API	long	NetPro_CreateDevChn(long lConnHandle, int nNum);

// 检查设备连接  返回值 0在线  否则不在线
NETPROSDK_API	long	NetPro_CheckDevConn(long lConnHandle);

// 设置检查设备连接状态的时间间隔（毫秒）  默认为15秒
NETPROSDK_API	long	NetPro_SetCheckConnTimeinterval(long lConnHandle, int nMillisecond);

// 打开音视频流(是否同时打开音频、视频流)
NETPROSDK_API	long	NetPro_OpenStream(long lConnHandle, int nChannel, char* pPassword, eNetStreamType eType, long lTimeSeconds, long lTimeZone, StreamCallBack streamCB, long lUserParam);

// 关闭音视频流
NETPROSDK_API	long	NetPro_CloseStream(long lConnHandle, int nChannel, eNetStreamType eType);

// 暂停接收音视频数据 nPasueFlag = 1 暂停接收， nPasueFlag = 0 恢复接收
NETPROSDK_API	long	NetPro_PasueRecvStream(long lConnHandle, int nChannel, int nPasueFlag);

// 切换码流
NETPROSDK_API	long	NetPro_SetStream(long lConnHandle, int nChannel, eNetVideoStreamType eType);

// 设置参数   事件回调返回 相同类型的事件  根据事件做对应处理
NETPROSDK_API	long	NetPro_SetParam(long lConnHandle, int nChannel, eNetProParam eParam, void* lData, int nDataSize);

// 获取参数
NETPROSDK_API	long	NetPro_GetParam(long lConnHandle, int nChannel, eNetProParam eParam, void* lData, int nDataSize);

// 录像下载
NETPROSDK_API	long	NetPro_RecDownload(long lConnHandle, int nChannel, const char* pFileName, char *pSrcFileName);

// 停止录像下载
NETPROSDK_API	long	NetPro_StopDownload(long lConnHandle, int nChannel);

// 删除录像文件
NETPROSDK_API	long	NetPro_DelRec(long lConnHandle, int nChannel, const char *pFileName);

// 开始对讲
NETPROSDK_API	long	NetPro_TalkStart(long lConnHandle, int nChannel);

// 对讲 （发送AAC文件） nNoPlay 传 0 对讲功能 ，传 1 自定义报警铃声
NETPROSDK_API	long	NetPro_TalkSendFile(long lConnHandle, int nChannel, const char *pFileName, int nNoPlay);

// 发送对讲数据
NETPROSDK_API	long	NetPro_TalkSend(long lConnHandle, int nChannel, const char* pData, DWORD dwSize);

// 结束对讲
NETPROSDK_API	long	NetPro_TalkStop(long lConnHandle, int nChannel);

// 录像回放 begin
NETPROSDK_API	long	NetPro_RecStreamPlay(long lConnHandle, const char *pRecName, int nRecNameLen);

// 历史流控制
NETPROSDK_API	long	NetPro_RecStreamCtrl(long lConnHandle, int nChn, eNetRecCtrlType eCtrlType, long lData);

// 录像回放 end

#endif





/*// 释放历史流回放通道
NETPROSDK_API	long	NetPro_DeleteRecPlayChn(long lConnHandle, int nChn);*/
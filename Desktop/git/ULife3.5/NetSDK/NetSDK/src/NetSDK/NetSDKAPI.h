/*
NetSDKAPI.h		
2017.4.10		
wwei
Ulife3.0 网络SDK
*/
#ifndef _NET_SDKAPI_H_
#define _NET_SDKAPI_H_

#if (defined _WIN32) || (defined _WIN64)
#ifdef NETSDK_EXPORTS
#define NETSDK_API __declspec(dllexport)
#else
#define NETSDK_API __declspec(dllimport)
#endif
#elif (defined __APPLE_CPP__) || (defined __APPLE_CC__)
#if defined(__arm__) //debug++
typedef unsigned long       DWORD;
#elif defined(__arm64__)
typedef unsigned int        DWORD;
#endif
#ifdef NETSDK_EXPORTS
#define NETSDK_API extern "C"
#else
#define NETSDK_API
#endif
#else
#define  __stdcall
typedef unsigned long       DWORD; //debug++
#define NETSDK_API //extern "C"
#endif	

#define NETSDK_VERSIONG	"V1.0.0.7 20180206"

typedef enum
{
	NetSDKErr_Success			= 0,			// 成功
	NetSDKErr_Error				= -1,			//失败

	NetSDKErr_NoSupport_BlockMode = -100, //不支持阻塞模式
	NetSDKErr_Timeout			= -101, //请求超时
	NetSDKErr_NoSupport_Req = -102, //SDK不支持该请求
	NetSDKErr_SendFailed		= -103, //发送请求失败
	NetSDKErr_SendReqWhenDisconnect = -104, //在断线的情况下发送的请求
	NetSDKErr_ConnectFailed = -105, //连接服务器失败
	NetSDKErr_SocketError = -106, //套接字异常
	NetSDKErr_BufferIsTooSamll = -107, //用作输出拷贝的buffer空间不够

	NetSDKErr_Param				= -2000,		// 参数错误
	NetSDKErr_Init				= -2001,		// 初始化失败
	NetSDKErr_UnInit			= -2002,		// 未初始化
	NetSDKErr_Pro				= -2003,		// 协议错误
	NetSDKErr_GetChannel		= -2004,		// 获取空闲通道错误
	NetSDKErr_HeartBeat			= -2005,		// 保持心跳失败
	NetSDKErr_LostConn			= -2006,		// 掉线

}eNetSDKErr;


typedef enum 
{	
	// 事件类型  ********************************************
	NETSDK_EVENT_CONN_SUCCESS	= 0,	// 连接成功

	NETSDK_EVENT_CONN_ERR,				// 连接失败

	NETSDK_EVENT_CONN_LOST,				// 设备掉线,

	NETSDK_EVENT_GOS_RECV,				// Ulife3.0  接收数据  dataLen返回接收长度; lRet表示应答结果, 0->成功，非0->失败(参见eNetSDKErr)

}eNetSDKEvent;

//注意不要在回调函数中调用Net_S_Close
typedef long (__stdcall* RecvCallBack)(long lHandle, eNetSDKEvent eParam, long lRet, void* pData, long dataLen, long lUserParam);


// 初始化,logFilePath == NULL 时无日志
NETSDK_API	long	Net_Init(const char* logFilePath);

// 反初始化
NETSDK_API	long	Net_UnInit();


/* ulife3.0 连接服务器 
参数：
pAddr		服务器地址
nPort		端口
nServerType	服务器类型 (怕有特殊处理，加此参数)
CBSCallBack	回调函数， 返回请求结果
lUserParam	用户自定义参数
autoRecnnt 重连标志,0->不重连,1->重连
返回值：
对应错误码	eNetProErr
*/
NETSDK_API	long	Net_S_Connect(const char* pAddr, int nPort, int nServerType, RecvCallBack serverCB, long lUserParam ,int autoRecnnt);


/* ulife3.0 开始发送心跳
参数：
lHandle		服务器通道，连接多个业务服务器时的唯一标识， Net_S_Connect返回
pData		要发送的数据
nDataLen	数据长度

返回值：
对应错误码	eNetProErr
*/
NETSDK_API	long	Net_S_StartHeartBeat(long lHandle, const char* pData, int nDataLen );


/* ulife3.0 停止发送心跳 
参数：
lHandle	服务器通道，连接多个业务服务器时的唯一标识， Net_S_Connect返回
返回值：
对应错误码	eNetProErr
*/
NETSDK_API	long	Net_S_StopHeartBeat(long lHandle);


/* ulife3.0 向服务器发送请求 
参数：
lHandle		服务器通道，连接多个业务服务器时的唯一标识， Net_S_Connect返回
pData		要发送的数据
nDataLen	数据长度

返回值：
返回发送的长度
*/
NETSDK_API	long	Net_S_Send(long lHandle, const char* pData, int nDataLen );


/* ulife3.0 向服务器发送请求 
参数：
lHandle		服务器通道，连接多个业务服务器时的唯一标识， Net_S_Connect返回
pData		要发送的数据
nDataLen	数据长度
block		该接口的调用方式, 1->阻塞调用，超时时间为timeout,结果存在 pRlt中; 0 -> 非阻塞调用，立即返回,结果在回调函数中
timeout	超时时间,单位ms, 当block为0时，即非阻塞模式调用该接口，timeout的做用是，在超时时间内，一定会回调结果
nerror		错误码,参见定义,当block为1时,该参数有用，即阻塞模式有用
pRlt			请求的的回复存放位置,当block为1时,该参数有用，阻塞调用才起作用，非阻塞方式的回复，在回调函数中返回
pRltLen		请求的回复数据的长度,当block为1时,该参数有用，
返回值：	0->成功 ,-1 -> 失败,
*/
NETSDK_API	long	Net_S_Exe_Cmd(long lHandle, const char* pData, int nDataLen ,int block, int timeout, int *nerror,char* pRlt,int *pRltLen);



NETSDK_API	long	Net_S_SetKey(long lHandle, unsigned char *pKey, int nKeyLen);

/* ulife3.0 关闭连接
参数：
lHandle	服务器通道，连接多个业务服务器时的唯一标识， Net_S_Connect返回
返回值：
对应错误码	eNetProErr
注意：//注意不要在回调函数RecvCallBack中调用Net_S_Close
*/
NETSDK_API	long	Net_S_Close(long lHandle);

/* 阻塞请求命令接口，不依赖于其他接口使用（初始化Net_Init，反初始化Net_UnInit除外）
参数：
pAddr		服务器地址
nPort		端口
pData		要发送的数据
nDataLen	数据长度
timeout		超时时间,单位ms,
pRlt		请求的的回复存放位置,如果pRlt输出的不是NULL，则必须调用Net_S_BlockRequestFree，否则会造成内存泄漏
pRltLen		请求的回复数据的长度, IN/OUT.输入时，表示pRlt的总大小; 输出时，表示回复的长度
pKey		加密KEY， 传空不加密
返回值：	0->成功 ,其他 失败，参见eNetSDKErr,
*/
NETSDK_API	long	Net_S_BlockRequest(const char* pAddr, int nPort, char* pData, int nDataLen , int timeout, char** pRlt, int *pRltLen, unsigned char *pKey, int nKeyLen);
NETSDK_API void Net_S_BlockRequestFree(char* pRlt);

// 加密
NETSDK_API	long	Net_EncodeData(unsigned char* pSrcData, unsigned int nSrcDataLen, unsigned char** pOutData, unsigned int* nOutLen);
NETSDK_API	long	Net_DecodeData(unsigned char* pSrcData, unsigned int nSrcDataLen, unsigned char** pOutData, unsigned int* nOutLen);

NETSDK_API	long	Net_DeleteData(unsigned char *pOutData);




#endif
#ifndef _P2P_COMMON_H_
#define _P2P_COMMON_H_


#include <stdio.h>
#include "p2p_dispatch.h"
#include "gss_transport.h"

#define MAX_P2PDEV_CHANNEL				66
#define P2P_DOWNLOAD_MAX_FILE_LEN		255
#define P2P_DOWNLOAD_HANDLE				2000
#define P2P_TALK_HANDLE					3000
#define P2P_GETPICTURE_HANDLE			5000

#define			P2P_CHANNEL_ADDVALUE	200


#define  RECV_VIDEO_FRAME		0x00F2
#define  RECV_AUDIO_FRAME		0x00F3
#define  RECV_DOWNLOAD_FRAME	0x00F5
#define  RECV_AI_FRAME			0x00F6

#if (defined _WIN32) || (defined _WIN64)
#include "../NetProSDKAPI.h"
#pragma comment(lib,"ws2_32.lib")
#pragma comment(lib,"Mswsock.lib")
#pragma comment(lib, "Iphlpapi.lib")
#ifdef _DEBUG
#pragma comment(lib, "p2pd")
#else
#pragma comment(lib, "p2p")
#endif
#else
#include "NetProSDKAPI.h"
#endif

#include "AVCommon.h"
#include "JLogWriter.h"
#include "JLThreadCtrl.h"

#ifdef WIN32
#else 
#define  __cdecl
#endif

#pragma pack(1)
typedef struct _P2pHead
{
	int				magicNo;				// 魔术字 0x67736d80
	int				dataLen;				// 消息体长度，不包含消息头
	char			proType;				// 协议类型 1-json, 2-其他
	char			msgType;				// 消息类型 1-请求， 2-应答， 3-通知
	int				msgChildType;			// 消息子类型 ，对应TUTK类型
	char			res[6];					// 预留

}P2pHead;
#pragma pack()

class CP2pCommon
{
public:
	CP2pCommon();
	virtual ~CP2pCommon();

	int avSendIOCtrl(p2p_transport *transport, int connection_id, unsigned int nIOCtrlType, const char *cabIOCtrlData, int nIOCtrlDataSize, int nFlag, void* pHandle);

};

#endif
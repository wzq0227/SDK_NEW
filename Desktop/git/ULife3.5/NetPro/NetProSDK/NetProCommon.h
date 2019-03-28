#ifndef _NET_PRO_COMMON_H_
#define _NET_PRO_COMMON_H_
#include "NetProSDKAPI.h"

class CNetProCommon
{
public:

	virtual long	Init() = 0;

	virtual long	UnInit() = 0;

	virtual long	ConnDev(const char* pUID, const char* pUser, const char* pPwd, int nTimeOut,  int nConnType, EventCallBack eventCB, long lUserParam) = 0;

	virtual long	CloseDev(long lConnHandle) = 0;

	virtual long	GetDevChnNum(long lConnHandle) = 0;

	virtual long	CreateDevChn(long lConnHandle, int nNum) = 0;

	virtual long	CheckDevConn(long lConnHandle) = 0;

	virtual long	SetCheckConnTimeinterval(long lConnHandle, int nMillisecond) = 0;

	virtual long	OpenStream(long lHandle, int nChannel, char* pPassword, eNetStreamType eType, long lTimeSeconds, long lTimeZone, StreamCallBack streamCB, long lUserParam) = 0;

	virtual long	CloseStream(long lHandle, int nChannel, eNetStreamType eType) = 0;

	virtual long	PasueRecvStream( long lConnHandle,int nChannel, int nPasueFlag) = 0;

	virtual long	SetParam(long lConnHandle, int nChannel, eNetProParam eParam, void* lData, int nDataSize) = 0;

	virtual long	GetParam(long lConnHandle, int nChannel, eNetProParam eParam, void* lData, int nDataSize) = 0;

	virtual long	RecDownload(long lConnHandle, int nChannel, const char* pFileName, char *pSrcFileName) = 0;

	virtual long	TalkSendFile(long lConnHandle, int nChannel, const char *pFileName, int nIsPlay)	= 0;

	virtual long	SetStream(long lConnHandle, int nChannel, eNetVideoStreamType eLevel) = 0;

	virtual long	StopDownload(long lConnHandle, int nChannel) = 0;

	virtual long	DelRec(long lConnHandle, int nChannel, const char *pFileName) = 0;

	virtual long	TalkStart(long lConnHandle, int nChannel) = 0;

	virtual long	TalkSend(long lConnHandle, int nChannel, const char* pData, DWORD dwSize) = 0;

	virtual long	TalkStop(long lConnHandle, int nChannel) = 0;

	virtual long	CreateRecPlayChn(long lConnHandle, const char *pData, int nDataLen) = 0;

	virtual long	DeleteRecPlayChn(long lConnHandle, int nChn) = 0;

	virtual long	RecStreamCtrl(long lConnHandle, int nChn, eNetRecCtrlType eCtrlType, long lData) = 0;
	
	virtual	long	SetTransportProType(eNetProTransportProType eProType, char* pServerAddr) = 0;

	virtual long	ConnServer(char* pServerAddr, int nPort, int nUseTcp, EventCallBack eventCB, long lUserParam) = 0;

	virtual long	CloseServer() = 0;
};


CNetProCommon* CreateChildPro(eNetProType eType);

#endif
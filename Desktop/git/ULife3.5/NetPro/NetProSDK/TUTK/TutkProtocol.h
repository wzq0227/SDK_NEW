#ifndef _TUTK_PROTOCOL_H_
#define _TUTK_PROTOCOL_H_

#include "../NetProCommon.h"
//#include "ProtocolChannel.h"
#include "TuckMainCtrl.h"


#ifndef MAX_CONN_CHANNEL
#define  MAX_CONN_CHANNEL	120
#endif


class CTutkProtocol : public CNetProCommon
{
public:
	CTutkProtocol();
	virtual ~CTutkProtocol();

	virtual long	Init();
	virtual long	UnInit();
	virtual long	ConnServer(char* pServerAddr, int nPort, int nUseTcp, EventCallBack eventCB, long lUserParam);
	virtual	long	SetTransportProType(eNetProTransportProType eProType, char* pServerAddr);
	virtual long	CloseServer();
	virtual long	ConnDev(const char* pUID, const char* pUser, const char* pPwd, int nTimeOut,  int nConnType, EventCallBack eventCB, long lUserParam);
	virtual long	CloseDev(long lConnHandle);
	virtual long	GetDevChnNum(long lConnHandle);
	virtual long	CreateDevChn(long lConnHandle, int nNum);
	virtual long	CheckDevConn(long lConnHandle);
	virtual long	SetCheckConnTimeinterval(long lConnHandle, int nMillisecond);
	virtual long	OpenStream(long lHandle, int nChannel, char* pPassword, eNetStreamType eType, long lTimeSeconds, long lTimeZone, StreamCallBack streamCB, long lUserParam);
	virtual long	CloseStream(long lHandle, int nChannel, eNetStreamType eType);
	virtual long	PasueRecvStream( long lConnHandle,int nChannel, int nPasueFlag);
	virtual long	SetParam(long lConnHandle, int nChannel, eNetProParam eParam, void* lData, int nDataSize);
	virtual long	GetParam(long lConnHandle, int nChannel, eNetProParam eParam, void* lData, int nDataSize);
	virtual long	RecDownload(long lConnHandle, int nChannel, const char* pFileName, char *pSrcFileName);
	virtual long	TalkSendFile(long lConnHandle, int nChannel, const char *pFileName, int nIsPlay);
	virtual long	SetStream(long lConnHandle, int nChannel, eNetVideoStreamType eLevel);
	virtual long	StopDownload(long lConnHandle, int nChannel);
	virtual long	DelRec(long lConnHandle, int nChannel, const char *pFileName);
	virtual long	TalkStart(long lConnHandle, int nChannel);
	virtual long	TalkSend(long lConnHandle, int nChannel, const char* pData, DWORD dwSize);
	virtual long	TalkStop(long lConnHandle, int nChannel);
	virtual long	CreateRecPlayChn(long lConnHandle, const char *pData, int nDataLen);
	virtual long	DeleteRecPlayChn(long lConnHandle, int nChn);
	virtual long	RecStreamCtrl(long lConnHandle, int nChn, eNetRecCtrlType eCtrlType, long lData);
protected:
	int				GetFreeChannel();
protected:

	CTutkMainCtrl*		m_pMainCtrl[MAX_CONN_CHANNEL];
	CMutexLock			m_mutexGetChannel;
};

#endif
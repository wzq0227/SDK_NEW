#ifndef _P2P_MAINCTRL_H_
#define _P2P_MAINCTRL_H_

#include "P2pChannel.h"

class CP2PMainCtrl
{
public:
	CP2PMainCtrl(int nIndex);
	virtual ~CP2PMainCtrl();
	long ConnDev(const char* pUID, const char* pUser, const char* pPwd, int nTimeOut, int nConnType, EventCallBack eventCB, long lUserParam, char *pServerAddr);
	long CloseDev();
	long GetDevChnNum();					// 获取设备通道数
	long CreateDevChnNum(int nNum);			// 创建 nNum 个通道
	long CheckDev();
	long SetCheckConnTimeinterval(int nMillisecond);
	long OpenStream(int nChannel, char* pPassword, eNetStreamType eType, long lTimeSeconds, long lTimeZone, StreamCallBack streamCB, long lUserParam);
	long CloseStream(int nChannel, eNetStreamType eType);
	long PasueRecvStream(int nChannel, int nPasueFlag);
	long SetParam(int nChannel, eNetProParam eParam, void* lData, int nDataSize);
	long GetParam(int nChannel, eNetProParam eParam, void* lData, int nDataSize);
	long RecDownload(int nChannel, const char* pFileName, char *pSrcFileName);
	long TalkSendFile(int nChannel, const char *pFileName, int nIsPlay);
	long SetStream(int nChannel, eNetVideoStreamType eLevel);
	long StopDownload(int nChannel);
	long DelRec(int nChannel, const char *pFileName);
	long TalkStart(int nChannel);
	long TalkSend(int nChannel, const char* pData, DWORD dwSize);
	long TalkStop(int nChannel);
	long CreateRecPlayChn(void* pData, int nDataLen);
	long DeleteRecPlayChn(int nChn);
	long RecStreamCtrl(int nChn, eNetRecCtrlType eCtrlType, long lData, int eCtrlType2 = -1);

	CP2pChannel			*m_pLoginChn;
protected:
	
	CP2pChannel			*m_protocolChn[MAX_P2PDEV_CHANNEL];
};

#endif
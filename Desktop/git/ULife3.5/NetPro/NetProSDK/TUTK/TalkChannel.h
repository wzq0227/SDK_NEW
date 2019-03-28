#ifndef _TALK_CHANNEL_H_
#define _TALK_CHANNEL_H_

#include <stdio.h>

#include "IOTCAPIs.h"
#include "AVAPIs.h"
#include "AVFRAMEINFO.h"
#include "AVIOCTRLDEFs.h"

#include "JLogWriter.h"

#if (defined _WIN32) || (defined _WIN64)
#include "../NetProSDKAPI.h"
#else
#include "NetProSDKAPI.h"
#endif

#define	 PRO_CHN_MAX_RECV_TALKFILE_SIZE	1024

class CTalkChannel
{
public:
	CTalkChannel();
	~CTalkChannel();


	int		StartTalk(int nIndex, int nChn, int nConnChannel, int nConnID, int nSessionID);
	int		StopTalk(int nConnChannel, int nConnID);
	int		SendAACfile(const char* pFile, int nFlag);
	int		SendAACData(const char* pBuf, int nLen);
	int		CheckTalk();

public:
	EventCallBack	m_eventCB;
	long			m_lUserParam;
	int		m_nIsTalkFlag;
	int		m_nSendFileChannel;
	int		m_nTalkServerChannel;
	int		m_nTalkRespFlag;
	FILE*	m_pReadAAC;

protected:
	int		m_nIndex;
	int		m_nChn;
	int		m_nPro;

};



#endif
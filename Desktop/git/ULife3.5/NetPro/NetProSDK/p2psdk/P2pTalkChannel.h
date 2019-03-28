#ifndef _P2P_TALK_CHANNEL_H_
#define _P2P_TALK_CHANNEL_H_


#include "P2pCommon.h"

#define	 P2P_CHN_MAX_RECV_TALKFILE_SIZE	320*10

class CP2pTalkChannel : CP2pCommon
{
public:
	CP2pTalkChannel();
	virtual ~CP2pTalkChannel();


	int		StartTalk(p2p_transport* pTransPort,  char *pUID, int nDevIndex, int nTalkChn);
	int		StopTalk();
	int		TalkSendFile(const char *pFileName, int nIsPlay);
	int		TalkSendFrame(char *pFrame, int nFrameLen);

	

	static void __cdecl on_connect_result(void *transport, void* user_data, int status);
	static void __cdecl on_disconnect(void *transport, void* user_data, int status);
	static void __cdecl on_recv(void *transport, void *user_data, char* data, int len);
	static void __cdecl on_device_disconnect(void *transport, void *user_data);


	int					m_nConnFlag;
	int					m_nTalkRespFlag;
	int					m_nIsTcpTransPond;
	char				m_strServerAddr[128];
	int					m_nServerPort;
	char				m_strID[128];
protected:
	int		ConnTalkChannel();
	int		ClostTalkChannel();

protected:
	p2p_transport*		m_pTransPort;
	int					m_nTalkChannel;
	char*				m_pSendTalkData;
	int					m_nSendDataLen;
	void*				m_pTcpHandle;
	FILE*				m_pReadTalkFile;
	int					m_nTalkChn;
};

#endif
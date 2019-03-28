#ifndef _GSS_CHANNEL_H_
#define _GSS_CHANNEL_H_

#include "P2pCommon.h"
#define QUERY_AI_ID "XXX"

class CGssChannel
{
public:
	CGssChannel();
	virtual ~CGssChannel();


public:

	long	ConnDev(char* pUid, char* pServer, int nPort, char *pUser, EventCallBack eventCB, long lUserParam);
	long	CloseDev();
	long	SendData(char *pBuf, int nLen);
	long	OpenStream(eNetStreamType eType, char *pBuf, int nLen, StreamCallBack streamCB, long lUserParam);
	long	CloseStream(eNetStreamType eType);
	long	PullConn();
	long	ClosePullConn();
	int		PasueRecvStream(int nPasue);
	int		avSendIOCtrl( unsigned int nIOCtrlType, const char *cabIOCtrlData, int nIOCtrlDataSize);
	int		GetSpecialStreamData(char *pData);
	static void __cdecl on_connect_result(void *transport, void* user_data, int status);
	static void __cdecl on_disconnect(void *transport, void* user_data, int status);
	static void __cdecl on_recv(void *transport, void *user_data, char* data, int len);
	static void __cdecl on_device_disconnect(void *transport, void *user_data);


	static void __cdecl DISPATCH_CB(void* dispatcher, int status, void* user_data, char* server, unsigned short port, unsigned int server_id); 
	static void __cdecl onpull_connect_result(void *transport, void* user_data, int status);
	static void __cdecl onpull_disconnect(void *transport, void* user_data, int status);
	static void __cdecl onpull_recv(void *transport, void *user_data, char* data, int len, char type, unsigned int time_stamp);
	static void __cdecl onpull_device_disconnect(void *transport, void *user_data);

	static fJThRet RunConnThread(void* pParam);
	int	ConnAction();


public:
	void*			m_pTransPort;
	void*			m_pPullTransPort;
	void*			m_pStreamTransPort;
	void*			m_pGetPicturePort;
	int				m_nCurPort;
	int				m_nRecvFirstSDFrame;
	int				m_nProjectType;
	int				m_nLightFlag;

	
	gss_client_conn_cfg		m_connCfg;
	char*					m_pServerAddr;
	char*					m_pDevID;
protected:
	
	int				DealWithCMD(int nIndex, int nChn, int nType, char *pData);
	int				StartStream();
	

	CJLThreadCtrl			m_tcConn;
	EventCallBack			m_eventCB;
	long					m_lUserParam;
	StreamCallBack			m_streamCB;
	long					m_lStreamParam;
	
	gss_client_conn_cb		m_connCB;
	int						m_nIsConnStream;
	int						m_nSignalingFlag;
	int						m_nAVFlag;
	int						m_nGetPicFlag;
	CMutexLock				m_mutexConn;
	int						m_nStopConnFlag;
	void*					m_pDispatcher;
	int						m_nQueryFlag;
};


#endif
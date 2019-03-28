#ifndef _P2P_PROTOCOL_H_
#define _P2P_PROTOCOL_H_

#include "../NetProCommon.h"


#include "P2pMainCtrl.h"

#ifndef MAX_CONN_CHANNEL
#define  MAX_CONN_CHANNEL	120
#endif





class CP2pProtocol : public CNetProCommon
{
public:
	CP2pProtocol();
	virtual ~CP2pProtocol();

	virtual long	Init();
	virtual long	UnInit();
	virtual	long	SetTransportProType(eNetProTransportProType eProType, char* pServerAddr);
	virtual long	ConnServer(char* pServerAddr, int nPort, int nUseTcp, EventCallBack eventCB, long lUserParam);
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


	static void __cdecl on_create_completeCB(p2p_transport *transport,int status,void *user_data);
	static void __cdecl on_disconnect_serverCB(p2p_transport *transport,int status,void *user_data);
	static void __cdecl on_connect_completeCB(p2p_transport *transport,int connection_id,int status,void *transport_user_data,void *connect_user_data);
	static void __cdecl on_connection_disconnectCB(p2p_transport *transport,int connection_id,void *transport_user_data,void *connect_user_data);
	static void __cdecl on_accept_remote_connectionCB(p2p_transport *transport,int connection_id, int conn_flag, void *transport_user_data);
	static void __cdecl on_connection_recvCB(p2p_transport *transport,int connection_id,void *transport_user_data,void *connect_user_data,char* data,int len);
	static void __cdecl on_tcp_proxy_connectedCB(p2p_transport *transport,void *transport_user_data,void *connect_user_data,unsigned short port, char* addr);

protected:
	//int				QueryDispatchServer(char* pDestUser, char *pAddr, );
	int				ConnTurnServer(char* pServerAddr, int nPort, int nUseTcp, EventCallBack eventCB, long lUserParam);
	int				GetCurChannel(int nHandle);
	int				GetFreeChannel();
	
protected:
	CP2PMainCtrl*			m_pMainCtrl[MAX_CONN_CHANNEL];
	CMutexLock				m_mutexGetChannel;
	int						m_nConnServerIndex;
	p2p_transport			*m_pTransPort;
	char*					m_pServerAddr;
	int						m_nIsConnServer;
	EventCallBack			m_eventCB;
	long					m_lUserParam;
	FILE*					m_pWriteFile;
	DWORD					m_dwRecvStartTime;
};

#endif
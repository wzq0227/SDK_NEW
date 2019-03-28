#ifndef P2P_CHANNEL_H_
#define P2P_CHANNEL_H_


#include "P2pDownLoad.h"
#include "P2pTalkChannel.h"
#include "GssChannel.h"



class  CP2pChannel
{
public:
	CP2pChannel(int nIndex);
	CP2pChannel(int nIndex, int nChn);
	virtual ~CP2pChannel();
	int _INIT_(int nIndex);
	long ConnDev(const char* pUID, const char* pUser, const char* pPwd, int nTimeOut, int nConnType, EventCallBack eventCB, long lUserParam,  char *pServerAddr);
	long CloseDev();
	long GetDevChnNum();					// 获取设备通道数
	long CreateStreamChn(int nStreamChn);
	long CheckDev();
	long SetCheckConnTimeinterval(int nMillisecond);
	long OpenStream(int nChannel, char* pPassword, eNetStreamType eType, long lTimeSeconds, long lTimeZone, StreamCallBack streamCB, long lUserParam);
	long CloseStream(int nChannel, eNetStreamType eType);
	long PasueRecvStream(int nChannel, int nPasueFlag);
	long SetParam(int nChannel, eNetProParam eParam, void* lData, int nDataSize, int nTypeTemp = -1);
	long GetParam(int nChannel, eNetProParam eParam, void* lData, int nDataSize);
	long RecDownload(int nChannel, const char* pFileName, char *pSrcFileName);
	long TalkSendFile(int nChannel, const char *pFileName, int nIsPlay);
	long SetStream(int nChannel, eNetVideoStreamType eLevel);
	long StopDownload(int nChannel);
	long DelRec(int nChannel, const char *pFileName);
	long TalkStart(int nChannel);
	long TalkSend(int nChannel, const char* pData, DWORD dwSize);
	long TalkStop(int nChannel);


	static fJThRet RunConnThread(void* pParam);
	int	ConnAction();
	static fJThRet RunTalkSendFileThread(void* pParam);
	int TalkSendFileAction();


	static void __cdecl DISPATCH_CB(void* dispatcher, int status, void* user_data, char* server, unsigned short port, unsigned int server_id); 
	static void __cdecl on_create_completeCB(p2p_transport *transport,int status,void *user_data);
	static void __cdecl on_disconnect_serverCB(p2p_transport *transport,int status,void *user_data);
	static void __cdecl on_connect_completeCB(p2p_transport *transport,int connection_id,int status,void *transport_user_data,void *connect_user_data);
	static void __cdecl on_connection_disconnectCB(p2p_transport *transport,int connection_id,void *transport_user_data,void *connect_user_data);
	static void __cdecl on_accept_remote_connectionCB(p2p_transport *transport,int connection_id, int conn_flag, void *transport_user_data);
	static void __cdecl on_connection_recvCB(p2p_transport *transport,int connection_id,void *transport_user_data,void *connect_user_data,char* data,int len);
	static void __cdecl on_tcp_proxy_connectedCB(p2p_transport *transport,void *transport_user_data,void *connect_user_data,unsigned short port, char* addr);
protected:
	int avSendIOCtrl( unsigned int nIOCtrlType, const char *cabIOCtrlData, int nIOCtrlDataSize);
	int GetTutkParamType(eNetProParam eParam, int nTutkType);
	int	ConnTurnServer(char* pServerAddr, int nPort, int nUseTcp);
	int				DealWithCMD(int nIndex, int nChn, int nType, char *pData);
public:
	EventCallBack			m_eventCB;
	long					m_lUserParam;
	StreamCallBack			m_streamCB;
	long					m_lStreamParam;

	p2p_transport			*m_pTransPort;
	void*					m_pDispatcher;
	int						m_nConnHandle;
	int						m_nGetPictureHandle;

	CP2pDownLoad			m_p2pDownLoad;
	CP2pTalkChannel			m_p2pTalk;
	CGssChannel				m_gssChannel;
	int						m_nConnFlag;
	int						m_nConnTurnServerType;

protected:
	int						m_nIsTcpTransPond;
	int						m_nIndex;
	int						m_nChn;
	int						m_nTalkRunFlag;
	int						m_nPlayAudioFile;
	char					m_strID[P2P_DOWNLOAD_MAX_FILE_LEN];
	char					m_strTalkFile[P2P_DOWNLOAD_MAX_FILE_LEN];
	CJLThreadCtrl			m_tcTalkSendFile;
	CMutexLock				m_mutexTalk;
	CJLThreadCtrl			m_tcConn;
	int						m_nQuerydispatchFlag;  // 查询设备所在服务器标志
	int						m_nConnTurnServerFlag; // 连接服务器标志
	int						m_nStreamType;
	int						m_nConnPictureChannelFlag;
	int						m_nStopConnThreadFlag;
	int						m_nTalkChn;
	
};


#endif
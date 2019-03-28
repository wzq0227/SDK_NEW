#ifndef _GOSCAM_PROTOCOL_CHANNEL_H_
#define _GOSCAM_PROTOCOL_CHANNEL_H_

#include <stdio.h>
#include "GoscamClient.h"
#include "cJSON.h"
#include <vector>
#include <string>
#include <vector>
#include <map>
#include <list>
using namespace std;


#include "NetSDKAPI.h"


#define  GOS_MAX_ADDR_LEN			32
#define  GOS_TOTAL_RECV_LEN			1024*500
#define	 GOS_RECV_HEARTBEAT_TIMEOUT	3*1000

#define ULIFE3_MESSAGE_TYPE_LEN 40
#define ULIFE3_DEVICEID_LEN 64

#ifndef MAX_CONN_CHANNEL
#define  MAX_CONN_CHANNEL	20
#endif

typedef struct _scheckresp{
	char pMsgTypeResp[ULIFE3_MESSAGE_TYPE_LEN];
	char pDevId[ULIFE3_DEVICEID_LEN];
	DWORD timeout;
	DWORD startTime;
	std::string body;
}SRespCheck;

class CGoscamProtocolChannel : public CGoscamClient
{
public:
	CGoscamProtocolChannel(int nIndex);
	virtual ~CGoscamProtocolChannel();

	long	S_Connect(const char* pAddr, int nPort, int nServerType, RecvCallBack serverCB, long lUserParam ,int autoRecnnt);
	long	S_Close();
	long	S_StartHeartBeat(const char* pData, int nDataLen );
	long	S_StopHeartBeat();
	long	S_Send(const char* pData, int nDataLen );
	long	S_Exe_Cmd(const char* pData, int nDataLen ,int block, int timeout, int *nerror,char* pRlt,int *pRltLen);
	long	S_SetKey( unsigned char *pKey, int nKeyLen);
	long BlockRequest( const char* pAddr, int nPort, char* pData, int nDataLen , int timeout, char** pRlt, int *pRltLen , unsigned char *pKey, int nKeyLen);
	void BlockRequestFree(char* pRlt);
	int		ConnectServer();

	static fJThRet RunTaskThread(void* pParam);
	static fJThRet RunRecvThread(void* pParam);
	int	 RunTaskAction();
	int	 RunRecvAction();

	bool	 FindRespTypeAndDevidFromReq(const char* pReq,int nReqLen,char *pRespType, char *pDevId,char *pReqType = NULL);
	bool FindBodyFromReq(const char* preq,int nReqlen,std::string &pBody);
	void CheckIsRespTimeout();
	void	CheckIsSendWhenDisconnect();
	void CheckIsSendRequestUnkonwn();
	void Callback_by_SendFailed(const char* pReq,int reqLen);
	void Callback_by_Timeout(SRespCheck resp);
	void Callback_by_SendReqWhenDisconnect(SRespCheck resp);
	void Callback_by_UnknownReq(const char* req);
	void	StartReconnect();
	void DelFromCheckListAfterRecvResp(char* presp,int respLen);
protected:
	int						m_nCurIndex;
	RecvCallBack			m_gosEventCB;						// 事件回调
	long					m_lGosUserParam;					
	char					m_strAddr[GOS_MAX_ADDR_LEN];
	int						m_nPort;
	int						m_nRunTaskFlag;						// 是否开启执行任务线程
	int						m_nHeartBeatFlag;					// 是否发送心跳标志
	char*					m_pHeartBeat;						// 心跳数据
	int						m_nHeartBeatDataLen;
	DWORD					m_dwLastHeartBeatTime;
	DWORD					m_dwRecvHeartBeatTime;
	int							m_heartCounts;
	DWORD				m_dwLastRecvTimer;
	DWORD				m_connectCount;
	std::string				m_loginString;
	DWORD				m_loginTimeout;
	bool						m_bSucLogin;
	int						m_nStusConn;
	int						m_autoReconnect;
	int						m_nReconnectFlag;

	vector<string>			m_sVectorTask;						// 任务
	vector<string>::iterator m_iterator;	

	CMutexLock				m_mutexLock;
	CJLThreadCtrl			m_tcTask;
	CJLThreadCtrl			m_tcRecv;
	
	SOCKET					m_hSocket;

	CMutexLock				m_mutexLockRespCheck;
	std::map<std::string,std::list<SRespCheck> > m_mapRespCheck;

	CMutexLock				m_listRespsWhenDiscnntLock;
	std::list<SRespCheck>	m_listRespsWhenDiscnnt;

	CMutexLock				m_listUnknowReqsLock;
	std::list<std::string> m_listUnknowReqs;
};

#endif
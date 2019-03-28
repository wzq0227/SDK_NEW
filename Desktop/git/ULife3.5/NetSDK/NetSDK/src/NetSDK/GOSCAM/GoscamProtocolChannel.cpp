#include "GoscamProtocolChannel.h"
#include "Protocol3.h"
#include "TestLog.h"


enum {
	E_STUS_CONN_INIT = 0,
	E_STUS_CONN_START,
	E_STUS_CONN_END,
};

#define ULIFE3_MSG_TYPE "MessageType"
#define ULIFE3_DEVICE_ID "DeviceId"

#define SELECT_TIMEOUT_VAR 100

// #define ULIFE3_MESSAGE_COUNT 30
// char g_MsgTypes[ULIFE3_MESSAGE_COUNT][40] = {
// 	"QueryNewerVersionUPSRequest","QueryNewerVersionUPSResponse",
// 	"AppHeartRequest","AppHeartResponse",
// 	"GetAllAreaInfoRequest","GetAllAreaInfoResponse",
// 	"AppGetBSAddressRequest","APPGetBSAddressResponse",
// 	"UserRegisterRequest","UserRegisterResponse",
// 	"LoginCGSARequest","LoginCGSAResponse",
// 	"BypassParamRequest","BypassParamResponse",
// 	"BindSmartDeviceRequest","BindSmartDeviceResponse",
// 	"UnbindSmartDeviceRequest","UnbindSmartDeviceResponse",
// 	"ModifyDeviceAttrRequest","ModifyDeviceAttrResponse",
// 	"GetUserDeviceListRequest","GetUserDeviceListResponse",
// 	"QueryDeviceBindRequest","QueryDeviceBindResponse",
// 	"ModifyUserPasswordRequest","ModifyUserPasswordResponse",
// 	"GetVerifyCodeRequest","GetVerifyCodeResponse",
// 	"ModifyPasswordByVerifyRequest","ModifyPasswordByVerifyResponse"
// };
// 
// std::map<std::string,std::string> g_mapReqResps;

//void InitUlife3ProtocolMsgType()
//{
// 	if (g_mapReqResps.size() <= 0)
// 	{
// 		for (int i = 0; i < ULIFE3_MESSAGE_COUNT; i += 2)
// 		{
// 			g_mapReqResps.insert(std::map<std::string,std::string>::value_type(g_MsgTypes[i],g_MsgTypes[i+1]));
// 		}
// 	}
//}

CGoscamProtocolChannel::CGoscamProtocolChannel(int nIndex) : CGoscamClient()
{
	memset(m_strAddr, 0, GOS_MAX_ADDR_LEN);
	m_nCurIndex				= nIndex;
	m_nPort					= -1;
	m_nRunTaskFlag			= 0;
	m_dwLastHeartBeatTime	= 0;
	m_dwLastRecvTimer = 0;
	m_dwRecvHeartBeatTime	= 0;
	m_heartCounts = 0;
	m_nHeartBeatFlag		= 0;
	m_connectCount			= 0;
	m_nHeartBeatDataLen		= 0;
	m_nReconnectFlag		= 0;
	m_pHeartBeat			= NULL;
	m_gosEventCB			= NULL;
	m_hSocket				= INVALID_SOCKET;
	m_loginString			= "";
	m_bSucLogin			= false;
	m_loginTimeout		= 0;
	m_autoReconnect		= 1;
	m_nStusConn			= E_STUS_CONN_INIT;

	m_mutexLock.CreateMutex();

	strcpy_s(m_tcTask.m_szName,J_DGB_NAME_LEN,"m_tcTask");
	m_tcTask.SetOwner(this);							
	m_tcTask.SetParam(this);

	strcpy_s(m_tcRecv.m_szName,J_DGB_NAME_LEN,"m_tcRecv");
	m_tcRecv.SetOwner(this);							
	m_tcRecv.SetParam(this);

//	InitUlife3ProtocolMsgType();
	m_mutexLockRespCheck.CreateMutex();
	m_listRespsWhenDiscnntLock.CreateMutex();
	m_listUnknowReqsLock.CreateMutex();
}



CGoscamProtocolChannel::~CGoscamProtocolChannel()
{
	S_Close();
	SAFE_DELETE(m_pHeartBeat);
	m_mutexLock.CloseMutex();
	m_mutexLockRespCheck.CloseMutex();
	m_listRespsWhenDiscnntLock.CloseMutex();
	m_listUnknowReqsLock.CloseMutex();
}

long CGoscamProtocolChannel::S_Close()
{
	S_StopHeartBeat();
	m_autoReconnect = 0;
	TEST_LOG_DATA("Destruct","Close socket!");
	Close(&m_hSocket);
	m_tcTask.StopThread(true);
	m_tcRecv.StopThread(true);
	m_mutexLock.Lock();
	m_sVectorTask.clear();
	m_nRunTaskFlag = 0;
	m_dwLastHeartBeatTime = 0;
	m_connectCount			= 0;
	m_mutexLock.Unlock();

	m_mutexLockRespCheck.Lock();
	m_mapRespCheck.clear();
	m_mutexLockRespCheck.Unlock();

	m_listRespsWhenDiscnntLock.Lock();
	m_listRespsWhenDiscnnt.clear();
	m_listRespsWhenDiscnntLock.Unlock();

	m_listUnknowReqsLock.Lock();
	m_listUnknowReqs.clear();
	m_listUnknowReqsLock.Unlock();

	return 0;
}

long CGoscamProtocolChannel::S_Connect(const char* pAddr, int nPort, int nServerType, RecvCallBack serverCB, long lUserParam ,int autoRecnnt)
{
	if( !pAddr || !serverCB || nPort < 1 ) return NetSDKErr_Param;

	if( m_nRunTaskFlag )	NetSDKErr_Success;
	
	m_gosEventCB		= serverCB;
	m_lGosUserParam		= lUserParam;
	m_nPort				= nPort;
	m_connectCount = 0;
	m_autoReconnect = autoRecnnt;

	memset(m_strAddr, 0, GOS_MAX_ADDR_LEN);
	memcpy(m_strAddr, pAddr, strlen(pAddr));

	m_sVectorTask.clear();
	string str(m_strAddr, strlen(pAddr));
	m_sVectorTask.push_back(str);
	

	m_tcTask.StartThread(RunTaskThread);
	m_tcRecv.StartThread(RunRecvThread);

	m_nRunTaskFlag	= 1;

	return NetSDKErr_Success;

}


int		 CGoscamProtocolChannel::ConnectServer()
{
	//if(m_hSocket != INVALID_SOCKET) return 0;
	if( m_hSocket != INVALID_SOCKET )
	{
		TEST_LOG_DATA("NONBLOCK_REQ","Close socket before Connect!");
		Close(&m_hSocket);
	}

	TEST_LOG_DATA("NONBLOCK_REQ","Start connect server -> %s:%d",m_strAddr,m_nPort);

	m_nStusConn = E_STUS_CONN_START;
	m_heartCounts = 0;
	m_hSocket = Connect(m_strAddr, m_nPort, SOCK_TCP4);
 	if(m_hSocket != INVALID_SOCKET)
 		SetIoSock(m_hSocket,0); //设置socket阻塞
	m_nStusConn = E_STUS_CONN_END;
	if( m_hSocket == INVALID_SOCKET ) 
	{
		TEST_LOG_DATA("NONBLOCK_REQ","Connect server failed!!!");
		return -1;
	}

	TEST_LOG_DATA("NONBLOCK_REQ","Connect server success!!! -> Socket = %d",m_hSocket);
	m_gosEventCB(m_nCurIndex, NETSDK_EVENT_CONN_SUCCESS, 0, NULL,0, m_lGosUserParam);

	m_dwLastHeartBeatTime = JGetTickCount();
	return 0;
}


int	 CGoscamProtocolChannel::RunTaskAction()
{

	int		nRet		= 0;
	int		nCount		= 0;

	if(m_dwLastHeartBeatTime > 0 && m_nHeartBeatFlag)
	{
		//JTRACE("lHandle = %d, m_dwLastHeartBeatTime = %ud, current time = %ud\r\n", m_nCurIndex,m_dwLastHeartBeatTime,JGetTickCount());
		//JTRACE("is now send heart = %d\r\n",(JGetTickCount() - m_dwLastHeartBeatTime) > (15*1000));
		if( (JGetTickCount() - m_dwLastHeartBeatTime) > (15*1000) )
		{
			TEST_LOG_DATA("NONBLOCK_REQ","Once Heart Time -> %ds",(int(JGetTickCount() - m_dwLastHeartBeatTime))/1000);
			if(m_hSocket != INVALID_SOCKET)
			{
				do 
				{
					nRet = GosSend(m_hSocket, m_pHeartBeat, m_nHeartBeatDataLen);
					TEST_LOG_DATA("NONBLOCK_REQ","Real Sended Cmd, heart -> Socket = %d,Ret = %d, %s",m_hSocket,nRet,m_pHeartBeat);
					if(nRet == -10)
					{
						return 2;
					}
					else if (nRet == -1)
					{
						return 3; //连接异常
					}
					nCount ++;
				} while (nRet <= 0 && nCount < 3);
				
				if(nRet > 0)
				{
					m_dwRecvHeartBeatTime = JGetTickCount();
					m_heartCounts++;
				}
				else
				{
					m_gosEventCB(m_nCurIndex, NETSDK_EVENT_CONN_LOST, NetSDKErr_HeartBeat, NULL, 0, m_lGosUserParam);
					JTRACE("lHandle = %d, HeartBeat error **********************************************\r\n", m_nCurIndex);
					return 0;
				}
					
				JTRACE("lHandle = %d, HeartBeat**********************************************\r\n", m_nCurIndex);
				m_dwLastHeartBeatTime = JGetTickCount();
			}

		}
	}

	if(m_sVectorTask.size() < 1) return 0;
	JTRACE("lHandle = %d, RunTaskAction NUM = %d\r\n", m_nCurIndex, m_sVectorTask.size());
	
	m_iterator = m_sVectorTask.begin();
	string str(m_strAddr, strlen(m_strAddr));
	if( str.compare(*m_iterator) == 0 )	// 登录任务
	{
		JTRACE("start connect.......\r\n");
		nRet = ConnectServer();
		m_nReconnectFlag = 0;
		if( nRet < 0 ) 
		{
			m_iterator = m_sVectorTask.erase(m_sVectorTask.begin());
			return 1;
		}
	}
	else													// 请求任务
	{
		if(m_hSocket == INVALID_SOCKET) return 1;
		nRet = GosSend(m_hSocket, (void *)((*m_iterator).c_str()), (*m_iterator).length());
		TEST_LOG_DATA("NONBLOCK_REQ","Real Sended Cmd -> Socket = %d,nRet = %d, %s",m_hSocket,nRet,m_iterator->c_str());
		if(nRet == -10)
		{
			return 2;
		}
		else if (nRet == -1)
		{
			return 3; //连接异常
		}
		JTRACE("GosSend len = %d\r\n", nRet);
	}

	m_iterator = m_sVectorTask.erase(m_sVectorTask.begin());


#if 0	
	for(m_iterator = m_sVectorTask.begin(); m_iterator != m_sVectorTask.end();)
	{
		if(strcmp((const char*)*m_iterator, m_strAddr) == 0)	// 登录任务
		{
			ConnectServer();
		}
		else													// 请求任务
		{
			GosSend(m_hSocket, *m_iterator, strlen((const char*)*m_iterator));
		}

		m_iterator = m_sVectorTask.erase(m_iterator);

		if(m_sVectorTask.size() == 0 ) break;

		++ m_iterator;
	}
#endif 
	return NetSDKErr_Success;
}


int CGoscamProtocolChannel::RunRecvAction()
{
	GosProHead* pHead							= NULL;
	char*		pRecvHead						= {0};
	int			nRet							= -1;
	char*		pRecvData						= NULL;
	char*		pTotalRecv						= NULL;
	int			nTotalRecvLen					= 0;
	int			nSerialNo						= -1;
//	int			nTotalPkt						= 0;
//	int			nCurPkt							= 0;
	DWORD		dwStartTime						= 0;

	if(m_hSocket == INVALID_SOCKET) return -1;

	pTotalRecv = new char[GOS_TOTAL_RECV_LEN];
	memset(pTotalRecv, 0, GOS_TOTAL_RECV_LEN);

	if(dwStartTime == 0) dwStartTime = JGetTickCount();

	nRet = GosRecvHead(m_hSocket, &pRecvHead);
	if(nRet > 0)
	{
		pHead = (GosProHead	*)pRecvHead;
		pHead->serialNo = ntohl(pHead->serialNo);
		pHead->dataLen = ntohs(pHead->dataLen);

		if(nSerialNo < 0) nSerialNo = pHead->serialNo;
		//if(nTotalPkt == 0) nTotalPkt = pHead->totalPkt;

		//JTRACE("Recv head: serialNo = %d, dataLen = %d, proType = %d, msgType = %d\r\n",pHead->serialNo, pHead->dataLen, pHead->proType, pHead->msgType);
		if(pHead && pHead->dataLen > 0)
		{
			
			pRecvData = new char[pHead->dataLen+1];
			memset(pRecvData, 0, pHead->dataLen+1);
			nRet = Recv(m_hSocket, pRecvData, pHead->dataLen);
			TEST_LOG_DATA("NONBLOCK_REQ","Recved len ->%d",nRet);
			if(nRet > 0)
			{
				TEST_LOG_DATA("NONBLOCK_REQ","Decrypt Recved len ->%d,nSerialNo -> %d, pHead->serialNo -> %d, pHead->proType -> %d",nRet,nSerialNo,pHead->serialNo,pHead->proType);
				if(CEasySocket::m_pKeyData && pHead->proType == 2)
				{
					xor_encrypt_64((unsigned char *)pRecvData, nRet, CEasySocket::m_pKeyData);
				}
				//JTRACE("Recv data: %s\r\n", pRecvData);
				if(nSerialNo == pHead->serialNo)
				{
					memcpy(pTotalRecv + nTotalRecvLen, pRecvData, nRet);
					nTotalRecvLen += nRet;
				}
				else
				{	
					TEST_LOG_DATA("NONBLOCK_REQ","nSerialNo != pHead->serialNo");
					m_dwLastRecvTimer = JGetTickCount();
					DelFromCheckListAfterRecvResp(pRecvData,nRet);
					m_gosEventCB(m_nCurIndex, NETSDK_EVENT_GOS_RECV, 0, pRecvData, nRet, m_lGosUserParam);
				}
			}
			else
			{

					SAFE_DELETE(pRecvData);
 					SAFE_DELETE(pRecvHead);
 					SAFE_DELETE(pTotalRecv);
 					return -1; //套接字异常
			}
		
			SAFE_DELETE(pRecvData);
		}
	}
	else
	{
 		SAFE_DELETE(pRecvHead);
 		SAFE_DELETE(pTotalRecv);
 		return -1; //套接字异常
	}

	if(m_dwRecvHeartBeatTime != 0 && (int)(JGetTickCount()-m_dwRecvHeartBeatTime) > GOS_RECV_HEARTBEAT_TIMEOUT)
	{
		m_gosEventCB(m_nCurIndex, NETSDK_EVENT_CONN_LOST, NetSDKErr_HeartBeat, NULL, 0, m_lGosUserParam);
	}

	if(nTotalRecvLen > 0)
	{
		TEST_LOG_DATA("NONBLOCK_REQ","Recved ->%s",pTotalRecv);
		cJSON* pRetRoot = cJSON_Parse( pTotalRecv);

		cJSON* type =cJSON_GetObjectItem(pRetRoot, "MessageType");
		if(type && strcmp(type->valuestring, "AppHeartResponse") == 0 )
		{
			m_dwRecvHeartBeatTime = 0;
			m_heartCounts--;
		}
// 		else
// 		{	
			TEST_LOG_DATA("NONBLOCK_REQ","Start Callback Recv!!!");
			DelFromCheckListAfterRecvResp(pTotalRecv,nTotalRecvLen);
			m_gosEventCB(m_nCurIndex, NETSDK_EVENT_GOS_RECV, 0, pTotalRecv, nTotalRecvLen, m_lGosUserParam);
			TEST_LOG_DATA("NONBLOCK_REQ","End Callback Recv!!!");
// 		}
		cJSON_Delete(pRetRoot);
		
	}
// 	else
// 	{
// 		CheckIsRespTimeout();
// 	}

	SAFE_DELETE(pRecvHead);
	SAFE_DELETE(pTotalRecv);
	return 0;
}

fJThRet CGoscamProtocolChannel::RunTaskThread(void* pParam)
{
	int					iIsRun				= 0;
	CJLThreadCtrl*		pThreadCtrl			= NULL;	
	CGoscamProtocolChannel*	pChannel			= NULL;	
	int					nRet				= 0;
	bool					bFirstReCnnt = true;

	pThreadCtrl	= (CJLThreadCtrl*)pParam;
	if ( pThreadCtrl==NULL )
	{
		return 0;
	}
	pChannel	= (CGoscamProtocolChannel *)pThreadCtrl->GetOwner();
	if ( pChannel == NULL )
	{
		pThreadCtrl->SetThreadState(THREAD_STATE_STOP);		// 运行状态
		return 0;
	}

	iIsRun	= 1;
	while(iIsRun)
	{
		if ( pThreadCtrl->GetNextAction() == THREAD_STATE_STOP )
		{
			iIsRun = 0;										// 不再运行
			break;
		}
		JSleep(SELECT_TIMEOUT_VAR);
		pChannel->m_mutexLock.Lock();
		nRet = pChannel->RunTaskAction();
		if(nRet == 1)
		{
			iIsRun = 100;										// 不再运行
			//break;
		}
		else if(nRet == 2)
		{
			iIsRun = 101;
			//break;
		}
		else if (nRet == 3)
		{
			iIsRun = 102; //连接异常
		}
		else
		{
			iIsRun = 1;
		}
		pChannel->m_mutexLock.Unlock();
		
		//重连
		if (iIsRun == 100 || iIsRun == 101 || iIsRun == 102 || pChannel->m_heartCounts > 2)
		{
			if(iIsRun == 100)	
			{

				if(pChannel->m_autoReconnect)
					pChannel->m_gosEventCB(pChannel->m_nCurIndex, NETSDK_EVENT_CONN_LOST, NetSDKErr_LostConn, NULL, 0, pChannel->m_lGosUserParam);
				else
					pChannel->m_gosEventCB(pChannel->m_nCurIndex, NETSDK_EVENT_CONN_ERR, -1, NULL, 0, pChannel->m_lGosUserParam);

			}

			if(iIsRun == 101 || iIsRun == 102)
			{
				pChannel->m_gosEventCB(pChannel->m_nCurIndex, NETSDK_EVENT_CONN_LOST, NetSDKErr_LostConn, NULL, 0, pChannel->m_lGosUserParam);
			}

// 			if(!bFirstReCnnt)
// 				JSleep(5*1000);
// 			else
// 				bFirstReCnnt = !bFirstReCnnt;
			TEST_LOG_DATA("NONBLOCK_REQ","Close socket in RunTaskThread!");
			pChannel->Close(&pChannel->m_hSocket);
			//pChannel->StartReconnect();
		}
		else
		{
			bFirstReCnnt = true;
		}

	}

	TEST_LOG_DATA("NONBLOCK_REQ","CGoscamProtocolChannel::RunTaskThread exit****************");
	JTRACE("CGoscamProtocolChannel::RunTaskThread exit****************%d\r\n", pChannel->m_nCurIndex);
	pThreadCtrl->NotifyStop();

// 	if(iIsRun == 100)	pChannel->m_gosEventCB(pChannel->m_nCurIndex, NETSDK_EVENT_CONN_ERR, -1, NULL, 0, pChannel->m_lGosUserParam);
// 
// 	if(iIsRun == 101)
// 	{
// 		pChannel->m_sVectorTask.clear();
// 		pChannel->m_gosEventCB(pChannel->m_nCurIndex, NETSDK_EVENT_CONN_LOST, NetSDKErr_LostConn, NULL, 0, pChannel->m_lGosUserParam);
// 	}

	iIsRun = 0;
	return 0;
}

fJThRet CGoscamProtocolChannel::RunRecvThread(void* pParam)
{
	int					iIsRun				= 0;
	CJLThreadCtrl*		pThreadCtrl			= NULL;	
	CGoscamProtocolChannel*	pChannel			= NULL;	
	int snChkTimeout = 0;

	pThreadCtrl	= (CJLThreadCtrl*)pParam;
	if ( pThreadCtrl==NULL )
	{
		return 0;
	}
	pChannel	= (CGoscamProtocolChannel *)pThreadCtrl->GetOwner();
	if ( pChannel == NULL )
	{
		pThreadCtrl->SetThreadState(THREAD_STATE_STOP);		// 运行状态
		return 0;
	}

	iIsRun	= 1;
	while(iIsRun)
	{
		if ( pThreadCtrl->GetNextAction() == THREAD_STATE_STOP )
		{
			iIsRun = 0;										// 不再运行
			break;
		}

		int isReadyRead = 100;
//  		if(pChannel->m_hSocket != INVALID_SOCKET)
//  			isReadyRead = pChannel->IsReadyToRead(pChannel->m_hSocket,SELECT_TIMEOUT_VAR);
//  		else
// 			JSleep(SELECT_TIMEOUT_VAR);
// 		int recvRet = pChannel->RunRecvAction();
//  		if(	(recvRet == -10 && isReadyRead == 1) 		|| 
//  			(recvRet == -1 && isReadyRead != 100)	/*	|| 
//  			( (snChkTimeout % (1000/SELECT_TIMEOUT_VAR)) == 0 && (pChannel->m_dwLastRecvTimer != 0) && (JGetTickCount() - pChannel->m_dwLastRecvTimer) > (30*1000)) 
//  			) */
//  			)
		JSleep(SELECT_TIMEOUT_VAR);
		if (pChannel->m_nStusConn == E_STUS_CONN_START || pChannel->m_nStusConn == E_STUS_CONN_INIT)
		{
			continue;
		}
		int recvRet = pChannel->RunRecvAction();
		if(-1 == recvRet)
		{
			iIsRun =101;
			//break;
		}
		else
		{
			iIsRun = 1;
		}

		if (iIsRun == 101)
		{
			pChannel->m_gosEventCB(pChannel->m_nCurIndex, NETSDK_EVENT_CONN_LOST, NetSDKErr_LostConn, NULL, 0, pChannel->m_lGosUserParam);
			TEST_LOG_DATA("NONBLOCK_REQ","Close socket in RunRecvThread!");
			pChannel->Close(&pChannel->m_hSocket);
			pChannel->StartReconnect();
		}
		else
		{
			pChannel->CheckIsSendWhenDisconnect();
			pChannel->CheckIsSendRequestUnkonwn();

			if ((++snChkTimeout % (1000/SELECT_TIMEOUT_VAR)) == 0)
			{
				pChannel->CheckIsRespTimeout();
				TEST_LOG_DATA("NONBLOCK_REQ","Once Check Timeout End!!! -> disconnect map size = %d,unknown reqs: %d,resp check: %d",
					pChannel->m_listRespsWhenDiscnnt.size(),pChannel->m_listUnknowReqs.size(),pChannel->m_mapRespCheck.size());
			}
		}
	}
	TEST_LOG_DATA("NONBLOCK_REQ","CGoscamProtocolChannel::RunRecvThread exit****************");
	JTRACE("CGoscamProtocolChannel::RunRecvThread exit****************%d\r\n", pChannel->m_nCurIndex);
	pThreadCtrl->NotifyStop();

// 	if(iIsRun == 101)
// 	{
// 		pChannel->m_sVectorTask.clear();
// 		pChannel->m_gosEventCB(pChannel->m_nCurIndex, NETSDK_EVENT_CONN_LOST, NetSDKErr_LostConn, NULL, 0, pChannel->m_lGosUserParam);
// 	}
	iIsRun = 0;
	return 0;
}


long	CGoscamProtocolChannel::S_StartHeartBeat(const char* pData, int nDataLen )
{
	if(m_nHeartBeatFlag) return 0;
	SAFE_DELETE(m_pHeartBeat);
	m_pHeartBeat = new char[nDataLen + 1];

	m_nHeartBeatDataLen = nDataLen;
	memset(m_pHeartBeat, 0, nDataLen + 1);
	memcpy(m_pHeartBeat, pData, nDataLen);
	m_pHeartBeat[nDataLen] = '\0';

	m_nHeartBeatFlag = 1;
	m_dwLastHeartBeatTime = 1;
	return NetSDKErr_Success;
}

long	CGoscamProtocolChannel::S_StopHeartBeat()
{
	m_nHeartBeatFlag = 0;
	m_nHeartBeatDataLen = 0;
	return NetSDKErr_Success;
}

long	CGoscamProtocolChannel::S_Send(const char* pData, int nDataLen )
{
	m_mutexLock.Lock();
// 	char	*pSendData	 = new char[nDataLen + 1];
// 	memset(pSendData, 0, nDataLen + 1);
	
	string str(pData, nDataLen);
	m_sVectorTask.push_back(str);
	m_mutexLock.Unlock();
	//SAFE_DELETE(pSendData);

	return NetSDKErr_Success;
}

long	CGoscamProtocolChannel::S_SetKey( unsigned char *pKey, int nKeyLen)
{
	return CEasySocket::SetKey(pKey, nKeyLen);
}

long	CGoscamProtocolChannel::S_Exe_Cmd(const char* pData, int nDataLen ,int block, int timeout, int *nerror,char* pRlt,int *pRltLen)
{
	std::string	 tempData = pData;
	if(block)
	{
		*nerror = NetSDKErr_NoSupport_BlockMode;
		return NetSDKErr_Error;
	}
	else
	{
		TEST_LOG_DATA("NONBLOCK_REQ","Exe_cmd -> timeout = %d, %s",timeout,pData);
		char pResp[ULIFE3_MESSAGE_TYPE_LEN] = {0};
		char pReqT[ULIFE3_MESSAGE_TYPE_LEN] = {0};
		char pDevid[ULIFE3_DEVICEID_LEN] = {0};

		if( FindRespTypeAndDevidFromReq(tempData.c_str(),tempData.length(),pResp,pDevid,pReqT)  ) 
		{
			TEST_LOG_DATA("NONBLOCK_REQ","Find Req -> %s,%s",pReqT,pResp);
			if(strcmp(pReqT,"LoginCGSARequest") == 0)
			{
				m_loginString = tempData;
				m_loginTimeout = timeout;
				m_bSucLogin = false;
			}

			SRespCheck temp;
			memset(&temp.pDevId,0,sizeof(temp.pDevId));
			memset(&temp.pMsgTypeResp,0,sizeof(temp.pMsgTypeResp));
			strcpy(temp.pMsgTypeResp,pResp);
			strcpy(temp.pDevId,pDevid);
			temp.startTime = JGetTickCount();
			temp.timeout = timeout;
			temp.body = "";

			if(strcmp(pReqT,"BypassParamRequest") == 0)
			{
				FindBodyFromReq(tempData.c_str(),tempData.length(),temp.body);
			}

// 			if (m_hSocket == INVALID_SOCKET)
// 			{
// 				//掉线
// 				//printf("CGoscamProtocolChannel::S_Exe_Cmd m_listRespsWhenDiscnntLock START\n");
// 				m_listRespsWhenDiscnntLock.Lock();
// 				//printf("CGoscamProtocolChannel::S_Exe_Cmd m_listRespsWhenDiscnntLock get lock\n");
// 				TEST_LOG_DATA("Socket is invalid, push cmd to m_listRespsWhenDiscnnt!");
// 				m_listRespsWhenDiscnnt.push_back(temp);
// 				m_listRespsWhenDiscnntLock.Unlock();
// 				//printf("CGoscamProtocolChannel::S_Exe_Cmd m_listRespsWhenDiscnntLock END\n");
// 			}
// 			else
			{
				m_mutexLock.Lock();
				string str(tempData.c_str(), tempData.length());
				TEST_LOG_DATA("NONBLOCK_REQ","Push cmd to m_sVectorTask!");
				m_sVectorTask.push_back(str);
				m_mutexLock.Unlock();

				m_mutexLockRespCheck.Lock();
				std::map<std::string,std::list<SRespCheck> >::iterator it = m_mapRespCheck.find(pResp);
				if (it != m_mapRespCheck.end())
				{
					TEST_LOG_DATA("NONBLOCK_REQ","Push Cmd to m_mapRespCheck!");
					it->second.push_back(temp);
				}
				else
				{
					std::list<SRespCheck> listChecks;
					listChecks.push_back(temp);
					TEST_LOG_DATA("NONBLOCK_REQ","Push Cmd to m_mapRespCheck 1111!");
					m_mapRespCheck.insert(std::map<std::string,std::list<SRespCheck> >::value_type(pResp,listChecks));
				}
				m_mutexLockRespCheck.Unlock();
			}
		}
		else
		{
			TEST_LOG_DATA("NONBLOCK_REQ","unknown type !!!");
			//没有找到对应的应答类型，属于异常情况
			m_listUnknowReqsLock.Lock();
			m_listUnknowReqs.push_back(tempData);
			m_listUnknowReqsLock.Unlock();
		}
		return NetSDKErr_Success;
	}
}

bool	 CGoscamProtocolChannel::FindRespTypeAndDevidFromReq(const char* pReq,int nReqLen,char *pRespType, char *pDevId,char *pReqType)
{
	//g_mapReqResps
	bool bSuc = false;
	cJSON *pReroot = NULL;
	do 
	{
		if (pReq == NULL || pRespType == NULL || pDevId == NULL)
		{
			break;
		}
		
 		pReroot = cJSON_Parse(pReq);
 		if (pReroot)
 		{
 			cJSON* type = cJSON_GetObjectItem(pReroot,ULIFE3_MSG_TYPE);
			if (type)
			{
				if (pReqType)
				{
					strcpy(pReqType,type->valuestring);
				}
				char *pFindReq = NULL;
				if ((pFindReq = strstr(type->valuestring,"Request")) != NULL)
				{
// 					std::map<std::string,std::string>::iterator it = g_mapReqResps.find(type->valuestring);
// 					if (it != g_mapReqResps.end())
// 					{
// 						strcpy(pRespType,it->second.c_str());
// 					}
// 					else
// 					{
						char tmpresq[128] = {0};
						strcpy(tmpresq,type->valuestring);
						char pTm[128] = {0};
						memcpy(pTm,tmpresq,pFindReq-type->valuestring);
						sprintf(pRespType,"%sResponse",pTm);
// 					}
				}
				else if(strstr(type->valuestring,"Response") != NULL)
				{
					strcpy(pRespType,type->valuestring);
					bSuc = true;
				}
				else
				{
					break;
				}
			}
			cJSON *body = cJSON_GetObjectItem(pReroot,"Body");
			if (body)
			{
				cJSON *devid = cJSON_GetObjectItem(body,ULIFE3_DEVICE_ID);
				if (devid)
				{
					strcpy(pDevId,devid->valuestring);
				}
			}
 		}
		bSuc = true;
	} while (false);

	cJSON_Delete(pReroot);
	return bSuc;
}

void CGoscamProtocolChannel::CheckIsRespTimeout()
{
	m_mutexLockRespCheck.Lock();
	DWORD curTime = JGetTickCount();
	std::list<SRespCheck> listTimeout;
	std::map<std::string,std::list<SRespCheck> >::iterator it = m_mapRespCheck.begin();
	for ( ; it != m_mapRespCheck.end(); )
	{
		size_t size = it->second.size();
		int nErase = 0;
		for (int i = 0; i < size; i++)
		{
			SRespCheck itCheck = it->second.front();
			if (itCheck.timeout < curTime - itCheck.startTime)
			{
				//超时，是列表中剔除
				it->second.pop_front();
				nErase++;
				listTimeout.push_back(itCheck);
			}
			else
			{
				//最先进入队列的都没有超时，后面的也应该没有超时
				break;
			}
		}

		if (nErase == size)
		{
			m_mapRespCheck.erase(it++);
		}
		else
		{
			it++;
		}
	}
	m_mutexLockRespCheck.Unlock();
	size_t sizeTimeout = listTimeout.size();
	if(sizeTimeout > 0)
		TEST_LOG_DATA("NONBLOCK_REQ","Timeout List size -> %d",sizeTimeout);
	for(int i = 0; i < sizeTimeout; i++)
	{
		SRespCheck temp = listTimeout.front();
		listTimeout.pop_front();
		Callback_by_Timeout(temp);
	}
}

void CGoscamProtocolChannel::Callback_by_SendFailed( const char* pReq,int reqLen )
{
	//发送失败时，已经回调了，连接断开的消息，暂不处理
	char pResp[ULIFE3_MESSAGE_TYPE_LEN] = {0};
	char pDevid[ULIFE3_DEVICEID_LEN] = {0};
	SRespCheck itCheck;
	if(FindRespTypeAndDevidFromReq(pReq,reqLen,pResp,pDevid))
	{
		m_mutexLockRespCheck.Lock();
		std::map<std::string,std::list<SRespCheck> >::iterator it = m_mapRespCheck.find(pResp);
		if ( it != m_mapRespCheck.end() )
		{
			size_t size = it->second.size();
			if(size > 0)
			{
				itCheck = it->second.front();
				it->second.clear();
			}
			m_mapRespCheck.erase(it);
		}
		m_mutexLockRespCheck.Unlock();

		char pRespData[1024] = {0};
		if (strcmp(itCheck.pDevId,"") == 0)
		{
			//请求时没有带DeviceId
			if(itCheck.body == "")
				sprintf(pRespData,"{\"%s\":\"%s\"}",ULIFE3_MSG_TYPE,itCheck.pMsgTypeResp);
			else
				sprintf(pRespData,"{\"%s\":\"%s\",\"Body\":%s}",ULIFE3_MSG_TYPE,itCheck.pMsgTypeResp,itCheck.body.c_str());
		}
		else
		{
			if(itCheck.body == "")
				sprintf(pRespData,"{\"%s\":\"%s\",\"%s\":\"%s\"}",ULIFE3_MSG_TYPE,itCheck.pMsgTypeResp,ULIFE3_DEVICE_ID,itCheck.pDevId);
			else
				sprintf(pRespData,"{\"%s\":\"%s\",\"%s\":\"%s\",\"Body\":%s}",ULIFE3_MSG_TYPE,itCheck.pMsgTypeResp,ULIFE3_DEVICE_ID,itCheck.pDevId,itCheck.body.c_str());
		}
		m_gosEventCB(m_nCurIndex, NETSDK_EVENT_GOS_RECV, NetSDKErr_SendFailed , pRespData,  strlen(pRespData), m_lGosUserParam);
	}
}

void CGoscamProtocolChannel::Callback_by_Timeout( SRespCheck resp )
{
	char pRespData[1024] = {0};
	if (strcmp(resp.pDevId,"") == 0)
	{
		//请求时没有带DeviceId
		if(resp.body == "")
			sprintf(pRespData,"{\"%s\":\"%s\"}",ULIFE3_MSG_TYPE,resp.pMsgTypeResp);
		else
			sprintf(pRespData,"{\"%s\":\"%s\",\"Body\":%s}",ULIFE3_MSG_TYPE,resp.pMsgTypeResp,resp.body.c_str());
	}
	else
	{
		if(resp.body == "")
			sprintf(pRespData,"{\"%s\":\"%s\",\"%s\":\"%s\"}",ULIFE3_MSG_TYPE,resp.pMsgTypeResp,ULIFE3_DEVICE_ID,resp.pDevId);
		else
			sprintf(pRespData,"{\"%s\":\"%s\",\"%s\":\"%s\",\"Body\":%s}",ULIFE3_MSG_TYPE,resp.pMsgTypeResp,ULIFE3_DEVICE_ID,resp.pDevId,resp.body.c_str());
	}
	TEST_LOG_DATA("NONBLOCK_REQ","Callbakc Timeout -> %s",pRespData);
	m_gosEventCB(m_nCurIndex, NETSDK_EVENT_GOS_RECV, NetSDKErr_Timeout , pRespData, strlen(pRespData), m_lGosUserParam);
}

void CGoscamProtocolChannel::StartReconnect()
{
	//
	if(m_autoReconnect == 0)
		return;

	if(m_nReconnectFlag == 1) return ;
	TEST_LOG_DATA("NONBLOCK_REQ","CGoscamProtocolChannel::StartReconnect !!!!");
	m_mutexLock.Lock();
	string str1(m_strAddr, strlen(m_strAddr));
	TEST_LOG_DATA("NONBLOCK_REQ","CGoscamProtocolChannel::push_back IP,PORT !!!!");
	m_sVectorTask.push_back(str1);
	// 	if(m_loginString != "" && m_bSucLogin)
	// 		m_sVectorTask.push_back(m_loginString);
	m_nReconnectFlag = 1;
	m_mutexLock.Unlock();
	TEST_LOG_DATA("NONBLOCK_REQ","CGoscamProtocolChannel::StartReconnect END!!!!");
	return ;


	std::list<SRespCheck> listTmp;
	m_mutexLockRespCheck.Lock();
	
	m_mutexLock.Lock();
	size_t sizeSend = m_sVectorTask.size();
	if (sizeSend > 0)
	{
		for (int i = 0; i < sizeSend; i++)
		{
			vector<string>::iterator itSend = m_sVectorTask.begin();
			char pResp[ULIFE3_MESSAGE_TYPE_LEN] = {0};
			char pDevid[ULIFE3_DEVICEID_LEN] = {0};
			if (FindRespTypeAndDevidFromReq((*itSend).c_str(),(*itSend).length(),pResp,pDevid))
			{
				std::map<std::string,std::list<SRespCheck> >::iterator itRecv = m_mapRespCheck.find(pResp);
				if (itRecv != m_mapRespCheck.end())
				{
					size_t sizerecv = itRecv->second.size();
					if (sizerecv > 0)
					{
						SRespCheck temp = itRecv->second.front();
						itRecv->second.pop_front();
						listTmp.push_back(temp);
						if (sizerecv == 1)
						{
							m_mapRespCheck.erase(itRecv);
						}
					}
				}
			}
			else
			{
				//没有找到对应的应答类型，属于异常情况
				m_listUnknowReqsLock.Lock();
				m_listUnknowReqs.push_back(*itSend);
				m_listUnknowReqsLock.Unlock();
			}
			m_sVectorTask.erase(itSend);
		}

	}
	m_mutexLock.Unlock();
	m_mutexLockRespCheck.Unlock();

	size_t sizetmp = listTmp.size();
	for ( ; sizetmp > 0; sizetmp--)
	{
		SRespCheck temp = listTmp.front();
		listTmp.pop_front();
		Callback_by_SendReqWhenDisconnect(temp);
	}
	//等待5s，开始重连,将ip地址插入task最前面，达到重连效果
	if((m_connectCount++%9) > 3)
		JSleep(5*1000);
	m_dwLastRecvTimer = 0;
	m_mutexLock.Lock();
	string str(m_strAddr, strlen(m_strAddr));
	m_sVectorTask.push_back(str);
// 	if(m_loginString != "" && m_bSucLogin)
// 		m_sVectorTask.push_back(m_loginString);
	m_mutexLock.Unlock();

// 	if(m_loginString != "" && m_bSucLogin)
// 	{
// 		char pResp[ULIFE3_MESSAGE_TYPE_LEN] = {0};
// 		char pDevid[ULIFE3_DEVICEID_LEN] = {0};
// 		if( FindRespTypeAndDevidFromReq(m_loginString.c_str(),m_loginString.length(),pResp,pDevid)  ) 
// 		{
// 			SRespCheck temp = {0};
// 			strcpy(temp.pMsgTypeResp,pResp);
// 			strcpy(temp.pDevId,pDevid);
// 			temp.startTime = JGetTickCount();
// 			temp.timeout = m_loginTimeout;
// 
// 			m_mutexLockRespCheck.Lock();
// 			std::map<std::string,std::list<SRespCheck> >::iterator it = m_mapRespCheck.find(pResp);
// 			if (it != m_mapRespCheck.end())
// 			{
// 				it->second.push_back(temp);
// 			}
// 			else
// 			{
// 				std::list<SRespCheck> listChecks;
// 				listChecks.push_back(temp);
// 				m_mapRespCheck.insert(std::map<std::string,std::list<SRespCheck> >::value_type(pResp,listChecks));
// 			}
// 			m_mutexLockRespCheck.Unlock();
// 		}
// 	}
}

void CGoscamProtocolChannel::DelFromCheckListAfterRecvResp( char* presp,int respLen )
{
	char pResp[ULIFE3_MESSAGE_TYPE_LEN] = {0};
	char pDevid[ULIFE3_DEVICEID_LEN] = {0};
	if(FindRespTypeAndDevidFromReq(presp,respLen,pResp,pDevid))
	{
		if (strcmp(pResp,"LoginCGSAResponse") == 0)
		{
			m_bSucLogin = true;
		}
		m_mutexLockRespCheck.Lock();
		std::map<std::string,std::list<SRespCheck> >::iterator it = m_mapRespCheck.find(pResp);
		if (it != m_mapRespCheck.end())
		{
			size_t size = it->second.size();
			
			if(size > 1)
			{
				it->second.pop_front();
			}
			else
			{
				m_mapRespCheck.erase(it);
			}
			TEST_LOG_DATA("NONBLOCK_REQ","Delete Resp Check -> %s",pResp);
		}
		
		m_mutexLockRespCheck.Unlock();
	}
}

void CGoscamProtocolChannel::CheckIsSendWhenDisconnect()
{
	//printf("CGoscamProtocolChannel::CheckIsSendWhenDisconnect() START\n");
	std::list<SRespCheck> listTmp;
	m_listRespsWhenDiscnntLock.Lock();
	//printf("CGoscamProtocolChannel::CheckIsSendWhenDisconnect() GET LOCK\n");
	size_t size = m_listRespsWhenDiscnnt.size();
	if (size > 0)
	{
		for ( ; size > 0; size--)
		{
			SRespCheck temp = m_listRespsWhenDiscnnt.front();
			m_listRespsWhenDiscnnt.pop_front();
			listTmp.push_back(temp);
			//Callback_by_SendReqWhenDisconnect(temp);
		}
	}
	m_listRespsWhenDiscnntLock.Unlock();

	size_t sizetmp = listTmp.size();
	for ( ; sizetmp > 0; sizetmp--)
	{
		SRespCheck temp = listTmp.front();
		listTmp.pop_front();
		Callback_by_SendReqWhenDisconnect(temp);
	}
	//printf("CGoscamProtocolChannel::CheckIsSendWhenDisconnect() END\n");
}

void CGoscamProtocolChannel::CheckIsSendRequestUnkonwn()
{
	std::list<std::string> listTmp;
	m_listUnknowReqsLock.Lock();
	size_t size = m_listUnknowReqs.size();
	if (size > 0)
	{
		for ( ; size > 0; size--)
		{
			std::string temp = m_listUnknowReqs.front();
			m_listUnknowReqs.pop_front();
			listTmp.push_back(temp);
			//Callback_by_UnknownReq(temp.c_str());
		}
	}
	m_listUnknowReqsLock.Unlock();

	size = listTmp.size();
	for ( ; size > 0; size--)
	{
		std::string temp = listTmp.front();
		listTmp.pop_front();
		Callback_by_UnknownReq(temp.c_str());
	}
}

void CGoscamProtocolChannel::Callback_by_SendReqWhenDisconnect( SRespCheck resp )
{
	char pRespData[1024] = {0};
	if (strcmp(resp.pDevId,"") == 0)
	{
		//请求时没有带DeviceId
		if(resp.body == "")
			sprintf(pRespData,"{\"%s\":\"%s\"}",ULIFE3_MSG_TYPE,resp.pMsgTypeResp);
		else
			sprintf(pRespData,"{\"%s\":\"%s\",\"Body\":%s}",ULIFE3_MSG_TYPE,resp.pMsgTypeResp,resp.body.c_str());
	}
	else
	{
		if(resp.body == "")
			sprintf(pRespData,"{\"%s\":\"%s\",\"%s\":\"%s\"}",ULIFE3_MSG_TYPE,resp.pMsgTypeResp,ULIFE3_DEVICE_ID,resp.pDevId);
		else
			sprintf(pRespData,"{\"%s\":\"%s\",\"%s\":\"%s\",\"Body\":%s}",ULIFE3_MSG_TYPE,resp.pMsgTypeResp,ULIFE3_DEVICE_ID,resp.pDevId,resp.body.c_str());
	}
	m_gosEventCB(m_nCurIndex, NETSDK_EVENT_GOS_RECV, NetSDKErr_SendReqWhenDisconnect ,  pRespData, strlen(pRespData), m_lGosUserParam);
}

void CGoscamProtocolChannel::Callback_by_UnknownReq( const char* req )
{
	m_gosEventCB(m_nCurIndex, NETSDK_EVENT_GOS_RECV, NetSDKErr_NoSupport_Req , (char*)req, strlen(req), m_lGosUserParam);
}

bool CGoscamProtocolChannel::FindBodyFromReq( const char* preq,int nReqlen,std::string &pBody )
{
	bool bsuc = false;
	do 
	{
		if(preq == NULL || nReqlen <= 0)
			break;

		cJSON* pRetRoot = cJSON_Parse( preq);

		cJSON* type =cJSON_GetObjectItem(pRetRoot, "Body");
		if (type)
		{
			pBody = cJSON_Print(type);
		}
		
		cJSON_Delete(pRetRoot);

		bsuc = true;
	} while (false);

	return bsuc;
}

long CGoscamProtocolChannel::BlockRequest( const char* pAddr, int nPort,char* pData, int nDataLen , int timeout, char** pRlt, int *pRltLen , unsigned char *pKey, int nKeyLen)
{
	long rlt_code = NetSDKErr_Success;
	SOCKET hsocket = INVALID_SOCKET;
	
	do 
	{
		if (pAddr == NULL || pData == NULL || *pRlt != NULL || pRltLen == NULL)
		{
			rlt_code = NetSDKErr_Param;
			break;
		}

		TEST_LOG_DATA("BLOCK_REQ","Start connect -> pAddr = %s,port = %d",pAddr,nPort);
        hsocket = Connect(pAddr, nPort, SOCK_TCP4);//, timeout);
		if( hsocket == INVALID_SOCKET ) 
		{
			TEST_LOG_DATA("BLOCK_REQ","Connect failed!");		
			rlt_code = NetSDKErr_ConnectFailed;
			break;
		}
		TEST_LOG_DATA("BLOCK_REQ","Connect successful! -> socket = %d,psend = %s",hsocket,pData);

		CEasySocket::SetKey(pKey, nKeyLen);

		int nRet = GosSend(hsocket,pData,nDataLen);
		if(nRet == -10)
		{
			rlt_code = NetSDKErr_SendFailed;
			break;
		}
		else if (nRet == -1)
		{
			rlt_code = NetSDKErr_SendFailed;
			break; //连接异常
		}

		HandleProtocol3 proto;
		int headerlen = 16;
		char pHeader[16] = {0};
		char *pRecvTmp = pHeader;
		int nNeedRecvLen = headerlen;
		bool bRecvHeaderOk = false;
		int nRecvedLen = 0;
		DWORD nCurrentTime = JGetTickCount();
		DWORD tmpTimeout = (DWORD)timeout;
		do 
		{
			int readytoread = IsReadyToRead(hsocket,timeout);
			if(readytoread == 0)
			{
				rlt_code = NetSDKErr_Timeout;
				break;
			}
			else if (readytoread == -1)
			{
				rlt_code = NetSDKErr_SocketError;
				break;
			}

			nRet = Recv1(hsocket, pRecvTmp+nRecvedLen, nNeedRecvLen-nRecvedLen);
			TEST_LOG_DATA("BLOCK_REQ","Need Recv -> %d, nRet = %d",nNeedRecvLen-nRecvedLen,nRet);
			if(nRet == -1 || nRet == -2)
			{
				printf("error is %d,%s\n",errno,strerror(errno));
				rlt_code = NetSDKErr_SocketError;
				break;
			}
			nRecvedLen += nRet;
			if (nRecvedLen == nNeedRecvLen)
			{
				if(!bRecvHeaderOk)
				{
					bRecvHeaderOk = true;
					nNeedRecvLen = ntohs(*((unsigned short*)(pRecvTmp+8)));
					pRecvTmp = (char*)malloc(nNeedRecvLen + headerlen);
					nRecvedLen = headerlen;
					nNeedRecvLen += nRecvedLen;
					memcpy(pRecvTmp,pHeader,headerlen);
				}
				else
				{
					break;
				}
			}
			
			if ( tmpTimeout < JGetTickCount() - nCurrentTime )
			{
				rlt_code = NetSDKErr_Timeout;
				break;
			}
			else
			{
				timeout -= JGetTickCount() - nCurrentTime;
			}
		} while (nRet > 0);
		
		if(pRecvTmp)
		{
			if(CEasySocket::m_pKeyData)
			{
				xor_encrypt_64((unsigned char *)(pRecvTmp+sizeof(GosProHead)), nNeedRecvLen-sizeof(GosProHead), CEasySocket::m_pKeyData);
			}
			*pRlt = (char*)malloc( nNeedRecvLen-sizeof(GosProHead)+1);
			memcpy(*pRlt,pRecvTmp+sizeof(GosProHead),nNeedRecvLen-sizeof(GosProHead));
			*(*pRlt+(nNeedRecvLen-sizeof(GosProHead))) = '\0';
			*pRltLen = nNeedRecvLen-sizeof(GosProHead);
			//proto.Parse(pRecvTmp,nNeedRecvLen);
		}
#if 0
		//目前只同时处理一天完整的消息
		if (proto.GetCountParseMessage() > 0)
		{
			char* pDst = proto.GetOneParseMessage();
			int len = strlen(pDst);

			if(CEasySocket::m_pKeyData)
			{
				xor_encrypt_64((unsigned char *)pDst, len, CEasySocket::m_pKeyData);
			}
			*pRlt = (char*)malloc(len + 1);
			memcpy(*pRlt,pDst,len);
			*(*pRlt+len) = '\0';
			*pRltLen = len;
		}
		else
		{
			break;
		}
#endif
	} while (false);

	if(rlt_code == NetSDKErr_Success)
	{
		if (pRlt && *pRlt)
		{
			TEST_LOG_DATA("BLOCK_REQ","Block Request successful! -> recv = %s",*pRlt);
		}
		else
		{
			TEST_LOG_DATA("BLOCK_REQ","Block Request successful! But out recv is null!");
		}
	}
	else
	{
		TEST_LOG_DATA("BLOCK_REQ","Block Request failed! -> rlt_code = %d",rlt_code);
		if (pRlt && *pRlt)
		{
			free(*pRlt);
			*pRlt = NULL;
		}
	}

	if (hsocket != INVALID_SOCKET)
	{
		TEST_LOG_DATA("BLOCK_REQ","Close socket!");
		Close(&hsocket);
	}

	return rlt_code;
}

void CGoscamProtocolChannel::BlockRequestFree( char* pRlt )
{
	if (pRlt)
	{
		free(pRlt);
	}
}
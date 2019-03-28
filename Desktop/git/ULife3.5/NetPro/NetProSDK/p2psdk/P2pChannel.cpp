#include "P2pChannel.h"


CP2pChannel::CP2pChannel(int nIndex)
{
	_INIT_(nIndex);
}

CP2pChannel::CP2pChannel(int nIndex, int nChn)
{
	m_nChn = nChn;
	_INIT_(nIndex);
}

int CP2pChannel::_INIT_(int nIndex)
{
	m_nIndex				= nIndex;
	m_gssChannel.m_nCurPort	= nIndex+P2P_CHANNEL_ADDVALUE;
	m_pTransPort			= NULL;
	m_nConnHandle			= -1;
	m_nIsTcpTransPond		= 0;
	m_eventCB				= NULL;
	m_lUserParam			= NULL;
	m_streamCB				= NULL;
	m_lStreamParam			= NULL;
	m_pDispatcher			= NULL;
	m_nTalkRunFlag			= 0;
	m_nQuerydispatchFlag	= -1;
	m_nConnTurnServerFlag	= -1;
	m_nConnFlag				= -1;
	m_nConnPictureChannelFlag = -1;
	m_nTalkChn				= 0;
	m_nStreamType			= 0;
	m_nPlayAudioFile		= 0;
	m_nGetPictureHandle		= -1;
	m_nConnTurnServerType   = 0;
	m_nStopConnThreadFlag	= 0;
	m_mutexTalk.CreateMutex();
	strcpy_s(m_tcTalkSendFile.m_szName,J_DGB_NAME_LEN,"m_tcTalkSendFile");
	m_tcTalkSendFile.SetOwner(this);
	m_tcTalkSendFile.SetParam(this);

	strcpy_s(m_tcConn.m_szName,J_DGB_NAME_LEN,"m_tcConn");
	m_tcConn.SetOwner(this);
	m_tcConn.SetParam(this);

	return 0;
}

CP2pChannel::~CP2pChannel()
{
	m_tcConn.StopThread(true);
	m_mutexTalk.CloseMutex();
}

void CP2pChannel::on_create_completeCB(p2p_transport *transport,int status,void *user_data)
{
	CP2pChannel *pThis = (CP2pChannel *)user_data;
	if(status == 0)
	{
		pThis->m_nConnTurnServerFlag = 1;
		JTRACE("p2p_transport_create success\r\n");
	}
	else
	{
		pThis->m_nConnTurnServerFlag = 0;
		JTRACE("p2p_transport_create error = %d\r\n", status);
	}
}

void CP2pChannel::on_disconnect_serverCB(p2p_transport *transport,int status,void *user_data)
{
	CP2pChannel *pThis = (CP2pChannel *)user_data;
	pThis->m_eventCB(pThis->m_nIndex+P2P_CHANNEL_ADDVALUE, 0 , NETPRO_EVENT_LOSTCONNECTION, status, NULL, pThis->m_lUserParam);
	JTRACE("on_disconnect_serverCB................ \r\n");
}

void CP2pChannel::on_connect_completeCB(p2p_transport *transport,int connection_id,int status,void *transport_user_data,void *connect_user_data)
{
	CP2pChannel *pThis = (CP2pChannel *)transport_user_data;
	JTRACE("connection_id = %d, status = %d\r\n", connection_id, status);
	int nCurHandle = (long)connect_user_data;

	// 
	// 	char addr[256];
	// 	int len = sizeof(addr);
	// 	p2p_addr_type addr_type;
	// 	p2p_get_conn_remote_addr(transport, connection_id, addr, &len, &addr_type);
	// 	JTRACE("addr_type = %d\r\n", addr_type);
	if(nCurHandle >= P2P_DOWNLOAD_HANDLE && nCurHandle < P2P_TALK_HANDLE)  // 下载通道连接状态
	{
		if(status == 0)
		{
			pThis->m_p2pDownLoad.m_nConnDownLoadFlag = 1;
		}
		else
		{
			pThis->m_p2pDownLoad.m_nConnDownLoadFlag = 0;
		}
	}
	else if( nCurHandle >= P2P_TALK_HANDLE && nCurHandle < P2P_GETPICTURE_HANDLE)	// 对讲通道状态
	{
		if(status == 0)
			pThis->m_p2pTalk.m_nConnFlag = 1;
		else
			pThis->m_p2pTalk.m_nConnFlag = 0;
	}
	else if(nCurHandle >= P2P_GETPICTURE_HANDLE)
	{
		if(status == 0)
			pThis->m_nConnPictureChannelFlag = 1;
		else
			pThis->m_nConnPictureChannelFlag = 0;
	}
	else	// 设备登录状态
	{
		if(status == 0)
		{
			pThis->m_nConnFlag = 1;
		}
		else
		{
			pThis->m_nConnFlag = 0;
		}
	}

}

void CP2pChannel::on_connection_disconnectCB(p2p_transport *transport,int connection_id,void *transport_user_data,void *connect_user_data)
{
	CP2pChannel *pThis = (CP2pChannel *)transport_user_data;
	int nCurHandle = (long)connect_user_data;
	JTRACE("on_connection_disconnectCB connection_id = %d\r\n", connection_id);

	if(nCurHandle >= P2P_DOWNLOAD_HANDLE && nCurHandle < P2P_TALK_HANDLE)  // 下载通道连接状态
	{
		nCurHandle -= P2P_DOWNLOAD_HANDLE;
		nCurHandle -= P2P_CHANNEL_ADDVALUE;
	}
	else if( nCurHandle >= P2P_TALK_HANDLE && nCurHandle < P2P_GETPICTURE_HANDLE)	// 对讲通道状态
	{
		nCurHandle -= P2P_TALK_HANDLE;
	}
	else if(nCurHandle >= P2P_GETPICTURE_HANDLE)
	{
		nCurHandle -= P2P_GETPICTURE_HANDLE;
	}

	pThis->m_eventCB(nCurHandle + P2P_CHANNEL_ADDVALUE, 0 , NETPRO_EVENT_LOSTCONNECTION, 0, NULL, pThis->m_lUserParam);
}

void CP2pChannel::on_accept_remote_connectionCB(p2p_transport *transport,int connection_id, int conn_flag, void *transport_user_data)
{
	JTRACE("on_accept_remote_connectionCB****************************************************\r\n");
}
#if 0
static FILE * fp = NULL;
static int ggCount = 0;
#endif
void CP2pChannel::on_connection_recvCB(p2p_transport *transport,int connection_id,void *transport_user_data,void *connect_user_data,char* data,int len)
{
	CP2pChannel *pThis = (CP2pChannel *)transport_user_data;
	int nCurHandle = (long)connect_user_data;
	P2pHead *pHead = (P2pHead *)data;
	PAVBuffArray		pstEle		= NULL;

	if(pThis->m_nConnHandle < 0) return;

	if(nCurHandle >= P2P_DOWNLOAD_HANDLE && nCurHandle < P2P_TALK_HANDLE)  // 下载通道连接状态
	{
		nCurHandle -= P2P_DOWNLOAD_HANDLE;
		nCurHandle -= P2P_CHANNEL_ADDVALUE;
	}
	else if( nCurHandle >= P2P_TALK_HANDLE && nCurHandle < P2P_GETPICTURE_HANDLE)	// 对讲通道状态
	{
		nCurHandle -= P2P_TALK_HANDLE;
	}
	else if(nCurHandle >= P2P_GETPICTURE_HANDLE)
	{
		nCurHandle -= P2P_GETPICTURE_HANDLE;
	}
	if(len != ( pHead->dataLen + sizeof(P2pHead)))
		JTRACE("***********************************************************************len = %d,  dataLen = %d\r\n", len, pHead->dataLen);
	//
	if(pHead->magicNo != 0x67736d80)
	{
		JTRACE("***********************************************************************\r\n\r\n");
		return ;
	}
	if(pHead->msgChildType == RECV_VIDEO_FRAME || pHead->msgChildType == RECV_AUDIO_FRAME)
	{
		gos_frame_head *pFrame = (gos_frame_head *)(data+sizeof(P2pHead));

		if(pHead->msgChildType == RECV_VIDEO_FRAME)
		{
			if(len > 500 *1024)
			{
				JTRACE(" recvlen = %d, dataLen = %d,  nFrameNo = %d, nFrameType = %d, nFrameRate = %d, nDataSize = %d\r\n",
					len, pHead->dataLen, pFrame->nFrameNo, pFrame->nFrameType, pFrame->nFrameRate, pFrame->nDataSize);

			}

    			
 
			/*unsigned char * pTeTTT = (unsigned char *)(data+sizeof(P2pHead)+sizeof(gos_frame_head));
			JTRACE("%d------%x, %x, %x, %x\r\n", pFrame->nFrameType,pTeTTT[0], pTeTTT[1],pTeTTT[2],pTeTTT[3]); 
			if( (pFrame->nFrameNo - nFrameNo) != 1) 
			{
 				JTRACE("====================================================================================================================%d, %d\r\n", pFrame->nFrameNo, nFrameNo);
 			}
 			nFrameNo = pFrame->nFrameNo;*/
		}
		else
		{	
			
#if 0
			if(fp == NULL)
			{
				fp = fopen("D:\\11111111111111.g711a", "wb");
			}
			if(fp)
			{
				ggCount ++;
				fwrite(data+sizeof(P2pHead)+sizeof(gos_frame_head), pFrame->nDataSize, 1, fp );
			}

			if(ggCount > 500 && fp)
			{
				fclose(fp);
				fp = NULL;
			}
#endif
			//JTRACE("gnframeno = %d recvlen = %d, dataLen = %d,  nFrameNo = %d, nFrameType = %d, nFrameRate = %d, nDataSize = %d\r\n",
				//	gnframeno, len, pHead->dataLen, pFrame->nFrameNo, pFrame->nFrameType, pFrame->nFrameRate, pFrame->nDataSize);
		}

// 		JTRACE("recvlen = %d, dataLen = %d,  nFrameNo = %d, nFrameType = %d, nFrameRate = %d, nDataSize = %d\r\n",
// 			len, pHead->dataLen, pFrame->nFrameNo, pFrame->nFrameType, pFrame->nFrameRate, pFrame->nDataSize);

 		
		if((pHead->dataLen+sizeof(P2pHead)) != len)
		{
			JTRACE("----------------************************************-------------------\r\n");
			return;
		}
		if(pFrame->nFrameType == gos_video_rec_end_frame)
		{
			JTRACE("----------------gos_video_rec_end_frame-------------------\r\n");
		}

		if(pFrame->nFrameType == gos_video_rec_start_frame) pThis->m_gssChannel.m_nRecvFirstSDFrame =  1;

		if(pThis->m_gssChannel.m_nRecvFirstSDFrame ==  0 && pFrame->nFrameType != gos_video_preview_i_frame)
		{
			JTRACE("no recv gos_video_rec_start_frame.....................................................\r\n");
			return ;
		}
		
		if(pThis->m_gssChannel.GetSpecialStreamData(data+sizeof(P2pHead)))
		{
			return ;
		} 


		
		if(pThis->m_streamCB)
			pThis->m_streamCB(nCurHandle + P2P_CHANNEL_ADDVALUE, 0, (unsigned char *)(data+sizeof(P2pHead)), pHead->dataLen, pThis->m_lStreamParam);
	}
	else if(pHead->msgChildType == RECV_DOWNLOAD_FRAME)
	{
		FILE_PACKET_HEAD *pPktHead = (FILE_PACKET_HEAD *)(data+sizeof(P2pHead));
		if(pPktHead)
		{
			JTRACE("total_packet_num = %d, curr_packet_no = %d, curr_packet_length = %d\r\n", pPktHead->total_packet_num, pPktHead->curr_packet_no, pPktHead->curr_packet_length );
			pstEle = pThis->m_p2pDownLoad.m_avbuffCtrl.BeginAddBuff( data+sizeof(P2pHead), pHead->dataLen, 0, 0 );
			if( pstEle )
			{
				pThis->m_p2pDownLoad.m_avbuffCtrl.EndAddBuff();
			}
		}

	}
	else
	{
		pThis->DealWithCMD(nCurHandle + P2P_CHANNEL_ADDVALUE, 0, pHead->msgChildType, (data+sizeof(P2pHead)));
		JTRACE("**********************recvlen = %d, dataLen = %d, proType = %d, msgType = %d, msgChildType = %x\r\n",len, pHead->dataLen, pHead->proType, pHead->msgType, pHead->msgChildType);
	}
}

void CP2pChannel::on_tcp_proxy_connectedCB(p2p_transport *transport,void *transport_user_data,void *connect_user_data,unsigned short port, char* addr)
{

}

void CP2pChannel::DISPATCH_CB(void* dispatcher, int status, void* user_data, char* server, unsigned short port, unsigned int server_id)
{
	CP2pChannel *pThis = (CP2pChannel *)user_data;
	JTRACE("DISPATCH_CB...........%d\r\n", status);

	if(pThis && pThis->m_nStopConnThreadFlag) return;

	if(status == 0)
	{
		pThis->m_nQuerydispatchFlag = 1;
		pThis->ConnTurnServer(server, port, 0);
	}
	else
	{
		pThis->m_nQuerydispatchFlag = 0;
	}

}

int	CP2pChannel::ConnTurnServer(char* pServerAddr, int nPort, int nUseTcp)
{
	int						nRet	= 0;
	p2p_transport_cfg		cfg		= {0};
	p2p_transport_cb		cb		= {0};


	cb.on_create_complete = on_create_completeCB;
	cb.on_disconnect_server = on_disconnect_serverCB;
	cb.on_connect_complete = on_connect_completeCB;
	cb.on_connection_disconnect = on_connection_disconnectCB;
	cb.on_accept_remote_connection = on_accept_remote_connectionCB;
	cb.on_connection_recv = on_connection_recvCB;
	cb.on_tcp_proxy_connected = on_tcp_proxy_connectedCB;

	memset(&cfg, 0, sizeof(cfg));
	cfg.server = pServerAddr;
	cfg.port = (short)nPort;
	cfg.terminal_type = P2P_CLIENT_TERMINAL;
	cfg.user = NULL;
	cfg.password = NULL;
	cfg.user_data = this;
	cfg.use_tcp_connect_srv = m_nConnTurnServerType/*nUseTcp*/;
	cfg.cb = &cb;

	nRet = p2p_transport_create(&cfg, &m_pTransPort);
	if(nRet != 0 )
	{
		return NetProErr_TransPortCreateErr;
	}

	return NetProErr_Success;
}

long CP2pChannel::ConnDev(const char* pUID, const char* pUser, const char* pPwd, int nTimeOut, int nConnType, EventCallBack eventCB, long lUserParam,  char *pServerAddr)
{
	int				nRet			= 0;
	int				nServerType		= 0;
	
	if(eventCB == NULL) return NetProErr_Param;

	m_eventCB = eventCB;
	m_lUserParam = lUserParam;
	memset(m_strID, '\0', sizeof(m_strID));
	sprintf(m_strID, "%s", pUID);
	
	if(nConnType >= 10)
	{	
		m_nIsTcpTransPond = 1;
		m_gssChannel.m_nProjectType = nConnType-10;
		memset(m_p2pDownLoad.m_strID, 0, sizeof(m_p2pDownLoad.m_strID));
		memcpy(m_p2pDownLoad.m_strID, pUID, strlen(pUID));
		m_p2pDownLoad.m_nIsTcpTransPond = 1;
		
		memset(m_p2pTalk.m_strID, 0, sizeof(m_p2pTalk.m_strID));
		memcpy(m_p2pTalk.m_strID, pUID, strlen(pUID));
		m_p2pTalk.m_nIsTcpTransPond = 1;
		m_nStopConnThreadFlag = 2;
		return m_gssChannel.ConnDev((char *)pUID, pServerAddr, nTimeOut, (char *)pUser, eventCB, lUserParam);
	}
	m_gssChannel.m_nProjectType = nConnType;

	if(m_nConnHandle >= 0 || m_pDispatcher) return NetProErr_HasConnect;
	m_nConnTurnServerType = nTimeOut;
	p2p_query_dispatch_server((char*)pUID, pServerAddr, this, DISPATCH_CB, &m_pDispatcher);

	m_tcConn.StartThread(RunConnThread);

	return NetProErr_Success;
}
fJThRet CP2pChannel::RunConnThread(void* pParam)
{
	JLOG_TRY
	CJLThreadCtrl*		pThreadCtrl			= NULL;
	CP2pChannel*	pChannel			= NULL;
	int				iIsRun				= 0;
	int				nRet				= 0;

	pThreadCtrl	= (CJLThreadCtrl*)pParam;
	if ( pThreadCtrl==NULL )
	{
		return 0;
	}
	pChannel	= (CP2pChannel *)pThreadCtrl->GetOwner();
	if ( pChannel == NULL )
	{
		pThreadCtrl->SetThreadState(THREAD_STATE_STOP);		
		return 0;
	}
	
	pChannel->ConnAction();
	iIsRun	= 1;
	pChannel->m_mutexTalk.Lock();
	pChannel->m_nStopConnThreadFlag = 2;
	pChannel->m_mutexTalk.Unlock();
	//pThreadCtrl->NotifyStop();
	iIsRun = 0;
	JTRACE("CP2pChannel::RunConnThread exit **********************\r\n");
	return 0;
	JLOG_CATCH("CP2pChannel::RunConnThread exit **********************\r\n");
	
	return 0;
}

int	CP2pChannel::ConnAction()
{
	int nCount = 0;
	int nRet   = 0;

	while(nCount < 500 && m_nQuerydispatchFlag < 0 && !m_nStopConnThreadFlag)
	{
		JSleep(10);
		nCount ++;
	}
	if(m_nStopConnThreadFlag) 
	{
		if(m_pDispatcher)
		{
			destroy_p2p_dispatch_requester(m_pDispatcher);
			m_pDispatcher = NULL;
		}
		return 0;
	}

	if(m_nQuerydispatchFlag != 1)
	{
		if(m_pDispatcher)
		{
			destroy_p2p_dispatch_requester(m_pDispatcher);
			m_pDispatcher = NULL;
		}
		m_nQuerydispatchFlag = -1;
		m_nStopConnThreadFlag = 2;
		m_eventCB(m_nIndex + P2P_CHANNEL_ADDVALUE, 0 , NETPRO_EVENT_CONN_ERR, -10001, NULL,m_lUserParam);
		return 0;
	}

	if(m_pDispatcher)
	{
		destroy_p2p_dispatch_requester(m_pDispatcher);
		m_pDispatcher = NULL;
	}

	nCount = 0;
	while(nCount < 500 && m_nConnTurnServerFlag < 0 && !m_nStopConnThreadFlag)
	{
		JSleep(10);
		nCount ++;
	}
	if(m_nStopConnThreadFlag) return 0;
	if(m_nConnTurnServerFlag != 1 )
	{
		if(m_pTransPort)
		{
			p2p_transport_destroy(m_pTransPort);
			m_pTransPort = NULL;
		}
		m_nConnTurnServerFlag = -1;
		m_nStopConnThreadFlag = 2;
		m_eventCB(m_nIndex + P2P_CHANNEL_ADDVALUE, 0 , NETPRO_EVENT_CONN_ERR, -10002, NULL,m_lUserParam);
		return 0;
	}

	m_nConnFlag = -1;
	m_nConnPictureChannelFlag = -1;
	nRet = p2p_transport_connect(m_pTransPort, (char*)m_strID, (void*)m_nIndex, 0, &m_nConnHandle);
	if(nRet != 0 )
	{
		JTRACE("CP2pChannel::ConnDev p2p_transport_connect error =%d\r\n", nRet);
		m_nStopConnThreadFlag = 2;
		m_eventCB(m_nIndex + P2P_CHANNEL_ADDVALUE, 0 , NETPRO_EVENT_CONN_ERR, -10003, NULL,m_lUserParam);
		return NetProErr_TransPortCreateErr;
	}
	nRet = p2p_transport_connect(m_pTransPort, (char*)m_strID, (void*)(m_nIndex+P2P_GETPICTURE_HANDLE), 0, &m_nGetPictureHandle);
	if(nRet != 0 )
	{
		m_nStopConnThreadFlag = 2;
		m_eventCB(m_nIndex + P2P_CHANNEL_ADDVALUE, 0 , NETPRO_EVENT_CONN_ERR, -10005, NULL,m_lUserParam);
		JTRACE("CP2pChannel::m_nGetPictureHandle p2p_transport_connect error =%d\r\n", nRet);
		return NetProErr_TransPortCreateErr;
	}

	nCount = 0;
	while(nCount < 500 )
	{
		if(m_nConnFlag >= 0 && m_nConnPictureChannelFlag >= 0 && !m_nStopConnThreadFlag)
		{
			break;
		}
		JSleep(10);
		nCount ++;
	}
	if(m_nStopConnThreadFlag) return 0;
	JTRACE("m_nConnFlag  = %d, m_nConnPictureChannelFlag = %d\r\n", m_nConnFlag, m_nConnPictureChannelFlag);
	if( m_nConnFlag == 1 && m_nConnPictureChannelFlag == 1 ) 
	{
		JTRACE("CP2pChannel::ConnAction() conndev success  m_nConnHandle = %d, m_nGetPictureHandle = %d\r\n", m_nConnHandle, m_nGetPictureHandle);
		m_nStopConnThreadFlag = 2;	
		m_eventCB(m_nIndex + P2P_CHANNEL_ADDVALUE, 0 , NETPRO_EVENT_CONN_SUCCESS, 0, NULL, m_lUserParam);
	}
	else
	{
		JTRACE("CP2pChannel::ConnAction() conndev error   m_nConnHandle = %d, m_nGetPictureHandle = %d\r\n", m_nConnHandle, m_nGetPictureHandle);
		m_nStopConnThreadFlag = 2;
		m_eventCB(m_nIndex + P2P_CHANNEL_ADDVALUE, 0 , NETPRO_EVENT_CONN_ERR, -1, NULL, m_lUserParam);
	}

	return 0;
}

long CP2pChannel::CloseDev()
{
	
	if(m_nStopConnThreadFlag != 2)
	{
		m_mutexTalk.Lock();
		
		m_nStopConnThreadFlag = 1;
		m_mutexTalk.Unlock();
		while(m_nStopConnThreadFlag != 2)
		{
			JTRACE("%d, %d@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@11111\r\n", m_nIndex, m_nStopConnThreadFlag);
			JSleep(5);
		}
	}
	m_tcConn.StopThread(true);
	m_mutexTalk.Lock();
	TalkStop(0);
	
	if(m_nIsTcpTransPond)
	{
		m_gssChannel.CloseDev();
		m_mutexTalk.Unlock();
		return 0;
	}
	if(m_nGetPictureHandle >= 0)
	{
		p2p_transport_disconnect(m_pTransPort, m_nGetPictureHandle);
		m_nGetPictureHandle = -1;
	}
	if(m_nConnHandle >= 0 /*&& m_pTransPort*/)
	{
		p2p_transport_disconnect(m_pTransPort, m_nConnHandle);
		m_nConnHandle = -1;
		JTRACE(" CP2pChannel::CloseDev..................................\r\n");
	}
	if(m_pTransPort)
	{
		p2p_transport_destroy(m_pTransPort);
		m_pTransPort = NULL;
	}
	m_nIsTcpTransPond = 0;
	JTRACE(" CP2pChannel::CloseDev111..................................\r\n");
	m_mutexTalk.Unlock();
	return NetProErr_Success;
}
long CP2pChannel::GetDevChnNum()
{
	return NetProErr_Success;
}
long CP2pChannel::CreateStreamChn(int nStreamChn)
{
	return NetProErr_Success;
}
long CP2pChannel::CheckDev()
{
	return NetProErr_Success;
}
long CP2pChannel::SetCheckConnTimeinterval(int nMillisecond)
{
	return NetProErr_Success;
}



int CP2pChannel::avSendIOCtrl( unsigned int nIOCtrlType, const char *cabIOCtrlData, int nIOCtrlDataSize)
{
	int			nRet		= -1;
	int			nError		= -1;
	P2pHead		head		= {0};
	int			nHandle		= 0;

	char* pData = new char[sizeof(P2pHead) + nIOCtrlDataSize+1];
	memset(pData, '\0', sizeof(P2pHead) + nIOCtrlDataSize+1);
	head.magicNo = 0x67736d80;
	head.dataLen = nIOCtrlDataSize;
	head.proType = 2;
	head.msgType = 1;
	head.msgChildType = nIOCtrlType;
	if(m_gssChannel.m_pDevID)
	{
		if(strcmp(m_gssChannel.m_pDevID, QUERY_AI_ID) == 0)
		{
			head.msgType = 4;
		}
	}
	


	memcpy(pData, (char *)&head, sizeof(P2pHead));
	if(nIOCtrlDataSize > 0)
		memcpy(pData+sizeof(P2pHead), cabIOCtrlData, nIOCtrlDataSize);

	if(m_nIsTcpTransPond)
	{
		if(nIOCtrlType == IOTYPE_USER_IPCAM_PLAY_RECORD_REQ || nIOCtrlType == IOTYPE_USER_IPCAM_STOP_PLAY_RECORD_REQ )
		{

			m_gssChannel.avSendIOCtrl(nIOCtrlType, cabIOCtrlData, nIOCtrlDataSize);
			//m_gssChannel.SendData(pData, sizeof(P2pHead) + nIOCtrlDataSize);
		}
		else
		{
			m_gssChannel.SendData(pData, sizeof(P2pHead) + nIOCtrlDataSize);
		}
		return 0;
	}

	//SMsgAVIoctrlPlayRecordReq * pReq = (SMsgAVIoctrlPlayRecordReq * )(pData+sizeof(P2pHead));
	nHandle = m_nConnHandle;
	if(nIOCtrlType == IOTYPE_USER_IPCAM_PLAY_RECORD_REQ )
	{
		SMsgAVIoctrlPlayRecordReq * pReq = (SMsgAVIoctrlPlayRecordReq *)cabIOCtrlData;
		if(pReq->type == 0)
		{
			nHandle = m_nGetPictureHandle;
		}
		else if(pReq->type == 1)
		{
			m_gssChannel.m_nRecvFirstSDFrame = 0;
// 			JTRACE("p2p_set_conn_opt start.............\r\n");
// 			p2p_set_conn_opt(m_pTransPort, m_nConnHandle, P2P_RESET_BUF, NULL, 0);
// 			JTRACE("p2p_set_conn_opt end.............\r\n");
		}
	}
// 	if(nIOCtrlType == IOTYPE_USER_IPCAM_STOP_PLAY_RECORD_REQ )
// 		p2p_set_conn_opt(m_pTransPort, m_nConnHandle, P2P_RESET_BUF, NULL, 0);
	
	nRet = p2p_transport_send(m_pTransPort, nHandle, pData, sizeof(P2pHead) + nIOCtrlDataSize, P2P_SEND_NONBLOCK, &nError);

	if(nRet > 0) return 0;
	return nRet;

}
long CP2pChannel::OpenStream(int nChannel, char* pPassword, eNetStreamType eType, long lTimeSeconds, long lTimeZone, StreamCallBack streamCB, long lUserParam)
{
	int nRet	= -1;
	SMsgAVIoctrlAVStream	sAVStream = {0};

	//if(m_nConnHandle < 0 && m_nIsTcpTransPond == 0) return NetProErr_NoConn;
	PasueRecvStream(nChannel, 0);
	
	m_nStreamType = 0;
	sAVStream.channel	  = nChannel;
	sAVStream.reserved[0] = lTimeSeconds;
	sAVStream.reserved[1] = lTimeZone;
	memset(sAVStream.password, '\0', sizeof(sAVStream.password));
	if(pPassword)
	{
		memcpy(sAVStream.password, pPassword, strlen(pPassword));
	}

	m_streamCB = streamCB;
	m_lStreamParam = lUserParam;

	if(eType == NETPRO_STREAM_REC) m_nStreamType = 1;

	if(m_nIsTcpTransPond)
	{
		// 是否需要清空缓存 debug++
		
		return m_gssChannel.OpenStream(eType, (char*)&sAVStream, sizeof(SMsgAVIoctrlAVStream), streamCB, lUserParam);
	}

	
	if(eType == NETPRO_STREAM_REC)
	{	
		p2p_set_conn_opt(m_pTransPort, m_nConnHandle, P2P_RESET_BUF, NULL, 0);
		m_nStreamType = 1;
		return NetProErr_Success;
	}

	if(eType == NETPRO_STREAM_VIDEO || eType == NETPRO_STREAM_ALL)
	{
		m_gssChannel.m_nRecvFirstSDFrame = 1;
		p2p_set_conn_opt(m_pTransPort, m_nConnHandle, P2P_RESET_BUF, NULL, 0);
		nRet = avSendIOCtrl(IOTYPE_USER_IPCAM_START, (char*)&sAVStream, sizeof(SMsgAVIoctrlAVStream));
		if(nRet != 0) return NetProErr_OpenStream;

	}

	if(eType == NETPRO_STREAM_AUDIO || eType == NETPRO_STREAM_ALL)
	{
		nRet = avSendIOCtrl(IOTYPE_USER_IPCAM_AUDIOSTART, (char*)&sAVStream, sizeof(SMsgAVIoctrlAVStream));
		if(nRet != 0) return NetProErr_OpenStream;
	}

	return NetProErr_Success;
}

long CP2pChannel::PasueRecvStream(int nChannel, int nPasueFlag)
{
	unsigned int is_pause = nPasueFlag;
	
	if(!m_nStreamType) return NetProErr_Success;
	
	if(m_nIsTcpTransPond) return m_gssChannel.PasueRecvStream(nPasueFlag);
	
	p2p_set_conn_opt(m_pTransPort, m_nConnHandle, P2P_PAUSE_RECV, &is_pause, 1);
	
	return NetProErr_Success;
}

long CP2pChannel::CloseStream(int nChannel, eNetStreamType eType)
{
	int nRet		= 0;
	SMsgAVIoctrlAVStream	sAVStream = {0};
	sAVStream.channel	  = nChannel;
	if(m_nIsTcpTransPond) return m_gssChannel.CloseStream(eType);

	if(m_nConnHandle < 0) return NetProErr_NoConn;
		
	if(eType == NETPRO_STREAM_REC) NetProErr_Success;

	if(eType == NETPRO_STREAM_AUDIO || eType == NETPRO_STREAM_ALL)
	{

		nRet = avSendIOCtrl(IOTYPE_USER_IPCAM_AUDIOSTOP, (char*)&sAVStream, sizeof(SMsgAVIoctrlAVStream));

		if(nRet != 0)
		{
			//return NetProErr_CloseStream;
		}
	}

	if(eType == NETPRO_STREAM_VIDEO || eType == NETPRO_STREAM_ALL)
	{
		nRet = avSendIOCtrl(IOTYPE_USER_IPCAM_STOP, (char*)&sAVStream, sizeof(SMsgAVIoctrlAVStream));
		if(nRet != 0)
		{
			return NetProErr_CloseStream;
		}
	}
	return NetProErr_Success;
}

long CP2pChannel::SetParam(int nChannel, eNetProParam eParam, void* lData, int nDataSize, int nTypeTemp)
{
	int nType		= 0;
	int nRet		= -1;

	nType = GetTutkParamType(eParam, -1);

	if(nType < 0 )
	{
		JTRACE("CP2pChannel::SetParam GetTutkParamType error \r\n");
		return NetProErr_PARAMTYPE;
	}

	nRet = avSendIOCtrl(nType, (char *)lData, nDataSize);
	if(nRet != 0)
	{
		JTRACE("CP2pChannel::SetParam error %d\r\n", nRet);
		return NetProErr_SETPARAM;
	}

	return NetProErr_Success;
}


long CP2pChannel::GetParam(int nChannel, eNetProParam eParam, void* lData, int nDataSize)
{
	int nType		= 0;
	int nRet		= -1;

	nType = GetTutkParamType(eParam, -1);

	if(nType < 0 )
	{
		JTRACE("CP2pChannel::GetParam GetTutkParamType error \r\n");
		return NetProErr_PARAMTYPE;
	}

	nRet = avSendIOCtrl(nType, (char *)lData, nDataSize);
	if(nRet != 0)
	{
		JTRACE("CP2pChannel::GetParam error %d\r\n", nRet);
		return NetProErr_SETPARAM;
	}
	return NetProErr_Success;
}
long CP2pChannel::RecDownload(int nChannel, const char* pFileName, char *pSrcFileName)
{
	if(m_nIsTcpTransPond)
	{
		m_p2pDownLoad.m_nServerPort = m_gssChannel.m_connCfg.port;
		memset(m_p2pDownLoad.m_strServerAddr, 0, sizeof(m_p2pDownLoad.m_strServerAddr));
		memcpy(m_p2pDownLoad.m_strServerAddr, m_gssChannel.m_pServerAddr, strlen(m_gssChannel.m_pServerAddr));

	}
	return m_p2pDownLoad.RecDownload(m_pTransPort, pFileName, pSrcFileName, m_strID, m_nIndex+P2P_CHANNEL_ADDVALUE, m_eventCB, m_lUserParam);
}

long CP2pChannel::SetStream(int nChannel, eNetVideoStreamType eLevel)
{
	int nRet		= 0;
	SMsgAVIoctrlSetStreamCtrlReq setStream = {0};

	///if(m_nConnHandle < 0) return NetProErr_NoConn;

	setStream.channel = nChannel;
	setStream.quality = AVIOCTRL_QUALITY_MAX;

	switch(eLevel)
	{
	case NETPRO_STREAM_HD:
		{
			setStream.quality = AVIOCTRL_QUALITY_UNKNOWN;
			break;
		}
	case NETPRO_STREAM_SD:
		{
			setStream.quality = AVIOCTRL_QUALITY_MAX;
			break;
		}
	}
	nRet = avSendIOCtrl(IOTYPE_USER_IPCAM_SETSTREAMCTRL_REQ, (char *)&setStream, sizeof(setStream));
	if(nRet != 0)
	{
		return NetProErr_SETPARAM;
	}

	return NetProErr_Success;
}

long CP2pChannel::StopDownload(int nChannel)
{
	return m_p2pDownLoad.StopDownload();
}
long CP2pChannel::DelRec(int nChannel, const char *pFileName)
{
	return NetProErr_Success;
}

fJThRet CP2pChannel::RunTalkSendFileThread(void* pParam)
{
	CJLThreadCtrl*		pThreadCtrl			= NULL;
	CP2pChannel*	pChannel			= NULL;
	int					iIsRun				= 1;
	pThreadCtrl	= (CJLThreadCtrl*)pParam;
	if ( pThreadCtrl==NULL )
	{
		return 0;
	}
	pChannel	= (CP2pChannel *)pThreadCtrl->GetOwner();
	if ( pChannel == NULL )
	{
		pThreadCtrl->SetThreadState(THREAD_STATE_STOP);
		return 0;
	}

	while(iIsRun)
	{
		if ( pThreadCtrl->GetNextAction() == THREAD_STATE_STOP )
		{
			iIsRun = 0;
			break;
		}
		//pChannel->m_mutexTalk.Lock();
		pChannel->TalkSendFileAction();
		//pChannel->m_mutexTalk.Unlock();
		JSleep(5);
	}

	pThreadCtrl->NotifyStop();

	JTRACE("RunTalkSendFileThread exit.......");
	return 0;
}
int CP2pChannel::TalkSendFileAction()
{
	int		nRet				= -1;

	if(m_nTalkRunFlag == 1)  // ø™ º∂‘Ω≤
	{
		m_nTalkRunFlag = 0;
		nRet = m_p2pTalk.StartTalk(m_pTransPort, m_strID, m_nIndex, m_nTalkChn);
		if(nRet < 0 )
		{
			m_eventCB(m_nIndex+ P2P_CHANNEL_ADDVALUE, 0, NETPRO_EVENT_TALK, NetProErr_OPENTALKERR, NULL, m_lUserParam);
			return -1;
		}
		if(nRet == 0)
			m_eventCB(m_nIndex+ P2P_CHANNEL_ADDVALUE, 0, NETPRO_EVENT_TALK, NetProErr_Success, NULL, m_lUserParam);

	}

	if(m_nTalkRunFlag == 2)  // ∑¢ÀÕAAC Œƒº˛
	{
		m_nTalkRunFlag = 0;
		nRet = m_p2pTalk.StartTalk(m_pTransPort, m_strID, m_nIndex, m_nTalkChn);
		if(nRet < 0 )
		{
			m_eventCB(m_nIndex+ P2P_CHANNEL_ADDVALUE, 0, NETPRO_EVENT_TALK, NetProErr_OPENTALKERR, NULL, m_lUserParam);
			return -1;
		}
		nRet = m_p2pTalk.TalkSendFile(m_strTalkFile, m_nPlayAudioFile);
		if(nRet < 0 )
		{
			m_eventCB(m_nIndex+ P2P_CHANNEL_ADDVALUE, 0, NETPRO_EVENT_TALK, NetProErr_TALKERR, NULL, m_lUserParam);
			return -1;
		}

		JSleep(1000);
		m_p2pTalk.StopTalk();
		m_eventCB(m_nIndex+ P2P_CHANNEL_ADDVALUE, 0, NETPRO_EVENT_TALK_SENDFILE_SUCCESS, NetProErr_Success, NULL, m_lUserParam);

	}

	return 0;
}
long CP2pChannel::TalkStart(int nChannel)
{
	m_mutexTalk.Lock();
	m_nTalkRunFlag	 = 1;
	m_mutexTalk.Unlock();
	m_nTalkChn = nChannel;
	if(m_nIsTcpTransPond)
	{
		m_p2pTalk.m_nServerPort = m_gssChannel.m_connCfg.port;
		memset(m_p2pTalk.m_strServerAddr, 0, sizeof(m_p2pTalk.m_strServerAddr));
		memcpy(m_p2pTalk.m_strServerAddr, m_gssChannel.m_pServerAddr, strlen(m_gssChannel.m_pServerAddr));

	}
	m_tcTalkSendFile.StartThread(RunTalkSendFileThread);

	return NetProErr_Success;
}
long CP2pChannel::TalkSendFile(int nChannel, const char *pFileName, int nIsPlay)
{	
	if(!pFileName)
	{
		return NetProErr_TALKERR;
	}
	m_mutexTalk.Lock();
	memset(m_strTalkFile, 0, P2P_DOWNLOAD_MAX_FILE_LEN);
	memcpy(m_strTalkFile, pFileName, strlen(pFileName));
	m_nPlayAudioFile = nIsPlay;
	m_nTalkRunFlag	 = 2;
	m_mutexTalk.Unlock();
	return NetProErr_Success;
}
long CP2pChannel::TalkSend(int nChannel, const char* pData, DWORD dwSize)
{	
	return m_p2pTalk.TalkSendFrame((char *)pData, dwSize);
	return NetProErr_Success;
}
long CP2pChannel::TalkStop(int nChannel)
{
	m_tcTalkSendFile.StopThread(TRUE);
	return m_p2pTalk.StopTalk();
	return NetProErr_Success;
}

int CP2pChannel::GetTutkParamType(eNetProParam eParam, int nTutkType)
{
	int nType				= nTutkType;

	switch (eParam)
	{
	case NETPRO_PARAM_GET_DEVCAP:
		nType = IOTYPE_USER_IPCAM_GET_DEVICE_ABILITY_REQ;
		break;
	case NETPRO_PARAM_GET_DEVINFO:
		nType = IOTYPE_USER_IPCAM_GET_ALL_PARAM_REQ;
		break;
	case NETPRO_PARAM_GET_DEVPWD:
		nType = IOTYPE_USER_IPCAM_GET_AUTHENTICATION_REQ;
		break;
	case NETPRO_PARAM_SET_DEVPWD:
		nType = IOTYPE_USER_IPCAM_SET_AUTHENTICATION_REQ;
		break;
	case NETPRO_PARAM_PTZ:
		nType = IOTYPE_USER_IPCAM_PTZ_COMMAND;
		break;
	case NETPRO_PARAM_GET_STREAMQUALITY:
		nType = IOTYPE_USER_IPCAM_GETSTREAMCTRL_REQ;
		break;
	case NETPRO_PARAM_SET_REC:
		nType = IOTYPE_USER_IPCAM_MANUAL_RECORD_REQ;
		break;
	case NETPRO_PARAM_GET_VIDEOMODE:
		nType = IOTYPE_USER_IPCAM_GET_VIDEOMODE_REQ;
		break;
	case NETPRO_PARAM_SET_VIDEOMODE:
		nType = IOTYPE_USER_IPCAM_SET_VIDEOMODE_REQ;
		break;
	case NETPRO_PARAM_SET_MOTIONDETECT:
		nType = IOTYPE_USER_IPCAM_SETMOTIONDETECT_REQ;
		break;
	case NETPRO_PARAM_GET_MOTIONDETECT:
		nType = IOTYPE_USER_IPCAM_GETMOTIONDETECT_REQ;
		break;
	case NETPRO_PARAM_SET_PIRDETECT:
		nType = IOTYPE_USER_IPCAM_SET_PIRDETECT_REQ;
		break;
	case NETPRO_PARAM_GET_PIRDETECT:
		nType = IOTYPE_USER_IPCAM_GET_PIRDETECT_REQ;
		break;
	case NETPRO_PARAM_SET_ALARMCONTROL:
		nType = IOTYPE_USER_IPCAM_SET_ALARM_CONTROL_REQ;
		break;
	case NETPRO_PARAM_GET_ALARMCONTROL:
		nType = IOTYPE_USER_IPCAM_GET_ALARM_CONTROL_REQ;
		break;
	case NETPRO_PARAM_GET_RECMONTHLIST:
		nType = IOTYPE_USER_IPCAM_GET_MONTH_EVENT_LIST_REQ;
		break;
	case NETPRO_PARAM_GET_RECLIST:
		nType = IOTYPE_USER_IPCAM_GET_DAY_EVENT_LIST_REQ;
		break;
	case NETPRO_PARAM_GET_SDINFO:
		nType = IOTYPE_USER_IPCAM_GET_STORAGE_INFO_REQ;
		break;
	case NETPRO_PARAM_SET_SDFORMAT:
		nType = IOTYPE_USER_IPCAM_FORMAT_STORAGE_REQ;
		break;
	case NETPRO_PARAM_GET_WIFIINFO:
		nType = IOTYPE_USER_IPCAM_GETWIFI_REQ;
		break;
	case NETPRO_PARAM_SET_WIFIINFO:
		nType = IOTYPE_USER_IPCAM_SETWIFI_REQ;
		break;
	case NETPRO_PARAM_GET_TEMPERATURE:
		nType = IOTYPE_USER_IPCAM_GET_TEMPERATURE_REQ;
		break;
	case NETPRO_PARAM_SET_TEMPERATURE:
		nType = IOTYPE_USER_IPCAM_SET_TEMPERATURE_REQ;
		break;
	case NETPRO_PARAM_GET_TIMEINFO:
		nType = IOTYPE_USER_IPCAM_GET_TIME_PARAM_REQ;
		break;
	case NETPRO_PARAM_SET_TIMEINFO:
		nType = IOTYPE_USER_IPCAM_SET_TIME_PARAM_REQ;
		break;
	case NETPRO_PARAM_SET_AUDIOALARM:
		nType = IOTYPE_USER_IPCAM_SET_AUDIO_ALARM_REQ;
		break;
	case NETPRO_PARAM_SET_UPDATE:
		nType = IOTYPE_USER_IPCAM_SET_UPDATE_REQ;
		break;
	case NETPRO_PARAM_GET_NVR_REC:
		nType = IOTYPE_USER_NVR_RECORDLIST_REQ;
		break;
	case NETPRO_PARAM_SET_LIGHT:
		nType = IOTYPE_USER_IPCAM_SET_LIGHT_REQ;
		break;
	case NETPRO_PARAM_GET_LIGHTTIME:
		nType = IOTYPE_USER_IPCAM_GET_LIGHT_TIME_REQ;
		break;
	case NETPRO_PARAM_SET_LIGHTTIME:
		nType = IOTYPE_USER_IPCAM_SET_LIGHT_TIME_REQ;
		break;
	case NETPRO_PARAM_DEV_RESET:
		nType = IOTYPE_USER_IPCAM_RESET_REQ;
		break;
	case NETPRO_PARAM_SET_MOBILE_CLENT_TYPE:
		nType = IOTYPE_USER_IPCAM_SET_MOBILE_CLENT_TYPE_REQ;
		break;
	case NETPRO_PARAM_GET_CAMEREA_STATUS:
		nType = IOTYPE_USER_IPCAM_GET_CAMEREA_STATUS_REQ;
		break;
	case NETPRO_PARAM_SET_LOCAL_STORE_CFG:
		nType = IOTYPE_USER_IPCAM_PLAY_RECORD_REQ;
		break;
	case NETPRO_PARAM_SET_LOCAL_STORE_STOP:
		nType = IOTYPE_USER_IPCAM_STOP_PLAY_RECORD_REQ;
		break;
	}

	return nType;
}


int CP2pChannel::DealWithCMD(int nIndex, int nChn, int nType, char *pData)
{
	eNetProParam eType	= (eNetProParam)-1;
	int		nRet		= 0;
	int		nFlag		= 0;  //1 鈥撁嬧€溾劉陋每碌藴

	switch (nType)
	{
	case IOTYPE_USER_IPCAM_GET_DEVICE_ABILITY_RESP:  // 获取设备能力集请求应答
		{
			nFlag = 1;
			eType = NETPRO_PARAM_GET_DEVCAP;
			nRet = 101;
			break;
		}
	case IOTYPE_USER_IPCAM_GET_DEVICE_ABILITY1_RESP:  // 获取设备能力集请求应答
		{
			nFlag = 1;
			eType = NETPRO_PARAM_GET_DEVCAP;
			nRet = 102;
			break;
		}
	case IOTYPE_USER_IPCAM_GET_DEVICE_ABILITY2_RESP:  // 获取设备能力集请求应答
		{
			nFlag = 1;
			eType = NETPRO_PARAM_GET_DEVCAP;
			nRet = 103;
			break;
		}
	case IOTYPE_USER_IPCAM_GET_ALL_PARAM_RESP:		// 获取所有配置项参数请求应答
		{
			nFlag = 1;
			eType = NETPRO_PARAM_GET_DEVINFO;
			break;
		}
	case IOTYPE_USER_IPCAM_GET_AUTHENTICATION_RESP:		// 获取设备鉴权信息(用户名，密码)请求应答
		{
			nFlag = 1;
			eType = NETPRO_PARAM_GET_DEVPWD;
			break;
		}
	case IOTYPE_USER_IPCAM_SET_AUTHENTICATION_RESP:	 // 设置设备鉴权信息(用户名，密码)请求应答
		{
			nFlag = 1;
			eType = NETPRO_PARAM_SET_DEVPWD;
			SMsgAVIoctrlSetDeviceAuthenticationInfoResp	*sRet = (SMsgAVIoctrlSetDeviceAuthenticationInfoResp	*)pData;
			if(sRet)	nRet = sRet->result;
			else		nRet = NetProErr_SETPARAM;
			break;
		}
	case IOTYPE_USER_IPCAM_GETSTREAMCTRL_RESP:			// 获取当前码流参数应答
		{
			//nFlag = 1;
			eType = NETPRO_PARAM_GET_STREAMQUALITY;
			eNetVideoStreamType	eStreamType;
			SMsgAVIoctrlSetStreamCtrlReq* sRet = (SMsgAVIoctrlSetStreamCtrlReq*)pData;

			if(sRet->quality == AVIOCTRL_QUALITY_UNKNOWN)
				eStreamType = NETPRO_STREAM_HD;
			else if(sRet->quality == AVIOCTRL_QUALITY_MAX)
				eStreamType = NETPRO_STREAM_SD;

			m_eventCB(nIndex, nChn, eType, nRet, (long)eStreamType, m_lUserParam);

			break;
		}
	case IOTYPE_USER_IPCAM_MANUAL_RECORD_RESP:			// 手动录像开启或结束请求应答
		{
			nFlag = 1;
			eType = NETPRO_PARAM_SET_REC;
			SMsgAVIoctrlManualRecordResp *sRet = (SMsgAVIoctrlManualRecordResp *)pData;
			if(sRet)	nRet = sRet->result;
			else		nRet = NetProErr_SETPARAM;
			break;
		}
	case IOTYPE_USER_IPCAM_GET_VIDEOMODE_RESP:			// 陋脪禄掳聽鈥濃垎碌茠拢聽惟鈥澛堵ワ？
		{
			nFlag = 1;
			eType = NETPRO_PARAM_GET_VIDEOMODE;
			break;
		}
	case IOTYPE_USER_IPCAM_SET_VIDEOMODE_RESP:			// 鈥γ嬅封垰聽鈥濃垎碌茠拢聽惟鈥澛堵ワ？
		{
			nFlag = 1;
			eType = NETPRO_PARAM_SET_VIDEOMODE;
			SMsgAVIoctrlSetVideoModeResp *sRet = (SMsgAVIoctrlSetVideoModeResp *)pData;
			if(sRet)	nRet = sRet->result;
			else		nRet = NetProErr_SETPARAM;
			break;
		}
	case IOTYPE_USER_IPCAM_GETMOTIONDETECT_RESP:			// 陋脪禄掳鈥溾垎鈭偯樷€櫭忊墹鈥氣墹艗聽藵鈥澛堵ワ？
		{
			nFlag = 1;
			eType = NETPRO_PARAM_GET_MOTIONDETECT;
			break;
		}
	case IOTYPE_USER_IPCAM_SETMOTIONDETECT_RESP:			// 鈥γ嬅封垰鈥溾垎鈭偯樷€櫭忊墹鈥氣墹艗聽藵鈥澛堵ワ？
		{
			nFlag = 1;
			eType = NETPRO_PARAM_SET_MOTIONDETECT;
			SMsgAVIoctrlSetMotionDetectResp *sRet = (SMsgAVIoctrlSetMotionDetectResp *)pData;
			if(sRet)	nRet = sRet->result;
			else		nRet = NetProErr_SETPARAM;
			break;
		}
	case IOTYPE_USER_IPCAM_GET_PIRDETECT_RESP:			// 陋脪禄掳鈭徝曗€氣€櫭忊墹鈥氣墹艗聽藵鈥澛堵ワ？
		{
			nFlag = 1;
			eType = NETPRO_PARAM_GET_PIRDETECT;
			break;
		}
	case IOTYPE_USER_IPCAM_SET_PIRDETECT_RESP:			// 鈥γ嬅封垰鈭徝曗€氣€櫭忊墹鈥氣墹艗聽藵鈥澛堵ワ？
		{
			nFlag = 1;
			eType = NETPRO_PARAM_SET_PIRDETECT;
			SMsgAVIoctrlSetPirDetectResp *sRet = (SMsgAVIoctrlSetPirDetectResp *)pData;
			if(sRet)	nRet = sRet->result;
			else		nRet = NetProErr_SETPARAM;
			break;
		}
	case IOTYPE_USER_IPCAM_GET_ALARM_CONTROL_RESP:			// 陋脪禄掳鈥溌郝糕墹潞鈭懧库墹艗聽藵鈥澛堵ワ？
		{
			nFlag = 1;
			eType = NETPRO_PARAM_GET_ALARMCONTROL;
			break;
		}
	case IOTYPE_USER_IPCAM_SET_ALARM_CONTROL_RESP:			// 鈥γ嬅封垰鈥溌郝糕墹潞鈭懧库墹艗聽藵鈥澛堵ワ？
		{
			nFlag = 1;
			eType = NETPRO_PARAM_SET_ALARMCONTROL;
			SMsgAVIoctrlSetAlarmControlResp *sRet = (SMsgAVIoctrlSetAlarmControlResp *)pData;
			if(sRet)	nRet = sRet->result;
			else		nRet = NetProErr_SETPARAM;
			break;
		}
	case IOTYPE_USER_IPCAM_GET_MONTH_EVENT_LIST_RESP:			// 陋脪禄掳卢潞艙脪聽卤潞鈥奥♀€撀泵屸€澛堵ワ？
		{
			nFlag = 1;
			eType = NETPRO_PARAM_GET_RECMONTHLIST;
			break;
		}
	case IOTYPE_USER_IPCAM_GET_DAY_EVENT_LIST_RESP:			// 陋脪禄掳茠鈮ッ兠徛号撁捖♀€撀泵屸€澛堵ワ？
		{
			nFlag = 1;
			eType = NETPRO_PARAM_GET_RECLIST;
			break;
		}
	case IOTYPE_USER_IPCAM_GET_STORAGE_INFO_RESP:			// 陋脪禄掳SD酶庐鈥撯増艙垄鈥澛堵ワ？
		{
			nFlag = 1;
			eType = NETPRO_PARAM_GET_SDINFO;
			break;
		}
	case IOTYPE_USER_IPCAM_FORMAT_STORAGE_RESP:			// 鈭徝捖犖┞楽D酶庐鈥澛堵ワ？
		{
			nFlag = 1;
			eType = NETPRO_PARAM_SET_SDFORMAT;
			SMsgAVIoctrlFormatStorageResp *sRet = (SMsgAVIoctrlFormatStorageResp *)pData;
			if(sRet)	nRet = sRet->result;
			else		nRet = NetProErr_SETPARAM;
			break;
		}
	case IOTYPE_USER_IPCAM_GETWIFI_RESP:			// 陋脪禄掳WIFI鈮づ捖犓濃€澛堵ワ？
		{
			nFlag = 1;
			eType = NETPRO_PARAM_GET_WIFIINFO;
			break;
		}
	case IOTYPE_USER_IPCAM_SETWIFI_RESP:			// 鈥γ嬅封垰WIFI鈮づ捖犓濃€澛堵ワ？
		{
			nFlag = 1;
			eType = NETPRO_PARAM_SET_WIFIINFO;
			SMsgAVIoctrlFormatStorageResp *sRet = (SMsgAVIoctrlFormatStorageResp *)pData;
			if(sRet)	nRet = sRet->result;
			else		nRet = NetProErr_SETPARAM;
			break;
		}
	case IOTYPE_USER_IPCAM_GET_TEMPERATURE_RESP:			// 陋脪禄掳艗卢鈭偮宦甭γ樷墹艗聽藵鈥澛堵ワ？
		{
			nFlag = 1;
			eType = NETPRO_PARAM_GET_TEMPERATURE;
			break;
		}
	case IOTYPE_USER_IPCAM_SET_TEMPERATURE_RESP:			// 鈥γ嬅封垰艗卢鈭偮宦甭γ樷墹艗聽藵鈥澛堵ワ？
		{
			nFlag = 1;
			eType = NETPRO_PARAM_SET_TEMPERATURE;
			SMsgAVIoctrlSetTemperatureAlarmParamResp *sRet = (SMsgAVIoctrlSetTemperatureAlarmParamResp *)pData;
			if(sRet)	nRet = sRet->result;
			else		nRet = NetProErr_SETPARAM;
			break;
		}
	case IOTYPE_USER_IPCAM_GET_TIME_PARAM_RESP:			// 陋脪禄掳聽卤潞鈥扳墹艗聽藵鈥澛堵ワ？
		{
			nFlag = 1;
			eType = NETPRO_PARAM_GET_TIMEINFO;
			break;
		}
	case IOTYPE_USER_IPCAM_SET_TIME_PARAM_RESP:			// 鈥γ嬅封垰聽卤潞鈥扳墹艗聽藵鈥澛堵ワ？
		{
			nFlag = 1;
			eType = NETPRO_PARAM_SET_TIMEINFO;
			SMsgAVIoctrlSetTimeParamResp *sRet = (SMsgAVIoctrlSetTimeParamResp *)pData;
			if(sRet)	nRet = sRet->result;
			else		nRet = NetProErr_SETPARAM;
			break;
		}
	case IOTYPE_USER_IPCAM_GET_RECORDFILE_START_RESP:			// 酶鈩⒙犅号撀€樏柯号撁掆€澛堵ワ？
		{
			SMsgAVIoctrlGetRecordFileStartResp *sRet = (SMsgAVIoctrlGetRecordFileStartResp *)pData;
			if(sRet)	nRet = sRet->result;
			else		nRet = NetProErr_SETPARAM;

			if(sRet->result >= 0)
			{
				m_eventCB(nIndex, nChn, NETPRO_EVENT_REC_DOWNLOAD_RET, NetProErr_Success, NULL, m_lUserParam);
			}
			/*else
			{
			m_pMainCtrl[nIndex-P2P_CHANNEL_ADDVALUE]->m_pLoginChn->m_eventCB(nIndex, m_nDevChn, NETPRO_EVENT_REC_DOWNLOAD_RET, NetProErr_DOWNLOADERR, NULL, m_pMainCtrl[nIndex-P2P_CHANNEL_ADDVALUE]->m_lUserParam);
			}*/
			//m_nStartDownLoadFlag = sRet->result;

			//			JTRACE("download rec type = %d===========================\r\n", m_nStartDownLoadFlag);

			break;
		}
	case IOTYPE_USER_IPCAM_GET_RECORDFILE_STOP_RESP:
		{
			SMsgAVIoctrlGetRecordFileStopResp *sRet = (SMsgAVIoctrlGetRecordFileStopResp *)pData;

			break;
		}
	case IOTYPE_USER_IPCAM_SPEAKERPROCESS_RESP:  //鈭傗€樜┾墹鈥澛堵ワ？
		{
			if(m_p2pTalk.m_nTalkRespFlag == 0)
				m_p2pTalk.m_nTalkRespFlag = 1;
			else
				m_p2pTalk.m_nTalkRespFlag = 0;
			JTRACE("talk resp ===================\r\n");
			break;
		}
	case IOTYPE_USER_IPCAM_FILE_RESEND_RESP: //鈭傗劉鈭灺该访柯ヂ?
		{
			JTRACE("IOTYPE_USER_IPCAM_FILE_RESEND_RESP............\r\n");
			break;
		}
	case IOTYPE_USER_IPCAM_SETSTREAMCTRL_RESP: //码流切换应答
		{
			nFlag = 1;
			SMsgAVIoctrlSetStreamCtrlResp *sRet = (SMsgAVIoctrlSetStreamCtrlResp *)pData;
			eType = NETPRO_EVENT_SET_STREAM;
			if(sRet)	nRet = sRet->result;
			else		nRet = NetProErr_SETPARAM;
#if 0
			m_mutexRecvFrame.Lock();
			if(sRet->result == 0)
			{
				m_nVideoStreamTimeSpan = 0;
				m_dwLastRecvVideoFrameTime = 0;
				m_nRecvFirstIFrameFlag = 0;
			}
			m_mutexRecvFrame.Unlock();
#endif
			break;
		}
	case IOTYPE_USER_IPCAM_DEL_RECORDFILE_RESP:
		{
			nFlag = 1;
			SMsgAVIoctrlDelRecordFileResp *sRet = (SMsgAVIoctrlDelRecordFileResp *)pData;
			eType = NETPRO_EVENT_DEL_REC;
			if(sRet)	nRet = sRet->result;
			else		nRet = NetProErr_SETPARAM;
			break;
		}
	case IOTYPE_USER_IPCAM_SET_AUDIO_ALARM_RESP:
		{
			nFlag = 1;
			//SMsgAVIoctrlSetAudioAlarmResp* sRet = (SMsgAVIoctrlSetAudioAlarmResp *)pData;
			eType = NETPRO_PARAM_SET_AUDIOALARM;
			nRet = 0;
			break;
		}
	case IOTYPE_USER_IPCAM_SEND_ANDROID_MOTION_ALARM:  // 鈭炩墹鈼娒嘎甭γ樷€澛堵ワ？
		{
			nFlag = 1;
			eType = NETPRO_PARAM_GET_ANDROIDALARM;
			JTRACE("******************  alarm   *****************************\r\n");
			break;
		}
	case IOTYPE_USER_IPCAM_SET_UPDATE_RESP: // 鈥γ嬅封垰鈥λ澛衡垈鈥澛堵ワ？
		{
			nFlag = 1;
			//SMsgAVIoctrlSetAudioAlarmResp* sRet = (SMsgAVIoctrlSetAudioAlarmResp *)pData;

			SMsgAVIoctrlSetUpdateResp *sRet = (SMsgAVIoctrlSetUpdateResp *)pData;
			eType = NETPRO_PARAM_SET_UPDATE;

			if(sRet)	nRet = sRet->result;
			else		nRet = NetProErr_SETPARAM;
			break;
		}
	case IOTYPE_USER_IPCAM_GETSUPPORTSTREAM_RESP: // 陋脪禄掳脮庐碌驴鈥澛堵ワ？
		{
#if 0
			SMsgAVIoctrlGetSupportStreamResp  *pRet = (SMsgAVIoctrlGetSupportStreamResp  *)pData;
			if(pRet)
			{
				m_nNVRNum = pRet->number;
				for(int i = 0; i < m_nNVRNum; i ++)
				{
					m_nNVRChannel[i] = pRet->streams[i].channel;
				}
				m_pMainCtrl[nIndex-P2P_CHANNEL_ADDVALUE]->m_pLoginChn->m_eventCB(m_nCurIndex, m_nDevChn, NETPRO_EVENT_RET_DEVCHN_NUM, (long)m_nNVRNum, NULL, m_pMainCtrl[nIndex-P2P_CHANNEL_ADDVALUE]->m_pLoginChn->m_lUserParam);
			}
#endif
			break;
		}
	case IOTYPE_USER_IPCAM_RECORD_PLAYCONTROL_RESP: // 卢潞艙脪酶每梅鈭嗏€澛堵ワ？
		{
#if 0		
			nFlag = 1;
			eType = NETPRO_PARAM_CTRLT_NVR_REC;
			SMsgAVIoctrlPlayRecordResp  *pRet = (SMsgAVIoctrlPlayRecordResp  *)pData;
			if(pRet)
			{
				if(pRet->command == AVIOCTRL_RECORD_PLAY_START)
					m_nCreateRecPlayChnParam = pRet->result;

				nRet = pRet->result;
			}
#endif
			break;
		}
	case IOTYPE_USER_NVR_RECORDLIST_RESP: // 陋脪禄掳 NVR 卢潞艙脪隆鈥撀泵屄ッ涒€撀扳€澛堵ワ？
		{
			nFlag = 1;
			eType = NETPRO_PARAM_GET_NVR_REC;
			break;
		}
	case IOTYPE_USER_IPCAM_SET_LIGHT_RESP: // 鈥γ嬅封垰碌鈭喢糕劉蟺每鈥澛堵ワ？
		{
			nFlag = 1;
			eType = NETPRO_PARAM_SET_LIGHT;

			SMsgAVIoctrlSetLightResp *sRet = (SMsgAVIoctrlSetLightResp *)pData;
			if(sRet)	nRet = sRet->result;
			else		nRet = NetProErr_SETPARAM;
			break;
		}
	case IOTYPE_USER_IPCAM_GET_LIGHT_TIME_RESP: // 陋脪禄掳碌鈭喡÷÷犅甭衡€扳€澛堵ワ？
		{
			nFlag = 1;
			eType = NETPRO_PARAM_GET_LIGHTTIME;
			break;
		}
	case IOTYPE_USER_IPCAM_SET_LIGHT_TIME_RESP: // 鈥γ嬅封垰碌鈭喡÷÷犅甭衡€扳€澛堵ワ？
		{
			nFlag = 1;
			eType = NETPRO_PARAM_SET_LIGHTTIME;

			SMsgAVIoctrlSetLightTimeResp *sRet = (SMsgAVIoctrlSetLightTimeResp *)pData;
			if(sRet)	nRet = sRet->result;
			else		nRet = NetProErr_SETPARAM;

			break;
		}
	case IOTYPE_USER_IPCAM_RESET_RESP: // 陋梅鈭徛モ墺藛鈮ッ熲€γ嬅封垰鈥澛堵ワ？
		{
			nFlag = 1;
			eType = NETPRO_PARAM_DEV_RESET;
			SMsgAVIoctrlResetResp *sRet = (SMsgAVIoctrlResetResp *)pData;
			if(sRet)	nRet = sRet->result;
			else		nRet = NetProErr_SETPARAM;
			break;
		}
	case IOTYPE_USER_IPCAM_SET_MOBILE_CLENT_TYPE_RESP: //鈭炩墹鈼娒嘎犆仿櫭该暵熲垈脌梅鈭毰捖幝涒€澛堵ワ？
		{
			nFlag = 1;
			eType = NETPRO_PARAM_SET_MOBILE_CLENT_TYPE;
			SMsgAVIoctrlSetAndriodAlarmMsgResp *sRet = (SMsgAVIoctrlSetAndriodAlarmMsgResp *)pData;
			if(sRet)	nRet = sRet->result;
			else		nRet = NetProErr_SETPARAM;
			break;
		}
	case IOTYPE_USER_IPCAM_STARTRESP:
		{
			nFlag = 1;
			eType = NETPRO_EVENT_OPENSTREAM_RET;
			SMsgAVIoctrlAVStreamResp *sRet = (SMsgAVIoctrlAVStreamResp *)pData;
			if(sRet)
			{	if(sRet->result != 0)
			nRet = NetProErr_OpenStreamPwdErr;
			else
				nRet = sRet->result;
			}
			else
			{
				nRet = NetProErr_OpenStreamPwdErr;
			}
			break;
		}
	case IOTYPE_USER_IPCAM_GET_CAMEREA_STATUS_RESP: //返回门铃状态
		{
			nFlag = 1;
			eType = NETPRO_PARAM_GET_CAMEREA_STATUS; //CAMEREA_STATUS
			break;
		}
	case IOTYPE_USER_IPCAM_PLAY_RECORD_RESP:
		{ 
			nFlag = 1;
			eType = NETPRO_PARAM_SET_LOCAL_STORE_CFG; //CAMEREA_STATUS

			SMsgAVIoctrlPlayPreviewResp *pResp = (SMsgAVIoctrlPlayPreviewResp *)pData;
			break;
		}
	case IOTYPE_USER_IPCAM_STOP_PLAY_RECORD_RESP:
		{
			nFlag = 1;
			eType = NETPRO_PARAM_SET_LOCAL_STORE_STOP; //CAMEREA_STATUS
			break;
		}

	}


	if(nFlag == 1)
		m_eventCB(nIndex, nChn, eType, nRet, (long)pData, m_lUserParam);

	return 0;
}

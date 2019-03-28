#include "P2pProtocol.h"


static CP2pProtocol *gThis = NULL;
#define  MAX_SERVER_ADDR_LEN	1024
CP2pProtocol::CP2pProtocol() : CNetProCommon()
{
	for(int i = 0; i < MAX_CONN_CHANNEL; i++)
	{
		m_pMainCtrl[i]	= NULL;
	}
	m_dwRecvStartTime = 0;
	m_nConnServerIndex = -1;
	gThis = this;
	m_nIsConnServer	= 0;
	m_mutexGetChannel.CreateMutex();
	m_pWriteFile	= NULL;
	m_pServerAddr	= NULL;
	m_pServerAddr = new char[MAX_SERVER_ADDR_LEN];
	//m_pWriteFile = fopen("D:\\0.h264", "wb");
}


CP2pProtocol::~CP2pProtocol()
{
	
	if(m_pWriteFile)
	{
		fclose(m_pWriteFile);
		m_pWriteFile = NULL;
	}
	SAFE_DELETE(m_pServerAddr);
	m_mutexGetChannel.CloseMutex();
}


long CP2pProtocol::Init()
{

	p2p_init(NULL);
	//p2p_log_set_level(4);
	return NetProErr_Success;
}

long CP2pProtocol::UnInit()
{
	p2p_uninit();
	return NetProErr_Success;
}

int	 CP2pProtocol::GetCurChannel(int nHandle)
{
	for( int i = 0; i < MAX_CONN_CHANNEL; i++ )
	{
		if(m_pMainCtrl[i] )
		{
			if(m_pMainCtrl[i]->m_pLoginChn->m_nConnHandle == nHandle)
				return i;
		}
	}

	return -1;
}

int	 CP2pProtocol::GetFreeChannel()
{
	for( int i = 0; i < MAX_CONN_CHANNEL; i++ )
	{
		if( NULL == m_pMainCtrl[i] )
		{
			m_pMainCtrl[i] = new CP2PMainCtrl(i);
			if(m_pMainCtrl[i])
			{
				m_mutexGetChannel.Unlock();
				return i;
			}
			else
			{
				m_mutexGetChannel.Unlock();
				return -1;
			}
		}
	}
	
	return -1;
}

void CP2pProtocol::on_create_completeCB(p2p_transport *transport,int status,void *user_data)
{
	if(status == 0)
	{
		gThis->m_nIsConnServer = 1;
		JTRACE("p2p_transport_create success\r\n");
	}
	else
	{
		gThis->m_nIsConnServer = 0;
		JTRACE("p2p_transport_create error = %d\r\n", status);
	}

	//gThis->m_eventCB(0, 0 , NETPRO_EVENT_CONNP2P_RET, status, NULL, gThis->m_lUserParam);

}

void CP2pProtocol::on_disconnect_serverCB(p2p_transport *transport,int status,void *user_data)
{
	//gThis->m_eventCB(0, 0 , NETPRO_EVENT_P2PSERVER_LOST, status, NULL, gThis->m_lUserParam);
	JTRACE("on_disconnect_serverCB................ \r\n");
}

void CP2pProtocol::on_connect_completeCB(p2p_transport *transport,int connection_id,int status,void *transport_user_data,void *connect_user_data)
{
	JTRACE("connection_id = %d, status = %d\r\n", connection_id, status);
	int nCurHandle = (long)connect_user_data;//gThis->GetCurChannel(connection_id);

// 
// 	char addr[256];
// 	int len = sizeof(addr);
// 	p2p_addr_type addr_type;
// 	p2p_get_conn_remote_addr(transport, connection_id, addr, &len, &addr_type);
// 	JTRACE("addr_type = %d\r\n", addr_type);
	if(nCurHandle >= P2P_DOWNLOAD_HANDLE && nCurHandle < P2P_TALK_HANDLE)  // 下载通道连接状态
	{
		if(status == 0)
			gThis->m_pMainCtrl[nCurHandle-P2P_DOWNLOAD_HANDLE-P2P_CHANNEL_ADDVALUE]->m_pLoginChn->m_p2pDownLoad.m_nConnDownLoadFlag = 1;
		else
			gThis->m_pMainCtrl[nCurHandle-P2P_DOWNLOAD_HANDLE-P2P_CHANNEL_ADDVALUE]->m_pLoginChn->m_p2pDownLoad.m_nConnDownLoadFlag = 0;
	}
	else if( nCurHandle >= P2P_TALK_HANDLE)	// 对讲通道状态
	{
		if(status == 0)
			gThis->m_pMainCtrl[nCurHandle-P2P_TALK_HANDLE]->m_pLoginChn->m_p2pTalk.m_nConnFlag = 1;
		else
			gThis->m_pMainCtrl[nCurHandle-P2P_TALK_HANDLE]->m_pLoginChn->m_p2pTalk.m_nConnFlag = 0;
	}
	else	// 设备登录状态
	{

		if(!gThis->m_pMainCtrl[nCurHandle]) return ;

		if(status == 0)
		{
			gThis->m_pMainCtrl[nCurHandle]->m_pLoginChn->m_nConnFlag = 1;
			gThis->m_pMainCtrl[nCurHandle]->m_pLoginChn->m_eventCB(nCurHandle + P2P_CHANNEL_ADDVALUE, 0 , NETPRO_EVENT_CONN_SUCCESS, status, NULL, gThis->m_pMainCtrl[nCurHandle]->m_pLoginChn->m_lUserParam);
		}
		else
		{
			gThis->m_pMainCtrl[nCurHandle]->m_pLoginChn->m_nConnFlag = 0;
			gThis->m_pMainCtrl[nCurHandle]->m_pLoginChn->m_eventCB(nCurHandle + P2P_CHANNEL_ADDVALUE, 0 , NETPRO_EVENT_CONN_ERR, status, NULL, gThis->m_pMainCtrl[nCurHandle]->m_pLoginChn->m_lUserParam);
		}
	}
	
}

void CP2pProtocol::on_connection_disconnectCB(p2p_transport *transport,int connection_id,void *transport_user_data,void *connect_user_data)
{
	int nCurHandle = (long)connect_user_data;
	JTRACE("on_connection_disconnectCB connection_id = %d\r\n", connection_id);

	if(nCurHandle >= P2P_DOWNLOAD_HANDLE && nCurHandle < P2P_TALK_HANDLE)  // 下载通道连接状态
	{
		nCurHandle -= P2P_DOWNLOAD_HANDLE;
		nCurHandle -= P2P_CHANNEL_ADDVALUE;
	}
	else if( nCurHandle >= P2P_TALK_HANDLE)	// 对讲通道状态
	{
		nCurHandle -= P2P_TALK_HANDLE;
	}
	if(gThis->m_pMainCtrl[nCurHandle])
		gThis->m_pMainCtrl[nCurHandle]->m_pLoginChn->m_eventCB(nCurHandle + P2P_CHANNEL_ADDVALUE, 0 , NETPRO_EVENT_LOSTCONNECTION, 0, NULL, gThis->m_pMainCtrl[nCurHandle]->m_pLoginChn->m_lUserParam);
}

void CP2pProtocol::on_accept_remote_connectionCB(p2p_transport *transport,int connection_id, int conn_flag, void *transport_user_data)
{

}

void CP2pProtocol::on_connection_recvCB(p2p_transport *transport,int connection_id,void *transport_user_data,void *connect_user_data,char* data,int len)
{
	int nCurHandle = (long)connect_user_data;
	P2pHead *pHead = (P2pHead *)data;
	PAVBuffArray		pstEle		= NULL;

	if(nCurHandle >= P2P_DOWNLOAD_HANDLE && nCurHandle < P2P_TALK_HANDLE)  // 下载通道连接状态
	{
		nCurHandle -= P2P_DOWNLOAD_HANDLE;
		nCurHandle -= P2P_CHANNEL_ADDVALUE;
	}
	else if( nCurHandle >= P2P_TALK_HANDLE)	// 对讲通道状态
	{
		nCurHandle -= P2P_TALK_HANDLE;
		//nCurHandle -= P2P_CHANNEL_ADDVALUE;
	}

	if(!gThis->m_pMainCtrl[nCurHandle] || !gThis->m_pMainCtrl[nCurHandle]->m_pLoginChn  ) return ;
	if(gThis->m_pWriteFile)
	{
		//fwrite((data),  len, 1, gThis->m_pWriteFile);
	}

	//JTRACE("pHead->msgChildType = %x\r\n", pHead->msgChildType);
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
			//JTRACE("RECV frame no ============================= %d\r\n", pFrame->nFrameNo);
			//();
			//char strLOG[1024] = {0};
			//sprintf(strLOG, "RECV_VIDEO_FRAME = %d\r\n", (int)(JGetTickCount()-gThis->m_dwRecvStartTime));
			//OutputDebugString(strLOG);
			//JTRACE("RECV_VIDEO_FRAME = %d, \r\n", (int)(JGetTickCount()-gThis->m_dwRecvStartTime));
			//JTRACE("timespan = %d, recvlen = %d, dataLen = %d,  nFrameNo = %d, nFrameType = %d, nFrameRate = %d, nDataSize = %d\r\n",
			//	(int)(JGetTickCount()-gThis->m_dwRecvStartTime), len, pHead->dataLen, pFrame->nFrameNo, pFrame->nFrameType, pFrame->nFrameRate, pFrame->nDataSize);
			//gThis->m_dwRecvStartTime = JGetTickCount();
			//JTRACE("recvlen = %d, dataLen = %d, proType = %d, msgType = %d, msgChildType = %x, nFrameNo = %d, nFrameType = %d, nFrameRate = %d, nDataSize = %d\r\n",len, pHead->dataLen, pHead->proType, pHead->msgType, 
			//	pHead->msgChildType, pFrame->nFrameNo, pFrame->nFrameType, pFrame->nFrameRate, pFrame->nDataSize);
		}
		
		if(gThis->m_pMainCtrl[nCurHandle]->m_pLoginChn->m_streamCB)
			gThis->m_pMainCtrl[nCurHandle]->m_pLoginChn->m_streamCB(nCurHandle + P2P_CHANNEL_ADDVALUE, 0, (unsigned char *)(data+sizeof(P2pHead)), pHead->dataLen, gThis->m_pMainCtrl[nCurHandle]->m_pLoginChn->m_lStreamParam);
		if(gThis->m_pWriteFile)
		{
			fwrite((data+sizeof(P2pHead)),  pHead->dataLen, 1, gThis->m_pWriteFile);
		}
	}
	else if(pHead->msgChildType == RECV_DOWNLOAD_FRAME)
	{
		FILE_PACKET_HEAD *pPktHead = (FILE_PACKET_HEAD *)(data+sizeof(P2pHead));
		if(pPktHead)
		{
			if(!gThis->m_pMainCtrl[nCurHandle]) return ;
			JTRACE("total_packet_num = %d, curr_packet_no = %d, curr_packet_length = %d\r\n", pPktHead->total_packet_num, pPktHead->curr_packet_no, pPktHead->curr_packet_length );
			pstEle = gThis->m_pMainCtrl[nCurHandle]->m_pLoginChn->m_p2pDownLoad.m_avbuffCtrl.BeginAddBuff( data+sizeof(P2pHead), pHead->dataLen, 0, 0 );
			if( pstEle )
			{
				gThis->m_pMainCtrl[nCurHandle]->m_pLoginChn->m_p2pDownLoad.m_avbuffCtrl.EndAddBuff();
			}
		}
		
	}
	else
	{
		//gThis->DealWithCMD(nCurHandle + P2P_CHANNEL_ADDVALUE, 0, pHead->msgChildType, (data+sizeof(P2pHead)));
		JTRACE("**********************recvlen = %d, dataLen = %d, proType = %d, msgType = %d, msgChildType = %x\r\n",len, pHead->dataLen, pHead->proType, pHead->msgType, pHead->msgChildType);
	}

}

void CP2pProtocol::on_tcp_proxy_connectedCB(p2p_transport *transport,void *transport_user_data,void *connect_user_data,unsigned short port, char* addr)
{

}

long	CP2pProtocol::SetTransportProType(eNetProTransportProType eProType, char* pServerAddr)
{
	int nEnable = 0;

		
	memset(m_pServerAddr, 0, MAX_SERVER_ADDR_LEN);
	memcpy(m_pServerAddr, pServerAddr, strlen(pServerAddr));
	

	if(eProType == NETPRO_ENABLE_ALL)
	{
		return NetProErr_Success;
	}
	else if(eProType == NETPRO_ONLY_P2P)
	{
		p2p_set_global_opt(P2P_ENABLE_RELAY, &nEnable, sizeof(int));
	}
	else if(eProType == NETPRO_ONLY_RELAY)
	{
		nEnable = 1;
		p2p_set_global_opt(P2P_ONLY_RELAY, &nEnable, sizeof(int));
	}

	return NetProErr_Success;
}
int				CP2pProtocol::ConnTurnServer(char* pServerAddr, int nPort, int nUseTcp, EventCallBack eventCB, long lUserParam)
{
	//分发服务：udp：192.168.20.152:9999
	//p2p服务：tcp：192.168.20.152:34780

	int						nRet	= 0;
	p2p_transport_cfg		cfg		= {0};
	p2p_transport_cb		cb		= {0};

	if(eventCB == NULL) return NetProErr_Param;
	m_eventCB = eventCB;
	m_lUserParam = lUserParam;

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
	cfg.use_tcp_connect_srv = 1/*nUseTcp*/;
	cfg.cb = &cb;

	nRet = p2p_transport_create(&cfg, &m_pTransPort);
	if(nRet != 0 )
	{
		return NetProErr_TransPortCreateErr;
	}

	return NetProErr_Success;
}
long CP2pProtocol::ConnServer(char *pServer, int nPort, int nUseTCPFlag, EventCallBack eventCB, long lUserParam)
{
	return 0;
	return ConnTurnServer(pServer, nPort, nUseTCPFlag, eventCB, lUserParam);
}


long CP2pProtocol::CloseServer()
{
#if 0
	m_mutexGetChannel.Lock();
	for(int i = 0; i < MAX_CONN_CHANNEL; i++)
	{
		SAFE_DELETE(m_pMainCtrl[i]);
	}
	m_mutexGetChannel.Unlock();
#endif
	if(m_pTransPort)
	{
		p2p_transport_destroy(m_pTransPort);
		m_pTransPort = NULL;
	}
	m_nIsConnServer = 0;
	JTRACE("CloseServer+++++++++++++++++++++++++++++++++++++\r\n");
	return NetProErr_Success;
}

long CP2pProtocol::ConnDev(const char* pUID, const char* pUser, const char* pPwd, int nTimeOut, int nConnType, EventCallBack eventCB, long lUserParam)
{
	int			lHandle = -1;
	int			nRet	= -1;
	m_mutexGetChannel.Lock();
	lHandle = GetFreeChannel();

	if( lHandle < 0 )
	{
		m_mutexGetChannel.Unlock();
		return NetProErr_GetChannel;
	}

	///if(!m_nIsConnServer) return NetProErr_TransPortCreate;

	//if(!m_pTransPort) return NetProErr_TransPortCreate;

	if(!m_pMainCtrl[lHandle])
	{	
		m_mutexGetChannel.Unlock();
		return NetProErr_TransPortCreate;
	}

	JTRACE("ConnDev lHandle = %d\r\n", lHandle);
	nRet = m_pMainCtrl[lHandle]->ConnDev(pUID, pUser, pPwd, nTimeOut, nConnType, eventCB, lUserParam, m_pServerAddr);
	//nRet = m_pMainCtrl[lHandle]->ConnDev(pUID, "119.23.128.209", pPwd, 6000, nConnType, eventCB, lUserParam, m_pTransPort);


	if(nRet != NetProErr_Success ) 
	{	
		SAFE_DELETE(m_pMainCtrl[lHandle]);	
		m_mutexGetChannel.Unlock();
		return -1;
	}
	m_mutexGetChannel.Unlock();
	return lHandle;
}

long CP2pProtocol::CloseDev(long lConnHandle)
{
	m_mutexGetChannel.Lock();
    SAFE_DELETE(m_pMainCtrl[lConnHandle]);
	m_mutexGetChannel.Unlock();
	return 0;
}

long	CP2pProtocol::GetDevChnNum(long lConnHandle)
{
	if( lConnHandle < 0 ) return NetProErr_GetChannel;

	return m_pMainCtrl[lConnHandle]->GetDevChnNum();

}

long	CP2pProtocol::CreateDevChn(long lConnHandle, int nNum)
{
	if( lConnHandle < 0 ) return NetProErr_GetChannel;

	return m_pMainCtrl[lConnHandle]->CreateDevChnNum(nNum);

}

long CP2pProtocol::SetCheckConnTimeinterval(long lConnHandle, int nMillisecond)
{
	if( lConnHandle < 0 ) return NetProErr_GetChannel;

	return m_pMainCtrl[lConnHandle]->SetCheckConnTimeinterval(nMillisecond);

	return 0;
}

long	CP2pProtocol::CheckDevConn(long lConnHandle)
{
	if( lConnHandle < 0 ) return NetProErr_GetChannel;

	if(!m_pMainCtrl[lConnHandle]) return NetProErr_Param;

	return m_pMainCtrl[lConnHandle]->CheckDev();

	return 0;
}



long CP2pProtocol::OpenStream(long lHandle, int nChannel, char* pPassword, eNetStreamType eType, long lTimeSeconds, long lTimeZone, StreamCallBack streamCB, long lUserParam)
{
	if( lHandle < 0 ) return NetProErr_GetChannel;

	if(!m_pMainCtrl[lHandle]) return NetProErr_Param;

	//if(!m_nIsConnServer) return NetProErr_TransPortCreate;

	return m_pMainCtrl[lHandle]->OpenStream(nChannel, pPassword, eType, lTimeSeconds, lTimeZone, streamCB, lUserParam);

}

long CP2pProtocol::CloseStream(long lHandle, int nChannel, eNetStreamType eType)
{
	if( lHandle < 0 ) return NetProErr_GetChannel;

	//if(!m_nIsConnServer) return NetProErr_TransPortCreate;
	if(!m_pMainCtrl[lHandle]) return NetProErr_Param;

	return m_pMainCtrl[lHandle]->CloseStream( nChannel, eType );
}

long	CP2pProtocol::PasueRecvStream( long lConnHandle,int nChannel, int nPasueFlag)
{
	if( lConnHandle < 0 ) return NetProErr_GetChannel;

	//if(!m_nIsConnServer) return NetProErr_TransPortCreate;
	if(!m_pMainCtrl[lConnHandle]) return NetProErr_Param;

	return m_pMainCtrl[lConnHandle]->PasueRecvStream( nChannel, nPasueFlag );

}

long	CP2pProtocol::SetParam(long lConnHandle, int nChannel, eNetProParam eParam, void* lData, int nDataSize)
{
	if( lConnHandle < 0 ) return NetProErr_GetChannel;

	if(!m_pMainCtrl[lConnHandle]) return NetProErr_Param;

	return m_pMainCtrl[lConnHandle]->SetParam(nChannel, eParam, lData, nDataSize);
}

long	CP2pProtocol::GetParam(long lConnHandle, int nChannel, eNetProParam eParam, void* lData, int nDataSize)
{
	if( lConnHandle < 0 ) return NetProErr_GetChannel;

	if(!m_pMainCtrl[lConnHandle]) return NetProErr_Param;

	return m_pMainCtrl[lConnHandle]->GetParam( nChannel, eParam, lData, nDataSize);
}

long	CP2pProtocol::RecDownload(long lConnHandle, int nChannel, const char* pFileName, char *pSrcFileName)
{
	if( lConnHandle < 0 ) return NetProErr_GetChannel;

	if(!m_pMainCtrl[lConnHandle]) return NetProErr_Param;

	return m_pMainCtrl[lConnHandle]->RecDownload( nChannel, pFileName, pSrcFileName);
}

long	CP2pProtocol::TalkSendFile(long lConnHandle, int nChannel, const char *pFileName, int nIsPlay)
{
	if( lConnHandle < 0 ) return NetProErr_GetChannel;

	if(!m_pMainCtrl[lConnHandle]) return NetProErr_Param;

	return m_pMainCtrl[lConnHandle]->TalkSendFile( nChannel, pFileName, nIsPlay);
}

long	CP2pProtocol::SetStream(long lConnHandle, int nChannel, eNetVideoStreamType eLevel)
{
	if( lConnHandle < 0 ) return NetProErr_GetChannel;

	if(!m_pMainCtrl[lConnHandle]) return NetProErr_Param;

	return m_pMainCtrl[lConnHandle]->SetStream( nChannel, eLevel);
}
long	CP2pProtocol::StopDownload(long lConnHandle, int nChannel)
{
	if( lConnHandle < 0 ) return NetProErr_GetChannel;

	if(!m_pMainCtrl[lConnHandle]) return NetProErr_Param;

	return m_pMainCtrl[lConnHandle]->StopDownload( nChannel);
}
long	CP2pProtocol::DelRec(long lConnHandle, int nChannel, const char *pFileName)
{
	if( lConnHandle < 0 ) return NetProErr_GetChannel;

	if(!m_pMainCtrl[lConnHandle]) return NetProErr_Param;

	return m_pMainCtrl[lConnHandle]->DelRec( nChannel, pFileName);
}

long	CP2pProtocol::TalkStart(long lConnHandle, int nChannel)
{
	if( lConnHandle < 0 ) return NetProErr_GetChannel;

	if(!m_pMainCtrl[lConnHandle]) return NetProErr_Param;

	return m_pMainCtrl[lConnHandle]->TalkStart( nChannel);
}	

long	CP2pProtocol::TalkSend(long lConnHandle, int nChannel, const char* pData, DWORD dwSize)
{
	if( lConnHandle < 0 ) return NetProErr_GetChannel;

	if(!m_pMainCtrl[lConnHandle]) return NetProErr_Param;

	return m_pMainCtrl[lConnHandle]->TalkSend( nChannel, pData, dwSize);
}

long	CP2pProtocol::TalkStop(long lConnHandle, int nChannel)
{
	if( lConnHandle < 0 ) return NetProErr_GetChannel;

	if(!m_pMainCtrl[lConnHandle]) return NetProErr_Param;

	return m_pMainCtrl[lConnHandle]->TalkStop( nChannel);
}

long	CP2pProtocol::CreateRecPlayChn(long lConnHandle, const char *pData, int nDataLen)
{
	if( lConnHandle < 0 ) return NetProErr_GetChannel;

	if(!m_pMainCtrl[lConnHandle]) return NetProErr_Param;

	return m_pMainCtrl[lConnHandle]->CreateRecPlayChn( (void *)pData, nDataLen);
}

long CP2pProtocol::DeleteRecPlayChn(long lConnHandle, int nChn)
{
	if( lConnHandle < 0 ) return NetProErr_GetChannel;

	if(!m_pMainCtrl[lConnHandle]) return NetProErr_Param;

	return m_pMainCtrl[lConnHandle]->DeleteRecPlayChn( nChn);
}

long CP2pProtocol::RecStreamCtrl(long lConnHandle, int nChn, eNetRecCtrlType eCtrlType, long lData)
{
	if( lConnHandle < 0 ) return NetProErr_GetChannel;

	if(!m_pMainCtrl[lConnHandle]) return NetProErr_Param;

	return m_pMainCtrl[lConnHandle]->RecStreamCtrl( nChn, eCtrlType, lData);
}



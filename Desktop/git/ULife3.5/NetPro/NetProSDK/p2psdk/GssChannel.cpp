#include "GssChannel.h"

CGssChannel::CGssChannel()
{
	m_pTransPort		= NULL;
	m_pStreamTransPort	= NULL;
	m_pGetPicturePort	= NULL;
	m_nCurPort			= 0;
	m_nIsConnStream		= 0;
	m_eventCB			= NULL;
	m_lUserParam		= NULL;
	m_streamCB			= NULL;
	m_lStreamParam		= NULL;
	m_pPullTransPort	= NULL;
	m_pDevID			= NULL;
	m_pServerAddr		= NULL;
	m_pDispatcher		= NULL;
	m_nSignalingFlag	= -1;
	m_nAVFlag			= -1;	
	m_nQueryFlag		= -1;
	m_nGetPicFlag		= -1;
	m_nRecvFirstSDFrame = 1;
	m_nProjectType		= 0;
	m_nStopConnFlag		= 0;
	m_nLightFlag		= -1;
	
	memset(&m_connCfg, 0, sizeof(m_connCfg));

	m_mutexConn.CreateMutex();
	strcpy_s(m_tcConn.m_szName,J_DGB_NAME_LEN,"m_tcConn");
	m_tcConn.SetOwner(this);
	m_tcConn.SetParam(this);
}

CGssChannel::~CGssChannel()
{
	SAFE_DELETE(m_pDevID);
	SAFE_DELETE(m_pServerAddr);
	m_mutexConn.CloseMutex();
}

void CGssChannel::on_connect_result(void *transport, void* user_data, int status)
{
	CGssChannel *pThis = (CGssChannel *)user_data;

	if(pThis->m_pTransPort == transport)
	{
		if(status == 0)
			pThis->m_nSignalingFlag			= 1;
		else
			pThis->m_nSignalingFlag			= 0;
		JTRACE("on_connect_result = %d\r\n", status);
	}
	else if(pThis->m_pStreamTransPort == transport)
	{
		JTRACE("openstream on_connect_result = %d, m_pStreamTransPort = %x, transport = %x\r\n", status, pThis->m_pStreamTransPort , transport);
		pThis->m_nIsConnStream = 1;
		if(status == 0)
			pThis->m_nAVFlag			= 1;
		else
			pThis->m_nAVFlag			= 0;
	}
	else if(pThis->m_pGetPicturePort == transport)
	{
		JTRACE("getpicture on_connect_result = %d, m_pGetPicturePort = %x, transport = %x\r\n", status, pThis->m_pGetPicturePort, transport);
		if(status == 0)
			pThis->m_nGetPicFlag			= 1;
		else
			pThis->m_nGetPicFlag			= 0;
	}
	
}

void CGssChannel::on_disconnect(void *transport, void* user_data, int status)
{
	CGssChannel *pThis = (CGssChannel *)user_data;
	if(pThis->m_eventCB)
		pThis->m_eventCB(pThis->m_nCurPort, 0,  NETPRO_EVENT_LOSTCONNECTION, status, NULL, pThis->m_lUserParam);
}
//DWORD dwTesxt = 0;
void CGssChannel::on_recv(void *transport, void *user_data, char* data, int len)
{
	CGssChannel *pThis = (CGssChannel *)user_data;
	P2pHead *p2pHead = (P2pHead *)data;


	//JTRACE("======================================len = %d, dataLen = %d\r\n", len, p2pHead->dataLen);
	if(p2pHead->magicNo != 0x67736d80)
	{
		JTRACE("on_recv---***********************************************************************%d\r\n\r\n", len);
		//return ;
	}
	if(p2pHead->msgChildType  == RECV_AI_FRAME)
	{
			JTRACE("RECV_AI_FRAME---***********************************************************************%d\r\n\r\n", len);
	}

	if(pThis->m_pTransPort == transport)
	{
		pThis->DealWithCMD(pThis->m_nCurPort, p2pHead->dataLen, p2pHead->msgChildType, (data+sizeof(P2pHead)));
	}
	else if(pThis->m_pStreamTransPort == transport || pThis->m_pGetPicturePort == transport)
	{

		if((p2pHead->dataLen+sizeof(P2pHead)) != len) return;

		gos_frame_head *pHead = (gos_frame_head *)(data+sizeof(P2pHead));

		if(pHead->nFrameType == gos_video_rec_start_frame) pThis->m_nRecvFirstSDFrame =  1;

		if(pThis->m_nRecvFirstSDFrame ==  0 && pHead->nFrameType != gos_video_preview_i_frame) 
		{
			if(pHead->nFrameType < 50)
				JTRACE("no recv gos_video_rec_start_frame.....................................................%d, %d\r\n", pHead->nFrameNo, pHead->nFrameType);
			return ;
		}


		if(pThis->GetSpecialStreamData(data+sizeof(P2pHead)))
		{
			return ;
		} 
		//JTRACE("start.....................................................%d, %d\r\n", pHead->nFrameNo, pHead->nFrameType);


		if(pThis->m_streamCB)
			pThis->m_streamCB(pThis->m_nCurPort, 0, (unsigned char *)(data+sizeof(P2pHead)), p2pHead->dataLen, pThis->m_lStreamParam);

		
		//JTRACE("--------------------------%d\r\n", (int)(JGetTickCount()-dwTesxt));
		//dwTesxt = JGetTickCount();
		
//  			JTRACE("len = %d, nFrameNo = %d, nFrameType = %d, nFrameRate = %d, nDataSize = %d, ncodeType = %d, %x\r\n",
//  				len, pHead->nFrameNo,pHead->nFrameType,pHead->nFrameRate,pHead->nDataSize, pHead->nCodeType, pThis->m_lStreamParam);
	}
}

void CGssChannel::on_device_disconnect(void *transport, void *user_data)
{
	CGssChannel *pThis = (CGssChannel *)user_data;
	pThis->m_eventCB(pThis->m_nCurPort, 0,  NETPRO_EVENT_LOSTCONNECTION, 0, NULL, pThis->m_lUserParam);
}


fJThRet CGssChannel::RunConnThread(void* pParam)
{
	CJLThreadCtrl*		pThreadCtrl			= NULL;
	CGssChannel*	pChannel			= NULL;
	int				iIsRun				= 0;
	int				nRet				= 0;

	pThreadCtrl	= (CJLThreadCtrl*)pParam;
	if ( pThreadCtrl==NULL )
	{
		return 0;
	}
	pChannel	= (CGssChannel *)pThreadCtrl->GetOwner();
	if ( pChannel == NULL )
	{
		pThreadCtrl->SetThreadState(THREAD_STATE_STOP);		
		return 0;
	}
	pChannel->ConnAction();
	pChannel->m_mutexConn.Lock();
	pChannel->m_nStopConnFlag = 2;
	pChannel->m_mutexConn.Unlock();
	iIsRun	= 1;
#if 0
	while(iIsRun)
	{
		if ( pThreadCtrl->GetNextAction() == THREAD_STATE_STOP )
		{
			iIsRun = 0;										// ≤ª‘Ÿ‘À–�?
			break;
		}

		pChannel->ConnAction();
		JSleep(5);
	}
#endif
	pThreadCtrl->NotifyStop();
	iIsRun = 0;
	JTRACE("CGssChannel::RunConnThread exit **********************\r\n");

	return 0;
}

int	CGssChannel::ConnAction()
{
	int		nCount = 0;
	m_connCfg.cb	= &m_connCB;

	
	while(	nCount < 1000 && !m_nStopConnFlag)
	{
		if(m_nQueryFlag >= 0)
			break;

		nCount ++;
		JSleep(5);
	}

	if(m_pDispatcher)
	{
		destroy_gss_dispatch_requester(m_pDispatcher);
		m_pDispatcher = NULL;
	}

	if(m_nQueryFlag != 1 || m_nStopConnFlag)
	{
		m_eventCB(m_nCurPort, 0,  NETPRO_EVENT_CONN_ERR, -20001, NULL, m_lUserParam);
		return 0;
	}


	gss_client_signaling_connect(&m_connCfg, &m_pTransPort);
	
	if(m_nAVFlag != 1)
		gss_client_av_connect(&m_connCfg, &m_pStreamTransPort);

	if(m_nGetPicFlag != 1)
		gss_client_av_connect(&m_connCfg, &m_pGetPicturePort);
	

	JTRACE("gss_client_av_connect %x, %x\r\n", m_pStreamTransPort, m_pGetPicturePort);

	nCount = 0;
	while(	nCount < 1000 )
	{
		if(m_nSignalingFlag >= 0 && m_nAVFlag >= 0 && m_nGetPicFlag >= 0 && !m_nStopConnFlag)
			break;

		nCount ++;
		JSleep(5);
	}

	if(m_nSignalingFlag == 1 && m_nAVFlag == 1 && m_nGetPicFlag == 1)
	{
		m_eventCB(m_nCurPort, 0,  NETPRO_EVENT_CONN_SUCCESS, 0, NULL, m_lUserParam);	
	}
	else
	{
		/*if(m_pGetPicturePort)
		{
			gss_client_av_destroy(m_pGetPicturePort);
			m_pGetPicturePort= NULL;
		}
		if(m_pStreamTransPort)
		{
			gss_client_av_destroy(m_pStreamTransPort);
			m_pStreamTransPort= NULL;
		}
		if(m_pTransPort)
		{
			gss_client_signaling_destroy(m_pTransPort);
			m_pTransPort = NULL;
		}*/
		m_eventCB(m_nCurPort, 0,  NETPRO_EVENT_CONN_ERR, -1, NULL, m_lUserParam);
	}

	return 0;
}

void CGssChannel::onpull_connect_result(void *transport, void* user_data, int status)
{
	JTRACE("onpull_connect_result  = %d\r\n", status);
}
void CGssChannel::onpull_disconnect(void *transport, void* user_data, int status)
{
	JTRACE("onpull_disconnect  = %d\r\n", status);
}
void CGssChannel::onpull_recv(void *transport, void *user_data, char* data, int len, char type, unsigned int time_stamp)
{
	CGssChannel *pThis = (CGssChannel *)user_data;
	P2pHead *p2pHead = (P2pHead *)data;


	//JTRACE("======================================len = %d, dataLen = %d\r\n", len, p2pHead->dataLen);
	if(p2pHead->magicNo != 0x67736d80)
	{
		JTRACE("***********************************************************************\r\n\r\n");
		return ;
	}

	gos_frame_head *pHead = (gos_frame_head *)(data+sizeof(P2pHead));

	//JTRACE("len = %d, nFrameNo = %d, nFrameType = %d, nFrameRate = %d, nDataSize = %d, %x\r\n",
	//	len, pHead->nFrameNo,pHead->nFrameType,pHead->nFrameRate,pHead->nDataSize, pThis->m_lStreamParam);
	if((p2pHead->dataLen+sizeof(P2pHead)) != len) return;
	if(pThis->m_streamCB)
		pThis->m_streamCB(pThis->m_nCurPort, 0, (unsigned char *)(data+sizeof(P2pHead)), p2pHead->dataLen, pThis->m_lStreamParam);


}
void CGssChannel::onpull_device_disconnect(void *transport, void *user_data)
{
	JTRACE("onpull_device_disconnect \r\n");
}

long	CGssChannel::PullConn()
{
	gss_pull_conn_cfg	cfg;
	gss_pull_conn_cb	cb;
	memset(&cfg, 0, sizeof(gss_pull_conn_cfg));
	memset(&cb, 0, sizeof(gss_pull_conn_cb));

	cb.on_connect_result	= onpull_connect_result;
	cb.on_disconnect	= onpull_disconnect;
	cb.on_recv	= onpull_recv;
	cb.on_device_disconnect	= onpull_device_disconnect;

	cfg.server = m_connCfg.server;
	cfg.port = m_connCfg.port;
	cfg.uid = m_connCfg.uid;
	cfg.user_data = this;
	cfg.cb = &cb;

	return gss_client_pull_connect(&cfg, &m_pPullTransPort);
}

long	CGssChannel::ClosePullConn()
{
	if(m_pPullTransPort)
	{
		gss_client_pull_destroy(m_pPullTransPort);
		m_pPullTransPort = NULL;
	}
	return 0;
}

void CGssChannel::DISPATCH_CB(void* dispatcher, int status, void* user_data, char* server, unsigned short port, unsigned int server_id)
{
	CGssChannel *pThis = (CGssChannel *)user_data;
	int nLen = 0;
	if(status == 0)
	{
		SAFE_DELETE(pThis->m_pServerAddr);
		nLen = strlen(server) +1 ;
		pThis->m_pServerAddr	 = new char[nLen];
		memset(pThis->m_pServerAddr, 0, nLen);
		memcpy(pThis->m_pServerAddr, server, strlen(server));

		pThis->m_connCfg.server = pThis->m_pServerAddr;
		pThis->m_connCfg.port = port;
		pThis->m_nQueryFlag = 1;
	}
	else
	{
		pThis->m_nQueryFlag = 0;
	}
}

long CGssChannel::ConnDev(char* pUid, char* pServer, int nPort, char *pUser, EventCallBack eventCB, long lUserParam)
{
	int					nRet		= -1;
	gss_client_conn_cb	cb			= {0};


	m_connCB.on_connect_result = on_connect_result;
	m_connCB.on_disconnect = on_disconnect;
	m_connCB.on_recv = on_recv;
	m_connCB.on_device_disconnect = on_device_disconnect;

	m_eventCB = eventCB;
	m_lUserParam = lUserParam;


	SAFE_DELETE(m_pDevID);
	SAFE_DELETE(m_pServerAddr);

	int nLen = strlen(pUid) +1 ;
	m_pDevID		 = new char[nLen];
	memset(m_pDevID, 0, nLen);
	memcpy(m_pDevID, pUid, strlen(pUid));

	
	m_connCfg.uid = m_pDevID;
	m_connCfg.user_data = this;
	m_connCfg.cb	= &m_connCB;

	if(m_pDispatcher)
	{
		destroy_gss_dispatch_requester(m_pDispatcher);
		m_pDispatcher = NULL;
	}
	m_nSignalingFlag	= -1;
	m_nAVFlag			= -1;
	m_nGetPicFlag		= -1;
	if(strcmp(m_pDevID, QUERY_AI_ID) == 0)
	{
		m_connCfg.server = pUser;//"120.79.186.226";
		m_connCfg.port = 6002;
		m_nQueryFlag = 1;
		m_nAVFlag			= 1;
		m_nGetPicFlag		= 1;
	}
	else
	{
		m_nQueryFlag = -1;
		gss_query_dispatch_server(pUid, pServer, this, DISPATCH_CB, &m_pDispatcher);

	}
	
	
	
	m_tcConn.StartThread(RunConnThread);
	return 0;
}


long	CGssChannel::CloseDev()
{
	if(m_nStopConnFlag != 2)
	{
		m_mutexConn.Lock();
		m_nStopConnFlag = 1;
		m_mutexConn.Unlock();
		while(m_nStopConnFlag != 2 )
		{
			JSleep(5);
		}
	}
	m_tcConn.StopThread(true);
	if(m_pDispatcher)
	{
		destroy_gss_dispatch_requester(m_pDispatcher);
		m_pDispatcher = NULL;
	}
	if(m_pGetPicturePort)
	{
		gss_client_av_destroy(m_pGetPicturePort);
		m_pGetPicturePort= NULL;
	}
	if(m_pStreamTransPort)
	{
		gss_client_av_destroy(m_pStreamTransPort);
		m_pStreamTransPort= NULL;
	}
	if(m_pTransPort)
	{
		gss_client_signaling_destroy(m_pTransPort);
		m_pTransPort = NULL;
	}
	m_nSignalingFlag	= -1;
	m_nAVFlag			= -1;	

	SAFE_DELETE(m_pDevID);
	SAFE_DELETE(m_pServerAddr);
	return 0;
}
int	CGssChannel::GetSpecialStreamData(char *pData)
{
	if(m_nProjectType != 1) return 0;

	gos_frame_head*		pNewFrameHead	= (gos_frame_head *)pData;
	if(pNewFrameHead->nFrameType == gos_special_frame)
	{
		gos_special_data* pSpecialData = (gos_special_data *)(pData+sizeof(gos_frame_head));
		if(m_nLightFlag != pSpecialData->nLightFlag)
		{
			m_nLightFlag = pSpecialData->nLightFlag;

			m_eventCB(m_nCurPort, 0, NETPRO_EVENT_GET_LIGHTSTATE, m_nLightFlag, NULL, m_lUserParam);
		}
		return 1;
	}

	return 0;
}

long	CGssChannel::SendData(char *pBuf, int nLen)
{
	if(!m_pTransPort) return NetProErr_NoConn;

	return gss_client_signaling_send(m_pTransPort, pBuf, nLen, P2P_SEND_NONBLOCK);
}

int		CGssChannel::PasueRecvStream(int nPasue)
{
	gss_client_av_pause_recv(m_pStreamTransPort, nPasue);
	return 0;
}

long	CGssChannel::OpenStream(eNetStreamType eType, char *pBuf, int nLen, StreamCallBack streamCB, long lUserParam)
{

	//if(!m_pStreamTransPort) return NetProErr_NotConnStreamServer;
	int nRet = 0;
	
	
	if(m_streamCB == NULL)
	{
		m_streamCB = streamCB;
		m_lStreamParam = lUserParam;
	}

	if(eType == NETPRO_STREAM_REC)
	{	
		if(!m_pStreamTransPort) return 0;
		gss_client_av_clean_buf(m_pStreamTransPort);
		return NetProErr_Success;
	}

	if(eType == NETPRO_STREAM_LIVE)
	{
		return PullConn();
	}
	if(!m_pStreamTransPort) return 0;
	if(eType == NETPRO_STREAM_VIDEO || eType == NETPRO_STREAM_ALL)
	{
		m_nRecvFirstSDFrame = 1;
		gss_client_av_clean_buf(m_pStreamTransPort);
		nRet = avSendIOCtrl(IOTYPE_USER_IPCAM_START, pBuf, nLen);
		if(nRet != 0) return NetProErr_OpenStream;

	}
#if 1
	if(eType == NETPRO_STREAM_AUDIO || eType == NETPRO_STREAM_ALL)
	{
		nRet = avSendIOCtrl(IOTYPE_USER_IPCAM_AUDIOSTART, pBuf, nLen);
		if(nRet != 0) return NetProErr_OpenStream;
	}
#endif
	return 0;//gss_client_av_send(m_pStreamTransPort, pBuf, nLen, P2P_SEND_NONBLOCK);
}

int CGssChannel::avSendIOCtrl( unsigned int nIOCtrlType, const char *cabIOCtrlData, int nIOCtrlDataSize)
{
	int			nRet		= -1;
	int			nError		= -1;
	P2pHead		head		= {0};

	char* pData = new char[sizeof(P2pHead) + nIOCtrlDataSize+1];
	memset(pData, '\0', sizeof(P2pHead) + nIOCtrlDataSize+1);
	head.magicNo = 0x67736d80;
	head.dataLen = nIOCtrlDataSize;
	head.proType = 2;
	head.msgType = 1;
	head.msgChildType = nIOCtrlType;

	memcpy(pData, (char *)&head, sizeof(P2pHead));
	memcpy(pData+sizeof(P2pHead), cabIOCtrlData, nIOCtrlDataSize);

	if(nIOCtrlType == IOTYPE_USER_IPCAM_PLAY_RECORD_REQ )
	{
		
		SMsgAVIoctrlPlayRecordReq * pReq = (SMsgAVIoctrlPlayRecordReq *)cabIOCtrlData;
		if(pReq->type == 0)
		{
			return gss_client_av_send(m_pGetPicturePort, pData, sizeof(P2pHead) + nIOCtrlDataSize, P2P_SEND_NONBLOCK);
		}
		else if(pReq->type == 1)
		{
			//gss_client_av_clean_buf(m_pStreamTransPort);
			m_nRecvFirstSDFrame = 0;
		}
	}
// 	if(nIOCtrlType == IOTYPE_USER_IPCAM_STOP_PLAY_RECORD_REQ )
// 		gss_client_av_clean_buf(m_pStreamTransPort);
	
	return gss_client_av_send(m_pStreamTransPort, pData, sizeof(P2pHead) + nIOCtrlDataSize, P2P_SEND_NONBLOCK);
	
}

long	CGssChannel::CloseStream(eNetStreamType eType)
{
	int nRet = 0;

	if(eType == NETPRO_STREAM_REC)
	{	
		return NetProErr_Success;
	}

	if(eType == NETPRO_STREAM_LIVE)
	{
		return ClosePullConn();
	}

	if(!m_pStreamTransPort) return 0;

	if(eType == NETPRO_STREAM_AUDIO || eType == NETPRO_STREAM_ALL)
	{
		nRet = avSendIOCtrl(IOTYPE_USER_IPCAM_AUDIOSTOP, NULL, 0);
	}

	if(eType == NETPRO_STREAM_VIDEO || eType == NETPRO_STREAM_ALL)
	{
		nRet = avSendIOCtrl(IOTYPE_USER_IPCAM_STOP, NULL, 0);
		if(nRet != 0)
		{
			return NetProErr_CloseStream;
		}
	}
	return NetProErr_Success;
}

int CGssChannel::DealWithCMD(int nIndex, int nChn, int nType, char *pData)
{
	eNetProParam eType	= (eNetProParam)-1;
	int		nRet		= 0;
	int		nFlag		= 0;  //1 –Ë“™ªÿµ˜

	switch (nType)
	{
	case IOTYPE_USER_IPCAM_GET_DEVICE_ABILITY_RESP:  // ��ȡ�豸����������Ӧ��
		{
			nFlag = 1;
			eType = NETPRO_PARAM_GET_DEVCAP;
			nRet = 101;
			break;
		}
	case IOTYPE_USER_IPCAM_GET_DEVICE_ABILITY1_RESP:  // ��ȡ�豸����������Ӧ��
		{
			nFlag = 1;
			eType = NETPRO_PARAM_GET_DEVCAP;
			nRet = 102;
			break;
		}
	case IOTYPE_USER_IPCAM_GET_DEVICE_ABILITY2_RESP:  // ��ȡ�豸����������Ӧ��
		{
			nFlag = 1;
			eType = NETPRO_PARAM_GET_DEVCAP;
			nRet = 103;
			break;
		}
	case IOTYPE_USER_IPCAM_GET_ALL_PARAM_RESP:		// ��ȡ�����������������Ӧ��
		{
			nFlag = 1;
			eType = NETPRO_PARAM_GET_DEVINFO;
			break;
		}
	case IOTYPE_USER_IPCAM_GET_AUTHENTICATION_RESP:		// ��ȡ�豸��Ȩ��Ϣ(�û���������)����Ӧ��
		{
			nFlag = 1;
			eType = NETPRO_PARAM_GET_DEVPWD;
			break;
		}
	case IOTYPE_USER_IPCAM_SET_AUTHENTICATION_RESP:	 // �����豸��Ȩ��Ϣ(�û���������)����Ӧ��
		{
			nFlag = 1;
			eType = NETPRO_PARAM_SET_DEVPWD;
			SMsgAVIoctrlSetDeviceAuthenticationInfoResp	*sRet = (SMsgAVIoctrlSetDeviceAuthenticationInfoResp	*)pData;
			if(sRet)	nRet = sRet->result;
			else		nRet = NetProErr_SETPARAM;
			break;
		}
	case IOTYPE_USER_IPCAM_GETSTREAMCTRL_RESP:			// ��ȡ��ǰ��������Ӧ��
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
	case IOTYPE_USER_IPCAM_MANUAL_RECORD_RESP:			// �ֶ�¼�������������Ӧ��
		{
			nFlag = 1;
			eType = NETPRO_PARAM_SET_REC;
			SMsgAVIoctrlManualRecordResp *sRet = (SMsgAVIoctrlManualRecordResp *)pData;
			if(sRet)	nRet = sRet->result;
			else		nRet = NetProErr_SETPARAM;
			break;
		}
	case IOTYPE_USER_IPCAM_GET_VIDEOMODE_RESP:			// ªÒ»° ”∆µƒ£ Ω”¶¥
		{
			nFlag = 1;
			eType = NETPRO_PARAM_GET_VIDEOMODE;
			break;
		}
	case IOTYPE_USER_IPCAM_SET_VIDEOMODE_RESP:			// …Ë÷√ ”∆µƒ£ Ω”¶¥
		{
			nFlag = 1;
			eType = NETPRO_PARAM_SET_VIDEOMODE;
			SMsgAVIoctrlSetVideoModeResp *sRet = (SMsgAVIoctrlSetVideoModeResp *)pData;
			if(sRet)	nRet = sRet->result;
			else		nRet = NetProErr_SETPARAM;
			break;
		}
	case IOTYPE_USER_IPCAM_GETMOTIONDETECT_RESP:			// ªÒ»°“∆∂Ø’Ï≤‚≤Œ ˝”¶¥
		{
			nFlag = 1;
			eType = NETPRO_PARAM_GET_MOTIONDETECT;
			break;
		}
	case IOTYPE_USER_IPCAM_SETMOTIONDETECT_RESP:			// …Ë÷√“∆∂Ø’Ï≤‚≤Œ ˝”¶¥
		{
			nFlag = 1;
			eType = NETPRO_PARAM_SET_MOTIONDETECT;
			SMsgAVIoctrlSetMotionDetectResp *sRet = (SMsgAVIoctrlSetMotionDetectResp *)pData;
			if(sRet)	nRet = sRet->result;
			else		nRet = NetProErr_SETPARAM;
			break;
		}
	case IOTYPE_USER_IPCAM_GET_PIRDETECT_RESP:			// ªÒ»°∫ÏÕ‚’Ï≤‚≤Œ ˝”¶¥
		{
			nFlag = 1;
			eType = NETPRO_PARAM_GET_PIRDETECT;
			break;
		}
	case IOTYPE_USER_IPCAM_SET_PIRDETECT_RESP:			// …Ë÷√∫ÏÕ‚’Ï≤‚≤Œ ˝”¶¥
		{
			nFlag = 1;
			eType = NETPRO_PARAM_SET_PIRDETECT;
			SMsgAVIoctrlSetPirDetectResp *sRet = (SMsgAVIoctrlSetPirDetectResp *)pData;
			if(sRet)	nRet = sRet->result;
			else		nRet = NetProErr_SETPARAM;
			break;
		}
	case IOTYPE_USER_IPCAM_GET_ALARM_CONTROL_RESP:			// ªÒ»°“ªº¸≤º∑¿≤Œ ˝”¶¥
		{
			nFlag = 1;
			eType = NETPRO_PARAM_GET_ALARMCONTROL;
			break;
		}
	case IOTYPE_USER_IPCAM_SET_ALARM_CONTROL_RESP:			// …Ë÷√“ªº¸≤º∑¿≤Œ ˝”¶¥
		{
			nFlag = 1;
			eType = NETPRO_PARAM_SET_ALARMCONTROL;
			SMsgAVIoctrlSetAlarmControlResp *sRet = (SMsgAVIoctrlSetAlarmControlResp *)pData;
			if(sRet)	nRet = sRet->result;
			else		nRet = NetProErr_SETPARAM;
			break;
		}
	case IOTYPE_USER_IPCAM_GET_MONTH_EVENT_LIST_RESP:			// ªÒ»°¬ºœÒ ±º‰¡–±Ì”¶¥
		{
			nFlag = 1;
			eType = NETPRO_PARAM_GET_RECMONTHLIST;
			break;
		}
	case IOTYPE_USER_IPCAM_GET_DAY_EVENT_LIST_RESP:			// ªÒ»°ƒ≥ÃÏ¬ºœÒ¡–±Ì”¶¥
		{
			nFlag = 1;
			eType = NETPRO_PARAM_GET_RECLIST;
			break;
		}
	case IOTYPE_USER_IPCAM_GET_STORAGE_INFO_RESP:			// ªÒ»°SDø®–≈œ¢”¶¥
		{
			nFlag = 1;
			eType = NETPRO_PARAM_GET_SDINFO;
			break;
		}
	case IOTYPE_USER_IPCAM_FORMAT_STORAGE_RESP:			// ∏Ò ΩªØSDø®”¶¥
		{
			nFlag = 1;
			eType = NETPRO_PARAM_SET_SDFORMAT;
			SMsgAVIoctrlFormatStorageResp *sRet = (SMsgAVIoctrlFormatStorageResp *)pData;
			if(sRet)	nRet = sRet->result;
			else		nRet = NetProErr_SETPARAM;
			break;
		}
	case IOTYPE_USER_IPCAM_GETWIFI_RESP:			// ªÒ»°WIFI≤Œ ˝”¶¥
		{
			nFlag = 1;
			eType = NETPRO_PARAM_GET_WIFIINFO;
			break;
		}
	case IOTYPE_USER_IPCAM_SETWIFI_RESP:			// …Ë÷√WIFI≤Œ ˝”¶¥
		{
			nFlag = 1;
			eType = NETPRO_PARAM_SET_WIFIINFO;
			SMsgAVIoctrlFormatStorageResp *sRet = (SMsgAVIoctrlFormatStorageResp *)pData;
			if(sRet)	nRet = sRet->result;
			else		nRet = NetProErr_SETPARAM;
			break;
		}
	case IOTYPE_USER_IPCAM_GET_TEMPERATURE_RESP:			// ªÒ»°Œ¬∂»±®æØ≤Œ ˝”¶¥
		{
			nFlag = 1;
			eType = NETPRO_PARAM_GET_TEMPERATURE;
			break;
		}
	case IOTYPE_USER_IPCAM_SET_TEMPERATURE_RESP:			// …Ë÷√Œ¬∂»±®æØ≤Œ ˝”¶¥
		{
			nFlag = 1;
			eType = NETPRO_PARAM_SET_TEMPERATURE;
			SMsgAVIoctrlSetTemperatureAlarmParamResp *sRet = (SMsgAVIoctrlSetTemperatureAlarmParamResp *)pData;
			if(sRet)	nRet = sRet->result;
			else		nRet = NetProErr_SETPARAM;
			break;
		}
	case IOTYPE_USER_IPCAM_GET_TIME_PARAM_RESP:			// ªÒ»° ±º‰≤Œ ˝”¶¥
		{
			nFlag = 1;
			eType = NETPRO_PARAM_GET_TIMEINFO;
			break;
		}
	case IOTYPE_USER_IPCAM_SET_TIME_PARAM_RESP:			// …Ë÷√ ±º‰≤Œ ˝”¶¥
		{
			nFlag = 1;
			eType = NETPRO_PARAM_SET_TIMEINFO;
			SMsgAVIoctrlSetTimeParamResp *sRet = (SMsgAVIoctrlSetTimeParamResp *)pData;
			if(sRet)	nRet = sRet->result;
			else		nRet = NetProErr_SETPARAM;
			break;
		}
	case IOTYPE_USER_IPCAM_GET_RECORDFILE_START_RESP:			// ø™ ºœ¬‘ÿ¬ºœÒ”¶¥
		{
			SMsgAVIoctrlGetRecordFileStartResp *sRet = (SMsgAVIoctrlGetRecordFileStartResp *)pData;
			if(sRet)	nRet = sRet->result;
			else		nRet = NetProErr_SETPARAM;

			if(sRet->result >= 0)
			{
				m_eventCB(nIndex, nChn, NETPRO_EVENT_REC_DOWNLOAD_RET, NetProErr_Success, NULL, m_lUserParam);
			}
			else
			{
				m_eventCB(nIndex, nChn, NETPRO_EVENT_REC_DOWNLOAD_RET, NetProErr_DOWNLOADERR, NULL, m_lUserParam);
			}
			//m_nStartDownLoadFlag = sRet->result;

			//			JTRACE("download rec type = %d===========================\r\n", m_nStartDownLoadFlag);

			break;
		}
	case IOTYPE_USER_IPCAM_GET_RECORDFILE_STOP_RESP:
		{
			SMsgAVIoctrlGetRecordFileStopResp *sRet = (SMsgAVIoctrlGetRecordFileStopResp *)pData;

			break;
		}
	case IOTYPE_USER_IPCAM_SPEAKERPROCESS_RESP:  //∂‘Ω≤”¶¥
		{
		
#if 0
			if(m_pMainCtrl[nIndex-P2P_TALK_HANDLE]->m_pLoginChn->m_p2pTalk.m_nTalkRespFlag == 0)
				m_pMainCtrl[nIndex-P2P_TALK_HANDLE]->m_pLoginChn->m_p2pTalk.m_nTalkRespFlag = 1;
			else
				m_pMainCtrl[nIndex-P2P_TALK_HANDLE]->m_pLoginChn->m_p2pTalk.m_nTalkRespFlag = 0;
#endif
			JTRACE("talk resp ===================\r\n");
			break;
		}
	case IOTYPE_USER_IPCAM_FILE_RESEND_RESP: //∂™∞¸÷ÿ¥�?
		{
			JTRACE("IOTYPE_USER_IPCAM_FILE_RESEND_RESP............\r\n");
			break;
		}
	case IOTYPE_USER_IPCAM_SETSTREAMCTRL_RESP: //�����л�Ӧ��
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
	case IOTYPE_USER_IPCAM_SEND_ANDROID_MOTION_ALARM:  // ∞≤◊ø±®æØ”¶¥
		{
			nFlag = 1;
			eType = NETPRO_PARAM_GET_ANDROIDALARM;
			JTRACE("******************  alarm   *****************************\r\n");
			break;
		}
	case IOTYPE_USER_IPCAM_SET_UPDATE_RESP: // …Ë÷√…˝º∂”¶¥
		{
			nFlag = 1;
			//SMsgAVIoctrlSetAudioAlarmResp* sRet = (SMsgAVIoctrlSetAudioAlarmResp *)pData;

			SMsgAVIoctrlSetUpdateResp *sRet = (SMsgAVIoctrlSetUpdateResp *)pData;
			eType = NETPRO_PARAM_SET_UPDATE;

			if(sRet)	nRet = sRet->result;
			else		nRet = NetProErr_SETPARAM;
			break;
		}
	case IOTYPE_USER_IPCAM_GETSUPPORTSTREAM_RESP: // ªÒ»°Õ®µ¿”¶¥
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
				m_pMainCtrl[nIndex-P2P_CHANNEL_ADDVALUE]->m_pLoginChn->m_eventCB(m_nCurIndex, m_nDevChn, NETPRO_EVENT_RET_DEVCHN_NUM, (long)m_nNVRNum, NULL, m_lUserParam);
			}
#endif
			break;
		}
	case IOTYPE_USER_IPCAM_RECORD_PLAYCONTROL_RESP: // ¬ºœÒøÿ÷∆”¶¥
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
	case IOTYPE_USER_NVR_RECORDLIST_RESP: // ªÒ»° NVR ¬ºœÒ¡–±Ì¥Û–°”¶¥
		{
			nFlag = 1;
			eType = NETPRO_PARAM_GET_NVR_REC;
			break;
		}
	case IOTYPE_USER_IPCAM_SET_LIGHT_RESP: // …Ë÷√µ∆ø™πÿ”¶¥
		{
			nFlag = 1;
			eType = NETPRO_PARAM_SET_LIGHT;

			SMsgAVIoctrlSetLightResp *sRet = (SMsgAVIoctrlSetLightResp *)pData;
			if(sRet)	nRet = sRet->result;
			else		nRet = NetProErr_SETPARAM;
			break;
		}
	case IOTYPE_USER_IPCAM_GET_LIGHT_TIME_RESP: // ªÒ»°µ∆¡¡ ±º‰”¶¥
		{
			nFlag = 1;
			eType = NETPRO_PARAM_GET_LIGHTTIME;
			break;
		}
	case IOTYPE_USER_IPCAM_SET_LIGHT_TIME_RESP: // …Ë÷√µ∆¡¡ ±º‰”¶¥
		{
			nFlag = 1;
			eType = NETPRO_PARAM_SET_LIGHTTIME;

			SMsgAVIoctrlSetLightTimeResp *sRet = (SMsgAVIoctrlSetLightTimeResp *)pData;
			if(sRet)	nRet = sRet->result;
			else		nRet = NetProErr_SETPARAM;

			break;
		}
	case IOTYPE_USER_IPCAM_RESET_RESP: // ª÷∏¥≥ˆ≥ß…Ë÷√”¶¥
		{
			nFlag = 1;
			eType = NETPRO_PARAM_DEV_RESET;
			SMsgAVIoctrlResetResp *sRet = (SMsgAVIoctrlResetResp *)pData;
			if(sRet)	nRet = sRet->result;
			else		nRet = NetProErr_SETPARAM;
			break;
		}
	case IOTYPE_USER_IPCAM_SET_MOBILE_CLENT_TYPE_RESP: //∞≤◊ø ÷ª˙øÕªß∂À÷√Œª«Î«Û”¶¥
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
	case IOTYPE_USER_IPCAM_GET_CAMEREA_STATUS_RESP: //��������״̬
		{
			nFlag = 1;
			eType = NETPRO_PARAM_GET_CAMEREA_STATUS; //CAMEREA_STATUS
			break;
		}
	case IOTYPE_USER_IPCAM_PLAY_RECORD_RESP:
		{
			nFlag = 1;
			eType = NETPRO_PARAM_SET_LOCAL_STORE_CFG; //CAMEREA_STATUS
			break;
		}
	case IOTYPE_USER_IPCAM_STOP_PLAY_RECORD_RESP:
		{
			nFlag = 1;
			eType = NETPRO_PARAM_SET_LOCAL_STORE_STOP; //CAMEREA_STATUS
			break;
		}
	case TCP_NOTIFY_MSG_TYPE_AI_INFO:
		{
			nFlag = 1;
			eType = NETPRO_PRRAM_GET_AI_INFO; //CAMEREA_STATUS

// 			SAiInfo *pInfo = (SAiInfo *)pData;
// 			JTRACE("frameno = %d, streamid = %d, width = %d, height = %d, facecount = %d\r\n",
// 				pInfo->frameno,pInfo->streamid,pInfo->width,pInfo->height,pInfo->facecount);
			break;
		}
	default:
		{
			nRet = nChn;
			nFlag = 1;
			eType = NETPRO_PRRAM_TEST_AI_SERVER; //CAMEREA_STATUS
		}

	}


	if(nFlag == 1)
		m_eventCB(nIndex, 0, eType, nRet, (long)pData, m_lUserParam);

	return 0;
}

#include "P2pDownLoad.h"


CP2pDownLoad::CP2pDownLoad() : CP2pCommon()
{
	memset(m_strDownLoadFile, '\0', P2P_DOWNLOAD_MAX_FILE_LEN);
	memset(m_strUID, '\0', P2P_DOWNLOAD_MAX_FILE_LEN);

	m_pDownLoadFile			= NULL;
	m_pTcpHandle			= NULL;
	m_pTransPort			= NULL;
	m_nConnDownLoadFlag		= -1;
	m_nDownLoadChannel		= -1;
	m_nDevIndex				= -1;
	m_nDevChn				= 0;

	m_nNextDownLoadPacket	 = 0;
	m_nUdpLastRecv			 = 0;
	m_nReSendFlag			 = 0;
	m_nLastDownLoadProcess	 = -1;
	m_nReSendTime			 = -1;
	m_nReSendCount			 = 0;
	m_nUdpLostPktCont		 = 0;
	m_nUdpDLTotalPkt		 = 0;
	m_dwStartRecvTime		 = 0;
	m_nIsTcpTransPond		= 0;
	m_eventCB				= NULL;
	m_lUserParam			= NULL;


	memset(&m_sStartRecReq, 0, sizeof(m_sStartRecReq));

	strcpy_s(m_tcDownLoad.m_szName,J_DGB_NAME_LEN,"m_tcDownLoad");
	m_tcDownLoad.SetOwner(this);
	m_tcDownLoad.SetParam(this);
}


CP2pDownLoad::~CP2pDownLoad()
{
	CloseDownLoad();
}

void CP2pDownLoad::on_connect_result(void *transport, void* user_data, int status)
{
	CP2pDownLoad *pThis	= (CP2pDownLoad *)user_data;
	if(status == 0)
	{
		JTRACE("CP2pDownLoad::on_connect_result success........\r\n");
		pThis->m_nConnDownLoadFlag = 1;
	}
	else
	{
		JTRACE("CP2pDownLoad::on_connect_result error........\r\n");
		pThis->m_nConnDownLoadFlag = 0;
	}
}

void CP2pDownLoad::on_disconnect(void *transport, void* user_data, int status)
{

}
void CP2pDownLoad::on_recv(void *transport, void *user_data, char* data, int len)
{
	PAVBuffArray		pstEle		= NULL;
	CP2pDownLoad *pThis	= (CP2pDownLoad *)user_data;
	P2pHead *pHead = (P2pHead *)data;

	if(pHead->msgChildType == RECV_DOWNLOAD_FRAME)
	{
		FILE_PACKET_HEAD *pPktHead = (FILE_PACKET_HEAD *)(data+sizeof(P2pHead));
		if(pPktHead)
		{
			//JTRACE("total_packet_num = %d, curr_packet_no = %d, curr_packet_length = %d\r\n", pPktHead->total_packet_num, pPktHead->curr_packet_no, pPktHead->curr_packet_length );
			pstEle = pThis->m_avbuffCtrl.BeginAddBuff( data+sizeof(P2pHead), pHead->dataLen, 0, 0 );
			if( pstEle )
			{
				pThis->m_avbuffCtrl.EndAddBuff();
			}
		}
	}
	else if(pHead->msgChildType == IOTYPE_USER_IPCAM_GET_RECORDFILE_START_RESP)
	{
		SMsgAVIoctrlGetRecordFileStartResp *sRet = (SMsgAVIoctrlGetRecordFileStartResp *)(data+sizeof(P2pHead));

		if(sRet->result >= 0)
		{
			pThis->m_eventCB(pThis->m_nDevIndex, 0, NETPRO_EVENT_REC_DOWNLOAD_RET, NetProErr_Success, NULL, pThis->m_lUserParam);
		}
		else
		{	
			pThis->m_eventCB(pThis->m_nDevIndex, 0, NETPRO_EVENT_REC_DOWNLOAD_RET, NetProErr_DOWNLOADERR, NULL, pThis->m_lUserParam);
		}
	}

}

void CP2pDownLoad::on_device_disconnect(void *transport, void *user_data)
{

}

int CP2pDownLoad::ConnDownLoadChannel(int nDownLoadType)
{
	int						nRet = -1;
	int						nCount = 0;
	gss_client_conn_cfg		connCfg;
	gss_client_conn_cb		connCB;

	CloseDownLoadChannel();

	if(m_nIsTcpTransPond)
	{

		connCB.on_connect_result = on_connect_result;
		connCB.on_disconnect = on_disconnect;
		connCB.on_recv = on_recv;
		connCB.on_device_disconnect = on_device_disconnect;

		connCfg.server = m_strServerAddr;
		connCfg.port = m_nServerPort;
		connCfg.uid = m_strID;
		connCfg.user_data = this;
		connCfg.cb	= &connCB;

		gss_client_av_connect(&connCfg, &m_pTcpHandle);
	}
	else
	{
		nRet = p2p_transport_connect(m_pTransPort, m_strUID, (void *)(m_nDevIndex+P2P_DOWNLOAD_HANDLE), 1, &m_nDownLoadChannel);
		if(nRet != 0 )
		{
			JTRACE("CP2pChannel::ConnDev p2p_transport_connect error =%d\r\n", nRet);
			return -1;
		}
	}

	while(nCount < 20)
	{
		if(m_nConnDownLoadFlag >= 0)
			break;

		nCount ++;
		JSleep(200);
	}

	if(m_nConnDownLoadFlag != 1) return -2;

	//nRet = avSendIOCtrl(IOTYPE_USER_IPCAM_GET_RECORDFILE_STOP_REQ, NULL, 0, m_nIsTcpTransPond, m_pTcpHandle);
	//if(nRet != 0) return NetProErr_GETPARAM;

	//JSleep(100);

	m_sStartRecReq.reserved[0] = nDownLoadType;
	nRet = avSendIOCtrl(m_pTransPort, m_nDownLoadChannel, IOTYPE_USER_IPCAM_GET_RECORDFILE_START_REQ, (const char*)&m_sStartRecReq, sizeof(SMsgAVIoctrlGetRecordFileStartReq), m_nIsTcpTransPond, m_pTcpHandle);
	if(nRet != 0)
	{
		nRet = avSendIOCtrl(m_pTransPort, m_nDownLoadChannel, IOTYPE_USER_IPCAM_GET_RECORDFILE_START_REQ, (const char*)&m_sStartRecReq, sizeof(SMsgAVIoctrlGetRecordFileStartReq), m_nIsTcpTransPond, m_pTcpHandle);
		if(nRet != 0)
			return NetProErr_GETPARAM;
	}


	return 0;
}
int CP2pDownLoad::CloseDownLoadChannel()
{
	int nRet = 0;

	if(m_nDownLoadChannel >= 0 || m_pTcpHandle)
	{
		nRet = avSendIOCtrl(m_pTransPort, m_nDownLoadChannel, IOTYPE_USER_IPCAM_GET_RECORDFILE_STOP_REQ, NULL, 0, m_nIsTcpTransPond, m_pTcpHandle);
		if(nRet != 0)
		{
			nRet = avSendIOCtrl(m_pTransPort, m_nDownLoadChannel, IOTYPE_USER_IPCAM_GET_RECORDFILE_STOP_REQ, NULL, 0, m_nIsTcpTransPond, m_pTcpHandle);
			if(nRet != 0) 
				return -1;
		}
	}

	if(m_nDownLoadChannel >= 0)
	{
		p2p_transport_disconnect(m_pTransPort, m_nDownLoadChannel);
		m_nDownLoadChannel = -1;	
	}

	if(m_pTcpHandle)
	{
		gss_client_av_destroy(m_pTcpHandle);
		m_pTcpHandle= NULL;
	}

	m_nConnDownLoadFlag = -1;
	return 0;
}
int	CP2pDownLoad::RecDownload(p2p_transport* pTransPort, const char* pFileName, char *pSrcFileName, char *pUID, int nIndex, EventCallBack eventCB, long lUserParam)
{	

	//if(!pTransPort) return NetProErr_TransPortCreate;

	m_pTransPort = pTransPort;
	m_sStartRecReq.channel = 0;
	sprintf(m_sStartRecReq.filename, "%s", pSrcFileName);
	sprintf(m_strUID, "%s", pUID);
	m_nDevIndex = nIndex;
	m_eventCB = eventCB;
	m_lUserParam = lUserParam;


	m_nNextDownLoadPacket	 = 0;
	m_nUdpLastRecv			 = 0;
	m_nReSendFlag			 = 0;
	m_nLastDownLoadProcess	 = -1;
	m_nReSendTime			 = -1;
	m_nReSendCount			 = 0;
	m_nUdpLostPktCont		 = 0;
	m_nUdpDLTotalPkt		 = 0;
	m_dwStartRecvTime		 = 0;

	m_nVectorLost.clear();
	m_pDownLoadFile = fopen(pFileName, "wb");

	m_avbuffCtrl.SetUserID(nIndex);
	m_avbuffCtrl.SetSize( 100, 3, 5*1024);	

	if(!m_pDownLoadFile) return  NetProErr_OPENFILE;
	m_tcDownLoad.StartThread(RunDownLoadRecThread);
	return 0;
}
int CP2pDownLoad::CloseDownLoad()
{
	CloseDownLoadChannel();

	if(m_pDownLoadFile)
	{
		fflush(m_pDownLoadFile);
		fclose(m_pDownLoadFile);
		m_pDownLoadFile = NULL;
	}

	m_avbuffCtrl.Clear();

	return 0;
}

int CP2pDownLoad::StopDownload()
{
	int nRet		= 0;
	m_tcDownLoad.StopThread(true);

	CloseDownLoad();
	JTRACE("CP2pDownLoad::StopDownload*******************************\r\n");
	return 0;
}


fJThRet CP2pDownLoad::RunDownLoadRecThread(void* pParam)
{
	CJLThreadCtrl*		pThreadCtrl			= NULL;
	CP2pDownLoad*	pChannel			= NULL;
	int				iIsRun				= 0;
	int				nRet				= 0;

	pThreadCtrl	= (CJLThreadCtrl*)pParam;
	if ( pThreadCtrl==NULL )
	{
		return 0;
	}
	pChannel	= (CP2pDownLoad *)pThreadCtrl->GetOwner();
	if ( pChannel == NULL )
	{
		pThreadCtrl->SetThreadState(THREAD_STATE_STOP);		
		return 0;
	}

	if(pChannel->ConnDownLoadChannel() != 0 )
	{
		pChannel->m_eventCB(pChannel->m_nDevIndex, 0, NETPRO_EVENT_REC_DOWNLOAD_RET, NetProErr_DOWNLOADERR, NULL, pChannel->m_lUserParam);
		pThreadCtrl->NotifyStop();
		JTRACE("RunDownLoadRecThread ConnDownLoadChannel exit **********************\r\n");
		return 0;
	}

	iIsRun	= 1;
	while(iIsRun)
	{
		if ( pThreadCtrl->GetNextAction() == THREAD_STATE_STOP )
		{
			iIsRun = 0;										// ≤ª‘Ÿ‘À–�?
			break;
		}

		nRet = pChannel->DownLoadAction();
		if(nRet > 0 )
		{
			pChannel->CloseDownLoad();
			if(nRet == 1 ) pChannel->m_eventCB(pChannel->m_nDevIndex, 0, NETPRO_EVENT_REC_DOWNLOAD_SUCCESS, 100, NULL, pChannel->m_lUserParam); //œ¬‘ÿÕÍ≥�?
			iIsRun = 0;
			//JTRACE("*********************************************** %d", pChannel->m_nUdpWriteFileLen);
			break;
		}

		JSleep(5);
	}

	pThreadCtrl->NotifyStop();
	iIsRun = 0;
	JTRACE("RunDownLoadRecThread exit **********************\r\n");

	return 0;
}


int	CP2pDownLoad::DownLoadAction()
{
	PAVBuffArray		pstEle		= NULL;
	PAVBuffArray		pstEleV		= NULL;
	int					nRet		= 0;
	int					nCount		= 0;
	int					nConnFlag	= 0;

	pstEle = m_avbuffCtrl.BeginGetBuff();
	if ( pstEle )
	{
		pstEleV = pstEle;
		m_avbuffCtrl.EndGetBuff();

		nRet = UDP_DownLoadRec((char *)pstEleV->m_pBuf, pstEleV->m_iBufSize);
		if(nRet == 1 ) return nRet;
	}

	if((int)(JGetTickCount() - m_dwStartRecvTime) >= (5*1000) && m_dwStartRecvTime > 0 )
	{
		if(m_nUdpDLTotalPkt == 0)
		{
			m_eventCB(m_nDevIndex, m_nDevChn, NETPRO_EVENT_REC_DOWNLOAD_RET, NetProErr_DOWNLOADINGERR, NULL, m_lUserParam); //≥¨ ± ß∞�?
			return 1;
		}
		if(m_nReSendTime == -1)
		{
			int nLostPacketNum = 0;
			nLostPacketNum = m_nUdpDLTotalPkt - m_nUdpLastRecv;
			if(nLostPacketNum > 0 ) 
			{
				for(int i = 0; i < (nLostPacketNum ); i++)
				{
					m_nVectorLost.push_back(m_nUdpLastRecv+1+i);
					JTRACE("LOST PKT %d\r\n", m_nUdpLastRecv+1+i);
					if(i == (nLostPacketNum -1 )) break;
				}
			}

		}
		++ m_nReSendTime;
		int nReSendFlag = 5;

		if(m_nVectorLost.size() > 0 )
		{
			if(m_nReSendTime < nReSendFlag)
			{
				ReGetUDPDownloadPkt();
				nRet =  0;
			}
			else
			{

				do
				{
					nConnFlag = ConnDownLoadChannel(1);
					nCount ++;

				} while (nCount < 3 && nConnFlag != 0);

				if( nConnFlag != 0 )
				{
					m_eventCB(m_nDevIndex, m_nDevChn, NETPRO_EVENT_REC_DOWNLOAD_RET, NetProErr_DOWNLOADERR, NULL, m_lUserParam);

					return 1;
				}
				m_nReSendTime = 0;
				ReGetUDPDownloadPkt();	

			}

			m_dwStartRecvTime = JGetTickCount();
		}

		//m_dwStartRecvTime = 0;

		return nRet;
	}
	return 0;
}

int CP2pDownLoad::UDP_DownLoadRec(char* pBuf_,  int nRecvLen_)
{
	int				nRet					= 0;
	int				nDownLoadProcess		= 0;
	unsigned int	nCurPacket				= 0;
	int				nLostPacketNum			= 0;
	int				nRecvLen				= 0;
	char*			pBuf					= pBuf_ + sizeof(FILE_PACKET_HEAD);
	//char			strBuf[1024*10]			= {0};

	m_dwStartRecvTime = JGetTickCount();


	FILE_PACKET_HEAD *pPHead = (FILE_PACKET_HEAD *)pBuf_;
	nCurPacket = pPHead->curr_packet_no;
	if(m_nUdpDLTotalPkt < 1)
		m_nUdpDLTotalPkt = pPHead->total_packet_num;
	if(m_nDownLoadFileLength == 0)
	{
		m_nDownLoadFileLength = pPHead->total_file_length;
		//m_eventCB(m_nDevIndex, m_nDevChn, NETPRO_EVENT_REC_DOWNLOAD_RET, (long)m_nDownLoadFileLength, NULL, m_lUserParam);
	}

	nRecvLen = pPHead->curr_packet_length;


	if(nRecvLen != PRO_CHN_DOWNLOAD_PKT_SIZE)
	{
		JTRACE("EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE  nRecvLen = %d\r\n", nRecvLen);
	}

	if(nCurPacket == 0 ) return 0;

	if(nCurPacket == pPHead->total_packet_num)
	{
		//JTRACE("kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk  nRecvLen = %d\r\n", nRecvLen);
	}

	JTRACE("nRecvLen = %d, nCurPacket = %d**********************************\r\n", nRecvLen, nCurPacket);
	if(m_nReSendFlag)
	{


		for(m_iterator=m_nVectorLost.begin(); m_iterator != m_nVectorLost.end();)
		{
			if(*m_iterator == nCurPacket)
			{
				++ m_nReSendCount;
				fseek(m_pDownLoadFile, (nCurPacket-1)*(PRO_CHN_DOWNLOAD_PKT_SIZE), SEEK_SET);
				fwrite(pBuf, 1, nRecvLen, m_pDownLoadFile);
				m_nUdpWriteFileLen += nRecvLen;
				JTRACE("ReSend PKT %d, nTotalPacket %d\r\n", nCurPacket, m_nUdpDLTotalPkt);

				if(m_nUdpDLTotalPkt > 0)
					nDownLoadProcess = 100*(m_nUdpDLTotalPkt + m_nReSendCount - m_nUdpLostPktCont) / m_nUdpDLTotalPkt;

				if(m_nLastDownLoadProcess != nDownLoadProcess)
					m_eventCB(m_nDevIndex, m_nDevChn, NETPRO_EVENT_REC_DOWNLOADING,nDownLoadProcess /*(nDownLoadProcess > 95) ? 95:nDownLoadProcess*/, NULL, m_lUserParam); //∑µªÿœ¬‘ÿΩ¯∂»

				m_nLastDownLoadProcess = nDownLoadProcess;
				m_iterator = m_nVectorLost.erase(m_iterator);
				break;
			}
			++ m_iterator;
		}

		if(m_nReSendCount == m_nUdpLostPktCont) //∂™∞�?£¨÷ÿ¥´ÕÍ≥�? œ¬‘ÿ≥…π¶
		{
			JTRACE("resend success......\r\n");
			m_eventCB(m_nDevIndex, m_nDevChn, NETPRO_EVENT_REC_DOWNLOADING, 100, NULL, m_lUserParam);
			//m_eventCB(m_nDevIndex, NETPRO_EVENT_REC_DOWNLOAD_SUCCESS, 100, NULL, m_lUserParam); //œ¬‘ÿÕÍ≥�?
			return 1;
		}
		return 0;
	}

	//JTRACE("curr_num = %d, nTotalPacket = %d, nRecvLen = %d\r\n", nCurPacket, nTotalPacket, nRecvLen);

	nLostPacketNum =  nCurPacket - m_nUdpLastRecv;

	if(nLostPacketNum > 1 ) // ”–∂™∞¸
	{
		for(int i = 0; i < (nLostPacketNum -1 ); i++)
		{
			m_nVectorLost.push_back(m_nUdpLastRecv+1+i);
			JTRACE("LOST PKT %d\r\n", m_nUdpLastRecv+1+i);
			//fwrite(strBuf, 1, nRecvLen, m_pDownLoadFile);
		}

	}


	if(nCurPacket < m_nUdpLastRecv)
	{
		JTRACE("ErrorErrorErrorErrorErrorErrorErrorErrorErrorErrorErrorErrorErrorErrorErrorErrorErrorErrorError\r\n");
	}

	fseek(m_pDownLoadFile, (nCurPacket-1)*(PRO_CHN_DOWNLOAD_PKT_SIZE), SEEK_SET); //nRecvLen
	fwrite(pBuf, 1, nRecvLen, m_pDownLoadFile);
	m_nUdpWriteFileLen += nRecvLen;

	if(m_nUdpDLTotalPkt > 0)
		nDownLoadProcess = 100*(nCurPacket - m_nVectorLost.size()) / m_nUdpDLTotalPkt;

	if(m_nLastDownLoadProcess != nDownLoadProcess)
		m_eventCB(m_nDevIndex, m_nDevChn, NETPRO_EVENT_REC_DOWNLOADING,nDownLoadProcess /*(nDownLoadProcess > 95) ? 95:nDownLoadProcess*/, NULL, m_lUserParam); //∑µªÿœ¬‘ÿΩ¯∂»

	m_nLastDownLoadProcess = nDownLoadProcess;

	m_nUdpLastRecv = nCurPacket;

	if(nCurPacket == m_nUdpDLTotalPkt)
	{
		if(m_nVectorLost.size() == 0 ) // Œ¥∂™∞�?œ¬‘ÿÕÍ≥�?
		{
			m_eventCB(m_nDevIndex, m_nDevChn, NETPRO_EVENT_REC_DOWNLOADING, 100, NULL, m_lUserParam);
			//m_eventCB(m_nDevIndex, NETPRO_EVENT_REC_DOWNLOAD_SUCCESS, 100, NULL, m_lUserParam);
			return 1;  //œ¬‘ÿÕÍ≥�?
		}

	}

	return 0;
}

void CP2pDownLoad::ReGetUDPDownloadPkt()
{
	SMsgAVIoctrlFileRetransportReq	udpLostReq;
	int		nRet	 = -1;
	memset(&udpLostReq, 0, sizeof(udpLostReq));

	if(m_nUdpLostPktCont == 0)
	{
		m_nUdpLostPktCont = m_nVectorLost.size();
		JTRACE("total lost = %d==========================================================\r\n", m_nUdpLostPktCont);
	}
	//∂™∞¸÷ÿ–¬«Î«�?
	if(m_nVectorLost.size() > 255)
	{
		for(int i = 0; i < 255; i++)
			udpLostReq.loss_packet_no[i] = m_nVectorLost[i];

		udpLostReq.total_num = 255;
	}
	else
	{
		for(int i = 0; i < m_nVectorLost.size(); i++)
			udpLostReq.loss_packet_no[i] = m_nVectorLost[i];

		udpLostReq.total_num = m_nVectorLost.size();
	}

	udpLostReq.channel = 0;
	udpLostReq.loss_flag = 1;
	m_nReSendFlag = 1;
	JTRACE("resend time = %d..............................\r\n", m_nReSendTime);
	nRet = avSendIOCtrl(m_pTransPort, m_nDownLoadChannel, IOTYPE_USER_IPCAM_FILE_RESEND_REQ, (char *)&udpLostReq,sizeof(udpLostReq), m_nIsTcpTransPond, m_pTcpHandle);
	if(nRet != 0)
	{
		nRet = avSendIOCtrl(m_pTransPort, m_nDownLoadChannel, IOTYPE_USER_IPCAM_FILE_RESEND_REQ, (char *)&udpLostReq,sizeof(udpLostReq), m_nIsTcpTransPond, m_pTcpHandle);
		if(nRet != 0) 
		{
			JTRACE("CP2pDownLoad::ReGetUDPDownloadPkt error*******************************\r\n");
			return;
		}
	}

}


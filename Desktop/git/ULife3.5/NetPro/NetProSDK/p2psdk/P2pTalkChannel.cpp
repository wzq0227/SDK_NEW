#include "P2pTalkChannel.h"


CP2pTalkChannel::CP2pTalkChannel() : CP2pCommon()
{
	m_pTransPort		= NULL;
	m_nTalkChannel		= -1;
	m_nConnFlag			= -1;
	m_nTalkRespFlag		= 0;
	m_nIsTcpTransPond	= 0;
	m_pTcpHandle		= NULL;
	m_pReadTalkFile		= NULL;
	m_pSendTalkData		= NULL;
	m_nSendDataLen		= 0;
	m_nTalkChn			= 0;
}


CP2pTalkChannel::~CP2pTalkChannel()
{
	SAFE_DELETE(m_pSendTalkData);
}


void CP2pTalkChannel::on_connect_result(void *transport, void* user_data, int status)
{
	CP2pTalkChannel *pThis	= (CP2pTalkChannel *)user_data;
	if(status == 0)
	{
		pThis->m_nConnFlag = 1;
	}
	else
	{
		pThis->m_nConnFlag = 0;
	}
}

void CP2pTalkChannel::on_disconnect(void *transport, void* user_data, int status)
{

}
void CP2pTalkChannel::on_recv(void *transport, void *user_data, char* data, int len)
{
	CP2pTalkChannel *pThis	= (CP2pTalkChannel *)user_data;
	P2pHead *pHead = (P2pHead *)data;
	if(pHead->msgChildType == IOTYPE_USER_IPCAM_SPEAKERPROCESS_RESP)
	{
		pThis->m_nTalkRespFlag = 1;
	}
}

void CP2pTalkChannel::on_device_disconnect(void *transport, void *user_data)
{

}

int		CP2pTalkChannel::StartTalk(p2p_transport* pTransPort, char *pUID, int nDevIndex, int nTalkChn)
{
	//if(!pTransPort) return NetProErr_TransPortCreate;

	int		nRet = -1;
	int		nCount = 0;
	SMsgAVIoctrlAVStream	avStream	= {0};
	gss_client_conn_cfg		connCfg;
	gss_client_conn_cb		connCB;
	if(m_nTalkChannel >= 0 ) return 1;

	if(m_pTcpHandle) return 1;

	ClostTalkChannel();

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
		m_pTransPort = pTransPort;
		nRet = p2p_transport_connect(m_pTransPort, pUID, (void *)(nDevIndex+P2P_TALK_HANDLE), 1, &m_nTalkChannel);
		if(nRet != 0 )
		{
			JTRACE("CP2pChannel::ConnDev p2p_transport_connect error =%d\r\n", nRet);
			return -1;
		}
	}
	

	while(nCount < 50)
	{
		if(m_nConnFlag >= 0)
			break;

		nCount ++;
		JSleep(100);
	}

	if(m_nConnFlag != 1) return -2;
	m_nTalkRespFlag = 0;
	avStream.reserved[0] = nTalkChn;
	m_nTalkChn = nTalkChn;
	nRet = avSendIOCtrl(m_pTransPort, m_nTalkChannel, IOTYPE_USER_IPCAM_SPEAKERSTART, (const char*)&avStream, sizeof(SMsgAVIoctrlGetRecordFileStartReq), m_nIsTcpTransPond, m_pTcpHandle);
	if(nRet != 0)
	{
		return NetProErr_OPENTALKERR;
	}
	nCount = 0;
	while(m_nTalkRespFlag == 0 && nCount < 50)
	{
		nCount ++ ;
		JSleep(100);
	}

	if(m_nTalkRespFlag == 0)
	{
		ClostTalkChannel();
		return NetProErr_OPENTALKERR;
	}

	return NetProErr_Success;
}

int		CP2pTalkChannel::StopTalk()
{
	SMsgAVIoctrlAVStream	avStream	= {0};

	if(m_pReadTalkFile)
	{
		fclose(m_pReadTalkFile);
		m_pReadTalkFile = NULL;
	}
// 	if(m_nTalkChannel >= 0)
// 	{
// 		avSendIOCtrl(m_pTransPort, m_nTalkChannel, IOTYPE_USER_IPCAM_SPEAKERSTOP, (const char*)&avStream, sizeof(SMsgAVIoctrlGetRecordFileStartReq), m_nIsTcpTransPond, m_pTcpHandle);
// 	}

	ClostTalkChannel();
	return NetProErr_Success;
}

int		CP2pTalkChannel::TalkSendFile(const char *pFileName, int nIsPlay)
{
	int						nRet			= 0;
	int						nReadLen		= 0;
	char					*pStrRead		= NULL;
	gos_frame_head			frameinfo		= {0};
	SMsgAVIoctrlAVStream	avStream		= {0};

	if(!m_nTalkRespFlag) return -1;

	m_pReadTalkFile = fopen(pFileName, "rb");
	if(NULL == m_pReadTalkFile )
	{
		return -1;
	}
	frameinfo.nFrameType = gos_audio_frame;
	frameinfo.nCodeType = gos_audio_G711A;
	frameinfo.nFrameRate = 8000;
	fseek(m_pReadTalkFile,0L,SEEK_END); 
	frameinfo.reserved = ftell(m_pReadTalkFile);  //文件总大小
	fseek(m_pReadTalkFile,0L,SEEK_SET); 
	frameinfo.nTimestamp = nIsPlay;
	pStrRead = new char[P2P_CHN_MAX_RECV_TALKFILE_SIZE+sizeof(gos_frame_head)];

	do 
	{
		
		memset(pStrRead, 0, P2P_CHN_MAX_RECV_TALKFILE_SIZE+sizeof(gos_frame_head));
		
		nReadLen = fread((pStrRead+sizeof(gos_frame_head)), 1, P2P_CHN_MAX_RECV_TALKFILE_SIZE, m_pReadTalkFile);
		if( nReadLen > 0 )
		{
			frameinfo.nTimestamp = JGetTickCount();
			frameinfo.nDataSize	 = nReadLen;
			memcpy(pStrRead, (char*)&frameinfo, sizeof(gos_frame_head));
			nRet = avSendIOCtrl(m_pTransPort, m_nTalkChannel, P2P_USER_TALK_SENDFILE, (const char*)pStrRead, nReadLen+sizeof(gos_frame_head), m_nIsTcpTransPond, m_pTcpHandle);
			if(nRet != 0 )
				JTRACE("TalkSendFile err %d\r\n", nRet);
			else
				JTRACE("TalkSendFile success %d\r\n", nReadLen);

			JSleep(20);
		}

	} while (nReadLen > 0 && m_pReadTalkFile);

	avSendIOCtrl(m_pTransPort, m_nTalkChannel, IOTYPE_USER_IPCAM_SPEAKERSTOP, (const char*)&avStream, sizeof(SMsgAVIoctrlGetRecordFileStartReq), m_nIsTcpTransPond, m_pTcpHandle);

	SAFE_DELETE(pStrRead);
	fclose(m_pReadTalkFile);
	m_pReadTalkFile = NULL;

	return 0;
}

int		CP2pTalkChannel::TalkSendFrame(char *pFrame, int nFrameLen)
{
	gos_frame_head			frameinfo		= {0};

	int nSendLen = nFrameLen + sizeof(gos_frame_head);
	frameinfo.nFrameType = gos_audio_frame;
	frameinfo.nCodeType = gos_audio_G711A;
	frameinfo.nFrameRate = 8000;
	frameinfo.nDataSize = nFrameLen;
	frameinfo.reserved = 0;  //文件总大小
	
	if(m_nTalkChannel < 0) return -1;

	if((nSendLen > nFrameLen) || !m_pSendTalkData)
	{
		SAFE_DELETE(m_pSendTalkData);
		m_pSendTalkData = new char[nSendLen + 1];
		m_nSendDataLen = nSendLen;
	}
	if(!m_pSendTalkData ) return -2;

	memcpy(m_pSendTalkData, &frameinfo, sizeof(gos_frame_head));
	memcpy(m_pSendTalkData+sizeof(gos_frame_head), pFrame, nFrameLen);

	avSendIOCtrl(m_pTransPort, m_nTalkChannel, P2P_USER_TALK_SENDFILE, (const char*)m_pSendTalkData, nSendLen, m_nIsTcpTransPond, m_pTcpHandle);

	return 0;
}

int		CP2pTalkChannel::ConnTalkChannel()
{
	return NetProErr_Success;
}
int		CP2pTalkChannel::ClostTalkChannel()
{
	if(m_nTalkChannel >= 0)
	{
		p2p_transport_disconnect(m_pTransPort, m_nTalkChannel);
		m_nTalkChannel		= -1;
	}

	if(m_pTcpHandle)
	{
		gss_client_av_destroy(m_pTcpHandle);
		m_pTcpHandle= NULL;
	}
	SAFE_DELETE(m_pSendTalkData);
	m_nSendDataLen = 0;
	m_nConnFlag			= -1;
	m_nTalkRespFlag		= 0;
	return NetProErr_Success;
} 
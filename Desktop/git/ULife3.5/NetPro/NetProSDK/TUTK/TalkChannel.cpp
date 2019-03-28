#include "TalkChannel.h"



CTalkChannel::CTalkChannel()
{
	m_nSendFileChannel		= -1;
	m_nTalkRespFlag			= 0;
	m_nIsTalkFlag			= 0;
	m_nIndex				= 0;
	m_nChn					= 0;
	m_nPro					= 0;
	m_pReadAAC				= NULL;
	m_eventCB				= NULL;
	m_lUserParam			= NULL;
}

CTalkChannel::~CTalkChannel()
{
	if(m_pReadAAC)
	{
		fclose(m_pReadAAC);
		m_pReadAAC = NULL;
	}
}
int		CTalkChannel::CheckTalk()
{
	return m_nIsTalkFlag;
}

int		CTalkChannel::StartTalk(int nIndex, int nChn, int nConnChannel, int nConnID, int nSessionID)
{
	int						nRet		= -1;
	int						nCount		= 0;
	SMsgAVIoctrlAVStream	avStream	= {0};
	st_SInfo				sInfo		= {0};
	
	if(m_nIsTalkFlag)	return 0;

	m_nIndex = nIndex;
	m_nChn = nChn;
	m_nPro	= 0;

	nRet = IOTC_Session_Check( nSessionID, &sInfo );
	if(nRet != 0 ) 
	{
		JTRACE("TalkSendFileAction   IOTC_Session_Check error\r\n");
		return -1;
	}

	m_nSendFileChannel = IOTC_Session_Get_Free_Channel(nConnID);
	if(m_nSendFileChannel < 0)
	{
		//m_eventCB(m_nCurIndex, );
		JTRACE("TalkSendFileAction   IOTC_Session_Get_Free_Channel error\r\n");
		return -1;
	}

	avStream.reserved[0] = nChn;
	avStream.channel = m_nSendFileChannel;
	m_nTalkRespFlag = 0;
	//¿ªÆô¶Ô½²
	nRet = avSendIOCtrl(nConnChannel, IOTYPE_USER_IPCAM_SPEAKERSTART, (char *)&avStream, sizeof(SMsgAVIoctrlAVStream));
	if(nRet != 0 )
	{
		IOTC_Session_Channel_OFF(nConnID, m_nSendFileChannel);
		JTRACE("TalkSendFileAction   start talk error\r\n");
		return -1;
	}


	while(m_nTalkRespFlag == 0 && nCount < 10)
	{
		nCount ++ ;
		JSleep(300);
	}

	if(m_nTalkRespFlag == 0)
	{
		IOTC_Session_Channel_OFF(nConnID, m_nSendFileChannel);
		JTRACE("TalkSendFileAction   m_nTalkRespFlag \r\n");
		return -1;
	}

	//int nReSend = 0;
	//JTRACE("m_nConnID2 = %d\r\n", m_nConnID);
	m_nTalkServerChannel = avServStart(nConnID, NULL, NULL, 5, 0, m_nSendFileChannel); //SDK_DEBUG++
	//nServerChannel = avServStart2(m_nConnID, NULL, 5, 0, nSendFileChannel);
	//nServerChannel = avServStart3(m_nConnID, NULL, 5, 0, nSendFileChannel, &nReSend);
	if( m_nTalkServerChannel < 0 )
	{
		avSendIOCtrl(nConnChannel, IOTYPE_USER_IPCAM_SPEAKERSTOP, (char *)&avStream, sizeof(SMsgAVIoctrlAVStream));
		IOTC_Session_Channel_OFF(nConnID, m_nSendFileChannel);
		JTRACE("TalkSendFileAction   avServStart error %d\r\n", m_nTalkServerChannel);
		return -1;
	}

	m_nIsTalkFlag = 1;

	return 0;
}
int		CTalkChannel::SendAACData(const char* pBuf, int nLen)
{
	int					nRet			= 0;
	FRAMEINFO_t			frameinfo		= {0};

	frameinfo.codec_id  = MEDIA_CODEC_AUDIO_AAC;
	frameinfo.flags		= AUDIO_SAMPLE_16K << 2;//(AUDIO_SAMPLE_8K << 2) | (AUDIO_DATABITS_16 << 1) | AUDIO_CHANNEL_MONO;
	frameinfo.onlineNum = 0;
	frameinfo.nByteNum  = nLen;
	frameinfo.reserve2  = nLen;

	nRet = avSendAudioData(m_nTalkServerChannel, pBuf, nLen, (void*)&frameinfo, sizeof(frameinfo));
	if(nRet != 0 )
	{
		JTRACE("avSendAudioData err %d\r\n", nRet);
	}
	else
	{
		JTRACE("avSendAudioData success %d\r\n", nLen);
	}


	return 0;
}

int		CTalkChannel::SendAACfile(const char* pFile, int nFlag)
{
	int					nRet			= 0;
	int					nReadLen		= 0;
	char	strRead[PRO_CHN_MAX_RECV_TALKFILE_SIZE]		= {0};
	FRAMEINFO_t			frameinfo		= {0};
	int					nTotalUpLen		= 0;

	if(!m_nIsTalkFlag) return -1;

	m_pReadAAC = fopen(pFile, "rb");
	if(NULL == m_pReadAAC )
	{
		return -1;
	}

	frameinfo.codec_id = MEDIA_CODEC_AUDIO_AAC;
	frameinfo.flags = AUDIO_SAMPLE_16K << 2;//(AUDIO_SAMPLE_8K << 2) | (AUDIO_DATABITS_16 << 1) | AUDIO_CHANNEL_MONO;
	//frameinfo.cam_index = nSendFileChannel/*m_nChannel*/;
	frameinfo.onlineNum = 0;
	fseek(m_pReadAAC,0L,SEEK_END); 
	frameinfo.nByteNum = ftell(m_pReadAAC);
	frameinfo.reserve2 = ftell(m_pReadAAC);
	fseek(m_pReadAAC,0L,SEEK_SET); 
	frameinfo.reserve1[0] = nFlag;

	do 
	{
		memset(strRead, 0, PRO_CHN_MAX_RECV_TALKFILE_SIZE);
		nReadLen = fread(strRead, 1, PRO_CHN_MAX_RECV_TALKFILE_SIZE, m_pReadAAC);
		if( nReadLen > 0 )
		{


			frameinfo.timestamp = JGetTickCount();

			nRet = avSendAudioData(m_nTalkServerChannel, strRead, nReadLen, (void*)&frameinfo, sizeof(frameinfo));
			if(nRet != 0 )
			{
				JTRACE("avSendAudioData err %d\r\n", nRet);
			}
			else
			{
				nTotalUpLen += nReadLen;
				JTRACE("avSendAudioData success %d\r\n", nReadLen);
			}

			if(nFlag && m_eventCB)
			{
				int nPro = 100 / (frameinfo.reserve2 / nTotalUpLen);
				if(nPro >= 100)
				{
					nPro = 90;
				}

				if(m_nPro != nPro)
					m_eventCB(m_nIndex, m_nChn, NETPRO_EVENT_UPLOAD_AUDIOFILE,  nPro, NULL, m_lUserParam);

				m_nPro = nPro;
			}

			JSleep(10/*1000/16*/);
		}

		

	} while (nReadLen > 0 && m_pReadAAC);

	if(nFlag )
	{
		if(nTotalUpLen == frameinfo.reserve2)
		{
			m_eventCB(m_nIndex, m_nChn, NETPRO_EVENT_UPLOAD_AUDIOFILE,  100, NULL, m_lUserParam);
		}
		else
		{
			m_eventCB(m_nIndex, m_nChn, NETPRO_EVENT_UPLOAD_AUDIOFILE,  NetProErr_SetAlarmAudio, NULL, m_lUserParam);
		}

	}
	
	fclose(m_pReadAAC);
	m_pReadAAC = NULL;

	return 0;
}


int		CTalkChannel::StopTalk(int nConnChannel, int nConnID)
{
	int						nRet		= -1;
	SMsgAVIoctrlAVStream	avStream	= {0};

	if(m_pReadAAC)
	{
		fclose(m_pReadAAC);
		m_pReadAAC = NULL;
	}
	avStream.reserved[0] = m_nChn;
	avStream.channel = m_nSendFileChannel;
	nRet = avSendIOCtrl(nConnChannel, IOTYPE_USER_IPCAM_SPEAKERSTOP, (char *)&avStream, sizeof(SMsgAVIoctrlAVStream));
	if(nRet != 0 )
	{
		IOTC_Session_Channel_OFF(nConnID, m_nSendFileChannel);
		JTRACE("TalkSendFileAction   stop talk error\r\n");
		return -1;
	}

	if(m_nSendFileChannel >= 0)
	{
		IOTC_Session_Channel_OFF(nConnID, m_nSendFileChannel);
	}

	if(m_nTalkServerChannel >= 0)
	{
		avServStop(m_nTalkServerChannel);
		avServExit(nConnID, m_nTalkServerChannel);
	}
	
	m_nIsTalkFlag = 0;

	return 0;
}
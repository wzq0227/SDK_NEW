#include "AVEncoder.h"


CAVEncoder::CAVEncoder()
{
// 	m_pAACEncoder		= NULL;
// 	m_pAACCxt			= NULL;
// 	m_pSrcFrame			= NULL;
	m_pPcmBuff			= NULL;
	m_pTempBuff			= NULL;
	m_pRecvBuf			= NULL;
	m_encCallBack		= NULL;
	m_lUserParam		= NULL;
	m_nTempLen			= 0;
	m_nHasRecvLen		= 0;
	m_nRecvSuccess		= 0;
	m_nInitFlag			= 0;
	m_nMaxOutputBytes	= 0;
	m_nInputSamples		= 0;
	m_nOldSample		= 0;
	m_nOldChannel		= 0;
	m_hAACHandle		= NULL;

	m_pRecvBuf = new unsigned char[MAX_RECV_PCMBUF_SIZE];
	m_hMutexEncode.CreateMutex();

}


CAVEncoder::~CAVEncoder()
{

	//EncodeUnInit();
	EncodeAACStop();
	SAFE_DELETE(m_pRecvBuf);
	m_hMutexEncode.CloseMutex();
	
}



int CAVEncoder::EncodeAACStart(DWORD nSample, int nChannel, ENCCallBack encCB, long lUserParam)
{
	int						nRet			= -1;
	int						nSize			= 0;
	faacEncConfigurationPtr pConfiguration  = NULL;

	m_hMutexEncode.Lock();

	if( m_nInitFlag ) return 0;

	if( encCB )
	{
		m_encCallBack = encCB;
		m_lUserParam  = lUserParam;
	}

	m_hAACHandle = faacEncOpen(nSample, nChannel, &m_nInputSamples, &m_nMaxOutputBytes);
	if( !m_hAACHandle || m_nInputSamples < 0 || m_nMaxOutputBytes < 0)
	{
		if(m_hAACHandle)
		{	
			faacEncClose(m_hAACHandle);
			m_hAACHandle = NULL;
		}
		m_hMutexEncode.Unlock();
		return -1;
	}

	pConfiguration = faacEncGetCurrentConfiguration(m_hAACHandle);
	if( !pConfiguration )
	{
		m_hMutexEncode.Unlock();
		return -1;
	}

	pConfiguration->inputFormat = FAAC_INPUT_16BIT;
	pConfiguration->outputFormat = 1;// 0 = Raw; 1 = ADTS
	pConfiguration->aacObjectType = LOW;
	pConfiguration->allowMidside = 0;
	pConfiguration->useLfe = 0;
	pConfiguration->useTns   = 1 ;                   //时域噪音控制,大概就是消爆音
	pConfiguration->shortctl=SHORTCTL_NORMAL;
	pConfiguration->quantqual=50;
	pConfiguration->version = MPEG2;
	pConfiguration->allowMidside = 0;
	pConfiguration->useLfe = 0;

	if(!m_pRecvBuf)
	{
		m_pRecvBuf = new unsigned char[MAX_RECV_PCMBUF_SIZE];
		if(!m_pRecvBuf)
		{
			return -1;
		}
	}

	if(!m_pPcmBuff)
	{
		m_pPcmBuff = new unsigned char[m_nInputSamples*(16/8)+1];
		m_pTempBuff = new unsigned char[1024*20];
	}


	nRet = faacEncSetConfiguration(m_hAACHandle, pConfiguration);


	m_nInitFlag = 1;
	m_nHasRecvLen = 0;
	m_nTempLen		= 0;
	m_hMutexEncode.Unlock();
	return 0;
}


int CAVEncoder::EncodeAACPutBuf(unsigned  char *pInData, int nInLen)
{
	unsigned char*	pOutData = NULL;
	unsigned char*	p		 = NULL;
	int				nRet = 0;
	int				nIndex = 0;

	if(nInLen > MAX_RECV_PCMBUF_SIZE ) return AVErrParam;

	if( !m_nInitFlag ) return AVErrEncodeAACInit;

	m_hMutexEncode.Lock();

	memcpy(m_pRecvBuf+m_nHasRecvLen, pInData, nInLen);

	m_nHasRecvLen += nInLen;

	p = m_pRecvBuf;

	if(m_nHasRecvLen < (m_nInputSamples*2))
	{
		m_hMutexEncode.Unlock();
		return 0;
	}

	pOutData = new unsigned char[m_nMaxOutputBytes];

	while( m_nHasRecvLen >= (m_nInputSamples*2) )
	{
		memset(m_pPcmBuff, 0, sizeof(m_pPcmBuff));
		memcpy(m_pPcmBuff, p, m_nInputSamples*2);

		nRet = faacEncEncode(m_hAACHandle, (int*)m_pPcmBuff, m_nInputSamples, pOutData, m_nMaxOutputBytes);
		if(nRet > 0)
		{
			if( m_encCallBack ) m_encCallBack(pOutData, nRet, m_lUserParam);
		}

		p		+= m_nInputSamples*2;
		m_nHasRecvLen	-= m_nInputSamples*2;

	}

	memset(m_pPcmBuff, 0, sizeof(m_pPcmBuff));
	memcpy(m_pPcmBuff, p, m_nHasRecvLen);
	memcpy(m_pRecvBuf, m_pPcmBuff, nInLen);


	SAFE_DELETE(pOutData);

	m_hMutexEncode.Unlock();

	return 0;

}



int CAVEncoder::EncodeAACStop()
{
	if(!m_nInitFlag) return 0;
	m_hMutexEncode.Lock();
	if(m_hAACHandle)
	{	
		faacEncClose(m_hAACHandle);
		m_hAACHandle = NULL;
	}
	SAFE_DELETE(m_pPcmBuff);
	SAFE_DELETE(m_pTempBuff);
	//SAFE_DELETE(m_pRecvBuf);
	m_nInitFlag	= 0;
	m_hMutexEncode.Unlock();

	return 0;
}


int CAVEncoder::EncodeInit(DWORD nSample, int nChannel)
{
	int						nRet			= -1;
	int						nSize			= 0;
	faacEncConfigurationPtr pConfiguration  = NULL;

	m_hMutexEncode.Lock();
	m_nOldSample = nSample;
	m_nOldChannel = nChannel;
	m_hAACHandle = faacEncOpen(nSample, nChannel, &m_nInputSamples, &m_nMaxOutputBytes);
	if( !m_hAACHandle || m_nInputSamples < 0 || m_nMaxOutputBytes < 0)
	{
		if(m_hAACHandle)
		{	
			faacEncClose(m_hAACHandle);
			m_hAACHandle = NULL;
		}
		m_hMutexEncode.Unlock();
		return -1;
	}

	pConfiguration = faacEncGetCurrentConfiguration(m_hAACHandle);
	if( !pConfiguration )
	{
		m_hMutexEncode.Unlock();
		return -1;
	}

	pConfiguration->inputFormat = FAAC_INPUT_16BIT;
	pConfiguration->outputFormat = 1;// 0 = Raw; 1 = ADTS
	pConfiguration->aacObjectType = LOW;
	pConfiguration->allowMidside = 0;
	pConfiguration->useLfe = 0;
	//pConfiguration->bitRate = 48000;
	pConfiguration->useTns   = 1 ;                   //时域噪音控制,大概就是消爆音
	//pConfiguration->bandWidth  = 32000 ;              //频宽
	pConfiguration->shortctl=SHORTCTL_NORMAL;
	pConfiguration->quantqual=50;
	pConfiguration->version = MPEG2;
	pConfiguration->allowMidside = 0;
	pConfiguration->useLfe = 0;

	if(!m_pRecvBuf)
	{
		m_pRecvBuf = new unsigned char[MAX_RECV_PCMBUF_SIZE];
		if(!m_pRecvBuf)
		{
			return -1;
		}
	}

	if(!m_pPcmBuff)
	{
		m_pPcmBuff = new unsigned char[m_nInputSamples*(16/8)];
		m_pTempBuff = new unsigned char[1024*20];
	}


	nRet = faacEncSetConfiguration(m_hAACHandle, pConfiguration);

// 	av_register_all(); 
// 
// 	avcodec_register_all();
// 
// 	m_pAACEncoder = avcodec_find_encoder(AV_CODEC_ID_AAC);
// 
// 	if( !m_pAACEncoder ) 
// 	{
// 		m_hMutexEncode.Unlock();
// 		return -1;
// 	}
// 
// 	m_pAACCxt	= avcodec_alloc_context3(m_pAACEncoder);
// 	
// 	if( !m_pAACCxt )	
// 	{
// 		m_hMutexEncode.Unlock();
// 		return -1;
// 	}
// 
// 
// 	m_pAACCxt->channels = 1;
// 	m_pAACCxt->codec_id = AV_CODEC_ID_AAC;
// 	m_pAACCxt->sample_fmt = AV_SAMPLE_FMT_FLTP/*AV_SAMPLE_FMT_S16*/;
// 	m_pAACCxt->sample_rate = 44100;
// 	m_pAACCxt->bit_rate = 16000;
// 	m_pAACCxt->channel_layout=AV_CH_LAYOUT_STEREO; 
// 	m_pAACCxt->profile = FF_PROFILE_AAC_LOW;
// 	m_pAACCxt->strict_std_compliance = FF_COMPLIANCE_EXPERIMENTAL;
// 
// 	
// 	nRet = avcodec_open2(m_pAACCxt, m_pAACEncoder, NULL);
// 	if( nRet < 0 )
// 	{
// 		m_hMutexEncode.Unlock();
// 		return -1;
// 	}
// 
// 	m_pSrcFrame = av_frame_alloc();  
// 	m_pSrcFrame->nb_samples= m_pAACCxt->frame_size;  
// 	m_pSrcFrame->format= m_pAACCxt->sample_fmt; 
// 
// 
// 	uint8_t* frame_buf; 
// 	nSize = av_samples_get_buffer_size(NULL, m_pAACCxt->channels,m_pAACCxt->frame_size,m_pAACCxt->sample_fmt, 1);  
// 	frame_buf = (uint8_t *)malloc(nSize);  
// 	avcodec_fill_audio_frame(m_pSrcFrame, m_pAACCxt->channels, m_pAACCxt->sample_fmt,(const uint8_t*)frame_buf, nSize, 1); 
// 	free(frame_buf);

	m_nInitFlag = 1;
	m_nHasRecvLen = 0;
	m_nTempLen		= 0;
	m_hMutexEncode.Unlock();

	return 0;
}


int CAVEncoder::EncodeUnInit()
{

	m_hMutexEncode.Lock();
	if(m_hAACHandle)
	{	
		faacEncClose(m_hAACHandle);
		m_hAACHandle = NULL;
	}
	
// 	if(m_pAACCxt)
// 	{
// 		avcodec_close(m_pAACCxt);
// 		avcodec_free_context(&m_pAACCxt);
// 		m_pAACCxt = NULL;
// 	}
// 
// 	if(m_pSrcFrame)
// 	{
// 		av_frame_free(&m_pSrcFrame);
// 		m_pSrcFrame = NULL;
// 	}

	//SAFE_DELETE(m_pRecvBuf);
	SAFE_DELETE(m_pPcmBuff);
	SAFE_DELETE(m_pTempBuff);
	m_nInitFlag	= 0;
	m_hMutexEncode.Unlock();
	return 0;
}


int	CAVEncoder::EncodePCM2G711A(DWORD nSample, int nChannel, unsigned char *pInData, int nInLen, unsigned char **pOutData, int *nOutLen)
{
	int nRetLen = 0;
	*pOutData = new unsigned char[1024*10];
	nRetLen = m_g711Dec.G711_EnCode(*pOutData, (const char*)pInData, nInLen);
	if(nRetLen < 0) 
	{
		return 0;
	}

	*nOutLen = nRetLen;

	return nRetLen;
}

int	CAVEncoder::EncodePCM2AAC(DWORD nSample, int nChannel, unsigned char *pInData, int nInLen, unsigned char **pOutData, int *nOutLen)
{


	//unsigned char*	pOutData = NULL;
	unsigned char*	p		 = NULL;
	int				nRet = 0;
	int				nIndex = 0;

	if(nInLen > MAX_RECV_PCMBUF_SIZE ) return AVErrParam;

	if( *pOutData != NULL ) return -2;

	if( !m_nInitFlag ) EncodeInit(nSample, nChannel);

	if( m_nOldSample!= nSample || m_nOldChannel != nChannel )
	{
		EncodeUnInit();
		EncodeInit(nSample, nChannel);
	}

	if( !m_nInitFlag ) return AVErrEncodeAACInit;

	m_hMutexEncode.Lock();

	memcpy(m_pRecvBuf+m_nHasRecvLen, pInData, nInLen);

	m_nHasRecvLen += nInLen;

	p = m_pRecvBuf;

	if(m_nHasRecvLen < (m_nInputSamples*2))
	{
		m_hMutexEncode.Unlock();
		return 0;
	}

	*pOutData = new unsigned char[m_nMaxOutputBytes];

	int nCount = 0;
	while( m_nHasRecvLen >= (m_nInputSamples*2) )
	{
		memset(m_pPcmBuff, 0, sizeof(m_pPcmBuff));
		memcpy(m_pPcmBuff, p, m_nInputSamples*2);

		nRet = faacEncEncode(m_hAACHandle, (int*)m_pPcmBuff, m_nInputSamples, *pOutData, m_nMaxOutputBytes);
// 		if(nRet > 0)
// 		{
// 			if( m_encCallBack ) m_encCallBack(pOutData, nRet, m_lUserParam);
// 		}
		*nOutLen = nRet;

		printf("nCount = %d\r\n", nCount);
		++nCount;
		p		+= m_nInputSamples*2;
		m_nHasRecvLen	-= m_nInputSamples*2;

	}

	memset(m_pPcmBuff, 0, sizeof(m_pPcmBuff));
	memcpy(m_pPcmBuff, p, m_nHasRecvLen);
	memcpy(m_pRecvBuf, m_pPcmBuff, nInLen);


	//SAFE_DELETE(pOutData);

	m_hMutexEncode.Unlock();
#if 0
	int nRet = 0;

	int got_frame = 0;

	if(nInLen > MAX_RECV_PCMBUF_SIZE ) return -2;

	if( *pOutData != NULL ) return -2;

	if( !m_nInitFlag ) EncodeInit(nSample, nChannel);

	if( m_nOldSample!= nSample || m_nOldChannel != nChannel )
	{
		EncodeUnInit();
		EncodeInit(nSample, nChannel);
	}

	if( !m_nInitFlag )	return -5;

	m_hMutexEncode.Lock();

	*pOutData = new unsigned char[m_nMaxOutputBytes];

	memcpy(m_pRecvBuf, pInData, nInLen);
	if( (m_nHasRecvLen + nInLen) > (m_nInputSamples*2) )
	{
		nRet = faacEncEncode(m_hAACHandle, (int*)m_pPcmBuff, m_nInputSamples, *pOutData, m_nMaxOutputBytes);
		m_pRecvBuf += m_nInputSamples*2;
	}

	// 接收m_nInputSamples*2 的数据长度才送编码 begin
	if(!m_nRecvSuccess)
	{
		if( m_nHasRecvLen < (m_nInputSamples*2) )
		{
			if(m_nTempLen > 0)
			{
				memcpy(m_pPcmBuff + m_nHasRecvLen, m_pTempBuff, m_nTempLen);
				memset(m_pTempBuff, 0, sizeof(m_pTempBuff));
				m_nHasRecvLen += m_nTempLen ;
				m_nTempLen = 0;
				if(m_nHasRecvLen == m_nInputSamples*2)
				{
					m_nRecvSuccess = 1;
				}
			}

			if((m_nHasRecvLen + nInLen) > (m_nInputSamples*2)) 
			{
				memcpy(m_pPcmBuff + m_nHasRecvLen, pInData, m_nInputSamples*2 - m_nHasRecvLen);
				memcpy(m_pTempBuff, pInData+ (m_nInputSamples*2 - m_nHasRecvLen),  (m_nHasRecvLen + nInLen)-(m_nInputSamples*2) );
				m_nTempLen = (m_nHasRecvLen + nInLen)-(m_nInputSamples*2);
				m_nRecvSuccess = 1;
				m_nHasRecvLen = m_nInputSamples*2; 
			}
			else
			{
				memcpy(m_pPcmBuff + m_nHasRecvLen, pInData, nInLen);
				m_nHasRecvLen += nInLen ;
				if(m_nHasRecvLen == m_nInputSamples*2)
				{
					m_nRecvSuccess = 1;
				}
			}

		}
	}
	// 接收m_nInputSamples*2 的数据长度才送编码 end

	if(m_nRecvSuccess)
	{
		nRet = faacEncEncode(m_hAACHandle, (int*)m_pPcmBuff, m_nInputSamples, *pOutData, m_nMaxOutputBytes);
		memset(m_pPcmBuff, 0, sizeof(m_pPcmBuff));
		m_nHasRecvLen = 0;
		m_nRecvSuccess = 0;

		if(nRet < 1)
		{
			m_hMutexEncode.Unlock();

			return -6;
		}
	}


	*nOutLen = nRet;

	m_hMutexEncode.Unlock();
#endif
	return 0;
}
/*
int	CAVEncoder::EncodePCM2AAC(DWORD nSample, int nChannel, unsigned char *pInData, int nInLen, unsigned char **pOutData, int *nOutLen)
{
	
	int nRet = 0;

	int got_frame = 0;

	if( *pOutData != NULL ) return -2;

	if( !m_nInitFlag ) EncodeInit(nSample, nChannel);

	if( m_nOldSample!= nSample || m_nOldChannel != nChannel )
	{
		EncodeUnInit();
		EncodeInit(nSample, nChannel);
	}
	
	if( !m_nInitFlag )	return -5;

	m_hMutexEncode.Lock();

	*pOutData = new unsigned char[m_nMaxOutputBytes];

	// 接收m_nInputSamples*2 的数据长度才送编码 begin
	if(!m_nRecvSuccess)
	{
		if( m_nHasRecvLen < (m_nInputSamples*2) )
		{
			if(m_nTempLen > 0)
			{
				memcpy(m_pPcmBuff + m_nHasRecvLen, m_pTempBuff, m_nTempLen);
				memset(m_pTempBuff, 0, sizeof(m_pTempBuff));
				m_nHasRecvLen += m_nTempLen ;
				m_nTempLen = 0;
				if(m_nHasRecvLen == m_nInputSamples*2)
				{
					m_nRecvSuccess = 1;
				}
			}

			if((m_nHasRecvLen + nInLen) > (m_nInputSamples*2)) 
			{
				memcpy(m_pPcmBuff + m_nHasRecvLen, pInData, m_nInputSamples*2 - m_nHasRecvLen);
				memcpy(m_pTempBuff, pInData+ (m_nInputSamples*2 - m_nHasRecvLen),  (m_nHasRecvLen + nInLen)-(m_nInputSamples*2) );
				m_nTempLen = (m_nHasRecvLen + nInLen)-(m_nInputSamples*2);
				m_nRecvSuccess = 1;
				m_nHasRecvLen = m_nInputSamples*2; 
			}
			else
			{
				memcpy(m_pPcmBuff + m_nHasRecvLen, pInData, nInLen);
				m_nHasRecvLen += nInLen ;
				if(m_nHasRecvLen == m_nInputSamples*2)
				{
					m_nRecvSuccess = 1;
				}
			}
			
		}
	}
	// 接收m_nInputSamples*2 的数据长度才送编码 end
	
	if(m_nRecvSuccess)
	{
		nRet = faacEncEncode(m_hAACHandle, (int*)m_pPcmBuff, m_nInputSamples, *pOutData, m_nMaxOutputBytes);
		memset(m_pPcmBuff, 0, sizeof(m_pPcmBuff));
		m_nHasRecvLen = 0;
		m_nRecvSuccess = 0;

		if(nRet < 1)
		{
			m_hMutexEncode.Unlock();

			return -6;
		}
	}

	
	*nOutLen = nRet;

	m_hMutexEncode.Unlock();

	return 0;
}*/
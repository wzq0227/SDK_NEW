#include "AVDecoder.h"

CAVDecoder::CAVDecoder()
{
	DbgStrOut("CAVDecoder start\r\n");
#if (defined _WIN32) || (defined _WIN64)
	m_pAudioCtl			= NULL;
#endif
	m_nCurPort			= -1;
	m_pCodecContext		= NULL;
	m_pAVFrame			= NULL;
	//m_pCapFrame			= NULL;
	m_pAVCodec			= NULL;
	m_decCB				= NULL;
	m_lUserParam		= NULL;
	m_pSwsContext		= NULL;
	m_pDecBuff			= NULL;
	m_nDecBuffLen		= 0;
	m_nDecTypeCB		= 0;
	m_dwLastPlaySound	= 0;
	m_nIsEnableAudio	= 0;
	m_dwLastCallBackTime = 0;
	m_nPlayMode			= 2;
	m_pWritDecFile		= NULL;
	m_lShowWnd			= NULL;
	m_pPcmData			= NULL;
	m_nPcmLen			= 0;
	m_nEnable			= 1;
	m_nValue			= 5;
	m_nDecFlag			= 0;
	m_pPicturePath		= NULL;
	m_bInitAACDec		= FALSE;

	m_eAvPixFormat		= AV_PIX_FMT_YUVJ420P/*AV_PIX_FMT_YUV420P*/;

	m_pOutAudioBuf		= new unsigned char[MAX_AUDIO_OUT_LEN];

	

	m_hAac = NeAACDecOpen();


	
	m_showCB			= ShowCB;

	m_hMutexCodec.CreateMutex();

	Init();

	DbgStrOut("CAVDecoder end\r\n");
}

CAVDecoder::~CAVDecoder()
{
	
	UnInit();
	NeAACDecClose(m_hAac);
	SAFE_DELETE(m_pOutAudioBuf);
	SAFE_DELETE(m_pPcmData);
	SAFE_DELETE(m_pPicturePath);
	
	m_hMutexCodec.CloseMutex();
}
void	CAVDecoder::SetCurPort(int nPort)
{
	m_nCurPort = nPort;
	m_avRecord.m_nCurPort = nPort;
}
void	CAVDecoder::SetMainCtl(long lMainHandle)
{
#if (defined _WIN32) || (defined _WIN64)
	m_pAudioCtl = (CAudioCtl *)lMainHandle;
#endif
}


long	CAVDecoder::Init()
{
	
	if( NULL == m_pWritDecFile )
	{
		//m_pWritDecFile = fopen( "D:\\tttttttttttttt.yuv", "wb");
	}
	
	if( NULL != m_pAVCodec )
	{
		return 0;
	}

	m_hMutexCodec.Lock();
	
	avcodec_register_all();

	avformat_network_init();

	m_pCodecContext		= avcodec_alloc_context3(NULL/*m_pAVCodec*/);		
	if( NULL == m_pCodecContext )
	{
		m_hMutexCodec.Unlock();
		return -1;
	}
	
	m_pAVFrame			= av_frame_alloc(); //avcodec_alloc_frame
	if( NULL == m_pAVFrame )
	{
		avcodec_free_context(&m_pCodecContext);
		m_pCodecContext = NULL;

		m_hMutexCodec.Unlock();
		return -1;
	}

/*	m_pCapFrame			= av_frame_alloc(); //avcodec_alloc_frame
	if( NULL == m_pCapFrame )
	{
		avcodec_free_context(&m_pCodecContext);
		m_pCodecContext = NULL;

		av_frame_free(&m_pAVFrame);
		m_pAVFrame = NULL;
		m_hMutexCodec.Unlock();
		return -1;
	}
*/
	//m_sound.SetVolumeOut(120);
	m_hMutexCodec.Unlock();

	return 0;
}

long	CAVDecoder::UnInit()
{

	m_hMutexCodec.Lock();

#if (defined _WIN32) || (defined _WIN64)
	m_directDraw.ReleaseDirectDraw();
#endif
	m_nDecFlag = 0;
	if(m_pAVFrame)
	{
		av_frame_free(&m_pAVFrame);
		m_pAVFrame = NULL;
	}
	if(m_pCodecContext)
	{
		avcodec_close(m_pCodecContext);
		avcodec_free_context(&m_pCodecContext);
		m_pCodecContext = NULL;
	}
	

	if ( m_pSwsContext )
	{
		sws_freeContext(m_pSwsContext);
		m_pSwsContext		= NULL;						
	}

	if(m_pWritDecFile)
	{
		fclose(m_pWritDecFile);
		m_pWritDecFile = NULL;
	}

	SAFE_DELETE(m_pDecBuff);
	m_nDecBuffLen = 0;
	
	
// 	if(m_pCapFrame)
// 	{
// 		av_frame_free(&m_pCapFrame);
// 		m_pCapFrame = NULL;
// 	}
	m_hMutexCodec.Unlock();
	return 0;
}
int		CAVDecoder::CutFrameSuccess(int nValue)
{
	if(!m_decCB) return -1;

	stDecFrameParam		stDecParam	 = {0};
	memset(&stDecParam, 0, sizeof(stDecParam));
	stDecParam.nPort	= m_nCurPort;
	stDecParam.nDecType = nValue;
	m_decCB( &stDecParam, m_lUserParam );
	return 0;
}
long	CAVDecoder::VideoDec2Picture( unsigned char *pBuf, int nLen)
{
	int					nRet		 = -1;
	int					nResult		 = 0;		
	int					nDecBufLen	 = 0;
	stDecFrameParam		stDecParam	 = {0};
	AVPicture*			pAVDsc	     = NULL;
	AVDictionary*		optionsDict	 = NULL;
	AVPacket			packet		 = {0};
	int					nWaitTime	 = 0;

	if(!pBuf || nLen <= 0) return 0;

	memset(&stDecParam, 0, sizeof(stDecParam));

	//AVFrame*			pAVFrame			= av_frame_alloc();

	AVCodecContext* pCodecContext		= avcodec_alloc_context3(NULL/*m_pAVCodec*/);		

	m_pAVCodec = avcodec_find_decoder(AV_CODEC_ID_H264);
	if( NULL == m_pAVCodec )
	{
		if(pCodecContext)
		{
			avcodec_close(pCodecContext);
			avcodec_free_context(&pCodecContext);
		}
		//av_frame_free(&pAVFrame);
		return -1;
	}


	nRet = avcodec_open2(pCodecContext, m_pAVCodec, &optionsDict);
	if( nRet < 0 )
	{	
		if(pCodecContext)
		{
			avcodec_close(pCodecContext);
			avcodec_free_context(&pCodecContext);
		}
		//av_frame_free(&pAVFrame);
		return -2;
	}


	packet.data = pBuf;
	packet.size = nLen;

	avcodec_decode_video2(pCodecContext, m_pAVFrame, &nResult, &packet);

	if(nResult)//解码成功
	{	
			m_nDecFlag = 1;
			//memcpy(m_pCapFrame, pAVFrame, sizeof(AVFrame));
			m_avRecord.m_nPicWidth		= m_pCodecContext->width;
			m_avRecord.m_nPicHeight		= m_pCodecContext->height;
//            JTRACE("%x----------------%s\r\n",m_pPicturePath,m_pPicturePath);
			if(m_pPicturePath)
			{
				nRet = Save2JPEG(m_pPicturePath);
				JTRACE("Save2JPEG result = %d\r\n", nRet);
			}
			
			stDecParam.nPort	= m_nCurPort;
			stDecParam.nDecType = RecCaptureSuccess;
			if(m_decCB)
			{
				m_decCB( &stDecParam, m_lUserParam );
			}
			if(pCodecContext)
			{
				avcodec_close(pCodecContext);
				avcodec_free_context(&pCodecContext);
			}
			//av_frame_free(&pAVFrame);
			return 0;
	}
	else
	{
		m_nDecFlag = 0;
	}
	if(pCodecContext)
	{
		avcodec_close(pCodecContext);
		avcodec_free_context(&pCodecContext);
	}
	//av_frame_free(&pAVFrame);
	return -3;
}

long	CAVDecoder::VideoDec( unsigned char *pBuf, int nLen, int nFrameNo )
{
	int					nRet		 = -1;
	int					nResult		 = 0;		
	int					nDecBufLen	 = 0;
	stDecFrameParam		stDecParam	 = {0};
	AVPicture*			pAVDsc	     = NULL;
	AVDictionary*		optionsDict	 = NULL;
	AVPacket			packet		 = {0};
	int					nWaitTime	 = 0;
	
	if(!pBuf || nLen <= 0) return 0;

	m_pAVCodec = avcodec_find_decoder(AV_CODEC_ID_H264);
	if( NULL == m_pAVCodec )
	{
		return -1;
	}

	m_pCodecContext->thread_count = 2;
	m_pCodecContext->thread_type = FF_THREAD_FRAME;
	nRet = avcodec_open2(m_pCodecContext, m_pAVCodec, &optionsDict);
	if( nRet < 0 )
	{	
		return -2;
	}


	packet.data = pBuf;
	packet.size = nLen;
	
    int preDecTime =  JGetTickCount();
    
	nRet = avcodec_decode_video2(m_pCodecContext, m_pAVFrame, &nResult, &packet);
	
	if(nResult)//解码成功
	{
//        printf("_____________dec_timeInterval:%d\r\n",int( JGetTickCount()- preDecTime));
		m_nDecFlag  = 1;
		//jmemcpy(m_pCapFrame, m_pAVFrame, sizeof(AVFrame));
		m_avRecord.m_nPicWidth		= m_pCodecContext->width;
		m_avRecord.m_nPicHeight		= m_pCodecContext->height;
	
		nDecBufLen = avpicture_get_size(m_eAvPixFormat, m_pCodecContext->width, m_pCodecContext->height);
	
		if( NULL == m_nDecBuffLen )
		{
			m_pDecBuff		= new unsigned char[nDecBufLen];
			m_nDecBuffLen	= nDecBufLen;
		}

		if( nDecBufLen > m_nDecBuffLen )
		{
			SAFE_DELETE( m_pDecBuff );
			m_pDecBuff		= new unsigned char[nDecBufLen];
			m_nDecBuffLen	= nDecBufLen;
		}

		if( NULL == m_pDecBuff )  return -1;

		if( /*m_eAvPixFormat ==*/ m_pCodecContext->pix_fmt == AV_PIX_FMT_YUVJ420P ||m_pCodecContext->pix_fmt == AV_PIX_FMT_YUV420P )
		{
			avpicture_layout((AVPicture *)m_pAVFrame, m_pCodecContext->pix_fmt, m_pCodecContext->width, m_pCodecContext->height, m_pDecBuff, m_nDecBuffLen);
		
		}
		else
		{
			if ( m_pSwsContext==NULL )
			{
				m_pSwsContext = sws_getContext(m_pCodecContext->width, m_pCodecContext->height, m_pCodecContext->pix_fmt,
					m_pCodecContext->width, m_pCodecContext->height, m_eAvPixFormat, SWS_BILINEAR, NULL, NULL, NULL);
			}

			if( m_pSwsContext )
			{
				

				pAVDsc = (AVPicture*)av_frame_alloc();	

				avpicture_fill(pAVDsc, m_pDecBuff, m_eAvPixFormat, m_pCodecContext->width, m_pCodecContext->height);
		
				sws_scale(m_pSwsContext, m_pAVFrame->data, m_pAVFrame->linesize, 0, m_pCodecContext->height, pAVDsc->data, pAVDsc->linesize);
			
				av_free(pAVDsc);
				
			}
			
		}

		
		stDecParam.nPort	= m_nCurPort;
		stDecParam.nDecType = m_nDecTypeCB;
		stDecParam.lpBuf	= m_pDecBuff;
		stDecParam.lSize	= m_nDecBuffLen;
		stDecParam.lWidth	= m_pCodecContext->width;
		stDecParam.lHeight	= m_pCodecContext->height;
		stDecParam.nSampleRate	= 0;
		stDecParam.nAudioChannels	= 0;


		if(m_pWritDecFile)
		{
			//fwrite(m_pDecBuff, m_nDecBuffLen, 1, m_pWritDecFile);
		}

		
		if(m_nPlayMode == 1)
		{
			if( m_dwLastCallBackTime > 0 && m_avRecord.m_dwVideoFrameRate > 0)
			{
				//JTRACE("%d...\r\n", (int)(JGetTickCount() - m_dwLastCallBackTime));
				
				int nTimeSpan = (int)(JGetTickCount() - m_dwLastCallBackTime);
				nWaitTime = (1000/m_avRecord.m_dwVideoFrameRate) - nTimeSpan;
				nWaitTime = (nWaitTime > (1000/m_avRecord.m_dwVideoFrameRate+10)) ? 0 : nWaitTime;
//                printf("nTimeSpan_________________ %d,   nWaitTime = %d  fps:%d ***********\r\n", nTimeSpan, nWaitTime,m_avRecord.m_dwVideoFrameRate);
				if(nWaitTime > 0)
				{
					JSleep(nWaitTime);
				}
			}
		}	
		
		
		if(m_decCB)
		{
			//JTRACE("nframeNO = %d, callback data time = %d\r\n", nFrameNo, (int)(JGetTickCount() - m_dwLastCallBackTime));
			m_decCB( &stDecParam, m_lUserParam );
			
		}
		m_dwLastCallBackTime = JGetTickCount();
	
#if (defined _WIN32) || (defined _WIN64)
		if( m_lShowWnd != NULL )
		{
			//JTRACE("show.........................\r\n");
			m_showCB(1, m_pDecBuff, m_nDecBuffLen, this);
		}
#endif


		return 0;
	}
	else
	{
		m_nDecFlag = 0;
		JTRACE("dec error.........................%d, %d\r\n", nResult,nRet );
	}


	return -3;
}


int	CAVDecoder::Save2JPEG(const char* pFilePath)
{
	AVFormatContext*	pFormatCtx = NULL;
	AVStream*			pAVStream  = NULL;
	AVCodecContext*		pCodecCtx  = NULL;
	AVCodec*			pCodec	   = NULL;
	AVPacket			pkt;  
	int					nPicSize   = 0;
	int					got_picture = 0;
	int					nRet	   = -1;	
	int					nWidth	   = 0;
	int					nHeight    = 0;
	//AVFrame*			pAVFrame   = NULL;

	//pAVFrame = av_frame_alloc();

	if(!m_pAVFrame || m_nDecFlag == 0 || m_pAVFrame->width<=0)  return -1;

	//jmemcpy(pAVFrame, m_pCapFrame, sizeof(AVFrame));

	nWidth = m_pAVFrame->width;
	nHeight = m_pAVFrame->height;
	if(nWidth < 1 || nHeight < 1)
	{
		return -10;
	}

	
	av_register_all();
	pFormatCtx = avformat_alloc_context();  
	if( !pFormatCtx )
	{
		
		return -1111;
	}

	pFormatCtx->oformat = av_guess_format("mjpeg", pFilePath, NULL);  
	if(!pFormatCtx->oformat)
	{
		
		return -7;
	}

	if( avio_open(&pFormatCtx->pb, pFilePath, AVIO_FLAG_READ_WRITE) < 0) 
	{  
		if(pFormatCtx)
		{
			avformat_free_context(pFormatCtx);  
		}
	
		return -2;  
	}  

	pAVStream = avformat_new_stream(pFormatCtx, 0);  
	if( !pAVStream ) 
	{  
		if(pFormatCtx)
		{
			avio_close(pFormatCtx->pb);  
			avformat_free_context(pFormatCtx);  
		}
	
		return -3;  
	}  

	// 设置该stream的信息  
	pCodecCtx = pAVStream->codec;  

	pCodecCtx->codec_id = pFormatCtx->oformat->video_codec;  
	pCodecCtx->codec_type = AVMEDIA_TYPE_VIDEO;  
	pCodecCtx->pix_fmt = AV_PIX_FMT_YUVJ420P;  
	pCodecCtx->width = nWidth;  
	pCodecCtx->height = nHeight;  
	pCodecCtx->time_base.num = 1;  
	pCodecCtx->time_base.den = 25;  

	
	av_dump_format(pFormatCtx, 0, pFilePath, 1);  

	// 查找解码器  
	pCodec = avcodec_find_encoder(pCodecCtx->codec_id);  
	if( !pCodec ) 
	{  
		if( pAVStream )
		{  
			avcodec_close(pAVStream->codec);  
		}  
		if(pFormatCtx)
		{
			avio_close(pFormatCtx->pb);  
			avformat_free_context(pFormatCtx);  
		}
		
		return -4;  
	}  
	// 设置pCodecCtx的解码器为pCodec  
	if( avcodec_open2(pCodecCtx, pCodec, NULL) < 0 ) 
	{  
		if( pAVStream )
		{  
			avcodec_close(pAVStream->codec);  
		}  
		if(pFormatCtx)
		{
			avio_close(pFormatCtx->pb);  
			avformat_free_context(pFormatCtx);  
		}
	
		return -5;  
	}  

	avformat_write_header(pFormatCtx, NULL);  

	nPicSize = pCodecCtx->width * pCodecCtx->height;  

	av_new_packet(&pkt, nPicSize * 3);  

	nRet = avcodec_encode_video2(pCodecCtx, &pkt, m_pAVFrame/*m_pCapFrame*/, &got_picture);  
	if( nRet < 0 ) 
	{  
		if( pAVStream )
		{  
			avcodec_close(pAVStream->codec);  
		}  
		if(pFormatCtx)
		{
			avio_close(pFormatCtx->pb);  
			avformat_free_context(pFormatCtx);  
		}
		av_free_packet(&pkt);  
	
		return -6;  
	}  
	if( got_picture == 1 ) 
	{  
		nRet = av_write_frame(pFormatCtx, &pkt);  
	}  

	av_free_packet(&pkt);  

	av_write_trailer(pFormatCtx);  


	if( pAVStream )
	{  
		avcodec_close(pAVStream->codec);  
	}  
	if(pFormatCtx)
	{
		avio_close(pFormatCtx->pb);  
		avformat_free_context(pFormatCtx);  
	}


	return 0;
}



////////////////////////////////////////////////////////////
// Pix format convert
int CAVDecoder::GetRGB32Data(unsigned char** pOutBuf)
{
	AVPicture*	pAVDsc			 = NULL;
	int			nDecBufLen		 = 0;

	if(*pOutBuf != NULL) return -1;

	nDecBufLen = avpicture_get_size(AV_PIX_FMT_RGB24, m_pCodecContext->width, m_pCodecContext->height);

	*pOutBuf = new unsigned char[nDecBufLen];

	if ( m_pSwsContext==NULL )
	{
		m_pSwsContext = sws_getContext(m_pCodecContext->width, m_pCodecContext->height, m_pCodecContext->pix_fmt,
			m_pCodecContext->width, m_pCodecContext->height, AV_PIX_FMT_RGB24, SWS_BILINEAR, NULL, NULL, NULL);
	}

	if( m_pSwsContext )
	{


		pAVDsc = (AVPicture*)av_frame_alloc();	

		avpicture_fill(pAVDsc, *pOutBuf, AV_PIX_FMT_RGB24, m_pCodecContext->width, m_pCodecContext->height);

		sws_scale(m_pSwsContext, m_pAVFrame->data, m_pAVFrame->linesize, 0, m_pCodecContext->height, pAVDsc->data, pAVDsc->linesize);

		av_free(pAVDsc);

	}
	return 0;
}

void CAVDecoder::RaiseVolume(char* buf, int size, int uRepeat, double vol)//buf为需要调节音量的音频数据块首地址指针，size为长度，uRepeat为重复次数，通常设为1，vol为增益倍数,可以小于1  
{  
	if (!size)  
	{  
		return;  
	}  
	for (int i = 0; i < size;)  
	{  
		signed long minData = -0x8000; //如果是8bit编码这里变成-0x80  
		signed long maxData = 0x7FFF;//如果是8bit编码这里变成0xFF  

		signed short wData = buf[i + 1];  
		wData = MAKEWORD(buf[i], buf[i + 1]);  
		signed long dwData = wData;  

		for (int j = 0; j < uRepeat; j++)  
		{  
			dwData = dwData * vol;  
			if (dwData < -0x8000)  
			{  
				dwData = -0x8000;  
			}  
			else if (dwData > 0x7FFF)  
			{  
				dwData = 0x7FFF;  
			}  
		}  
		wData = LOWORD(dwData);  
		buf[i] = LOBYTE(wData);  
		buf[i + 1] = HIBYTE(wData);  
		i += 2;  
	}  
}  

long	CAVDecoder::AudioDec2( unsigned char *pBuf, int nLen )
{
	int				nRet			= -1;
	int				nResult			= 0;
	AVDictionary*	optionsDict		= NULL;
	AVCodecContext*	avCtx			= NULL;
	AVPacket		packet			= {0};
	stDecFrameParam	stDecParam		= {0};

	m_pAVCodec = avcodec_find_decoder(AV_CODEC_ID_AAC);
	if( NULL == m_pAVCodec )
	{
		return -1;
	}
	avCtx = avcodec_alloc_context3(m_pAVCodec);
	if( !avCtx )
	{
		return -1;
	}

	nRet = avcodec_open2(avCtx, m_pAVCodec, &optionsDict);
	if( nRet < 0 )
	{	
		return -1;
	}

	packet.data = pBuf;
	packet.size = nLen;
	nRet = avcodec_decode_audio4(avCtx, m_pAVFrame, &nResult, &packet);
	if(nResult)//解码成功
	{	
		SwrContext *swrContext = swr_alloc();
		swr_alloc_set_opts(swrContext, avCtx->channel_layout, AV_SAMPLE_FMT_FLT/*AV_SAMPLE_FMT_S16*/,
			avCtx->sample_rate, avCtx->channel_layout, avCtx->sample_fmt,
			avCtx->sample_rate, 0, NULL);  
		swr_init(swrContext); 

		int out_nb_samples=avCtx->frame_size;  
		int out_channels=av_get_channel_layout_nb_channels(AV_CH_LAYOUT_STEREO);  
		int out_buffer_size=av_samples_get_buffer_size(NULL,out_channels ,out_nb_samples,AV_SAMPLE_FMT_FLT, 1);  

		memset(m_pOutAudioBuf, '\0', MAX_AUDIO_OUT_LEN);
		
		nRet =  swr_convert(swrContext,&m_pOutAudioBuf, 192000,(const uint8_t **)m_pAVFrame->data , m_pAVFrame->nb_samples); 
		
		
	
		swr_free(&swrContext);
	
	
		CHAR *data = (CHAR*)calloc(1,out_buffer_size);
		
		for (int i = 0; i < (out_buffer_size/2); i++)
		{
			data[i*2] = (CHAR)(m_pOutAudioBuf[i] & 0xFF);
			data[i*2+1] = (CHAR)((m_pOutAudioBuf[i] >> 8) & 0xFF);
		}
		
		
		memset(m_pOutAudioBuf, '\0', MAX_AUDIO_OUT_LEN);
		memcpy(m_pOutAudioBuf,data,out_buffer_size);
		if (data)
		{
			free(data);
			data = NULL;
		}

		stDecParam.nPort	= m_nCurPort;
		stDecParam.nDecType = 4;
		stDecParam.lpBuf	= m_pOutAudioBuf;//(unsigned char *)m_pAVFrame->data;
		stDecParam.lSize	= m_pAVFrame->linesize[0];
		stDecParam.lWidth	= 0;
		stDecParam.lHeight	= 0;

		if(m_decCB)
		{
			m_decCB( &stDecParam, m_lUserParam );
		}
#if (defined _WIN32) || (defined _WIN64)

		m_showCB(2, (unsigned char *)m_pOutAudioBuf,out_buffer_size, this);
#endif


		avcodec_free_context(&avCtx);
		return 0;
	}

	avcodec_free_context(&avCtx);

	return -1;
}
#if 0
int CAVDecoder::volume_adjust(short  * in_buf, short  * out_buf, float in_vol)
{
	int i, tmp;

	// in_vol[0, 100]
	float vol = in_vol - 98;

	if(-98<vol && vol<0)
		vol = 1/(vol*(-1));
	else if(0<=vol && vol<=1)
		vol = 1;
	/*
	else if(1<=vol && vol<=2)
	vol = vol;
	*/
	else if(vol<=-98)
		vol = 0;
	else if(vol>=2)
		vol = 40;  //这个值可以根据你的实际情况去调整

	tmp = (*in_buf)*vol; // 上面所有关于vol的判断，其实都是为了此处*in_buf乘以一个倍数，你可以根据自己的需要去修改

	// 下面的code主要是为了溢出判断
	if(tmp > 32767)
		tmp = 32767;
	else if(tmp < -32768)
		tmp = -32768;
	*out_buf = tmp;

	return 0;
}
#endif
long	CAVDecoder::G711ADec( unsigned char *pBuf, int nLen ,char **pPcmBuf, int *nPcmLen)
{
	stDecFrameParam	stDecParam	= {0};

	*pPcmBuf = new char[nLen*3];
	
	*nPcmLen = m_g711Dec.G711_Decode(*pPcmBuf, pBuf, nLen);

	if(*nPcmLen <= 0) 
	{
		JTRACE("G711_Decode error..................................................\r\n");
		return -1;
	}

	return 0;
}
long	CAVDecoder::G711ADec( unsigned char *pBuf, int nLen ,int nSampleRate)
{
	int		nPcmLen				= 0;
	stDecFrameParam	stDecParam	= {0};

	if(m_pPcmData == NULL)
	{
		m_pPcmData = new char[1024*10];
		m_nPcmLen = 1024*10;
	}
	if(m_nPcmLen < nLen*3)
	{
		m_pPcmData = new char[nLen*3];
		m_nPcmLen = nLen*3;
	}

	nPcmLen = m_g711Dec.G711_Decode(m_pPcmData, pBuf, nLen);

	if(nPcmLen <= 0) 
	{
		JTRACE("G711_Decode error..................................................\r\n");
		return -1;
	}

	stDecParam.nPort	= m_nCurPort;
	stDecParam.nDecType = 4;
	stDecParam.lpBuf	= (unsigned char *)m_pPcmData;
	stDecParam.lSize	= nPcmLen;
	stDecParam.lWidth	= 0;
	stDecParam.lHeight	= 0;
	stDecParam.nSampleRate	= 8000;
	stDecParam.nAudioChannels	= 1;
	if(m_decCB)
	{
		m_decCB( &stDecParam, m_lUserParam );
	}
#if (defined _WIN32) || (defined _WIN64)
	//m_showCB(2, m_pAVFrame->data[0], m_pAVFrame->linesize[0], this);
	if(m_showCB)
		m_showCB(2, (unsigned char *)m_pPcmData, nPcmLen, this);
#endif

	return 0;
}

long	CAVDecoder::AudioDec( unsigned char *pBuf, int nLen ,int nSampleRate)
{
	int				nRet			=-1;
	stDecFrameParam	stDecParam		= {0};

	if( !m_pOutAudioBuf ) return 0;
	memset(m_pOutAudioBuf, '\0', MAX_AUDIO_OUT_LEN);
	nRet = AACDecDecode(m_pOutAudioBuf, (char *)pBuf, nLen, nSampleRate);
	if(nRet <= 0)
	{
		return -1;
	}
	if(m_nEnable)
		RaiseVolume((char *)m_pOutAudioBuf, nRet, 1, m_nValue );

	stDecParam.nPort	= m_nCurPort;
	stDecParam.nDecType = 4;
	stDecParam.lpBuf	= m_pOutAudioBuf;
	stDecParam.lSize	= nRet;
	stDecParam.lWidth	= 0;
	stDecParam.lHeight	= 0;
	stDecParam.nSampleRate	= 16000;
	stDecParam.nAudioChannels	= 2;

	if(m_pWritDecFile)
	{
		//fwrite(m_pOutAudioBuf, nRet, 1, m_pWritDecFile);
	}
	if(m_decCB)
	{
		m_decCB( &stDecParam, m_lUserParam );
	}
#if (defined _WIN32) || (defined _WIN64)
		//m_showCB(2, m_pAVFrame->data[0], m_pAVFrame->linesize[0], this);
	if(m_showCB)
		m_showCB(2, m_pOutAudioBuf, nRet, this);
#endif
		
	return -1;
}

long CAVDecoder::AACDecDecode( void* pOutBuf,CHAR* pInputBuf,unsigned long inLen ,int nSampleRate)
{
	long			uOutBufLen		= 0;
	CHAR*			p				= pInputBuf;
	CHAR*			q				= (CHAR*)pOutBuf;
	unsigned long	uInBufLen		= inLen;
	void*			pOutBufTmp		= NULL;
	short*			pOutBufTmpT		= NULL;
	int				i				= 0;
	unsigned long	ulSampleRate	= 0;
	unsigned char	uchChannels		= 0;

	if (m_bInitAACDec == false)
	{
		
		m_pAacConf = NeAACDecGetCurrentConfiguration(m_hAac);
		m_pAacConf->defObjectType = LC;
		m_pAacConf->defSampleRate = nSampleRate/2/*8000*/;
		m_pAacConf->outputFormat = FAAD_FMT_16BIT;
		m_pAacConf->dontUpSampleImplicitSBR = 1;
		NeAACDecSetConfiguration(m_hAac,m_pAacConf);
		
		NeAACDecInit(m_hAac,(unsigned char*)pInputBuf,inLen,&ulSampleRate,&uchChannels);
		m_bInitAACDec = true;
		//return 0;
	}

	do 
	{
		pOutBufTmp = ::NeAACDecDecode(m_hAac, &m_aacFrameInfo, (unsigned char*)p, uInBufLen);
		if (m_aacFrameInfo.error == 0 && m_aacFrameInfo.samples > 0)
		{
			//TRACE("---- Audio samplerate:%u channels:%d----\n",m_aacFrameInfo.samplerate,m_aacFrameInfo.channels);
			CHAR *data = (CHAR*)calloc(1,m_aacFrameInfo.samples*16*sizeof(char)/8);
			pOutBufTmpT = (short*)pOutBufTmp; 
			for (i = 0; i < m_aacFrameInfo.samples; i++)
			{
				data[i*2] = (CHAR)(pOutBufTmpT[i] & 0xFF);
				data[i*2+1] = (CHAR)((pOutBufTmpT[i] >> 8) & 0xFF);
			}

			memcpy(q,data,m_aacFrameInfo.samples*2);
			if (data)
			{
				free(data);
				data = NULL;
			}

			q += m_aacFrameInfo.samples*2;
			p += m_aacFrameInfo.bytesconsumed;
			uInBufLen -= m_aacFrameInfo.bytesconsumed;
			uOutBufLen += m_aacFrameInfo.samples*2;
			
		}
		else if (m_aacFrameInfo.error != 0)
		{
			
			uOutBufLen = -1; 
			break;
		}
	} while (uInBufLen > 0);

	return uOutBufLen;
}



long CAVDecoder::ShowCB(int nType, unsigned char *pBuf, int nLen, void *pUserParam)
{
#if (defined _WIN32) || (defined _WIN64)
	CAVDecoder * pThis = (CAVDecoder *)pUserParam;
	if( 1 == nType )
	{
		pThis->m_directDraw.InitDirectDraw((HWND)pThis->m_lShowWnd, pThis->m_pCodecContext->width, pThis->m_pCodecContext->height);

		pThis->m_directDraw.DrawDirectDraw((HWND)pThis->m_lShowWnd, pThis->m_pDecBuff);
	}
	else if( 2 == nType )
	{
		pThis->m_sound.SetBufDataOut(pBuf, nLen);
	}
#endif
	return 0;
}

#if (defined _WIN32) || (defined _WIN64)

int CAVDecoder::EnableAudio(int nEnable, int nSample)
{

	if( !m_pAudioCtl ) return -2;

	if( nEnable )
	{
		m_pAudioCtl->m_wfxWav.nChannels = 1;
		m_pAudioCtl->m_wfxWav.nSamplesPerSec	= nSample;
		if(nSample == 44100)
		{
			m_pAudioCtl->m_wfxWav.nChannels = 2;
		}
		m_pAudioCtl->m_wfxWav.nBlockAlign	= m_pAudioCtl->m_wfxWav.nChannels * (m_pAudioCtl->m_wfxWav.wBitsPerSample / 8);
		m_pAudioCtl->m_wfxWav.nAvgBytesPerSec= m_pAudioCtl->m_wfxWav.nBlockAlign * m_pAudioCtl->m_wfxWav.nSamplesPerSec;

		m_sound.InitDSBuffOut(&m_pAudioCtl->m_guidDSoundOut,GetDesktopWindow(),&m_pAudioCtl->m_wfxWav,AVP_SOUND_RATE);
		JSleep(100);
		m_sound.Play();
	}
	else
	{
		m_sound.StopPlay();

		m_sound.DestoryDSBuffOut();
	}

	m_nIsEnableAudio = nEnable;
	return 0;
}



#endif






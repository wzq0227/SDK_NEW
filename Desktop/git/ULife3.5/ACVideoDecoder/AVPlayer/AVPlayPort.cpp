#include "stdio.h"
#include "AVPlayPort.h"
#include <stdlib.h>

#define		REC_TYPE	1
#define		POOL_ELE_SIZE 200*1024

CAVPlayPort::CAVPlayPort()
{

}

CAVPlayPort::~CAVPlayPort()
{

	if(m_pTestFileH264)
	{
		fclose(m_pTestFileH264);
		m_pTestFileH264 = NULL;
	}
	StopRec();
	SAFE_DELETE(m_pReadH264Data);
	SAFE_DELETE(m_pCaptureH264);
	/*CloseRecFile();
	Stop();
	m_mutexRec.CloseMutex();
	m_mutexStop.CloseMutex();*/

	for(int i = 0 ; i < MAX_IFRAME_POS_COUNT; i++)
	{
		SAFE_DELETE(m_pH264FileNameArray[i]);
	}
	m_mutexRec.CloseMutex();
	m_mutexStop.CloseMutex();
}


CAVPlayPort::CAVPlayPort( int nPort )
{

	m_ePlayType			= ePlayStream;	
	m_nCurPort			= nPort;
	m_nPlayStatus		= eNMLPlayStatusStop;
	m_nBuffCount		= 60;
	m_nRecBuffCount		= 60;
	m_nRecBuffSize		= POOL_ELE_SIZE;
	m_nBuffSize			= POOL_ELE_SIZE;
	m_pReadFileCtx		= NULL;
	m_h264BStream		= NULL;
	m_aacBStream		= NULL;
	m_pReadH264Data		= NULL;
	m_nReadH264MaxDataLen = 0;
	m_nAACChannel		= 0;
	m_nAACSample		= 0;
	m_dPlaySpeed		= 1;
	m_nPlaySpeed		= 0;
	m_nOpenRecFileFlag	= 0;
	m_nRecFrameRate		= 0;
	m_nRecDuration		= 0;
	m_nRecFlag			= 0;
	m_nLastPlayRecTime	= 0;
	m_nFileDecOneTime   = 0;
	m_nLastPlay264Time  = 0;
	m_nSeekCaptureFlag	= 0;
	m_nLoadingFlag		= 0;
	m_nIsStartWriteMp4Flag = 0;
	m_nPlayFileArrayIndex = 0;
	m_nAddFileIndex		= 0;
	m_dwRecvRecFrameNo = -1;
	m_nDecFileFrameNo	= -1;

	m_nRecVideoStreamIndex	= 0;
	m_nRecAudioStreamIndex	= 0;
	m_nPlayRecFrameCount	= 0;
	m_nRecExtradataLen		= 0;
	m_nNeedPlayAudio		= 0;
	m_nPlayFileType			= 0;
	m_unPlayH264StartTime	= -1;
	m_nIsH264RecFlag		= 0;
	m_nH264StartRecTime		= 0;
	m_nH264TotalRecTime		= 0;
	m_unWriteFrameCount		= 0;

	m_pLocalFileName		= NULL;
	m_playRecCB				= NULL;
	m_lPlayRecParam			= NULL;
	m_pTestFile				= NULL;
	m_pTestFileH264			= NULL;
	m_pReadH264				= NULL;
	m_pCaptureH264			= NULL;
	m_nCaptureH264Len		= 0;
	m_nCutEndFlag			= 0;
	m_nPlayRecSuccessFlag	= 0;

	m_nCheckFileFlag		= 0;
	m_nRandDecFile			= 0;
	m_nIFrameCount			= 0;
	m_nPlayRecStreamTime	= 0;
	m_nIsDecFlag			= -1;
	for(int i = 0; i < MAX_IFRAME_POS_COUNT; i++)
	{
		m_nIFramePos[i] = 0;
		m_pH264FileNameArray[i] = NULL;
	}

	//m_writeRecCB	= WriteRec_CallBack;

	m_recbuffCtrl.SetUserID(nPort);
	//m_avbuffCtrl.SetUserID(nPort);
	m_decoderPort.SetCurPort(nPort);

	strcpy_s(m_tcDec.m_szName,J_DGB_NAME_LEN,"m_tcDec");			// 名称
	m_tcDec.SetOwner(this);							// 解码线程
	m_tcDec.SetParam(this);							// 解码线程

	strcpy_s(m_tcDecFile.m_szName,J_DGB_NAME_LEN,"m_tcDecFile");			
	m_tcDecFile.SetOwner(this);
	m_tcDecFile.SetParam(this);

	strcpy_s(m_tcRec.m_szName,J_DGB_NAME_LEN,"m_tcRec");
	m_tcRec.SetOwner(this);
	m_tcRec.SetParam(this);

	strcpy_s(m_tcReadH264.m_szName,J_DGB_NAME_LEN,"m_tcReadH264");
	m_tcReadH264.SetOwner(this);
	m_tcReadH264.SetParam(this);


	memset(m_strRecFilePath, '\0', MAX_REC_FILELEN);
	memset(m_recExtradata, '\0', MAX_REC_FILELEN);

	m_mutexStop.CreateMutex();
	m_mutexRec.CreateMutex();

	//m_pTestFileH264= fopen("D:\\Test1111.h264", "wb");

}

int CAVPlayPort::PutFrame(unsigned char *buf, int nLen)
{
	PAVBufferArray		pstEle		= NULL;
	gos_frame_head*		pDataInfo	= (gos_frame_head*)buf;
	int					nStreamType	= 0;
	int nRet = 0;
	
	if(m_nPlayStatus == eNMLPlayStatusStop) return 0;

	if(pDataInfo->nFrameType == gos_video_preview_i_frame)
	{
		JTRACE("get gos_video_preview_i_frame..............................\r\n");
		m_mutexStop.Lock();
		m_pCaptureH264 = new char[nLen];
		memcpy(m_pCaptureH264, buf, nLen);
		m_nCaptureH264Len = nLen;
		m_mutexStop.Unlock();
		return 0;
	}
	else if(pDataInfo->nFrameType == gos_video_cut_end_frame)
	{
		m_nCutEndFlag = 1;
		return 0;
	}
	else if(pDataInfo->nFrameType == gos_video_rec_end_frame)
	{
		m_nPlayRecSuccessFlag = 1 ;
		return 0;
	}
	else if((pDataInfo->nFrameType > gos_video_rec_b_frame && pDataInfo->nFrameType < gos_video_cut_end_frame) || pDataInfo->nFrameType == gos_cut_audio_frame )
	{
		m_decoderPort.m_avRecord.m_nRecType = 1;
		if(pDataInfo->nFrameType > gos_video_rec_b_frame && pDataInfo->nFrameType < gos_video_cut_end_frame)
		{
			m_decoderPort.m_avRecord.m_nPicWidth		= pDataInfo->sWidth;
			m_decoderPort.m_avRecord.m_nPicHeight		= pDataInfo->sHeight;
		}
		JTRACE("CUT -------------------------------------------pDataInfo->nFrameType = %d, pDataInfo->nFrameType = %d, pDataInfo->nDataSize = %d, width = %d, height = %d\r\n",
			pDataInfo->nFrameNo, pDataInfo->nFrameType, pDataInfo->nDataSize, pDataInfo->sWidth,pDataInfo->sHeight );
		WriteRec(buf, nLen);
		return 0;
	}
	else if((pDataInfo->nFrameType > gos_video_b_frame && pDataInfo->nFrameType < gos_video_rec_end_frame) || pDataInfo->nFrameType == gos_rec_audio_frame )
	{
		if(m_nIsDecFlag == -1)
		{
			m_nIsDecFlag = 0;
		}
		nStreamType = 1;
	}
	//JTRACE("pDataInfo->nFrameType = %d, pDataInfo->nFrameType = %d, pDataInfo->nDataSize = %d, width = %d, height = %d\r\n",
	//	pDataInfo->nFrameNo, pDataInfo->nFrameType, pDataInfo->nDataSize, pDataInfo->sWidth,pDataInfo->sHeight );
	nRet = m_avbuffer.AVBuffer_PutBuff((char *)buf, nLen);
	if(nRet == -20) // 缓存满
	{
		if(nStreamType)
		{
			//JTRACE("out buff............\r\n");
			m_nIsDecFlag = 1;
		}
	}

	

	if(m_nRecFlag)
	{
		if((pDataInfo->nFrameType > gos_unknown_frame && pDataInfo->nFrameType < gos_video_rec_i_frame) || pDataInfo->nFrameType == gos_audio_frame)
			WriteRec(buf, nLen);
	}
/*
	pstEle = m_avbuffCtrl.BeginAddBuff( buf, nLen, 0, 0 );
	if( pstEle )
	{
		m_avbuffCtrl.EndAddBuff();
	}*/

	return nRet;
}

int CAVPlayPort::SetVolume(int nEnable, int nValue)
{
	m_decoderPort.m_nEnable = nEnable;
	m_decoderPort.m_nValue = nValue;
	return 0;
}

int	CAVPlayPort::SetDecType(int nType)
{
	switch( nType )
	{
		case 0:
			m_decoderPort.m_eAvPixFormat = AV_PIX_FMT_YUVJ420P/*AV_PIX_FMT_YUV420P*/;
			break;
		case 1:
			m_decoderPort.m_eAvPixFormat = AV_PIX_FMT_BGRA;
			break;
		case 2:
			m_decoderPort.m_eAvPixFormat = AV_PIX_FMT_RGB24;
			break;
		case 3:
			m_decoderPort.m_eAvPixFormat = AV_PIX_FMT_RGB565;
			break;
		default:
			m_decoderPort.m_eAvPixFormat = AV_PIX_FMT_YUV420P;
			break;
	}

	m_decoderPort.m_nDecTypeCB = nType;
	return 0;
}

int	CAVPlayPort::SetBuffSize(int nType, int nBuffCount, int nBuffSize)
{
	if(nBuffCount < 1 || nBuffSize < 1)
	{
		return AVErrParam;
	}

	if(nBuffCount > 70 && nBuffCount != 101 && nBuffCount != 81 && nBuffCount != 121) // 留几个大缓存也不控速
		m_decoderPort.m_nPlayMode = 1;
	else
		m_decoderPort.m_nPlayMode = 2;
	
	if(nType == 0)
	{
		m_nBuffCount = nBuffCount;
		m_nBuffSize	 = nBuffSize;
	}
	else if(nType == 1)
	{
		m_nRecBuffCount = nBuffCount;
		m_nRecBuffSize	= nBuffSize;
	}

	return AVErrSuccess;
}

int CAVPlayPort::Play(long lPlayWnd, void* fCB, long lUserparam, long lMianHandle)
{

	if(lMianHandle != NULL)
		m_decoderPort.SetMainCtl(lMianHandle);
	
	if( eNMLPlayStatusStop == m_nPlayStatus )
	{
		if( NULL != fCB )
		{
			m_decoderPort.m_decCB		= (DECCallBack)fCB;
			m_decoderPort.m_lUserParam	= lUserparam;
			//m_decoderPort.m_decCB(NULL, lUserparam);
		}
#if (defined _WIN32) || (defined _WIN64)
		if(lPlayWnd)
			m_decoderPort.m_lShowWnd = lPlayWnd;
#endif	
		
		
		//m_avbuffCtrl.SetSize( m_nBuffCount, 3, m_nBuffSize);	
	
		if(m_ePlayType == ePlayStream)
		{
			m_avbuffer.AVBuffer_SetBuffSize(m_nBuffCount, m_nBuffSize);
			m_tcDec.StartThread(RunDecThread);
		}
		else if(m_ePlayType == ePlayFile && m_nOpenRecFileFlag)
		{
			m_avbuffer.AVBuffer_SetBuffSize(m_nBuffCount, m_nBuffSize);
			m_tcDecFile.StartThread(RunDecFileThread);
		}
		else if(m_ePlayType == ePlayH264File)
		{

		}
		m_nPlayStatus	= eNMLPlayStatusRun;		// 正在播放
	}
	

	return AVErrSuccess;
}

fJThRet CAVPlayPort::RunDecFileThread(void* pParam)
{
	JLOG_TRY
	int					iIsRun				= 0;				// 是否需要运行
	CJLThreadCtrl*		pThreadCtrl			= NULL;				// 对应用线程控制器
	CAVPlayPort*		lpPlayer			= NULL;				// 播放器

	// 初始化参数 begin
	pThreadCtrl	= (CJLThreadCtrl*)pParam;
	if ( pThreadCtrl==NULL )
	{
		return 0;
	}
	lpPlayer	= (CAVPlayPort *)pThreadCtrl->GetOwner();
	if ( lpPlayer==NULL )
	{
		pThreadCtrl->SetThreadState(THREAD_STATE_STOP);		
		return 0;
	}
	iIsRun	= 1;											
	while(iIsRun)
	{
		if ( pThreadCtrl->GetNextAction()==THREAD_STATE_STOP )
		{
			iIsRun = 0;
			break;
		}

		// 处理单个解码动作
		if ( lpPlayer->DecFileAction()==false )
		{
			iIsRun = 0;										
			break;
		}
	}

	pThreadCtrl->NotifyStop();
	iIsRun = 0;
	

	return 0;
	JLOG_CATCH("try-catch CAVPlayPort::RunDecFileThread \r\n");
	return 0;
	return 0;
}

int	CAVPlayPort::CheckMp4VideoData(unsigned char *pBuf, int nLen)
{
	int i		= 0;
	int nFlag	= 0;

	while(i < nLen)
	{
		if( nFlag && (pBuf[i+4] == 0x65) ) // I 帧开始
		{
			pBuf[i]	  = 0x00;
			pBuf[i+1] = 0x00; 
			pBuf[i+2] = 0x00;
			pBuf[i+3] = 0x01; 
			return 0;
		}
		if(pBuf[i] == 0x00 && pBuf[i+1] == 0x00 && pBuf[i+2] == 0x00 )
		{
			//0x67 SPS 已赋值
			//0x68 PPS
			//if(pBuf[i+4] == 0x41)	pBuf[i+4] = 0x61;
			if(pBuf[i+4] == 0x61 || pBuf[i+4] == 0x41)	return 0; // P 帧 

			if(pBuf[i+4] == H264_PPS_FLAG || pBuf[i+4] == 0x6 ) // PPS
			{
				pBuf[i+3] = 0x01; 

				if(pBuf[i+4] == H264_PPS_FLAG)
				{
					nFlag = 1;
				}
			}
			
			i += 5;

			continue;
		}

		++ i;
	}
	
	return -1;
}

int		CAVPlayPort::GetSampleIndex(int nSample)
{
	int nRet = -1;

	switch(nSample)
	{
	case 96000:
		nRet = 0;
		break;
	case 88200:
		nRet = 1;
		break;
	case 64000:
		nRet = 2;
		break;
	case 48000:
		nRet = 3;
		break;
	case 44100:
		nRet = 4;
	case 32000:
		nRet = 5;
		break;
	case 24000:
		nRet = 6;
		break;
	case 22050:
		nRet = 7;
		break;
	case 16000:
		nRet = 8;
		break;
	case 12000:
		nRet = 9;
		break;
	case 11025:
		nRet = 10;
		break;
	case 8000:
		nRet = 11;
		break;
	case 7350:
		nRet = 12;
		break;
	
	}

	return nRet;
}


int		CAVPlayPort::AddADTSHeader(int nSample, int nChannel, int nSrcLen, unsigned char *pOut)
{
	int nSampleIndex = -1;

	int nFrameLen = nSrcLen;

	int nProfile = 1; // AAC(Version 4) LC  

	nSampleIndex =	GetSampleIndex(nSample);

	if(nSampleIndex < 1 ||  nFrameLen < 1)	return -2;
	
	nFrameLen += AAC_ADTS_HEADER;

	*pOut++ = 0xff;                                    //syncword  (0xfff, high_8bits)  
	*pOut = 0xf0;                                      //syncword  (0xfff, low_4bits)  
	*pOut |= (0 << 3);                                 //ID (0, 1bit)  
	*pOut |= (0 << 1);                                 //layer (0, 2bits)  
	*pOut |= 1;                                        //protection_absent (1, 1bit)  
	pOut++;  
	*pOut = (unsigned char) ((nProfile & 0x3) << 6);  //profile (profile, 2bits)  
	*pOut |= ((nSampleIndex & 0xf) << 2);         //sampling_frequency_index (sam_idx, 4bits)  
	*pOut |= (0 << 1);                                 //private_bit (0, 1bit)  
	*pOut |= ((nChannel & 0x4) >> 2);                 //channel_configuration (channel, high_1bit)  
	pOut++;  
	*pOut = ((nChannel & 0x3) << 6);                  //channel_configuration (channel, low_2bits)  
	*pOut |= (0 << 5);                                 //original/copy (0, 1bit)  
	*pOut |= (0 << 4);                                 //home  (0, 1bit);  
	*pOut |= (0 << 3);                                 //copyright_identification_bit (0, 1bit)  
	*pOut |= (0 << 2);                                 //copyright_identification_start (0, 1bit)  
	*pOut |= ((nFrameLen & 0x1800) >> 11);             //frame_length (value, high_2bits)  
	pOut++;  
	*pOut++ = (unsigned char) ((nFrameLen & 0x7f8) >> 3);  //frame_length (value, middle_8bits)  
	*pOut = (unsigned char) ((nFrameLen & 0x7) << 5);      //frame_length (value, low_3bits)  
	*pOut |= 0x1f;                                         //adts_buffer_fullness (0x7ff, high_5bits)  
	pOut++;  
	*pOut = 0xfc;                                          //adts_buffer_fullness (0x7ff, low_6bits)  
	*pOut |= 0;                                            //number_of_raw_data_blocks_in_frame (0, 2bits);  
	pOut++;  
	

	return nFrameLen;

}

bool CAVPlayPort::DecFileAction()
{
	m_mutexStop.Lock();
	int nRet			= -1;
	AVPacket			readPkt ;
	unsigned char*		pAACBuf = NULL;
	int					nAACLen = 0;
	DWORD				nCurPlayTime = 0;
	DWORD				dwDecStart	 = 0;
	DWORD				dwCurDecTime = 0;
	int					nDecTime	 = 0;
	
	av_init_packet(&readPkt);

	
	nRet = av_read_frame(m_pReadFileCtx, &readPkt);
	
	if(nRet < 0 || readPkt.size <= 0)
	{
		m_mutexStop.Unlock();
		return FALSE;
	}

	//JTRACE("stream index = %d, pts = %d, dts = %d\r\n", readPkt.stream_index, readPkt.pts,readPkt.dts);

	if(readPkt.stream_index == m_nRecVideoStreamIndex) //video
	{

		if( (m_nFileDecOneTime-m_nFileDecAudioTime) > 0 && (m_nFileDecOneTime-m_nFileDecAudioTime) < 2000)
		{
			JSleep(m_nFileDecOneTime-m_nFileDecAudioTime);
		}
		m_nFileDecAudioTime = 0;
		m_nFileDecOneTime = 0;
		dwDecStart = JGetTickCount();
		//DWORD nDataLen = ntohl(*((DWORD*)(readPkt.data)));

		/*	packet中的数据起始处没有分隔符(0x00000001), 也不是0x65、0x67、0x68、0x41等字节，所以可以肯定这不是标准的nalu。
		*/

// 方法一
		// 手动修改帧头及增加SPS PPS begin
							/*readPkt.data[0] = 0x00;
							readPkt.data[1] = 0x00;
							readPkt.data[2] = 0x00;
							readPkt.data[3] = 0x01;
							nRet = CheckMp4VideoData(readPkt.data, readPkt.size);  //  比对原始数据与从MP4获取的数据 做此修改
							if(nRet < 0 ) //I 帧增加SPS PPS数据
							{
								unsigned char * pBuf = new unsigned char[readPkt.size+ m_nRecExtradataLen];

								memcpy(pBuf, m_recExtradata, m_nRecExtradataLen);
								memcpy(pBuf+m_nRecExtradataLen, readPkt.data, readPkt.size);
								m_decoderPort.VideoDec(pBuf, readPkt.size+ m_nRecExtradataLen);
								
								SAFE_DELETE(pBuf);
							}
							else
							{
								m_decoderPort.VideoDec(readPkt.data, readPkt.size);
							}*/
		// 手动修改帧头及增加SPS PPS end


		//JTRACE("readPkt.pts = %d, readPkt.dts = %d\r\n", readPkt.pts, readPkt.dts );

// 方法二 begin
		//分离某些封装格式（例如MP4/FLV/MKV等）中的H.264的时候，需要首先写入SPS和PPS，否则会导致分离出来的数据没有SPS、PPS而无法播放。H.264码流的SPS和PPS信息存储在AVCodecContext结构体的extradata中。需要使用ffmpeg中名称为“h264_mp4toannexb”的bitstream filter处理
		av_bitstream_filter_filter(m_h264BStream, m_pReadFileCtx->streams[m_nRecVideoStreamIndex]->codec, NULL, &readPkt.data, &readPkt.size, readPkt.data, readPkt.size, 0);  
		
		m_decoderPort.VideoDec(readPkt.data, readPkt.size);
		
// 方法二 end
		//JTRACE("1111111111111111pts = %d , dts = %d \r\n", readPkt.pts, readPkt.dts);

		m_nPlayRecFrameCount++;
		//nCurPlayTime = m_nPlayRecFrameCount/ m_nRecFrameRate;
		nCurPlayTime = readPkt.pts / m_pReadFileCtx->streams[m_nRecVideoStreamIndex]->time_base.den;

		if(nCurPlayTime != m_nLastPlayRecTime && m_playRecCB)
			m_playRecCB(m_nCurPort, AVRetPlayRecTime, (LONG)nCurPlayTime, m_lPlayRecParam);

		//m_nLastPlayRecTime = nCurPlayTime;

		dwCurDecTime = JGetTickCount();
		if((dwCurDecTime-dwDecStart) < 2000)
		{
			m_nFileDecOneTime = (int)((1000 / m_nRecFrameRate / m_dPlaySpeed) - (dwCurDecTime-dwDecStart));

			if(m_nFileDecOneTime < 0 ) m_nFileDecOneTime = 0;
		}
		
	}
	else if( readPkt.stream_index == m_nRecAudioStreamIndex ) //audio
	{
		if(m_nNeedPlayAudio)
		{
#if (defined _WIN32) || (defined _WIN64)
			m_decoderPort.EnableAudio(1);
#endif
			m_nNeedPlayAudio	= 0;
		}
		
		m_decoderPort.m_dwLastPlaySound = JGetTickCount();
		
		//JTRACE("222222222222222222222222222pts = %d , dts = %d \r\n", readPkt.pts, readPkt.dts);
		//av_bitstream_filter_filter(m_aacBStream, m_pReadFileCtx->streams[m_nRecAudioStreamIndex]->codec, NULL, &readPkt.data, &readPkt.size, readPkt.data, readPkt.size, readPkt.flags & AV_PKT_FLAG_KEY);  
		DWORD dwDecAudio = JGetTickCount();

		if(m_pTestFile)
		{
			fwrite(readPkt.data, readPkt.size, 1, m_pTestFile);
		}
		m_decoderPort.AudioDec(readPkt.data, readPkt.size, m_nAACSample);	
		m_nFileDecAudioTime += (int)(JGetTickCount() - dwDecAudio);
		//JTRACE("***************%d\r\n", m_nFileDecAudioTime);
/*
		pAACBuf = new unsigned char[AAC_ADTS_HEADER + readPkt.size];
	
		nAACLen = AddADTSHeader(m_nAACSample, m_nAACChannel, readPkt.size, pAACBuf); //添加ADTS 头

		if(nAACLen <= 0)  
		{
			SAFE_DELETE(pAACBuf);
			return TRUE;
		}

		memcpy(pAACBuf + AAC_ADTS_HEADER, readPkt.data, readPkt.size);

		if(m_pTestFile)
		{
			fwrite(pAACBuf, nAACLen, 1, m_pTestFile);
		}
		m_decoderPort.AudioDec(pAACBuf, nAACLen, m_nAACSample);	
*/
		//JTRACE("DecFileAction size = %d\r\n", nAACLen);

		SAFE_DELETE(pAACBuf);
	
	}
	
	av_free_packet(&readPkt);

#if (defined _WIN32) || (defined _WIN64)
	if(m_decoderPort.m_dwLastPlaySound != 0)
	{
		if(JGetTickCount() - m_decoderPort.m_dwLastPlaySound > 1000)
		{
			if(m_decoderPort.m_nIsEnableAudio)
			{
				m_decoderPort.EnableAudio(0);

				m_nNeedPlayAudio = 1;
			}
			m_decoderPort.m_dwLastPlaySound = JGetTickCount();
		}
	}
	else
	{
		m_decoderPort.m_dwLastPlaySound = JGetTickCount();
	}

#endif
		m_mutexStop.Unlock();
		return TRUE;
}

int CAVPlayPort::OpenRecFile(const char *pFileName, DWORD* dwDuration, DWORD* dwFrameRate, void* playRecCB, long lUserParam)
{
	int nRet = -1;
	int nSPSFlag = 0;
	int nPPSFlag = 0;

	AVCodecContext* video_dec_ctx = NULL;
	AVCodecContext* audio_dec_ctx = NULL;
	
	m_nPlayFileType = 0;

	if(playRecCB != NULL)
	{
		m_playRecCB		= (RECCallBack)playRecCB;
		m_lPlayRecParam = lUserParam;
	}

	av_register_all();

	CloseRecFile();

	m_ePlayType = ePlayFile;

	nRet = avformat_open_input(&m_pReadFileCtx, pFileName, NULL, NULL);

	if( !m_pReadFileCtx )
	{
		*dwFrameRate = nRet;
		return nRet;//AVErrPlayRecFile_Open;
	}
	nRet = avformat_find_stream_info(m_pReadFileCtx, NULL);
	if ( nRet < 0 )
	{
		return AVErrPlayRecFile_GET;
	}

	av_dump_format(m_pReadFileCtx,0,pFileName,0);

	if(m_pReadFileCtx->nb_streams > 2) m_pReadFileCtx->nb_streams = 2;

	for(int i = 0; i < m_pReadFileCtx->nb_streams; i++)
	{
		if(m_pReadFileCtx->streams[i]->codec->codec_id == AV_CODEC_ID_H264)
		{
			video_dec_ctx =  m_pReadFileCtx->streams[i]->codec; //debug+++++
			//m_pReadFileCtx->streams[i].time_base.den
			m_nRecVideoStreamIndex	 = i;
		}
		else if(m_pReadFileCtx->streams[i]->codec->codec_id == AV_CODEC_ID_AAC)
		{	
			audio_dec_ctx =  m_pReadFileCtx->streams[i]->codec;
			m_nAACChannel = audio_dec_ctx->channels;
			m_nAACSample  = audio_dec_ctx->sample_rate;
			m_nRecAudioStreamIndex	 = i;
			
		}
	}

	if(video_dec_ctx)
	{
		m_nRecFrameRate = video_dec_ctx->framerate.num /  video_dec_ctx->framerate.den;
		*dwFrameRate	= m_nRecFrameRate;
	}
	m_nRecExtradataLen = 0;
	m_recExtradata[m_nRecExtradataLen++] = 0x00;
	m_recExtradata[m_nRecExtradataLen++] = 0x00;
	m_recExtradata[m_nRecExtradataLen++] = 0x00;
	m_recExtradata[m_nRecExtradataLen++] = 0x01;
	
	for(int i = 0; i < video_dec_ctx->extradata_size; i++)
	{
		JTRACE("%x, ", video_dec_ctx->extradata[i]);
		if(video_dec_ctx->extradata[i] == H264_SPS_FLAG)
		{
			nSPSFlag = 1;
			
		}
		if(nSPSFlag && video_dec_ctx->extradata[i+4] != H264_PPS_FLAG)
		{
			m_recExtradata[m_nRecExtradataLen++] = video_dec_ctx->extradata[i];
		}
		if(video_dec_ctx->extradata[i+4] == H264_PPS_FLAG)
		{
			nSPSFlag = 0;
		}
		if(video_dec_ctx->extradata[i] == H264_PPS_FLAG)
		{
			
			m_recExtradata[m_nRecExtradataLen++] = 0x00;
			m_recExtradata[m_nRecExtradataLen++] = 0x00;
			m_recExtradata[m_nRecExtradataLen++] = 0x00;
			m_recExtradata[m_nRecExtradataLen++] = 0x01;
			nPPSFlag = 1;	
		}
		if(nPPSFlag)
		{
			m_recExtradata[m_nRecExtradataLen++] = video_dec_ctx->extradata[i];
		}

	}
	JTRACE("\r\n");
	for(int i = 0; i < m_nRecExtradataLen; i++)
	{
		JTRACE("%x, ", m_recExtradata[i]);
	
	}

	m_dPlaySpeed = 1;
	m_nPlaySpeed = 0;

	nRet = GetMp4Param(pFileName, dwDuration, NULL);
	if(nRet !=  0)
	{
		return AVErrPlayRecFile_GET_;
	}

	m_h264BStream =  av_bitstream_filter_init("h264_mp4toannexb");
	if(!m_h264BStream)
	{
		return -100;
	}

	m_aacBStream =  av_bitstream_filter_init("aac_adtstoasc");
	if(!m_aacBStream)
	{
		return -101;
	}

	
	m_nPlayRecFrameCount = 0;
	m_nLastPlayRecTime	 = 0;
	m_nOpenRecFileFlag	 = 1;
	m_nFileDecOneTime = 0;
	m_nFileDecAudioTime = 0;

	//m_pTestFile = fopen("D:\\PlayMp4_aac1.aac", "wb");
	
	
	return AVErrSuccess;
}


int		CAVPlayPort::GetMp4Param(const char *pFilePath, DWORD* dwDuration, DWORD* dwFrameRate)
{
	FILE*	pFile			= NULL;
	char	strRead[1024]	= {0};
	DWORD	nReadLen		= 0;
	DWORD	nHasReadLen		= 0;
	int		nHasReadmhvd	= 0;
	int		nHasReadstsz	= 0;
	int		nReadSuccess	= 0;

	DWORD	nFrameCount		= 0;
	int		nTimescale		= 0;
	DWORD	nDuration		= 0;

	pFile = fopen(pFilePath, "rb");

	if(pFile == NULL ) return -1;

	while(1)
	{
		if(nHasReadmhvd && nHasReadstsz) break;

		memset(strRead, '\0', sizeof(strRead));

		nReadLen = fread(strRead, 1, sizeof(strRead), pFile);

		if(nReadLen < 1) break;

		for(int i = 0; i < nReadLen; i++)
		{
			if(!nHasReadmhvd && strRead[i] == 0x6D && strRead[i+1] == 0x76 && strRead[i+2] == H264_PPS_FLAG && strRead[i+3] == 0x64)//mvhd BOX
			{
				nHasReadLen = nHasReadLen+i+16;
				fseek(pFile, nHasReadLen, SEEK_SET);
				memset(strRead, '\0', sizeof(strRead));
				nReadLen = fread(strRead, 1, 4, pFile);
				//JTRACE("================%x, %x, %x, %x\r\n", strRead[0], strRead[1], strRead[2], strRead[3]);
				if(nReadLen < 1) break;
				nHasReadLen += 4;
				nTimescale = ntohl(*((DWORD*)(strRead)));

				memset(strRead, '\0', sizeof(strRead));
				nReadLen = fread(strRead, 1, 4, pFile);
				//JTRACE("================%x, %x, %x, %x\r\n", strRead[0], strRead[1], strRead[2], strRead[3]);
				if(nReadLen < 1) break;
				nHasReadLen += 4;

				nDuration = ntohl(*((DWORD*)(strRead)));
				nHasReadmhvd = 1;
				nReadSuccess = 1;
				break;
			}
			if(nReadSuccess) break;

			if(!nHasReadstsz && strRead[i] == 0x73 && strRead[i+1] == 0x74 && strRead[i+2] == 0x73 && strRead[i+3] == 0x7A)//stsz BOX
			{
				fseek(pFile, nHasReadLen+i+12, SEEK_SET);

				memset(strRead, '\0', sizeof(strRead));
				nReadLen = fread(strRead, 1, 4, pFile);
				//JTRACE("================%x, %x, %x, %x\r\n", strRead[0], strRead[1], strRead[2], strRead[3]);
				if(nReadLen < 1) break;
				nFrameCount = ntohl(*((DWORD*)(strRead)));
				nHasReadstsz = 1;
			}
		}

		if(!nReadSuccess)
			nHasReadLen += nReadLen;
		else
			nReadSuccess = 0;

	}

	if(nFrameCount < 1 || nTimescale < 1 || nDuration < 1) 
	{
		fclose(pFile);
		pFile = NULL;

		return -1;
	}

	m_nRecDuration	= nDuration / nTimescale;
	//m_nRecFrameRate = nFrameCount / m_nRecDuration;

	*dwDuration = m_nRecDuration;
	//*dwFrameRate = m_nRecFrameRate;
	fclose(pFile);
	pFile = NULL;

	return 0;
}

int CAVPlayPort::CloseRecFile()
{


	if(m_pTestFile)
	{
		fclose(m_pTestFile);
		m_pTestFile = NULL;
	}

	
	
	m_tcDecFile.StopThread(true);
	if(m_pReadFileCtx)
	{
		avformat_close_input(&m_pReadFileCtx);
		av_free(m_pReadFileCtx);
		m_pReadFileCtx = NULL;
	}

	if(m_h264BStream)
	{
		av_bitstream_filter_close(m_h264BStream); 
		m_h264BStream = NULL;
	}

	if(m_aacBStream)
	{
		av_bitstream_filter_close(m_aacBStream); 
		m_aacBStream = NULL;
	}


	m_ePlayType = ePlayStream;
	
	return AVErrSuccess;
}

int CAVPlayPort::RecPause(int nPause)
{

	if(m_nPlayFileType)
	{
		if(nPause)
		{
			m_tcReadH264.PauseThread();//av_read_pause
		}
		else
		{
			m_tcReadH264.ContinueThread();//av_read_play
		}
		return AVErrSuccess;
	}

	if(!m_nOpenRecFileFlag) return AVErrPlayRecFile_Open;

	if(nPause)
	{
#if (defined _WIN32) || (defined _WIN64)
		m_decoderPort.m_sound.StopPlay();
#endif
		m_tcDecFile.PauseThread();//av_read_pause
	}
	else
	{
#if (defined _WIN32) || (defined _WIN64)		
		m_decoderPort.m_sound.Play();
#endif
		m_tcDecFile.ContinueThread();//av_read_play
	}
	return AVErrSuccess;
}

int CAVPlayPort::RecSetSpeed(long nSpeed)
{
	//if( !m_nOpenRecFileFlag ) return AVErrPlayRecFile_Open;

	if( nSpeed < -4 || nSpeed > 4 ) return AVErrParam;

	m_dPlaySpeed = pow(2.0, (double)nSpeed);
	m_nPlaySpeed = nSpeed;

	return AVErrSuccess;
}

long CAVPlayPort::RecGetSpeed()
{
	//if( !m_nOpenRecFileFlag ) return AVErrPlayRecFile_Open;
	return m_nPlaySpeed;
}

int CAVPlayPort::RecSeek(DWORD dwTime, const char* pFileName)
{
	int nIndex = 0;
	if(m_nPlayFileType && m_pReadH264)
	{
		if(dwTime > 0)
			nIndex = (int)dwTime / 3;

		if(1)
		{
			if(nIndex >= m_nIFrameCount) nIndex = m_nIFrameCount -1;
			m_tcDecFile.PauseThread();
			fseek(m_pReadH264, m_nIFramePos[nIndex], SEEK_SET);
			if(pFileName)
			{
				m_nSeekCaptureFlag	= 1;
				memset(m_strRecCapFile, '\0', MAX_REC_FILELEN);
				memcpy(m_strRecCapFile, pFileName, strlen(pFileName));
			}
			else
			{
				m_nSeekCaptureFlag = 0;
			}
			m_tcDecFile.ContinueThread();
		}
		return AVErrSuccess;
	}
	if( !m_nOpenRecFileFlag ) return AVErrPlayRecFile_Open;
	
	if(dwTime < 0 || dwTime > m_nRecDuration) return AVErrParam;

	m_tcDecFile.PauseThread();
	av_seek_frame(m_pReadFileCtx,  -1, dwTime*AV_TIME_BASE, AVSEEK_FLAG_BACKWARD);
	JSleep(10);
	m_tcDecFile.ContinueThread();

	m_nPlayRecFrameCount = m_nRecFrameRate*dwTime;
	return AVErrSuccess;
}

int CAVPlayPort::SetFileName(int nType, const char *pFileName, void* recCB, long lUserParam)
{
	//if(!pFileName) return AVErrParam;
	int nLen = 0;
	if(nType == 0 && pFileName)
	{
		nLen = strlen(pFileName)+1;
		SAFE_DELETE(m_decoderPort.m_pPicturePath);
		m_decoderPort.m_pPicturePath = new char[nLen];
		memset(m_decoderPort.m_pPicturePath, 0 , nLen);
		memcpy(m_decoderPort.m_pPicturePath, pFileName, strlen(pFileName));
	}
	else if(nType == 1 && pFileName)
	{	
		nLen = strlen(pFileName)+1;
		SAFE_DELETE(m_pLocalFileName);
		m_pLocalFileName = new char[nLen];
		memset(m_pLocalFileName, 0 , nLen);
		memcpy(m_pLocalFileName, pFileName, strlen(pFileName));
		m_decoderPort.m_avRecord.StartRec(m_pLocalFileName);
	}
	else if(nType == 2 && recCB)
	{
		m_unPlayH264StartTime = -1;
		m_nLastPlay264Time	 = -1;
		m_playRecCB		= (RECCallBack)recCB;
		m_lPlayRecParam	= lUserParam;
	}
	return AVErrSuccess;
}

int	CAVPlayPort::Capture(const char *pFileName)
{
	
	int					nRet		= -1;
	char				strExt[20]  = {0};

	if( m_nPlayStatus != eNMLPlayStatusRun ) return AVErrPlay;

	// _splitpath( pFileName, NULL, NULL, NULL, strExt );
//
	//if(strcmp(strExt, ".jpg") == 0 || strcmp(strExt, ".JPG") == 0)
	//{
		if( m_decoderPort.m_avRecord.m_nPicWidth < 1 || m_decoderPort.m_avRecord.m_nPicHeight < 1 ) return AVErrResolution;

		nRet =  m_decoderPort.Save2JPEG( pFileName );

		if(nRet == -10 ) return AVErrResolution;

		//if(nRet	< 0  ) return AVErrCapture;

		return nRet;//AVErrSuccess;

	//}
	//else if(strcmp(strExt, ".bmp") == 0 || strcmp(strExt, ".BMP") == 0)
	//{
		return Save2BMP(pFileName);
	//}
	//else
	//{
		return AVErrCapture;
	//}
	
}


int	CAVPlayPort::Stop()
{
	JTRACE("CAVPlayPort::Stop().......................\r\n");
	if ( eNMLPlayStatusStop == m_nPlayStatus )
	{
		JTRACE("CAVPlayPort::00____________________________\r\n");
		return AVErrSuccess;
	}

	m_nPlayStatus = eNMLPlayStatusStop;
	JTRACE("CAVPlayPort::11____________________________\r\n");
	m_mutexStop.Lock();
	JTRACE("CAVPlayPort::00000000000000000\r\n");
	if(m_nRecFlag)
	{
		m_tcRec.StopThread(true);
		//m_recbuffCtrl.Clear();
	}
	JTRACE("CAVPlayPort::111111111111111\r\n");
	m_tcDec.StopThread(true);
	m_tcDecFile.StopThread(true);
	m_ePlayType = ePlayStream;
	JTRACE("CAVPlayPort::2222222222222222\r\n");
	m_avbuffer.AVBuffer_Clear();
	//m_avbuffCtrl.Clear();
	JTRACE("CAVPlayPort::3333333333333333333\r\n");
	if(m_h264BStream)
	{
		av_bitstream_filter_close(m_h264BStream); 
		m_h264BStream = NULL;
	}
	JTRACE("CAVPlayPort::444444444444444444444\r\n");
	if(m_aacBStream)
	{
		av_bitstream_filter_close(m_aacBStream); 
		m_aacBStream = NULL;
	}
	m_decoderPort.m_avRecord.m_dwVideoFrameRate = 0;
	JTRACE("CAVPlayPort::55555555555555555555555555\r\n");
	m_decoderPort.m_decCB			= NULL;
	m_decoderPort.m_lUserParam		= NULL;
	m_nIsDecFlag					= -1;
	m_nLoadingFlag					= 0;
	m_mutexStop.Unlock();
	JTRACE("CAVPlayPort::666666666666666666\r\n");
	return AVErrSuccess;
}

fJThRet CAVPlayPort::RunDecThread(void* pParam)
{
	int					iIsRun				= 0;				// 是否需要运行
	CJLThreadCtrl*		pThreadCtrl			= NULL;				// 对应用线程控制器
	CAVPlayPort*		lpPlayer			= NULL;				// 播放器

	// 初始化参数 begin
	pThreadCtrl	= (CJLThreadCtrl*)pParam;
	if ( pThreadCtrl==NULL )
	{
		return 0;
	}
	lpPlayer	= (CAVPlayPort *)pThreadCtrl->GetOwner();
	if ( lpPlayer==NULL )
	{
		pThreadCtrl->SetThreadState(THREAD_STATE_STOP);		// 运行状态
		return 0;
	}
	// 初始化参数 end


	// 进行解码操作 begin
	iIsRun	= 1;											// 需要运行
	while(iIsRun)
	{
		if ( pThreadCtrl->GetNextAction()==THREAD_STATE_STOP )
		{
			iIsRun = 0;										// 不再运行
			break;
		}
	
		// 处理单个解码动作
		if ( lpPlayer->DecAction()==false )
		{
			iIsRun = 0;										// 不再运行
			break;
		}
		JSleep(10);
	}
	
	pThreadCtrl->NotifyStop();
	iIsRun = 0;
	// 进行解码操作 end
	JTRACE("RunDecThread exit...............\r\n");
	return 0;
}

// 处理解码的动作
bool CAVPlayPort::DecAction()
{
	PAVBufferArray	pstEle		= NULL;
	PAVBufferArray	pstEleV		= NULL;
	gos_frame_head	*pDataInfo	= NULL;
	int				nRet 		= -1;
	DWORD			dwDecTime	= 0;
	int				nWaitTime	= 0;
	stDecFrameParam	stDecParam	 = {0};
	
	int	nHeadLen				= sizeof(gos_frame_head);

	if(m_nPlayStatus == eNMLPlayStatusStop) return false;

	if(m_mutexStop.Lock() == false)
	{
		JTRACE("DecAction m_mutexStop lock error");
		return 0;
	}
	if(m_nCaptureH264Len > 0 )
	{
		//JTRACE("nFrameRate = %d, nFrameIndex = %d, nFrameType = %d, nTimestamp = %d, nDataSize = %d\r\n", 
		//	pDataInfo->nFrameRate, pDataInfo->nFrameNo, pDataInfo->nFrameType, pDataInfo->nTimestamp, pDataInfo->nDataSize);
		nRet = m_decoderPort.VideoDec2Picture((unsigned char *)(m_pCaptureH264 + nHeadLen), m_nCaptureH264Len-nHeadLen);
		JTRACE("VideoDec2Picture  = %d\r\n", nRet);
		SAFE_DELETE(m_pCaptureH264);
		m_nCaptureH264Len = 0;
	}
	if(m_nCutEndFlag)  // 剪切视频完成
	{
		//DbgStrOut("cut success.............\r\n");
		StopRec();
		m_nCutEndFlag = 0;
		SAFE_DELETE(m_pLocalFileName);
		m_decoderPort.CutFrameSuccess(RecCutSuccess);
	}
	if(m_nPlayRecSuccessFlag) // 播放录像完成
	{
		m_unPlayH264StartTime = -1;
		m_nPlayRecSuccessFlag = 0;
		m_nPlayRecStreamTime = 0;
		m_dwRecvRecFrameNo	= -1;
		m_decoderPort.CutFrameSuccess(RecPlaySuccess);
	}
	//JSleep(50);

	if(m_avbuffer.GetHasRecv() < 20)
	{
		m_decoderPort.CutFrameSuccess(CacheFree);
	}
	if(m_nIsDecFlag == 0)
	{
		//JTRACE("111111111111111111111111\r\n");
		if(!m_nLoadingFlag)
		{
			m_nLoadingFlag = 1;
			m_decoderPort.CutFrameSuccess(RecLoading);
		}
		//JTRACE("&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&\r\n");
		m_mutexStop.Unlock();
		return true;
	}
	if(m_nLoadingFlag)
	{
		m_decoderPort.CutFrameSuccess(RecLoadSuccess);
		m_nLoadingFlag = 0;
	}

	if(m_nIsDecFlag == 1)
	{
		if(m_avbuffer.GetHasRecv() < 3)
		{
			m_nIsDecFlag = 0;
		}
	}
	pstEle = m_avbuffer.AVBuffer_GetBuff(NULL, NULL);//m_avbuffCtrl.BeginGetBuff();
	if ( pstEle )
	{
		pstEleV		= pstEle;
		m_avbuffer.AVBuffer_EndGetBuff();
		pDataInfo = (gos_frame_head *)pstEleV->m_pBuff;

		if(pDataInfo->nFrameType == gos_video_rec_start_frame)
		{
			m_decoderPort.CutFrameSuccess(RecStartPlay);
		}
		else if(pDataInfo->nFrameType > gos_video_b_frame && pDataInfo->nFrameType < gos_video_rec_end_frame) // 历时流
		{
		//	JTRACE("nFrameRate = %d, nFrameIndex = %d, nFrameType = %d, nTimestamp = %d, nDataSize = %d, m_unPlayH264StartTime = %d, pDataInfo->reserved = %d, m_nPlayRecStreamTime = %d\r\n", 
		//		pDataInfo->nFrameRate, pDataInfo->nFrameNo, pDataInfo->nFrameType, pDataInfo->nTimestamp, pDataInfo->nDataSize, m_unPlayH264StartTime, pDataInfo->reserved, m_nPlayRecStreamTime);
			if(m_decoderPort.m_avRecord.m_dwVideoFrameRate == 0 ) 
				m_decoderPort.m_avRecord.m_dwVideoFrameRate		= pDataInfo->nFrameRate;


			if(pDataInfo->nFrameType == gos_video_rec_i_frame )
			{

				if(pDataInfo->reserved != 0)
				{
					m_nPlayRecStreamTime = pDataInfo->reserved;
					JTRACE("\r\n\r\n");
					JTRACE("rec stream update time = %d\r\n", pDataInfo->reserved);
					m_unPlayH264StartTime = pDataInfo->nTimestamp;
					m_dwRecvRecFrameNo = pDataInfo->nFrameNo;
				}
				if(m_unPlayH264StartTime == -1)
				{
					m_dwRecvRecFrameNo = pDataInfo->nFrameNo;
					m_unPlayH264StartTime = pDataInfo->nTimestamp;
					JTRACE("m_unPlayH264StartTime = %d, nTimestamp = %d\r\n", m_unPlayH264StartTime, pDataInfo->nTimestamp);
				}
			}
			if(m_unPlayH264StartTime > 0 && pDataInfo->nFrameRate > 0)
			{
				int nCurPlayTime = (int)((pDataInfo->nFrameNo - m_dwRecvRecFrameNo)/(int)pDataInfo->nFrameRate);

				//JTRACE("nCurPlayTime = %d\r\n", nCurPlayTime);
				if(m_playRecCB && m_nLastPlay264Time != nCurPlayTime)
				{
					JTRACE("nCurPlayTime = %d, %d, %d, %d\r\n", nCurPlayTime+m_nPlayRecStreamTime, nCurPlayTime, pDataInfo->nFrameNo, m_dwRecvRecFrameNo);
					m_playRecCB(m_nCurPort, AVRetPlayRecTime, nCurPlayTime+m_nPlayRecStreamTime, m_lPlayRecParam);
				}
				m_nLastPlay264Time = nCurPlayTime;
			}
			
			nRet = m_decoderPort.VideoDec((unsigned char *)pstEleV->m_pBuff + nHeadLen, pDataInfo->nDataSize, pDataInfo->nFrameNo);
			
		}
		else if( pDataInfo->nFrameType > gos_unknown_frame && pDataInfo->nFrameType < gos_video_rec_i_frame ) //实时流
		{
			if(m_decoderPort.m_avRecord.m_dwVideoFrameRate == 0 ) 
				m_decoderPort.m_avRecord.m_dwVideoFrameRate		= pDataInfo->nFrameRate;


			if(m_pTestFileH264)
			{
				//fwrite(pstEleV->m_pBuff + nHeadLen, pDataInfo->nDataSize, 1, m_pTestFileH264);
			}
			//DWORD dwVideo = JGetTickCount();
			//JTRACE("dec frame no = %d\r\n", pDataInfo->nFrameNo);
			//JTRACE("m_avbuffer count = %d\r\n", m_avbuffer.GetHasRecv());
			//JTRACE("**nFrameRate = %d, nFrameIndex = %d, nFrameType = %d, nTimestamp = %d, nDataSize = %d\r\n", 
			//	pDataInfo->nFrameRate, pDataInfo->nFrameNo, pDataInfo->nFrameType, pDataInfo->nTimestamp, pDataInfo->nDataSize);
			nRet = m_decoderPort.VideoDec((unsigned char *)pstEleV->m_pBuff + nHeadLen, pDataInfo->nDataSize);
	
			//JTRACE("VideoDec use time = %d++++++++++++++\r\n", (int)(JGetTickCount()-dwVideo));
		}
		else if( gos_audio_frame == pDataInfo->nFrameType || pDataInfo->nFrameType == gos_rec_audio_frame) //audio
		{
			//DWORD dwVideo = JGetTickCount();
			if(pDataInfo->nCodeType == gos_audio_G711A)
			{
				if(m_decoderPort.m_avRecord.m_nRecType < 0)
					m_decoderPort.m_avRecord.m_nRecType = 1;
				//JTRACE("G711ADec================\r\n");
				m_decoderPort.G711ADec((unsigned char *)pstEleV->m_pBuff + nHeadLen, pDataInfo->nDataSize, pDataInfo->nFrameRate);
			}
			else
			{
				if(m_decoderPort.m_avRecord.m_nRecType < 0)
					m_decoderPort.m_avRecord.m_nRecType = 0;
				m_decoderPort.AudioDec((unsigned char *)pstEleV->m_pBuff + nHeadLen, pDataInfo->nDataSize, pDataInfo->nFrameRate);
			}
			//JTRACE("AudioDec use time = %d_______________r\n", (int)(JGetTickCount()-dwVideo));
		}
		
// 		if ( pstEleV->m_iMaxSize> m_nBuffSize )
// 		{
// 			pstEleV->Free();
// 		}
		m_mutexStop.Unlock();
		return true;
	}
	else
	{
		//JSleep(10);
	}
	m_mutexStop.Unlock();

	return true;
	
}

int		 CAVPlayPort::WriteRec(unsigned char* pBuf,  DWORD dwSize)
{
	gos_frame_head	*pDataInfo	= NULL;

	char			*pSpsPps	= NULL;
	int				nFrameType	= 1;
	int				nSpsPpsLen	= 0;
	int	nHeadLen				= sizeof(gos_frame_head);

	pDataInfo = (gos_frame_head *)pBuf;

	if(!pDataInfo) return -1;

//#ifndef WIN32
#if REC_TYPE
//#if (defined __APPLE_CPP__) || (defined __APPLE_CC__)
	if(pDataInfo->nFrameType == gos_audio_frame || pDataInfo->nFrameType == gos_cut_audio_frame ) nFrameType = 3;
	else if(pDataInfo->nFrameType == gos_video_i_frame || pDataInfo->nFrameType == gos_video_cut_i_frame) nFrameType = 1;
	else if(pDataInfo->nFrameType > gos_unknown_frame && pDataInfo->nFrameType < gos_video_end_frame) nFrameType = 2;
	if(pDataInfo->nCodeType == gos_audio_G711A)
	{
		char*	pPcmData		= NULL;
		int		nPcmLen			= 0;
		unsigned char*	pAACData		= NULL;
		int		nAACLen			= 0;
		m_decoderPort.G711ADec(pBuf+sizeof(gos_frame_head), pDataInfo->nDataSize, &pPcmData, &nPcmLen);
		if(nPcmLen >0)
		{
			//JTRACE("encode AAC start...............................\r\n");
			m_encoderPort.EncodePCM2AAC(8000, 1, (unsigned char *)pPcmData, nPcmLen, &pAACData, &nAACLen);
			//JTRACE("encode AAC end...............................\r\n");
			if(nAACLen > 0)
			{
				//JTRACE("nAACLen===========================================%d\r\n",nAACLen);
				int nRet =	m_decoderPort.m_avRecord.WriteRec(pAACData, nAACLen,pDataInfo->nFrameRate, pDataInfo->nTimestamp, nFrameType, 1);
				SAFE_DELETE(pPcmData);
				SAFE_DELETE(pAACData)

				return nRet;
			}
		}
		SAFE_DELETE(pPcmData);
		SAFE_DELETE(pAACData);
		return 0;
	}
	return m_decoderPort.m_avRecord.WriteRec(pBuf + nHeadLen, pDataInfo->nDataSize,pDataInfo->nFrameRate, pDataInfo->nTimestamp, nFrameType);
//#endif
#endif
	if(pDataInfo->nFrameType == gos_audio_frame) nFrameType = 2;
	
	if( pDataInfo->nFrameType == gos_video_i_frame && !m_decoderPort.m_avRecord.m_nOpenFileFlag )
	{

		m_decoderPort.m_avRecord.m_dwVideoFrameRate = pDataInfo->nFrameRate;

		m_decoderPort.m_avRecord.Get_SPS_PPS(pBuf + nHeadLen, pDataInfo->nDataSize, &pSpsPps, &nSpsPpsLen);

		m_decoderPort.m_avRecord.OpenRecFile(m_strRecFilePath, pSpsPps, nSpsPpsLen);

		if(pSpsPps)	SAFE_DELETE(pSpsPps);

	}

	if(pDataInfo->nCodeType == gos_audio_G711A)
	{
		char*	pPcmData		= NULL;
		int		nPcmLen			= 0;
		unsigned char*	pAACData		= NULL;
		int		nAACLen			= 0;
		m_decoderPort.G711ADec(pBuf+sizeof(gos_frame_head), pDataInfo->nDataSize, &pPcmData, &nPcmLen);
		if(nPcmLen >0)
		{
			//JTRACE("encode AAC start...............................\r\n");
			m_encoderPort.EncodePCM2AAC(8000, 1, (unsigned char *)pPcmData, nPcmLen, &pAACData, &nAACLen);
			//JTRACE("encode AAC end...............................\r\n");
			if(nAACLen > 0)
			{
				//JTRACE("nAACLen===========================================%d\r\n",nAACLen);
				int nRet = m_decoderPort.m_avRecord.WriteRecData(pAACData, nAACLen, nFrameType, pDataInfo->nTimestamp, pDataInfo->nFrameNo);
				SAFE_DELETE(pPcmData);
				SAFE_DELETE(pAACData)

				return 0;
			}
		}
		SAFE_DELETE(pPcmData);
		SAFE_DELETE(pAACData);
		return 0;
	}
	return m_decoderPort.m_avRecord.WriteRecData(pBuf + nHeadLen, pDataInfo->nDataSize, nFrameType, pDataInfo->nTimestamp, pDataInfo->nFrameNo);

}
// long  CAVPlayPort::WriteRec_CallBack(unsigned char* pBuf,  DWORD dwSize, void* pUserParam)
// {
// 	CAVPlayPort *pPlayPort = (CAVPlayPort *)pUserParam;
// 
// 	return pPlayPort->WriteRec(pBuf, dwSize);
// }

fJThRet CAVPlayPort::RunRecThread(void* pParam)
{
	JLOG_TRY
	int					iIsRun				= 0;				// 是否需要运行
	CJLThreadCtrl*		pThreadCtrl			= NULL;				// 对应用线程控制器
	CAVPlayPort*		lpPlayer			= NULL;				// 播放器

	// 初始化参数 begin
	pThreadCtrl	= (CJLThreadCtrl*)pParam;
	if ( pThreadCtrl==NULL )
	{
		return 0;
	}
	lpPlayer	= (CAVPlayPort *)pThreadCtrl->GetOwner();
	if ( lpPlayer==NULL )
	{
		pThreadCtrl->SetThreadState(THREAD_STATE_STOP);		// 运行状态
		return 0;
	}
	
	iIsRun	= 1;											// 需要运行
	while(iIsRun)
	{
		if ( pThreadCtrl->GetNextAction()==THREAD_STATE_STOP )
		{
			iIsRun = 0;										// 不再运行
			break;
		}

		if ( lpPlayer->RecAction()==false )
		{
			iIsRun = 0;										// 不再运行
			break;
		}
	}

	pThreadCtrl->NotifyStop();
	iIsRun = 0;
	
	JTRACE("***************************************RunRecThread exit************************\r\n");

	return 0;
	JLOG_CATCH("try-catch RunDecFileThread::RunDecThread \r\n");
	return 0;
}


// 处理解码的动作
bool CAVPlayPort::RecAction()
{
	JLOG_TRY
	PAVBuffArray	pstEle		= NULL;
	PAVBuffArray	pstEleV		= NULL;


	m_mutexStop.Lock();
	pstEle = m_recbuffCtrl.BeginGetBuff();
	if ( pstEle )
	{
		pstEleV		= pstEle;
		m_recbuffCtrl.EndGetBuff();

		
		WriteRec((unsigned char *)pstEleV->m_pBuf, pstEleV->m_iBufSize);
		
		if ( pstEleV->m_iMaxSize> m_nBuffSize )
		{
			pstEleV->Free();
		}
		m_mutexStop.Unlock();
		return true;
	}
	else
	{
		JSleep(10);
	}
	m_mutexStop.Unlock();
	return true;
	JLOG_CATCH("try-catch RunDecFileThread::DecAction \r\n");
	return false;
}


int	CAVPlayPort::Save2BMP(const char* pFileName)
{
	BITMAPFILEHEADER 	bmpFileHeader;			// 位图头
	BITMAPINFO			bmpinfo;				// 位图文件头
	unsigned char*		pBuf		= NULL;
	unsigned char*		pRgbBuf		= NULL;
	FILE*				pCapture	= NULL;
	int					iRGBDeep	= 0;
	int					iBitCount	= 0;
	int					nWidth		= 0;
	int					nHeight		= 0;
	int					i			= 0;

	nWidth  = m_decoderPort.m_avRecord.m_nPicWidth;
	nHeight = m_decoderPort.m_avRecord.m_nPicHeight;

	pBuf = m_decoderPort.m_pDecBuff;
	if(m_decoderPort.m_eAvPixFormat==AV_PIX_FMT_YUVJ420P) 
	{
		m_decoderPort.GetRGB32Data(&pRgbBuf);

		if(!pRgbBuf)		return AVErrCapture;

		pBuf = pRgbBuf;

		iRGBDeep = 3;
	}
	else if ( m_decoderPort.m_eAvPixFormat==AV_PIX_FMT_BGRA )		iRGBDeep = 4;
	else if ( m_decoderPort.m_eAvPixFormat==AV_PIX_FMT_RGB24 )	iRGBDeep = 3;
	else if ( m_decoderPort.m_eAvPixFormat==AV_PIX_FMT_RGB565 )	iRGBDeep = 2;
	else iRGBDeep = 4;
	iBitCount			= 8*iRGBDeep;

	// 创建位图头部 begin
	memset(&bmpinfo, 0, sizeof(BITMAPINFO));
	bmpinfo.bmiHeader.biSize		= sizeof(BITMAPINFOHEADER);
	bmpinfo.bmiHeader.biWidth		= nWidth;
	bmpinfo.bmiHeader.biHeight		= nHeight;
	bmpinfo.bmiHeader.biPlanes		= 1;
	bmpinfo.bmiHeader.biBitCount	= iBitCount;
	bmpinfo.bmiHeader.biCompression	= /*BI_RGB*/BI_BITFIELDS;
	bmpinfo.bmiHeader.biSizeImage	= ((nWidth*iRGBDeep*8+(iBitCount-1))&~(iBitCount-1))/8 * nHeight;
	bmpinfo.bmiColors[0].rgbBlue	= 0xF8;
	bmpinfo.bmiColors[0].rgbGreen	= 0x7e;
	bmpinfo.bmiColors[0].rgbRed		= 0x1F;
	bmpinfo.bmiColors[0].rgbReserved= 0;
	// 创建位图头部 end

	// 创建位图头部 begin
	bmpFileHeader.bfType		= 0x4d42;		// 'BM'
	bmpFileHeader.bfSize		= bmpinfo.bmiHeader.biSizeImage;
	bmpFileHeader.bfReserved1	= 0;
	bmpFileHeader.bfReserved2	= 0;
	bmpFileHeader.bfOffBits		= (DWORD)sizeof(bmpFileHeader) + (DWORD)sizeof(bmpinfo);
	// 创建位图头部 begin

	pCapture = fopen(pFileName,"wb");

	if ( pCapture==NULL )
	{
		SAFE_DELETE(pRgbBuf);
		return AVErrCreateCaptureFile;
	}

	// 写入内容 begin
	fwrite(&bmpFileHeader, sizeof(BITMAPFILEHEADER), 1, pCapture);		// 写文件头
	fwrite(&bmpinfo, sizeof(BITMAPINFO),  1, pCapture);				// 写位图头
	for(i=0; i < bmpinfo.bmiHeader.biHeight; i++)
	{
		// 写位图信息
		fwrite(pBuf+(bmpinfo.bmiHeader.biHeight-i-1)*iRGBDeep*bmpinfo.bmiHeader.biWidth,
			iRGBDeep*bmpinfo.bmiHeader.biWidth, 1, pCapture);
	}
	// 写入内容 end

	// 关闭文件 begin
	fclose(pCapture);
	pCapture = NULL;

	SAFE_DELETE(pRgbBuf);
	// 关闭文件 end
	return AVErrSuccess;
}


int	CAVPlayPort::StartRec(const char *pFileName, void* recCB, long lUserParam)
{
	if(pFileName == NULL) return -1;

	//m_decoderPort.m_avRecord.m_nRecType = nAudioType;

	if(m_decoderPort.m_avRecord.m_nRecType < 0)
	{
		//return AVErrGetAudioType;
	}

	if(recCB)
	{
		m_decoderPort.m_avRecord.m_recCB		= (RECCallBack)recCB;
		m_decoderPort.m_avRecord.m_lUserParam	= lUserParam;
	}
#if REC_TYPE
//#if (defined __APPLE_CPP__) || (defined __APPLE_CC__)
//#ifndef WIN32
	m_decoderPort.m_avRecord.StartRec(pFileName);
	m_nRecFlag = 1;
	return AVErrSuccess;
//#endif
#endif
	strcpy(m_strRecFilePath, pFileName);

// 	m_recbuffCtrl.SetSize( m_nRecBuffCount, 3, m_nRecBuffSize); // 设置缓存
// 
// 	strcpy(m_strRecFilePath, pFileName);
// 
// 	m_tcRec.StartThread(RunRecThread);

	m_nRecFlag = 1;

	JTRACE("CAVPlayPort::StartRec success\r\n");

	return AVErrSuccess;
}

int	CAVPlayPort::StopRec()
{
//#ifndef WIN32
#if REC_TYPE
//#if (defined __APPLE_CPP__) || (defined __APPLE_CC__)
	m_nRecFlag = 0;
	return m_decoderPort.m_avRecord.StopRec();
//#endif
#endif
	if( !m_nRecFlag ) return AVErrSuccess;

	m_nRecFlag = 0;

	//m_tcRec.StopThread(true);

	//m_recbuffCtrl.Clear();
	
	m_decoderPort.m_avRecord.CloseRecFile();

	JTRACE("CAVPlayPort::StopRec success\r\n");
	return 0;
}

DWORD CAVPlayPort::GetRecTime()
{
	return m_decoderPort.m_avRecord.GetRecTime();
}

long CAVPlayPort::SetRecTime(DWORD dwRecTime)
{
	return m_decoderPort.m_avRecord.SetRecTime(dwRecTime);
}

int	CAVPlayPort::SetRecParam(int nWidth, int nHeight, int nFrameRate, int nAACChannel)
{
	return m_decoderPort.m_avRecord.SetRecParam(nWidth, nHeight, nFrameRate, nAACChannel);
}

long CAVPlayPort::SetH264FileRecParam(int nIsRec, const char *pMp4FileName, int nStartTime, int nTotalTime)
{
	int		nRet			= -1;

	m_decoderPort.m_avRecord.m_nRecType = 1;
	
	nRet = StartRec(pMp4FileName, NULL, NULL);

	if(nRet != 0) return AVErrParam;

	m_nIsH264RecFlag		= nIsRec;
	m_nH264StartRecTime		= nStartTime;
	m_nH264TotalRecTime		= nTotalTime;
	m_unWriteFrameCount		= 0;

	return 0;
}

long CAVPlayPort::ENC_CallBack(unsigned char* lpBuf, long lSize, long lUserParam)
{
	CAVPlayPort *pThis = (CAVPlayPort *)lUserParam;
	gos_frame_head	sHead = {0};
	char		str[1024] = {0};

	sHead.nFrameType = gos_audio_frame;
	sHead.nCodeType = gos_audio_AAC;
	sHead.nFrameRate = 8000;
	sHead.nDataSize = lSize;

	memcpy(str, (char *)&sHead, sizeof(gos_frame_head));
	memcpy(str, lpBuf, lSize);

	pThis->m_mutexStop.Lock();
	pThis->WriteRec((unsigned char *)str, sizeof(gos_frame_head)+lSize);
	pThis->m_mutexStop.Unlock();

// 	if(gAacFile && lpBuf)
// 	{
// 		//fwrite(lpBuf, lSize, 1, gAacFile);
// 	}

	return 0;
}
long CAVPlayPort::DecH264File(const char *pFileName,  int nIsRand, void* playRecCB, long lUserParam)
{

	if(m_pReadH264)
	{
		return AVErrReadH264;
	}

	m_nPlayFileType			= 1;
	m_unPlayH264StartTime	= -1;
	m_nLastPlay264Time		= -1;
	m_nSeekCaptureFlag		= 0;
	m_nIsStartWriteMp4Flag	= 0;
	m_nPlayFileArrayIndex	= 0;
	m_nDecFileFrameNo		= -1;
	m_ePlayType				= ePlayH264File;
	if(playRecCB)
	{
		m_playRecCB		= (RECCallBack)playRecCB;
		m_lPlayRecParam = lUserParam;
	}
	if(!nIsRand)
		m_nRandDecFile = 1;

	m_pReadH264 = fopen(pFileName, "rb");
	if(!m_pReadH264) return AVErrPlayRecFile_Open;

	m_tcReadH264.StartThread(RunReadH264Thread);

	m_nLastPlayRecTime = 0;
	return 0;
}

long CAVPlayPort::StopDecH264File()
{
	JTRACE("CAVPlayPort::StopDecH264File().......................\r\n");
	
	m_tcReadH264.StopThread(true);
	StopRec();
	m_unWriteFrameCount		= 0;
	if(m_pReadH264)
	{
		fclose(m_pReadH264);
		m_pReadH264 = NULL;
	}
	
	m_nCheckFileFlag = 0;
	m_nRandDecFile	= 0;
	m_nIFrameCount = 0;
	m_nIsStartWriteMp4Flag = 0;
	m_nIsH264RecFlag = 0;

	SAFE_DELETE(m_pReadH264Data);

	return 0;
}


fJThRet CAVPlayPort::RunReadH264Thread(void* pParam)
{
	JLOG_TRY
		int					iIsRun				= 0;				// 是否需要运行
	CJLThreadCtrl*		pThreadCtrl			= NULL;				// 对应用线程控制器
	CAVPlayPort*		lpPlayer			= NULL;				// 播放器
	int					nRet				= 0;

	// 初始化参数 begin
	pThreadCtrl	= (CJLThreadCtrl*)pParam;
	if ( pThreadCtrl==NULL )
	{
		return 0;
	}
	lpPlayer	= (CAVPlayPort *)pThreadCtrl->GetOwner();
	if ( lpPlayer==NULL )
	{
		pThreadCtrl->SetThreadState(THREAD_STATE_STOP);		// 运行状态
		return 0;
	}

	iIsRun	= 1;											// 需要运行
	while(iIsRun)
	{
		if ( pThreadCtrl->GetNextAction()==THREAD_STATE_STOP )
		{
			iIsRun = 0;										// 不再运行
			break;
		}
		nRet = lpPlayer->ReadH264Action();
		if(nRet == 1)
			lpPlayer->ReadH264Finish();
// 		if ( nRet != 0 )
// 		{
// 			iIsRun = 0;										// 不再运行
// 			break;
// 		}
	}

	pThreadCtrl->NotifyStop();
	iIsRun = 0;

	
	JTRACE("***************************************RunReadH264Thread exit************************\r\n");

	return 0;
	JLOG_CATCH("try-catch RunDecFileThread::RunDecThread \r\n");
	return 0;
}

long CAVPlayPort::AddH264File(const char *pFileName, int nFileNameLen)
{
	m_mutexStop.Lock();
	for(int i = m_nAddFileIndex ; i < MAX_IFRAME_POS_COUNT; i ++)
	{
		if(NULL == m_pH264FileNameArray[i])
		{
			m_pH264FileNameArray[i] = new char[nFileNameLen+1];
			if(m_pH264FileNameArray[i])
			{
				m_nAddFileIndex = i+1;
				if(i == (MAX_IFRAME_POS_COUNT-1))
					m_nAddFileIndex = 0;

				memset(m_pH264FileNameArray[i], '\0', nFileNameLen+1);
				memcpy(m_pH264FileNameArray[i], pFileName, nFileNameLen);
				m_mutexStop.Unlock();
				return i+1;
			}
			return AVErrAddH264File;
		}
	}
	m_mutexStop.Unlock();
	return AVErrAddH264File;
}

void	CAVPlayPort::CheckH264File(FILE* pFile)
{
	int						nRead = 0;
	long					nHasReadLen = 0;
	unsigned char *			pPutData = NULL;
	gos_frame_head*			pFrameHead = NULL;
	unsigned int			unFrameTimeStamp = 0;
	char					strFrameHead[sizeof(gos_frame_head)] = {0};
	int						nVideoFrameCount	= 0;
	int						nFrameType		= 0;
	if(m_nCheckFileFlag == 0 )
	{
		do 
		{
			nRead = fread(strFrameHead, 1 ,sizeof(gos_frame_head), pFile);
			pFrameHead = (gos_frame_head*	)strFrameHead;

			if(pFrameHead->nFrameType != gos_rec_audio_frame)
				JTRACE("pFrameHead->nTimestamp = %ld, pFrameHead->nFrameNo = %d, pFrameHead->nFrameType = %d, pFrameHead->nFrameRate = %d, pFrameHead->reserved = %d\r\n", 
					pFrameHead->nTimestamp, pFrameHead->nFrameNo, pFrameHead->nFrameType, pFrameHead->nFrameRate, pFrameHead->reserved);
			
			if(pFrameHead->nFrameNo == 149)
			{
				JTRACE("");
			}
			if(pFrameHead->nFrameType == gos_video_i_frame)
			{
				++ nVideoFrameCount;
				m_decoderPort.m_avRecord.m_nPicWidth = pFrameHead->sWidth;
				m_decoderPort.m_avRecord.m_nPicHeight = pFrameHead->sHeight;
				nFrameType = pFrameHead->nFrameRate;
				if(m_unPlayH264StartTime == -1) m_unPlayH264StartTime = pFrameHead->nTimestamp;

				if(m_nIFrameCount < MAX_IFRAME_POS_COUNT)
				{
					m_nIFramePos[m_nIFrameCount] = nHasReadLen;
					m_nIFrameCount ++;
				}
				unFrameTimeStamp = pFrameHead->nTimestamp;
	
			}
			else if(pFrameHead->nFrameType == gos_audio_frame)
			{
				//JTRACE("AUDIO****************************codeType = %d, nDataSize = %d\r\n", pFrameHead->nCodeType, pFrameHead->nDataSize);
			}
			else
			{
				if(nVideoFrameCount > 0) ++nVideoFrameCount;
				unFrameTimeStamp = pFrameHead->nTimestamp;
				//JTRACE("pFrameHead->nFrameType = %d===================================\r\n", pFrameHead->nFrameType);
			}
			nHasReadLen += nRead;
			pPutData = new unsigned char[sizeof(gos_frame_head)+pFrameHead->nDataSize];
			nRead = fread(pPutData+(sizeof(gos_frame_head)), 1 ,pFrameHead->nDataSize, pFile);
			SAFE_DELETE(pPutData);
			nHasReadLen += nRead;
		} while (nRead > 0);

		if(m_playRecCB)
		{
			int nTotalTime = /*nVideoFrameCount / nFrameType;*/(int)((unFrameTimeStamp - m_unPlayH264StartTime)/1000);
			m_playRecCB(m_nCurPort, AVRetPlayRecTotalTime, nTotalTime, m_lPlayRecParam);
		}

		fseek(m_pReadH264, 0, SEEK_SET);
		m_nCheckFileFlag = 1;
	}

	if(! m_nRandDecFile && m_nIFrameCount > 1)
	{
		unsigned int seed = JGetTickCount(); 
		srand(seed);
		int nIndex=rand()%(m_nIFrameCount-1);

		JTRACE("decfile rand nIndex = %d, m_nIFrameCount = %d\r\n",nIndex , m_nIFrameCount);

		fseek(m_pReadH264, m_nIFramePos[nIndex], SEEK_SET);
		m_nRandDecFile = 1;
	}
}

int	CAVPlayPort::ReadH264Action()
{
	gos_frame_head*			pFrameHead = NULL;
	char					strFrameHead[sizeof(gos_frame_head)] = {0};
	int						nRead = 0;
	int						nRet  = -1;
	FILE*					pFile = NULL;
	int						nFrameRate = 0;

	if(!m_pReadH264)
	{
		PlayNextH264File();
		//JSleep(5);
		return 0;
	}

	pFile = m_pReadH264 ;

	CheckH264File(pFile);

	if(eNMLPlayStatusStop == m_nPlayStatus)
	{
		JSleep(5);
		return 0;
	}
	
	nRead = fread(strFrameHead, 1 ,sizeof(gos_frame_head), pFile);

	pFrameHead = (gos_frame_head*	)strFrameHead;
	//if(pFrameHead->nFrameType == 50)
		//JTRACE("nFrameNo = %d, nFrameType = %d, nCodeType = %d,nFrameRate = %d, sWidth= %d, sHeight = %d, pFrameHead->nTimestamp = %d\r\n", 
		//pFrameHead->nFrameNo, pFrameHead->nFrameType, pFrameHead->nCodeType, pFrameHead->nFrameRate, pFrameHead->sWidth, pFrameHead->sHeight,pFrameHead->nTimestamp);
	if(nRead > 0)
	{
		if(pFrameHead->nDataSize > 0)
		{
			if(m_pReadH264Data == NULL)
			{
				m_pReadH264Data = new unsigned char[100*1024];
				m_nReadH264MaxDataLen = 100*1024;
			}
			if((pFrameHead->nDataSize+sizeof(gos_frame_head)) > m_nReadH264MaxDataLen )
			{
				SAFE_DELETE(m_pReadH264Data);
				m_pReadH264Data = new unsigned char[pFrameHead->nDataSize+sizeof(gos_frame_head)];
				m_nReadH264MaxDataLen = pFrameHead->nDataSize+sizeof(gos_frame_head);
			}
			
			memcpy(m_pReadH264Data, strFrameHead, sizeof(gos_frame_head));

			nRead = fread(m_pReadH264Data+sizeof(gos_frame_head), 1 ,pFrameHead->nDataSize, pFile);

			
			if(m_nIsH264RecFlag)
			{
				if(!m_nIsStartWriteMp4Flag)
				{
					int nSeekIndex = 0;
				
					if(m_nH264StartRecTime > 0)
						nSeekIndex = (int)m_nH264StartRecTime / 3;

					fseek(m_pReadH264, m_nIFramePos[nSeekIndex], SEEK_SET);
					m_nIsStartWriteMp4Flag = 1;
					return 0;
				}
				
				//JTRACE("pFrameHead->nTimestamp = %d\r\n", pFrameHead->nTimestamp);
					
				int nCurPlayTime1 = (int)((pFrameHead->nTimestamp - m_unPlayH264StartTime)/1000);
				m_mutexStop.Lock();
				if(pFrameHead->nFrameType > gos_unknown_frame && pFrameHead->nFrameType < gos_video_end_frame)
				{	
					if(pFrameHead->nFrameType == gos_video_i_frame && m_unWriteFrameCount == 0) 
					{
						m_unWriteFrameCount = 1;
					}

					if(m_decoderPort.m_avRecord.m_nPicHeight < 1 || m_decoderPort.m_avRecord.m_nPicWidth < 1)
					{
						m_decoderPort.m_avRecord.m_nPicWidth = pFrameHead->sWidth;
						m_decoderPort.m_avRecord.m_nPicHeight = pFrameHead->sHeight;
					}

					if(m_unWriteFrameCount > 0) m_unWriteFrameCount++;

 					nFrameRate = pFrameHead->nFrameRate;
				}
				
				WriteRec(m_pReadH264Data, sizeof(gos_frame_head)+pFrameHead->nDataSize);
				m_mutexStop.Unlock();
				if(m_nH264TotalRecTime > 0)
				{	
					if(nFrameRate > 0 && (m_unWriteFrameCount / nFrameRate) > (m_nH264StartRecTime+m_nH264TotalRecTime))
					{
						return 1;
					}
				}
				
					
				
			}
			else if( pFrameHead->nFrameType > gos_unknown_frame && pFrameHead->nFrameType < gos_video_end_frame ) //video
			{
				JTRACE("pFrameHead->nTimestamp = %ld\r\n", pFrameHead->nTimestamp);
				int nCurPlayTime = (int)((pFrameHead->nTimestamp - m_unPlayH264StartTime)/1000);
// 				int nCurPlayTime = 0;
// 				if(pFrameHead->nFrameRate > 0)
// 					nCurPlayTime = (pFrameHead->nFrameNo - m_unPlayH264StartTime) / pFrameHead->nFrameRate;
				if(m_playRecCB && m_nLastPlay264Time != nCurPlayTime)
				{
					m_playRecCB(m_nCurPort, AVRetPlayRecTime, nCurPlayTime, m_lPlayRecParam);
				}

				m_nLastPlay264Time = nCurPlayTime;
				nRet = m_decoderPort.VideoDec((unsigned char *)(m_pReadH264Data + sizeof(gos_frame_head)), pFrameHead->nDataSize);
				if(m_nSeekCaptureFlag)
				{
					nRet = Capture(m_strRecCapFile);
					if(nRet == 0)
					{
						m_playRecCB(m_nCurPort, AVRetPlayRecSeekCapture, 0, m_lPlayRecParam);
						m_nSeekCaptureFlag = 0;
					}

				}
				if(pFrameHead->nFrameRate > 0)
				{
					if(m_nLastPlayRecTime == 0) m_nLastPlayRecTime = JGetTickCount();
					int nSleepTime = 0;
					if(m_nAddFileIndex < 1 && m_nDecFileFrameNo	>= 0)
						nSleepTime= (int)((1000 / pFrameHead->nFrameRate / m_dPlaySpeed)*(pFrameHead->nFrameNo - m_nDecFileFrameNo) - (int)(JGetTickCount()-m_nLastPlayRecTime));
					else
						 nSleepTime= (int)((1000 / pFrameHead->nFrameRate / m_dPlaySpeed) - (int)(JGetTickCount()-m_nLastPlayRecTime));

					if(nSleepTime < 0 || nSleepTime > 10000)
					{
						JTRACE("CAVPlayPort::ReadH264Action*************************************** nSleepTime = %d\r\n", nSleepTime);
						nSleepTime = 0;
					}

					JSleep(nSleepTime);
				}
				m_nDecFileFrameNo = pFrameHead->nFrameNo;
				m_nLastPlayRecTime = JGetTickCount();
			}
			else if( gos_audio_frame == pFrameHead->nFrameType ) //audio
			{
				if(pFrameHead->nCodeType == gos_audio_G711A)
				{
					
					//JTRACE("gos_audio_G711A datalen = %d\r\n", pFrameHead->nDataSize);
					m_decoderPort.G711ADec((unsigned char *)(m_pReadH264Data + sizeof(gos_frame_head)), pFrameHead->nDataSize, pFrameHead->nFrameRate);
				}
				else
				{
					m_decoderPort.AudioDec((unsigned char *)(m_pReadH264Data + sizeof(gos_frame_head)), pFrameHead->nDataSize, pFrameHead->nFrameRate);
				}
			}
		}
	}
	else
	{
		fclose(m_pReadH264);
		m_pReadH264 = NULL;
		//if(PlayNextH264File() == 0)
		//	return 0;
		
		return 1;
	}

	return 0;
}

int		CAVPlayPort::PlayNextH264File()
{
	m_mutexStop.Lock();
	for(int i = m_nPlayFileArrayIndex ; i < MAX_IFRAME_POS_COUNT; i++)
	{
		if(m_pH264FileNameArray[i])
		{
			if(i == (MAX_IFRAME_POS_COUNT - 1))
				m_nPlayFileArrayIndex = 0;
			else
				m_nPlayFileArrayIndex = i+1;
			m_pReadH264 = fopen(m_pH264FileNameArray[i], "rb");
			if(!m_pReadH264)
			{
				m_mutexStop.Unlock();
				return -1;
			}
			else
			{
				JTRACE("CAVPlayPort::PlayNextH264File()..........%d.............\r\n",m_nPlayFileArrayIndex );
				SAFE_DELETE(m_pH264FileNameArray[i]);
				m_mutexStop.Unlock();
				return 0;
			}
		}
	}

	m_mutexStop.Unlock();
	return -1;
}



void CAVPlayPort::ReadH264Finish()
{
	if(m_pReadH264)
	{
		fclose(m_pReadH264);
		m_pReadH264 = NULL;
	}

	if(m_nIsH264RecFlag)
	{
		if(m_playRecCB)
			m_playRecCB(m_nCurPort, AVRetPlayRecRecordFinish, 0, m_lPlayRecParam);
	}
	else
	{
		if(m_playRecCB)
			m_playRecCB(m_nCurPort, AVRetPlayRecFinish, (long)m_nPlayFileArrayIndex, m_lPlayRecParam);
	}
	
// 	if(m_decoderPort.m_decCB)
// 	{
// 		m_decoderPort.m_decCB(NULL, m_decoderPort.m_lUserParam);  // 返回空 代表读取完成。
// 	}
}

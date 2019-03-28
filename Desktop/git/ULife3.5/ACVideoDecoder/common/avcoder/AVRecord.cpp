#include "AVRecord.h"
#if (defined _WIN32) || (defined _WIN64)
#include <MMSystem.h>
#pragma comment(lib, "winmm.lib ")
#endif

CAVRecord::CAVRecord()
{
	m_pRecFormatCxt		= NULL;
	m_nHeadPos			= 0;
	m_nGetSpsPpsFlag	= 0;
	m_nOpenFileFlag		= 0;
	m_nPicWidth			= 0;
	m_nPicHeight		= 0;
	m_nVideoFrameCount  = 0;
	m_nAudioPts			= TIME_AUDIO_PTS_INIT;
	m_dwVideoFrameRate	= 0;
	m_dwAudioFrameRate	= 0;
	m_nRecTime			= 0;
	m_nRecEndTime		= 0;
	m_nLastRecTime		= 0;
	m_nLastVideoFrameNum= 0;
	m_nLastAudioFrameNum= 0;
	m_nAACChannel		= 2;
	m_recCB				= NULL;
	m_lUserParam		= NULL;
	m_testFile			= NULL;
	m_video_st			= NULL;
	m_nWriteFirst		= 0;
	m_nRecType			= -1;

	//m_testFile			= fopen("D:\\test_Rec.aac", "wb");

}

CAVRecord::~CAVRecord()
{
	m_nPicWidth = 0;
	m_nPicHeight = 0;
	if(m_testFile)
	{
		fclose(m_testFile);
		m_testFile = NULL;
	}

}

long	CAVRecord::StartRec(const char *pFileName)
{
	if(m_nWriteFirst) return -1;
	return MP4Mux_Open(pFileName);
}

long	CAVRecord::WriteRec(unsigned char *pBuf, int nLen,int nFrameRate, unsigned int nTimeStamp, int nFrameType, int nFlag)
{
	if(!m_nWriteFirst)
	{
		if(nFrameType == 1)  // I 帧
		{
			AM_VIDEO_INFO videoInfo;
			AM_AUDIO_INFO audioInfo;

			MP4Mux_GetVideoInfo(pBuf, nLen, nFrameRate, &videoInfo);
#if 1
			// 设置音频参数
			JTRACE("m_nRecType = %d-------------------------------\r\n", m_nRecType);
			audioInfo.sampleRate = 16000;                       // 采样率
			audioInfo.chunkSize  = 1024;                        // 每帧采集点数
			audioInfo.pktPtsIncr = 1024 * 90000 / 16000;        // 每帧播放时长
			if(m_nRecType)
			{
				audioInfo.sampleRate = 8000;                       // 采样率
				audioInfo.pktPtsIncr = 1024 * 90000 / 8000;        // 每帧播放时长
			}

			audioInfo.sampleSize = 16;                          // 位数
			audioInfo.channels   = 2;                           // 声道数
#endif
			videoInfo.rate = nFrameRate;
			videoInfo.width = m_nPicWidth;
			videoInfo.height = m_nPicHeight;
			MP4Mux_OnInfo(&videoInfo, &audioInfo);

			m_nWriteFirst = 1;
		}
		if(!m_nWriteFirst)
			return 0;
	}

	if(nFrameType < 3) //  视频帧
	{
		MP4Mux_WriteVideoData(pBuf, nLen, nTimeStamp, 0);

		m_nRecTime = MP4Mux_GetRecordTime();
		if(m_recCB && m_nLastRecTime != m_nRecTime)
			m_recCB(m_nCurPort, AVRecRetTime, (LONG)m_nRecTime, m_lUserParam);

		m_nLastRecTime = m_nRecTime;
	}
	else if(nFrameType == 3) // 音频帧
	{
		MP4Mux_WriteAudioData(pBuf, nLen, nTimeStamp);
	}

	return 0;

}

long	CAVRecord::StopRec()
{
	MP4Mux_Close();
	m_nWriteFirst = 0;
	return 0;
}

/*
void CAVRecord::TestInitMp4(unsigned char *buf)
{
const char *Path_I_V = "D:\\Video.h264";
const char *Path_I_A = "D:\\Audio.aac";

av_register_all();
AVFormatContext *pFormatContext_I_V = NULL;
if(avformat_open_input(&pFormatContext_I_V,Path_I_V,0,0) < 0)
goto end;
if(avformat_find_stream_info(pFormatContext_I_V,0) < 0)
goto end;
//打开、查找输入的音频流
const char *Path_O = "D:\\Media.mp4";
AVFormatContext *pFormatContext_I_A = NULL;
if(avformat_open_input(&pFormatContext_I_A,Path_I_A,0,0) < 0)
goto end;
if(avformat_find_stream_info(pFormatContext_I_A,0) < 0)
goto end;
//初始化一个用于输出的结构体AVFormatContext，并猜测其输出数据的格式

avformat_alloc_output_context2(&m_pRecFormatCxt,NULL,NULL,Path_O);
if(m_pRecFormatCxt == NULL)
goto end;
//结构体AVOutputFormat -- 存储输出数据的封装格式
AVOutputFormat *pOutputFormat = NULL;
//struct AVOutputFormat *oformat -- 结构体AVFormatContext的参数
pOutputFormat = m_pRecFormatCxt->oformat;
//获取视频流输入索引，创建对应输出视频流并设置其输出索引、编码器上下文等参数
int i = 0,VideoIndex_I = -1,VideoIndex_O = -1;
for(i=0;i<pFormatContext_I_V->nb_streams;i++)
{
if(pFormatContext_I_V->streams[i]->codec->codec_type == AVMEDIA_TYPE_VIDEO)
{
//获得视频流输入索引
VideoIndex_I = i;
//结构体AVStream -- 存储视频/音频流信息
AVStream *StreamIn = pFormatContext_I_V->streams[i];
//以输入的流所使用的编码器创建一条输出流，每次创建都会生成对应的新的索引
AVStream *StreamOut = avformat_new_stream(m_pRecFormatCxt,StreamIn->codec->codec);
if(!StreamOut)
goto end;
//获取生成的输出多媒体流中视/音频流的索引
VideoIndex_O = StreamOut->index;

for(int i =0 ; i < StreamIn->codec->extradata_size; i++)
{
JTRACE("%x, ", StreamIn->codec->extradata[i]);
JTRACE("\r\n");
}

//将输入视频/音频的参数拷贝至输出视频/音频的AVCodecContext结构体
if(avcodec_copy_context(StreamOut->codec,StreamIn->codec) < 0)
goto end;
StreamOut->codec->codec_tag = 0;
if(m_pRecFormatCxt->oformat->flags & AVFMT_GLOBALHEADER)
StreamOut->codec->flags |= CODEC_FLAG_GLOBAL_HEADER;
break;
}
}
//获取音频流输入索引，创建对应输出音频流并设置其输出索引、编码器上下文等参数
int AudioIndex_I = -1,AudioIndex_O = -1;
for(i=0;i<pFormatContext_I_A->nb_streams;i++)
{
if(pFormatContext_I_A->streams[i]->codec->codec_type == AVMEDIA_TYPE_AUDIO)
{
//获得音频流输入索引
AudioIndex_I = i;
AVStream *StreamIn = pFormatContext_I_A->streams[i];
AVStream *StreamOut = avformat_new_stream(m_pRecFormatCxt,StreamIn->codec->codec);
if(!StreamOut)
goto end;
AudioIndex_O = StreamOut->index;
if(avcodec_copy_context(StreamOut->codec,StreamIn->codec) < 0)
goto end;
StreamOut->codec->codec_tag = 0;
if(m_pRecFormatCxt->oformat->flags & AVFMT_GLOBALHEADER)
StreamOut->codec->flags |= CODEC_FLAG_GLOBAL_HEADER;
break;
}
}
//打开多媒体流输出文件

if(avio_open(&m_pRecFormatCxt->pb,Path_O,AVIO_FLAG_WRITE) < 0)
goto end;



//写多媒体流输出文件的文件头
if(avformat_write_header(m_pRecFormatCxt,NULL) < 0)
{
JTRACE("error\r\n");
}

end:
JTRACE("end\r\n");
}*/
AVStream* CAVRecord::AddMp4Stream(AVFormatContext *oc, AVCodec **codec, enum AVCodecID codec_id, AVFormatContext *pFormatContext_I_V )
{
	AVCodecContext *c = NULL;
	AVStream *st = NULL;


	*codec = avcodec_find_encoder(codec_id);
	if ( !(*codec) ) 
	{
		JTRACE("CAVRecord::AddMp4Stream   -avcodec_find_encoder error [%s]\r\n", avcodec_get_name(codec_id));
		return NULL;
	}

	st = avformat_new_stream(oc, *codec);
	if (!st) 
	{
		JTRACE("CAVRecord::AddMp4Stream   -avformat_new_stream error\r\n");
		return NULL;
	}
	st->id = oc->nb_streams-1;
	c = st->codec;

	switch ((*codec)->type) {
	case AVMEDIA_TYPE_AUDIO:
		c->codec_id		= codec_id;  
		c->codec_type	= AVMEDIA_TYPE_AUDIO;  
		c->sample_fmt  = (*codec)->sample_fmts ? (*codec)->sample_fmts[0] : AV_SAMPLE_FMT_FLTP;
		c->bit_rate    = 44100;
		c->sample_rate = 16000;
		c->channels    = 2;
		break;

	case AVMEDIA_TYPE_VIDEO:
		//avcodec_get_context_defaults3(c, *codec);  

		c->codec_id = AV_CODEC_ID_H264;  

		/* put sample parameters */  
		c->bit_rate = /*400000*/128000;  
		c->bit_rate_tolerance = 4000000;
		/* resolution must be a multiple of two */  
		c->width = /*352*/1280;  
		c->height = /*288*/960;  
		/* time base: this is the fundamental unit of time (in seconds) in terms 
		of which frame timestamps are represented. for fixed-fps content, 
		timebase should be 1/framerate and timestamp increments should be 
		identically 1. */ 
		c->extradata = /*m_pFileBufSPSPPS*/pFormatContext_I_V->streams[0]->codec->extradata;
		c->extradata_size = /*m_nSPSPPSLen;*/pFormatContext_I_V->streams[0]->codec->extradata_size;
		c->time_base.den = 50;  
		c->time_base.num = 1;  
		c->gop_size = 12; /* emit one intra frame every twelve frames at most */  
		c->pix_fmt = AV_PIX_FMT_YUV420P;  
		// 		c->codec_id = codec_id;
		// 		c->bit_rate = 400000;
		// 	
		// 		c->width    = 1280;
		// 		c->height   = 720;
		// 		c->coded_width = 1280;
		// 		c->coded_height = 720;
		// 		
		// 		c->time_base.den = 30;
		// 		c->time_base.num = 1;
		// 		c->gop_size      = 12; 
		// 		c->pix_fmt       = AV_PIX_FMT_YUV420P;

		if (c->codec_id == AV_CODEC_ID_MPEG2VIDEO) {

			c->max_b_frames = 2;
		}
		if (c->codec_id == AV_CODEC_ID_MPEG1VIDEO) {

			c->mb_decision = 2;
		}
		break;

	default:
		break;
	}

	c->codec_tag = 0;
	if (oc->oformat->flags & AVFMT_GLOBALHEADER)
		c->flags |= CODEC_FLAG_GLOBAL_HEADER;

	return st;
}


int		CAVRecord::SetRecParam(int nWidth, int nHeight, int nFrameRate,  int nAACChannel)
{
	m_nPicWidth = nWidth;
	m_nPicHeight = nHeight;
	m_dwVideoFrameRate = nFrameRate;
	m_nAACChannel	 = nAACChannel;
	return 0;
}

AVStream *CAVRecord::AddMp4Stream(AVFormatContext *oc,  enum AVCodecID codec_id ,char *pSPData, int nSPLen)
{
	AVCodecContext *c = NULL;
	AVStream *st = NULL;

	int	nType = 2;  //

	int nIndex = 8;  //8对应下列下标
	int nBitRate = 16000;
	if(m_nRecType)
	{
		nIndex = 11;
		nBitRate = 8000;
	}
	/*static const int mpeg4audio_sample_rates[16] = {
	96000, 88200, 64000, 48000, 44100, 32000,
	24000, 22050, 16000, 12000, 11025, 8000, 7350
	};*/
	//int nChannel = 2; m_nAACChannel
	m_strAACextra_data[0] = ( nType << 3 ) | ( nIndex >> 1 );
	m_strAACextra_data[1] = ( ( nIndex & 1 ) << 7 ) |(  m_nAACChannel << 3 );


	st = avformat_new_stream(oc, NULL);
	if (!st) 
	{
		JTRACE("CAVRecord::AddMp4Stream   -avformat_new_stream error\r\n");
		return NULL;
	}

	st->id = oc->nb_streams-1;
	c = st->codec;

	switch (codec_id) {
	case AV_CODEC_ID_AAC:
		c->codec_id	   = AV_CODEC_ID_AAC;  
		c->codec_type  = AVMEDIA_TYPE_AUDIO;  
		c->sample_fmt  = AV_SAMPLE_FMT_FLTP;
		c->bit_rate    = nBitRate;
		c->sample_rate = nBitRate;
		c->channels    = m_nAACChannel;
		//c->extradata = (uint8_t*)av_malloc(2);
		c->extradata = (uint8_t *)&m_strAACextra_data;
		//memcpy( c->extradata, m_strAACextra_data, 2 );
		c->extradata_size = 2;
// 		c->time_base.den = nBitRate;
// 		c->time_base.num = 1;
// 		c->flags |= CODEC_FLAG_GLOBAL_HEADER;

		break;

	case AV_CODEC_ID_H264:
		c->codec_id = AV_CODEC_ID_H264;  
		c->codec_type  = AVMEDIA_TYPE_VIDEO;  
		/* put sample parameters */  

		/* resolution must be a multiple of two */  
		c->width =	m_nPicWidth;  
		c->height =	m_nPicHeight; 
		c->coded_width = m_nPicWidth;
		c->coded_height = m_nPicHeight;
		/* time base: this is the fundamental unit of time (in seconds) in terms 
		of which frame timestamps are represented. for fixed-fps content, 
		timebase should be 1/framerate and timestamp increments should be 
		identically 1. */ 
		c->extradata = (uint8_t *)pSPData;
		c->extradata_size = nSPLen;
		c->time_base.den = m_dwVideoFrameRate*10000;  
		c->time_base.num = 1*10000;  

		c->gop_size      = 25; 
		c->qmin = 10;  
		c->qmax = 51;  

		// 		c->gop_size = 250; //关键帧的最大间隔帧数/
		// 		c->keyint_min =10; //关键帧的最小间隔帧数
		// 		c->refs=2;	//运动补偿
		// 		c->rc_max_rate=3000000;//最大码流，x264中单位kbps，ffmpeg中单位bps
		// 		c->rc_min_rate=512000;//最小码流
		c->pix_fmt = AV_PIX_FMT_YUV420P;  
		//c->flags |= CODEC_FLAG_GLOBAL_HEADER;
		break;

	default:
		break;
	}

	c->codec_tag = 0;
	if (oc->oformat->flags & AVFMT_GLOBALHEADER)
		c->flags |= CODEC_FLAG_GLOBAL_HEADER;


	return st;
}


long	CAVRecord::OpenRecFile(const char *pFileName, char *pSpsPps, int nLen)
{
	int nRet = -1;

	AVStream		*audio_st = NULL;


	if( m_nOpenFileFlag )	return 0;

	if(m_nPicWidth <= 0 || m_nPicHeight<= 0) 
	{
		return -2;
		nRet =  -11;
		if( m_recCB )	m_recCB(m_nCurPort, AVRecOpenErr, (LONG)nRet, m_lUserParam);
		return nRet;
	}

	if( !m_nGetSpsPpsFlag )
	{
		JTRACE("CAVRecord::OpenRecFile  get spspps NULL\r\n");
		nRet =  -7;
		if( m_recCB )	m_recCB(m_nCurPort, AVRecOpenErr, (LONG)nRet, m_lUserParam);
		return nRet;
	}


	av_register_all();

	if(m_pRecFormatCxt)
	{
		if(m_pRecFormatCxt->pb)
		{
			av_write_trailer(m_pRecFormatCxt);
			avio_close(m_pRecFormatCxt->pb);
		}

		for(int i =0 ; i < m_pRecFormatCxt->nb_streams; i++)
		{
			avcodec_close(m_pRecFormatCxt->streams[i]->codec);
			av_freep(&m_pRecFormatCxt->streams[i]->codec);
			av_freep(&m_pRecFormatCxt->streams[i]);
		}
		av_free(m_pRecFormatCxt);
		m_pRecFormatCxt = NULL;
	}
	//  		TestInitMp4(NULL);

	//  		return 0;


	m_nVideoFrameCount	= 0;
	m_nAudioPts			= TIME_AUDIO_PTS_INIT;
	avformat_alloc_output_context2(&m_pRecFormatCxt, NULL, NULL, pFileName);

	if(m_pRecFormatCxt == NULL)
	{
		JTRACE("CAVRecord::OpenRecFile   -avformat_alloc_output_context2 error [%d]\r\n", nRet);
		nRet =  -8;
		if( m_recCB )	m_recCB(m_nCurPort, AVRecOpenErr, (LONG)nRet, m_lUserParam);
		return nRet;
	}

	m_pRecFormatCxt->oformat->video_codec = AV_CODEC_ID_H264;  
	m_pRecFormatCxt->oformat->audio_codec = AV_CODEC_ID_AAC; 

	if(m_pRecFormatCxt->oformat == NULL)
	{
		JTRACE("CAVRecord::OpenRecFile   -avformat_alloc_output_context2 error [%d]\r\n", nRet);
		nRet =  -8;
		if( m_recCB )	m_recCB(m_nCurPort, AVRecOpenErr, (LONG)nRet, m_lUserParam);
		return nRet;
	}

	if (m_pRecFormatCxt->oformat->video_codec != AV_CODEC_ID_NONE) 
	{
		m_video_st = AddMp4Stream(m_pRecFormatCxt, AV_CODEC_ID_H264, pSpsPps, nLen);//AddMp4Stream(m_pRecFormatCxt, &video_codec, m_pRecFormatCxt->oformat->video_codec, pFormatContext_I_V);
		if(!m_video_st)
		{
			nRet =  -8;
			if( m_recCB )	m_recCB(m_nCurPort, AVRecOpenErr, (LONG)nRet, m_lUserParam);
			return nRet;
		}
	}
	if (m_pRecFormatCxt->oformat->audio_codec != AV_CODEC_ID_NONE) 
	{
		audio_st = AddMp4Stream(m_pRecFormatCxt, AV_CODEC_ID_AAC, pSpsPps, nLen);//AddMp4Stream(m_pRecFormatCxt, &audio_codec, m_pRecFormatCxt->oformat->audio_codec, NULL);
		if(!audio_st)
		{
			nRet =  -8;
			if( m_recCB )	m_recCB(m_nCurPort, AVRecOpenErr, (LONG)nRet, m_lUserParam);
			return nRet;
		}
	}

	av_dump_format(m_pRecFormatCxt, 0, pFileName, 1);

	nRet = avio_open(&m_pRecFormatCxt->pb, pFileName, AVIO_FLAG_WRITE);
	if( nRet < 0 )
	{
		JTRACE("CAVRecord::OpenRecFile   -avio_open error [%d]\r\n", nRet);
		nRet =  -8;
		if( m_recCB )	m_recCB(m_nCurPort, AVRecOpenErr, (LONG)nRet, m_lUserParam);
		return nRet;
	}

	nRet = avformat_write_header(m_pRecFormatCxt, NULL);
	if( nRet < 0 )
	{
		JTRACE("CAVRecord::OpenRecFile   -avformat_write_header error [%d]\r\n", nRet);
		nRet =  -9;
		if( m_recCB )	m_recCB(m_nCurPort, AVRecOpenErr, (LONG)nRet, m_lUserParam);
		return nRet;
	}

	if( m_recCB )	m_recCB(m_nCurPort, AVRecOpenSuccess, NULL, m_lUserParam);

	m_nOpenFileFlag = 1;
	m_nLastRecTime	= 0;
	m_nFirstRecTime = 0;
	m_nLastVideoFrameNum= 0;
	m_nLastAudioFrameNum= 0;

	return 0;

}

DWORD	CAVRecord::GetRecTime()
{
	return m_nRecTime;
}
long	CAVRecord::SetRecTime(DWORD dwRecTime)
{
	m_nRecEndTime = dwRecTime;
	return 0;
}
unsigned long XGetTimestamp(void)
{
#if (defined _WIN32) || (defined _WIN64)
	return timeGetTime();
#else
	struct timeval now;
	gettimeofday(&now,NULL);
	return now.tv_sec*1000+now.tv_usec/1000;
#endif
}

#if 0
long	CAVRecord::WriteRecData(unsigned char *pBuf, int nLen, int nBufType, unsigned long nTime, DWORD nFrameNum)
{

	int			nRet		= -1;
	int			nWriteCount = 0;
	int			nTemp		= 0;
	int64_t		Duration	= 0;
	AVPacket	avwritePkt;
	AVRational	time_base_in;
	AVRational	time_base_Duration;
	AVRational	time_base_out;
	AVRational	time_base_audio;

	time_base_Duration.den = 1;
	time_base_Duration.num = m_dwVideoFrameRate;

	time_base_audio.den = TIMEBASE_AUDIO_DEN;
	if(m_nRecType == 1)
	{
		if(m_nAudioPts == TIME_AUDIO_PTS_INIT)
			m_nAudioPts = -90000;

		time_base_audio.den = 8000;
	}
	time_base_audio.num = 1;


	time_base_in.den = AV_TIME_BASE;/*TIMEBASE_VIDEO_IN_DEN*/;
	time_base_in.num = 1;

	if(m_nFirstRecTime == 0)
	{
		m_nFirstRecTime = nTime;
	}
	if( !m_nOpenFileFlag )
	{
		return -2;
	}

	time_base_out.den = m_video_st->time_base.den ;/*m_dwFrameRate*/;
	time_base_out.num = 1;

	if(m_nRecEndTime != 0 && (m_nRecTime == m_nRecEndTime))
	{
		if( m_recCB )	m_recCB(m_nCurPort, AVRecTimeEnd, (LONG)m_nRecTime, m_lUserParam);

		return 1; //设置的录像时间  已录完
	}


	av_init_packet(&avwritePkt);

	if( nBufType == 1 ) //video
	{


		Duration = (double)AV_TIME_BASE/(double)(av_q2d(time_base_Duration));
#if 0
		if(m_nLastVideoFrameNum > 0)
		{
			nTemp = nFrameNum - m_nLastVideoFrameNum - 1;
			if(nTemp > 0 )
				m_nVideoFrameCount += nTemp;
		}
#endif 
		//time_base_out.den = Duration;
		//计算当前AVPacket数据的显示时间戳
		avwritePkt.pts = (double)(m_nVideoFrameCount*Duration)/(double)(av_q2d(time_base_in)*AV_TIME_BASE);
		//计算当前AVPacket数据的解码时间戳
		avwritePkt.dts = avwritePkt.pts;
		//计算当前AVPacket数据的时长
		avwritePkt.duration=(double)Duration/(double)(av_q2d(time_base_in)*AV_TIME_BASE);

		avwritePkt.pts = av_rescale_q_rnd(avwritePkt.pts,time_base_in,time_base_out,(AVRounding)(AV_ROUND_NEAR_INF|AV_ROUND_PASS_MINMAX));
		//int64_t dts -- 解码时间戳
		avwritePkt.dts = av_rescale_q_rnd(avwritePkt.dts,time_base_in,time_base_out,(AVRounding)(AV_ROUND_NEAR_INF|AV_ROUND_PASS_MINMAX));
		//int duration -- 数据的时长，以所属媒体流的时间基准为单位
		avwritePkt.duration = av_rescale_q(avwritePkt.duration,time_base_in,time_base_out);

		//avwritePkt.pts = (((double)(nTime - m_nFirstRecTime)/1000))  * (m_video_st->time_base.den);
		//avwritePkt.dts = avwritePkt.pts;

		m_nRecTime = avwritePkt.pts * av_q2d(time_base_out);

		m_nVideoFrameCount++;

		if( m_recCB && m_nLastRecTime != m_nRecTime)	
		{
			m_nAudioPts = m_nRecTime * TIMEBASE_AUDIO_DEN;
			m_recCB(m_nCurPort, AVRecRetTime, (LONG)m_nRecTime, m_lUserParam);
		}


		m_nLastVideoFrameNum = nFrameNum;

		m_nLastRecTime = m_nRecTime;



		//JTRACE("pts = %lld, dts = %lld, duration = %lld, m_dwVideoFrameRate = %d, m_nRecTime = %d\r\n", avwritePkt.pts, avwritePkt.dts, avwritePkt.duration, m_dwVideoFrameRate, m_nRecTime);

	}
	else if( nBufType == 2 )
	{
		//return 0;
		if(m_testFile) fwrite(pBuf, nLen, 1, m_testFile);
		pBuf += 7;
		nLen -= 7;
#if 0
		if(m_nLastAudioFrameNum > 0)
		{
			nTemp = nFrameNum - m_nLastAudioFrameNum - 1;
			if(nTemp > 0 )
				m_nAudioPts += (nTemp * TIME_AUDIO_PTS);
		}
#endif

		avwritePkt.dts = m_nAudioPts ;//XGetTimestamp();//
		avwritePkt.pts = m_nAudioPts ;//XGetTimestamp();//
		avwritePkt.duration = m_nAudioPts;
		
		
		m_nAudioPts += TIME_AUDIO_PTS;//TIME_AUDIO_PTS;//768;
		
	//JTRACE("write aac len...= %d\r\n", nLen);
		avwritePkt.pts = av_rescale_q_rnd(avwritePkt.pts, time_base_audio, time_base_audio, (AVRounding)(AV_ROUND_NEAR_INF|AV_ROUND_PASS_MINMAX));
		avwritePkt.dts = av_rescale_q_rnd(avwritePkt.dts, time_base_audio, time_base_audio, (AVRounding)(AV_ROUND_NEAR_INF|AV_ROUND_PASS_MINMAX));
		avwritePkt.duration = av_rescale_q(avwritePkt.duration, time_base_audio, time_base_audio);

		//m_nRecTime = avwritePkt.pts * av_q2d(time_base_out);
		//JTRACE("================================pts = %lld, dts = %lld, duration = %lld, m_nRecTime = %d\r\n", avwritePkt.pts, avwritePkt.dts, avwritePkt.duration, m_nRecTime);

		m_nLastAudioFrameNum = nFrameNum;
	}


	avwritePkt.pos			= -1;
	avwritePkt.stream_index	= nBufType -1;
	avwritePkt.flags	   |= AV_PKT_FLAG_KEY;
	avwritePkt.data			= (uint8_t*)pBuf;
	avwritePkt.size			= nLen;


	nRet = av_interleaved_write_frame(m_pRecFormatCxt, &avwritePkt);
	while(nRet < 0 && nWriteCount< 3)
	{
		nRet = av_interleaved_write_frame(m_pRecFormatCxt, &avwritePkt);
		nWriteCount ++;
	}
	if( nRet < 0)
	{
		JTRACE("CAVRecord::WriteMp4Data   -av_interleaved_write_frame error = [%d], frameType = [%d]\r\n", nRet, nBufType);
		av_free_packet(&avwritePkt);
		return -1;
	}


	//JTRACE("av_interleaved_write_frame nRet = %d, size = %d, time = %d\r\n", nRet, nLen, nTime);
	avio_flush(m_pRecFormatCxt->pb);
	av_free_packet(&avwritePkt);


	return 0;
}
#endif

long    CAVRecord::WriteRecData(unsigned char *pBuf, int nLen, int nBufType, unsigned long nTime, DWORD nFrameNum)
{

	int            nRet        = -1;
	int            nWriteCount = 0;
	int            nTemp        = 0;
	int64_t        Duration    = 0;
	AVPacket    avwritePkt;
	AVRational    time_base_in;
	AVRational    time_base_Duration;
	AVRational    time_base_out;
	AVRational    time_base_audio;

	time_base_Duration.den = 1;
	time_base_Duration.num = m_dwVideoFrameRate;

	time_base_audio.den = TIMEBASE_AUDIO_DEN;
	time_base_audio.num = 1;


	time_base_in.den = AV_TIME_BASE;/*TIMEBASE_VIDEO_IN_DEN*/;
	time_base_in.num = 1;

	if(m_nRecType == 1)
	{
		if(m_nAudioPts == TIME_AUDIO_PTS_INIT)
			m_nAudioPts = -90000;

		time_base_audio.den = 8000;
	}

	if(m_nFirstRecTime == 0)
	{
		m_nFirstRecTime = nTime;
	}
	if( !m_nOpenFileFlag )
	{
		return -2;
	}

	time_base_out.den = m_video_st->time_base.den ;/*m_dwFrameRate*/;
	time_base_out.num = 1;

	if(m_nRecEndTime != 0 && (m_nRecTime == m_nRecEndTime))
	{
		if( m_recCB )    m_recCB(m_nCurPort, AVRecTimeEnd, (LONG)m_nRecTime, m_lUserParam);

		return 1; 
	}


	av_init_packet(&avwritePkt);

	if( nBufType == 1 ) //video
	{


		Duration = (double)AV_TIME_BASE/(double)(av_q2d(time_base_Duration));
#if 0
		if(m_nLastVideoFrameNum > 0)
		{
			nTemp = nFrameNum - m_nLastVideoFrameNum - 1;
			if(nTemp > 0 )
				m_nVideoFrameCount += nTemp;
		}
#endif
		
		avwritePkt.pts = (double)(m_nVideoFrameCount*Duration)/(double)(av_q2d(time_base_in)*AV_TIME_BASE);
		avwritePkt.dts = avwritePkt.pts;
		avwritePkt.duration=(double)Duration/(double)(av_q2d(time_base_in)*AV_TIME_BASE);

		avwritePkt.pts = av_rescale_q_rnd(avwritePkt.pts,time_base_in,time_base_out,(AVRounding)(AV_ROUND_NEAR_INF|AV_ROUND_PASS_MINMAX));
		avwritePkt.dts = av_rescale_q_rnd(avwritePkt.dts,time_base_in,time_base_out,(AVRounding)(AV_ROUND_NEAR_INF|AV_ROUND_PASS_MINMAX));
		avwritePkt.duration = av_rescale_q(avwritePkt.duration,time_base_in,time_base_out);

		//avwritePkt.pts = (((double)(nTime - m_nFirstRecTime)/1000))  * (m_video_st->time_base.den);
		//avwritePkt.dts = avwritePkt.pts;

		m_nRecTime = avwritePkt.pts * av_q2d(time_base_out);

		m_nVideoFrameCount++;

		if( m_recCB && m_nLastRecTime != m_nRecTime)
		{
			m_nAudioPts = m_nRecTime * TIMEBASE_AUDIO_DEN;
			m_recCB(m_nCurPort, AVRecRetTime, (LONG)m_nRecTime, m_lUserParam);
		}


		m_nLastVideoFrameNum = nFrameNum;

		m_nLastRecTime = m_nRecTime;

		//JTRACE("pts = %lld, dts = %lld, duration = %lld, m_dwVideoFrameRate = %d, m_nRecTime = %d\r\n", avwritePkt.pts, avwritePkt.dts, avwritePkt.duration, m_dwVideoFrameRate, m_nRecTime);

	}
	else if( nBufType == 2 )
	{
		//return 0;
		if(m_testFile) fwrite(pBuf, nLen, 1, m_testFile);
		pBuf += 7;
		nLen -= 7;
#if 0
		if(m_nLastAudioFrameNum > 0)
		{
			nTemp = nFrameNum - m_nLastAudioFrameNum - 1;
			if(nTemp > 0 )
				m_nAudioPts += (nTemp * TIME_AUDIO_PTS);
		}
#endif

		avwritePkt.dts = m_nAudioPts;//XGetTimestamp();//
		avwritePkt.pts = m_nAudioPts;//XGetTimestamp();//
		//avwritePkt.duration = m_nAudioPts;

		m_nAudioPts += TIME_AUDIO_PTS;//TIME_AUDIO_PTS;//768;

		avwritePkt.pts = av_rescale_q_rnd(avwritePkt.pts, time_base_audio, time_base_audio, (AVRounding)(AV_ROUND_NEAR_INF|AV_ROUND_PASS_MINMAX));
		avwritePkt.dts = av_rescale_q_rnd(avwritePkt.dts, time_base_audio, time_base_audio, (AVRounding)(AV_ROUND_NEAR_INF|AV_ROUND_PASS_MINMAX));
		//avwritePkt.duration = av_rescale_q(avwritePkt.duration, time_base_audio, time_base_audio);

		//m_nRecTime = avwritePkt.pts * av_q2d(time_base_out);
		//JTRACE("================================pts = %lld, dts = %lld, duration = %lld, m_nRecTime = %d\r\n", avwritePkt.pts, avwritePkt.dts, avwritePkt.duration, m_nRecTime);

		m_nLastAudioFrameNum = nFrameNum;
	}


	avwritePkt.pos            = -1;
	avwritePkt.stream_index    = nBufType -1;
	avwritePkt.flags       |= AV_PKT_FLAG_KEY;
	avwritePkt.data            = (uint8_t*)pBuf;
	avwritePkt.size            = nLen;


	nRet = av_interleaved_write_frame(m_pRecFormatCxt, &avwritePkt);
	while(nRet < 0 && nWriteCount< 3)
	{
		nRet = av_interleaved_write_frame(m_pRecFormatCxt, &avwritePkt);
		nWriteCount ++;
	}
	if( nRet < 0)
	{
		JTRACE("CAVRecord::WriteMp4Data   -av_interleaved_write_frame error = [%d], frameType = [%d]\r\n", nRet, nBufType);
		av_free_packet(&avwritePkt);
		return -1;
	}


	//JTRACE("av_interleaved_write_frame nRet = %d, size = %d, time = %d\r\n", nRet, nLen, nTime);
	avio_flush(m_pRecFormatCxt->pb);
	av_free_packet(&avwritePkt);


	return 0;
}

long	CAVRecord::CloseRecFile()
{

	m_nOpenFileFlag = 0;
	m_nGetSpsPpsFlag = 0;
	if(m_pRecFormatCxt)
	{
		if(m_pRecFormatCxt->pb)
		{
			av_write_trailer(m_pRecFormatCxt);
			avio_close(m_pRecFormatCxt->pb);
		}

		for(int i =0 ; i < m_pRecFormatCxt->nb_streams; i++)
		{
			avcodec_close(m_pRecFormatCxt->streams[i]->codec);
			av_freep(&m_pRecFormatCxt->streams[i]->codec);
			av_freep(&m_pRecFormatCxt->streams[i]);
		}

		av_free(m_pRecFormatCxt);
		m_pRecFormatCxt = NULL;
	}

	m_nVideoFrameCount = 0;


	return 0;
}


int	CAVRecord::Get_SPS_PPS(unsigned char *data,unsigned int size, char **outData, int *outLen)
{
	int		nLen		= 0;
	int		nRetSPS		= -1;
	int		nRetPPS		= -1;
	int		nRet		= -1;
	char*	pSpsData	= NULL;
	char*	pPpsData	= NULL;

#if 0
	for(int i = 0; i < 200; i++)
	{
		JTRACE("%02x, ", data[i]);
	}
#endif

	if( *outData != NULL )
	{
		return -2;
	}

	if(m_nGetSpsPpsFlag)
		return 0;

	m_nHeadPos = 0;

	nRet = ReadSPSAndPPS(data, size,  &pSpsData, &pPpsData, &nRetSPS, &nRetPPS);

	if( nRet < 0 ) 
	{
		SAFE_DELETE(pSpsData);
		SAFE_DELETE(pPpsData);
		return -1;
	}

	nLen += nRetSPS;
	nLen += nRetPPS;


	*outData = new char[nLen];
	memcpy((*outData), pSpsData, nRetSPS);
	memcpy((*outData)+nRetSPS, pPpsData, nRetPPS);
	*outLen = nLen;
	m_nGetSpsPpsFlag = 1;

	for(int i = 0; i < nLen; i++)
	{
		JTRACE("%02x, ", (*outData)[i]);
	}

	SAFE_DELETE(pSpsData);
	SAFE_DELETE(pPpsData);

	return 0;

}


int CAVRecord::ReadSPSAndPPS(uint8_t *buf, int buf_size, char **out_spsbuf, char **out_ppsbuf, int *nSpsLen, int *nPpsLen)
{

	int nStartSpsPos	= -1;
	int nEndSpsPos		= -1;
	int nStartPpsPos	= -1;
	int nEndPpsPos		= -1;
	int nLen_sps		= 0;
	int nLen_pps		= 0;
	for(int i = 0 ; i < 100; i++)
	{
		JTRACE("%02x, ", buf[i]);
	}
	JTRACE("\r\n");
	for(int i = 0; i < buf_size; i++)
	{
		if( buf[i] == 0x00 && buf[i+1] == 0x00 && buf[i+2] == 0x00 && buf[i+3] == 0x01 )
		{
			if( buf[i+4] == H264_SPS_FLAG || buf[i+4] == H264_SPS_FLAG_ )
			{
				nStartSpsPos = i;
			}
			else if( buf[i+4] == H264_PPS_FLAG || buf[i+4] == H264_PPS_FLAG_ )
			{
				nEndSpsPos = i;
				nStartPpsPos = i;
			}
			else if(nStartSpsPos > -1 && nStartPpsPos > 4 && nEndSpsPos > 0 && nEndPpsPos < 0)
			{
				nEndPpsPos  = i;
				break;
			}

		}

	}

	nLen_sps = nEndSpsPos - nStartSpsPos;
	nLen_pps = nEndPpsPos - nStartPpsPos;
	if(nLen_sps < 1 || nLen_pps < 1)
	{
		return -1;
	}
	*nSpsLen = nLen_sps;
	*nPpsLen = nLen_pps;

	*out_spsbuf = new char[nLen_sps];
	if( !(*out_spsbuf) ) return -1;
	memcpy(*out_spsbuf,buf+nStartSpsPos,nLen_sps);

	*out_ppsbuf = new char[nLen_pps];
	if( !(*out_ppsbuf) ) return -1;
	memcpy(*out_ppsbuf,buf+nStartPpsPos,nLen_pps);


	return 0;
}


int CAVRecord::ReadSPS(uint8_t *buf, int buf_size,  char **out_buf) 
{
	int naltail_pos=m_nHeadPos;
	int nOutLen = 0;

	if( *out_buf )
		return -1;

	while(m_nHeadPos<buf_size)  
	{  
		//search for nal header
		if(buf[m_nHeadPos++] == 0x00 && 
			buf[m_nHeadPos++] == 0x00) 
		{
			if(buf[m_nHeadPos++] == 0x01)
				goto gotnal_head;
			else 
			{
				//cuz we have done an i++ before,so we need to roll back now
				m_nHeadPos--;		
				if(buf[m_nHeadPos++] == 0x00 && 
					buf[m_nHeadPos++] == 0x01 )
				{
					if(buf[m_nHeadPos++] == H264_SPS_FLAG)
					{
						m_nHeadPos --;
						goto gotnal_head;
					}
					else 
					{
						m_nHeadPos --;
						if(buf[m_nHeadPos++] == H264_SPS_FLAG_)
						{
							m_nHeadPos --;
							goto gotnal_head;
						}
					}


				}
				else
					continue;
			}
		}
		else 
			continue;

		//search for nal tail which is also the head of next nal
gotnal_head:
		//normal case:the whole nal is in this m_pFileBuf
		naltail_pos = m_nHeadPos;  
		while (naltail_pos<buf_size)  
		{  
			if(buf[naltail_pos++] == 0x00 && buf[naltail_pos++] == 0x00 )
			{ 

				if(buf[naltail_pos++] == 0x01)
				{
					nOutLen = (naltail_pos)-m_nHeadPos;
					break;
				}
				else
				{
					naltail_pos--;
					if(buf[naltail_pos++] == 0x00 &&
						buf[naltail_pos++] == 0x01)
					{	

						nOutLen = (naltail_pos)-m_nHeadPos;
						break;
					}
				}
			}  
		}


		if(nOutLen > 0)
		{
			*out_buf = new char[nOutLen +1 ];
			if( !(*out_buf) ) return -1;
			memcpy(*out_buf,buf+m_nHeadPos,nOutLen);
			m_nHeadPos=naltail_pos;

			return nOutLen;
		}
		else
		{
			return -1;
		}

		return 0;   		
	}

	return 0;
}

int CAVRecord::ReadPPS(uint8_t *buf, int buf_size,  char **out_buf)  
{    

	int naltail_pos=m_nHeadPos;
	int nalustart;//nal的开始标识符是几个00
	int nOutLen = 0;

	if( *out_buf )
		return -1;
	while(1)
	{
		if(m_nHeadPos==NO_MORE_BUFFER_TO_READ)
			return FALSE;
		while(naltail_pos<buf_size)  
		{  
			if(buf[naltail_pos++] == 0x00 && 
				buf[naltail_pos++] == 0x00) 
			{
				if(buf[naltail_pos++] == 0x01)
				{	
					nalustart=3;
					goto gotnal ;
				}
				else 
				{
					naltail_pos--;		
					if(buf[naltail_pos++] == 0x00 && 
						buf[naltail_pos++] == 0x01)
					{
						nalustart=4;
						goto gotnal;
					}
					else
						continue;
				}
			}
			else 
				continue;

gotnal:	

			//nalu.type = buf[m_nHeadPos]&0x1f; 
			nOutLen=naltail_pos-m_nHeadPos-nalustart;
			if( ( buf[m_nHeadPos]&0x1f) == 0x06 )
			{
				m_nHeadPos=naltail_pos;
				continue;
			}
			if(nOutLen > 0)
			{
				*out_buf = new char[nOutLen +1 ];
				if( !(*out_buf) ) return -1;
				memcpy(*out_buf,buf+m_nHeadPos,nOutLen);

				m_nHeadPos=naltail_pos;
				return nOutLen;
			}
			else
			{
				return -1;
			}  

		}
	}

	return 0;
}


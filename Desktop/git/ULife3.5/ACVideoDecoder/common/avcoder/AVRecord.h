#ifndef _AVRECORD_H_
#define _AVRECORD_H_



#include "../AVPlayer/AVPlayer.h"
#include "../AVPlayer/AVCommon.h"
#include "../AVPlayer/JLogWriter.h"

#include "mp4_muxer.h"
#define __STDC_CONSTANT_MACROS


#ifdef __cplusplus
extern "C" 
{
#endif
#include <libavutil/opt.h>
#include "libavcodec/avcodec.h"
#include "libavformat/avformat.h"
#include "libswscale/swscale.h"
#include "libswresample/swresample.h" 
#include "libavutil/avutil.h" 
#ifdef __cplusplus
}
#endif

#if (defined _WIN32) || (defined _WIN64)
#include <WinSock2.h>
#else
#include <arpa/inet.h>
#endif

// 获取SPS PPS begin
#define BUFFER_SIZE 32768
#define NO_MORE_BUFFER_TO_READ BUFFER_SIZE+3

// 获取SPS PPS end

#define TIMEBASE_AUDIO_DEN			16000
#define TIME_AUDIO_PTS_INIT			-1600
#define TIME_AUDIO_PTS				1024
#define TIMEBASE_VIDEO_IN_DEN		1200000


class CAVRecord
{
public:
	CAVRecord();
	virtual ~CAVRecord();

	//mp4muxer begin
	long	StartRec(const char *pFileName);
	long	WriteRec(unsigned char *pBuf, int nLen,int nFrameRate, unsigned int nTimeStamp, int nFrameType, int nFlag = 0);
	long	StopRec();
	//mp4muxer end

	// MP4 beign
	long	OpenRecFile(const char *pFileName, char *pSpsPps, int nLen);
	long	WriteRecData(unsigned char *pBuf, int nLen, int nBufType, unsigned long nTime, DWORD nFrameNum);
	long	CloseRecFile();
	int		Get_SPS_PPS(unsigned char *data,unsigned int size, char **outData, int *outLen);
	DWORD	GetRecTime();
	long	SetRecTime(DWORD dwRecTime);
	int		SetRecParam(int nWidth, int nHeight, int nFrameRate, int nAACChannel);
	//void	TestInitMp4(unsigned char *buf);
	// MP4 end
protected:

	int ReadSPSAndPPS(uint8_t *buf, int buf_size, char **out_spsbuf, char **out_ppsbuf, int *nSpsLen, int *nPpsLen);
	int ReadSPS(uint8_t *buf, int buf_size, char **out_buf);
	int ReadPPS(uint8_t *buf, int buf_size, char **out_buf);
	
	
	AVStream *AddMp4Stream(AVFormatContext *oc, AVCodec **codec, enum AVCodecID codec_id,AVFormatContext *pFormatContext_I_V );
	AVStream *AddMp4Stream(AVFormatContext *oc,  enum AVCodecID codec_id ,char *pSPData, int nSPLen);



public:
	int					m_nCurPort;
	int					m_nOpenFileFlag;
	int					m_nPicWidth;
	int					m_nPicHeight;
	DWORD				m_dwVideoFrameRate;
	DWORD				m_dwAudioFrameRate;
	RECCallBack			m_recCB;
	long				m_lUserParam;
	int					m_nRecType; // 0. 设备端AAC数据， 1. 设备端G711A数据

private:

	int					m_nWriteFirst;
	FILE*				m_testFile;
	int64_t				m_nVideoFrameCount;		// 视频帧总数(包含丢的帧)
	int64_t				m_nAudioPts;			// 音频时间戳		
	int					m_nGetSpsPpsFlag;		// 是否获取SPS PPS标志
	int					m_nHeadPos;
	int					m_nAACChannel;
	char				m_strAACextra_data[2];	// mp4 头extradata字段值
	DWORD				m_nRecTime;
	DWORD				m_nLastRecTime;
	DWORD				m_nFirstRecTime;
	DWORD				m_nRecEndTime;
	AVFormatContext*	m_pRecFormatCxt;
	AVStream*			m_video_st;
	DWORD				m_nLastVideoFrameNum;	// 写入的上一帧 视频帧号
	DWORD				m_nLastAudioFrameNum;	// 写入的上一帧 音频帧号

};

#endif
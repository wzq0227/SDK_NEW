#ifndef __QUEUE_H__
#define __QUEUE_H__

#ifdef WIN32
#include <Windows.h>
#else
#include<pthread.h>
#endif

#define QUE_BUF_COUNT 10

typedef struct
{
	unsigned int nIFrame;
	unsigned int nAVType;		//1 means video,2 means audio
	unsigned int dwSize;		//audio or video data size
	unsigned int dwFrameRate;	//video frame rate or audio samplingRate
	unsigned int dwTimeStamp;
	unsigned int gs_video_cap;	//video's capability
	unsigned int gs_reserved; 
}StDataInfo, stFrameHeader;

typedef struct
{
	stFrameHeader fheader;
	unsigned char*	pszBuf ;	
}AVFrameData;

typedef struct _queuebufdata
{
	AVFrameData*							m_listBuf[QUE_BUF_COUNT];
	int											m_bufcount;
	int											m_dwTotal;	
#ifdef WIN32
	CRITICAL_SECTION					m_cs;
#else
	pthread_mutex_t						m_cs;
#endif
}CQueueBuf;

CQueueBuf* QueueBuf_Create();
void QueueBuf_Destroy(CQueueBuf* queuebuf);
int QueueBuf_GetBuf(CQueueBuf* queuebuf,AVFrameData* pBuf);
int QueueBuf_AddBuf(CQueueBuf* queuebuf,AVFrameData* pBuf);
void QueueBuf_Empty(CQueueBuf* queuebuf);
void QueueBuf_Rest(CQueueBuf* queuebuf,int dwTime);

#endif

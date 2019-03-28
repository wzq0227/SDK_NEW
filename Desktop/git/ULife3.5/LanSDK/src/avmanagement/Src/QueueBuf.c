#include "QueueBuf.h"

CQueueBuf* QueueBuf_Create()
{
	CQueueBuf* pqueuebuf = (CQueueBuf*)malloc(sizeof(CQueueBuf));
	if (pqueuebuf != NULL)
	{
		pqueuebuf->m_dwTotal = QUE_BUF_COUNT;
		pqueuebuf->m_bufcount = 0;
		memset(pqueuebuf->m_listBuf,0,QUE_BUF_COUNT*sizeof(AVFrameData*));
		
#ifdef WIN32
		InitializeCriticalSection(&(pqueuebuf->m_cs));
#else
		pthread_mutex_init(&(pqueuebuf->m_cs),NULL);
#endif
		
		return pqueuebuf;
	}

	return NULL;
}

void QueueBuf_Destroy(CQueueBuf* queuebuf)
{
	QueueBuf_Empty(queuebuf);
#ifdef WIN32
	DeleteCriticalSection(&(queuebuf->m_cs));
#else
	pthread_mutex_destroy(&(queuebuf->m_cs));
#endif
	free(queuebuf);
}

int QueueBuf_GetBuf(CQueueBuf* queuebuf,AVFrameData* pBuf)
{
	int bRet = 0;
	int i = 0;
	if (queuebuf == NULL || pBuf == NULL)
	{
		return bRet;
	}
#ifdef WIN32
	EnterCriticalSection(&(queuebuf->m_cs));
#else
	pthread_mutex_lock(&(queuebuf->m_cs));
#endif

	if( queuebuf->m_bufcount > 0)
	{
		AVFrameData* pRet = queuebuf->m_listBuf[0];
		if (pRet)
		{
			memcpy(&(pBuf->fheader),&(pRet->fheader),sizeof(stFrameHeader));
			memcpy(pBuf->pszBuf,pRet->pszBuf,pRet->fheader.dwSize);
			free(pRet->pszBuf);
			free(pRet);

			for(i = 0; i < queuebuf->m_bufcount - 1; i++)
			{
				queuebuf->m_listBuf[i] = queuebuf->m_listBuf[i+1];
			}
			queuebuf->m_listBuf[queuebuf->m_bufcount - 1] = NULL;
			queuebuf->m_bufcount--;
		}
		
		bRet = 1;
	}

#ifdef WIN32
	LeaveCriticalSection(&(queuebuf->m_cs));
#else
	pthread_mutex_unlock(&(queuebuf->m_cs));
#endif

	return bRet;
}

int QueueBuf_AddBuf(CQueueBuf* queuebuf,AVFrameData* pBuf)
{
	int bRet = 0;

#ifdef WIN32
	EnterCriticalSection(&(queuebuf->m_cs));
#else
	pthread_mutex_lock(&(queuebuf->m_cs));
#endif

	if(queuebuf->m_bufcount>=0 && queuebuf->m_bufcount<queuebuf->m_dwTotal)
	{
		queuebuf->m_listBuf[queuebuf->m_bufcount++] = pBuf;
		bRet = 1;
	}

#ifdef WIN32
	LeaveCriticalSection(&(queuebuf->m_cs));
#else
	pthread_mutex_unlock(&(queuebuf->m_cs));
#endif

	return bRet;
}

void QueueBuf_Empty(CQueueBuf* queuebuf)
{
	int i = 0;
	if (queuebuf->m_bufcount > 0)
	{
		for( i = 0; i < queuebuf->m_bufcount; i++)
		{
			AVFrameData* pBuf = queuebuf->m_listBuf[i];
			if (pBuf)
			{
				free(pBuf->pszBuf);
				free(pBuf);
			}
			queuebuf->m_listBuf[i] = NULL;
		}
		queuebuf->m_bufcount = 0;
	}
}

void QueueBuf_Rest(CQueueBuf* queuebuf,int dwTime)
{
	int tmp = queuebuf->m_bufcount;
#ifdef WIN32
	if (tmp < queuebuf->m_dwTotal && tmp > queuebuf->m_dwTotal/4)
		Sleep(dwTime);
	else
		Sleep(10);
#else
	if (tmp < queuebuf->m_dwTotal && tmp > queuebuf->m_dwTotal/4)
		usleep(dwTime*1000);
	else
		usleep(10*1000);
#endif
}

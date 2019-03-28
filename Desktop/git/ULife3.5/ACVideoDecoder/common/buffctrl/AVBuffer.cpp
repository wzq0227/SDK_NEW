#include "AVBuffer.h"


CAVBufferArray::CAVBufferArray()
{
	m_pBuff			= NULL;
	m_nBuffSize		= 0;
	m_nMaxBufSize	= 0;
	m_nIsSaveBuff	= 0;
}

CAVBufferArray::CAVBufferArray(int nSize)
{
	m_pBuff			= NULL;
	Setbuff(nSize);
}

CAVBufferArray::~CAVBufferArray()
{	
	DeleteBuff();
}

void CAVBufferArray::Setbuff(int	nSize)
{
	DeleteBuff();
	if(nSize > 0)
	{
		m_pBuff = new char[nSize];
		m_nMaxBufSize	= nSize;
	}

}


void CAVBufferArray::DeleteBuff()
{
	SAFE_DELETE(m_pBuff);
	m_nBuffSize		= 0;
	m_nMaxBufSize	= 0;
	m_nIsSaveBuff	= 0;
}


CAVBuffer::CAVBuffer()
{
	m_avBuff				= NULL;
	m_nMaxBuffCount			= 0;
	m_nCurBuffCount			= 0;
	m_nAddIndex				= 0;
	m_nReadIndex			= 0;
	m_nExitFlag				= 0;
	m_nNeedIFrame			= 1;
	m_nLostFrameCount		= 0;
	m_pPictureBuff			= NULL;
	m_nGetPictureFrame		= 0;
	m_nFirstRetOutBufFlag	= 0;
	m_lockBuff.CreateMutex();
}


CAVBuffer::~CAVBuffer()
{

	AVBuffer_Clear();

	m_lockBuff.CloseMutex();
}

int					CAVBuffer::GetHasRecv()
{
	return m_nCurBuffCount;
}

int		CAVBuffer::AVBuffer_Clear()
{
	int				i			= 0;
	PAVBufferArray	pAVBuff		= NULL;
	m_nExitFlag = 1;
	m_lockBuff.Lock();
	JTRACE("AVBuffer_Clear **********************************************\r\n");
	for (i=0; i<m_nMaxBuffCount; i++)
	{
		pAVBuff = m_avBuff[i];
		SAFE_DELETE(pAVBuff);
	}

	SAFE_DELETE_A(m_avBuff);

	m_nMaxBuffCount			= 0;
	m_nCurBuffCount			= 0;
	m_nAddIndex				= 0;
	m_nReadIndex			= 0;
	m_nLostFrameCount		= 0;
	m_nFirstRetOutBufFlag	= 0;
	SAFE_DELETE(m_pPictureBuff);
	m_lockBuff.Unlock();
	return 0;
}

int		CAVBuffer::AVBuffer_SetBuffSize(int nBuffCount, int nBuffSize)
{
	AVBuffer_Clear();
	m_lockBuff.Lock();
	m_nExitFlag		=  0;
	m_avBuff = new PAVBufferArray[nBuffCount];
	m_nMaxBuffCount	= nBuffCount;

	for(int i = 0; i < m_nMaxBuffCount; i++)
	{
		m_avBuff[i] = new CAVBufferArray(nBuffSize);
	}

	SAFE_DELETE(m_pPictureBuff);
	m_pPictureBuff = new CAVBufferArray(nBuffSize);

	m_lockBuff.Unlock();

	return 0;
}


int		CAVBuffer::AVBuffer_PutBuff(char* pBuff, int nBuffSize)
{
	int nRet = 0;
	if(m_lockBuff.Lock() == false)
	{
		JTRACE("m_lockBuff.Lock WAIT_TIMEOUT**********************************************\r\n");
		return nRet;
	}

	if(!m_nFirstRetOutBufFlag)
	{
		if(m_nCurBuffCount  >= ((m_nMaxBuffCount-30)/2)) // 第一次返回缓存满 提前缓存大小的一半
		{
			nRet = -20;
		}
		m_nFirstRetOutBufFlag = 1;
	}
	if((m_nCurBuffCount +20) >= m_nMaxBuffCount) // 预留10帧  ，提前返回缓存满
	{
		nRet = -20;
	}
	


	if(m_nExitFlag)
	{
		m_lockBuff.Unlock();
		JTRACE("end input **********************************************1\r\n");
		return nRet;
	}
	gos_frame_head*			pFrameHead	= (gos_frame_head *)pBuff;
	if( !m_nGetPictureFrame && pFrameHead->nFrameType == gos_video_preview_i_frame)
	{
		jmemcpy(m_pPictureBuff->m_pBuff, pBuff, nBuffSize);
		m_pPictureBuff->m_nBuffSize = nBuffSize;
		m_nGetPictureFrame = 1;
		m_lockBuff.Unlock();
		return nRet;
	}

	PAVBufferArray	pAvBuff	= NULL;
	
	pAvBuff = m_avBuff[m_nAddIndex];
	if(!pAvBuff) 
	{
		m_lockBuff.Unlock();
		return nRet;
	}

	if(m_nLostFrameCount > 0)
	{
		if(pFrameHead->nFrameType == gos_video_i_frame || pFrameHead->nFrameType == gos_video_rec_i_frame)
		{
			m_nLostFrameCount = 0;
		}
	}
	if(pAvBuff->m_nIsSaveBuff == 1 || m_nLostFrameCount > 0)  // 缓存满
	{
		//if(pFrameHead->nFrameType < gos_audio_frame)
		//	JTRACE("CAVBuffer::LostVieoFrame  no = %d, type = %d, count = %d\r\n", pFrameHead->nFrameNo, pFrameHead->nFrameType, m_nLostFrameCount);
		//JTRACE("1^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^%d\r\n", m_nAddIndex);
		m_nLostFrameCount ++;
		m_lockBuff.Unlock();
		return nRet;
#if 0		
		LostBuff();
		pAvBuff = m_avBuff[m_nAddIndex];// m_nAddIndex 可能已经更新s
		if(!pAvBuff) return 0;
#endif
	}

	if(m_nNeedIFrame)
	{
		if(pFrameHead->nFrameType == gos_video_i_frame || pFrameHead->nFrameType == gos_video_rec_i_frame)
		{
			m_nNeedIFrame = 0;
		}
		else
		{
			m_lockBuff.Unlock();
			return nRet;
		}
	}

	if(pAvBuff == NULL || pAvBuff->m_nMaxBufSize < nBuffSize)
	{
		if(pAvBuff)
		{
			pAvBuff->Setbuff(nBuffSize);
		}
		else
		{
			pAvBuff = new CAVBufferArray[nBuffSize];
			if(!pAvBuff)
			{
				m_lockBuff.Unlock();
				return nRet;
			}
		}
	}

	jmemcpy(pAvBuff->m_pBuff, pBuff, nBuffSize);
	pAvBuff->m_nBuffSize = nBuffSize;
	pAvBuff->m_nIsSaveBuff = 1;

	m_nAddIndex++ ;
	m_nCurBuffCount++ ;
	if(m_nAddIndex == m_nMaxBuffCount)
	{
		m_nAddIndex = 0;		// 数组循环添加
	}
	
	m_lockBuff.Unlock();

	//JTRACE("\r\n");
	//JTRACE("AVBuffer_PutBuff  ret  -----------------------------------------------------------%d\r\n", nRet);
	//JTRACE("\r\n");
	return nRet;
}

PAVBufferArray		CAVBuffer::AVBuffer_GetBuff(char** pOutBuff, int* nOutBufLen)
{
	PAVBufferArray	pAvBuff	= NULL;

	if(m_nGetPictureFrame)
	{
		pAvBuff = m_pPictureBuff;
		m_nGetPictureFrame = 0;
		return pAvBuff;
	}

	if(m_lockBuff.Lock() == false)
	{
		JTRACE("m_lockBuff.Lock  AVBuffer_GetBuff WAIT_TIMEOUT**********************************************\r\n");
		return NULL;
	}
	if(m_avBuff[m_nReadIndex]->m_nIsSaveBuff == 1)
	{
		//JTRACE("Getbuf index = %d\r\n", m_nReadIndex);
	
		pAvBuff = m_avBuff[m_nReadIndex];

		pAvBuff->m_nIsSaveBuff = 0;

	}
	else
	{
		m_lockBuff.Unlock();
	}

	

	return pAvBuff;
}

int		CAVBuffer::AVBuffer_EndGetBuff()
{
	m_nReadIndex ++;
	m_nCurBuffCount --;

	//JTRACE("m_nCurBuffCount = %d\r\n", m_nCurBuffCount);
	if(m_nReadIndex == m_nMaxBuffCount)
		m_nReadIndex = 0;
	m_lockBuff.Unlock();
	return 0;
}
int		CAVBuffer::LostBuff()
{
	gos_frame_head*			pFrameHead	= NULL;
	int						i			= 0;
	int						nLostFlag	= 0;
	int						nFlag		= 0;

	pFrameHead = (gos_frame_head *)(m_avBuff[m_nReadIndex]->m_pBuff); 

	//if(pFrameHead->nFrameType != gos_video_i_frame &&  pFrameHead->nFrameType != gos_video_rec_i_frame) // 如果缓存里将要获取的数据不是I帧
	//{																									
		for(int i = m_nReadIndex; i < m_nMaxBuffCount; i++)// 直接丢帧直到下个I帧为止
		{
			if(m_avBuff[i]->m_nIsSaveBuff == 0)
			{
				// 没有找到I帧， 缓存已清空退出丢帧
				m_nAddIndex = 0;
				m_nReadIndex = 0;
				m_nCurBuffCount = 0;
				JTRACE("----------------------------------------------------------------------------------------------------------\r\n");
				return 0;
			}
			pFrameHead = (gos_frame_head *)(m_avBuff[i]->m_pBuff);

			if(pFrameHead->nFrameType == gos_video_i_frame ||  pFrameHead->nFrameType == gos_video_rec_i_frame) 
			{
				JTRACE("update m_nReadIndex............................................................\r\n");
				m_nReadIndex = i;			// 将要取数据的位置 移动到这个I帧
				return 0;
			}
			if(pFrameHead->nFrameType < gos_audio_frame)
				JTRACE("*************************LOST frame no  = %d, type = %d\r\n" ,pFrameHead->nFrameNo, pFrameHead->nFrameType);

			if(!nFlag)
			{
				m_nAddIndex = i;
				nFlag = 1;
				JTRACE("2^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^%d\r\n", m_nAddIndex);
			}
			m_avBuff[i]->m_nIsSaveBuff = 0; //直接丢了
			-- m_nCurBuffCount;

			if(i == m_nMaxBuffCount-1) i = -1; // 数组循环
		}
	//}
	//else	// 如果是I帧， 
	//{
//
//	}

	return 0;
}



#if 0

int		CAVBuffer::LostBuff()
{
	gos_frame_head*			pFrameHead	= NULL;
	int						i			= 0;
	int						nLostFlag	= 0;

	for(i = m_nAddIndex; i < m_nMaxBuffCount; i++)
	{
		pFrameHead = (gos_frame_head *)(m_avBuff[i]->m_pBuff);

		if(pFrameHead->nFrameType != gos_video_i_frame &&  pFrameHead->nFrameType != gos_video_rec_i_frame)
		{	
			nLostFlag =	1;

			//JTRACE("LOST buf index = %d\r\n" ,i);
			if(m_avBuff[i]->m_nIsSaveBuff == 0) return 0;

			m_avBuff[i]->m_nIsSaveBuff = 0;
			if(i == m_nMaxBuffCount-1) i = 0;

			m_nReadIndex = i+1;
			
			if(m_nCurBuffCount >  0)
				-- m_nCurBuffCount;
		}
		else
		{
			int nAddIndex = m_nAddIndex;
			int j = 0;
			int nTemp = -1;
			if(!nLostFlag)
			{
				for(int n = 1;  n < 11; n++)
				{
					
					if(nAddIndex+n >= m_nMaxBuffCount)
					{
						//JTRACE("LOST buf index = %d\r\n" ,j);
						m_avBuff[j]->m_nIsSaveBuff = 0;
						nTemp = j;
						j++;
						if(m_nCurBuffCount >  0)
							-- m_nCurBuffCount;
					}
					else
					{
						//JTRACE("LOST buf index = %d\r\n" ,nAddIndex+n);
						m_avBuff[nAddIndex+n]->m_nIsSaveBuff = 0;
						if(m_nCurBuffCount >  0)
							-- m_nCurBuffCount;
						nTemp = nAddIndex+n;
					}
				}

				if(nTemp > -1)
				{
					if(m_avBuff[nAddIndex]->m_nBuffSize > m_avBuff[nTemp]->m_nMaxBufSize)
					{
						m_avBuff[nTemp]->Setbuff(m_avBuff[nAddIndex]->m_nBuffSize);
					}
					jmemcpy(m_avBuff[nTemp]->m_pBuff, m_avBuff[nAddIndex]->m_pBuff,	m_avBuff[nAddIndex]->m_nBuffSize );
					m_avBuff[nTemp]->m_nBuffSize = m_avBuff[nAddIndex]->m_nBuffSize;
					m_avBuff[nTemp]->m_nIsSaveBuff = 1;
					m_nCurBuffCount ++;
					m_nReadIndex = nTemp;
				}
			}
			else
			{
				m_nNeedIFrame = 1;
			}

			break;
		}
	}
	
	return 0;
}


#endif

// 如果这个缓存好用， 那它是wwei写的 ，如果不好用我不知道是谁写的

#ifndef _AV_BUFFER_H_
#define _AV_BUFFER_H_

#include "../AVPlayer/JLSocketDef.h"
#include "../AVPlayer/JLogWriter.h"



typedef class CAVBufferArray
{
public:
	CAVBufferArray();
	CAVBufferArray(int nSize);
	virtual ~CAVBufferArray();

	void	Setbuff(int	nSize);
	void	DeleteBuff();

	char*		m_pBuff;				// 缓存
	int			m_nBuffSize;			// 数据长度
	int			m_nMaxBufSize;			// 缓存可放最大数据长度
	int			m_nIsSaveBuff;			// 是否存放数据
	

}* PAVBufferArray;


class CAVBuffer
{
public:
	CAVBuffer();
	virtual ~CAVBuffer();

	int					AVBuffer_SetBuffSize(int nBuffCount, int nBuffSize);
	int					AVBuffer_Clear();
	int					AVBuffer_PutBuff(char* pBuff, int nBuffSize);
	PAVBufferArray		AVBuffer_GetBuff(char** pOutBuff, int* nOutBufLen);
	int					AVBuffer_EndGetBuff();
	int					GetHasRecv();

	int							m_nMaxBuffCount;		// 最大缓存数
	
protected:
	int					LostBuff();
protected:
	PAVBufferArray*				m_avBuff;
	
	int							m_nCurBuffCount;		// 当前缓存数
	int							m_nExitFlag;
	int							m_nAddIndex;
	int							m_nReadIndex;
	int							m_nNeedIFrame;
	CMutexLock					m_lockBuff;
	int							m_nLostFrameCount;
	PAVBufferArray				m_pPictureBuff;
	int							m_nGetPictureFrame;
	int							m_nFirstRetOutBufFlag;
};

#endif
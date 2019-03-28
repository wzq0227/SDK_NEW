
// ������������ã� ������wweiд�� ������������Ҳ�֪����˭д��

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

	char*		m_pBuff;				// ����
	int			m_nBuffSize;			// ���ݳ���
	int			m_nMaxBufSize;			// ����ɷ�������ݳ���
	int			m_nIsSaveBuff;			// �Ƿ�������
	

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

	int							m_nMaxBuffCount;		// ��󻺴���
	
protected:
	int					LostBuff();
protected:
	PAVBufferArray*				m_avBuff;
	
	int							m_nCurBuffCount;		// ��ǰ������
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
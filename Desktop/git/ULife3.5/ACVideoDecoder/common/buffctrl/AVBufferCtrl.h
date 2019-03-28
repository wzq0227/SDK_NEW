#ifndef _AV_BUFFERCTRL_H_
#define _AV_BUFFERCTRL_H_

#include "../AVPlayer/JLSocketDef.h"
#include "../AVPlayer/JLogWriter.h"

typedef class CAVBuffArray
{
public:
	CAVBuffArray();
	CAVBuffArray(const void* pBuf,int iSize,long lRealID,DWORD dwData);
	const CAVBuffArray& operator =( const CAVBuffArray& stSrc );
	~CAVBuffArray();
	void Free();
	void Set(int iSize);

	BYTE*	m_pBuf;				// ����
	int		m_iBufSize;			// �����С
	int		m_iMaxSize;			// �����С
	long	m_lRSID;			// ʵʱ��ID
	bool	m_bIsNew;			// �Ƿ�Ϊ�µ�
	DWORD	m_dwData;			// �û�����
}* PAVBuffArray;

class CAVBufferCtrl  
{
public:
	CAVBufferCtrl();
	virtual ~CAVBufferCtrl();

	void		SetUserID(long lUserID);
	void		StopAdd();
	void		Clear();
	void		Reset();
	int			SetSize(int iBufSize,int iCanRead,int iEleSize);
	int			SetCanRead(int iCanRead);
	PAVBuffArray BeginAddBuff(const void* pBuf,int iSize,long lRealID,DWORD dwData);
	void		EndAddBuff();
	PAVBuffArray BeginGetBuff();
	void		EndGetBuff();
	int			GetHasRecv();
	int			GetSpan();
	int			GetSize();

protected:
	long					m_lUserID;				// �û�ID
	PAVBuffArray*			m_arBuf;				// Ԫ������
	long					m_lHasRecv;				// ��д����
	long					m_lHasRead;				// �Ѷ�����
	int						m_iRecvPos;				// ����λ��
	int						m_iReadPos;				// ��ȡλ��
	int						m_iLastRecvPos;			// ��һ����λ��(������)
	int						m_iLastReadPos;			// ��һ��ȡλ��(������)
	int						m_iCanRead;				// �ɶ�������
	int						m_iCurStep;				// ��ǰ����
	int						m_iBuffSize;			// �ش�С
	int						m_iEleSize;				// Ԫ�ش�С
	CMutexLock				m_mutexBuff;			// �������

	bool					m_bCanRead;				// �Ƿ�ɶ�
//	bool					m_bCanWrite;			// �Ƿ��д
	bool					m_bEndAdd;				// �Ƿ����д��
};

#endif 
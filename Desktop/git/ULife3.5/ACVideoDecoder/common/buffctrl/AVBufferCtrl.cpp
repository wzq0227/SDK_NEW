
#include "AVBufferCtrl.h"

CAVBuffArray::CAVBuffArray()
{
	m_pBuf		= NULL;			// ����
	m_iBufSize	= 0;			// �����С
	m_lRSID		= 0;			// ʵʱ��ID
	m_bIsNew	= true;			// �Ƿ�Ϊ�µ�
	m_dwData	= 0;			// �û�����
}

CAVBuffArray::CAVBuffArray(const void* pBuf,int iSize,long lRealID,DWORD dwData)
{
	DbgStrOut("CAVBuffArray\r\n");
	if (iSize<=0)
	{
		m_iBufSize	= 0;
		m_iMaxSize	= 0;
		m_pBuf		= NULL;
	}
	else
	{
		m_pBuf	= new BYTE[iSize];
		if ( m_pBuf )
		{
			m_iBufSize	= iSize;
			m_iMaxSize	= iSize;
			if ( pBuf ) jmemcpy(m_pBuf,pBuf,iSize);
		}
	}

	m_lRSID		= lRealID;		// ʵʱ��ID
	m_bIsNew	= true;			// �Ƿ�Ϊ�µ�
	m_dwData	= dwData;		// �û�����
}

const CAVBuffArray& CAVBuffArray::operator =( const CAVBuffArray& stSrc )
{
	CAVBuffArray*	pThis = this;

	if ( m_iBufSize<stSrc.m_iBufSize )
	{
		Set(stSrc.m_iBufSize);
	}
	
	m_lRSID		= stSrc.m_lRSID;				// ʵʱ��ID
	m_bIsNew	= stSrc.m_bIsNew;				// �Ƿ�Ϊ�µ�
	m_dwData	= stSrc.m_dwData;				// �û�����
	jmemcpy(m_pBuf,stSrc.m_pBuf,stSrc.m_iBufSize);		// ����

	return *pThis;
}

CAVBuffArray::~CAVBuffArray()
{
	Free();
}

void CAVBuffArray::Free()
{
	SAFE_DELETE(m_pBuf);		// ����
	m_iBufSize	= 0;			// �����С
	m_iMaxSize	= 0;			// �����С
	m_lRSID		= 0;			// ʵʱ��ID
	m_dwData	= 0;			// �û�����
}

void CAVBuffArray::Set(int iSize)
{
	Free();
	if ( iSize>0 )
	{
		m_iBufSize	= iSize;			// �����С
		m_pBuf		= new BYTE[iSize];
		m_iMaxSize	= iSize;			// �����С
	}
}

//////////////////////////////////////////////////////////////////////
// Construction/Destruction
//////////////////////////////////////////////////////////////////////

CAVBufferCtrl::CAVBufferCtrl()
{
	DbgStrOut("CAVBufferCtrl start\r\n");
	m_lUserID		= 0;				// �û�ID
	m_arBuf			= NULL;				// Ԫ������

	m_lHasRecv		= 0;				// ��д����
	m_lHasRead		= 0;				// �Ѷ�����
	m_iRecvPos		= -1;				// ����λ��
	m_iReadPos		= -1;				// ��ȡλ��
	
	m_mutexBuff.CreateMutex();
//	m_mutexVar.CreateMutex(NULL,FALSE,NULL,"CAVBufferCtrl:m_mutexVar");
//	m_eventRead.CreateEvent(NULL,FALSE,FALSE,NULL,"CAVBufferCtrl:m_eventRead");

	m_bCanRead		= false;			// �Ƿ�ɶ�
//	m_bCanWrite		= false;			// �Ƿ��д
	m_bEndAdd		= false;			// �Ƿ����д��
	m_iBuffSize		= 0;				// �ش�С
	
	m_iCanRead		= 0;				// �ɶ�������
	m_iCurStep		= 0;				// ��ǰ����
	DbgStrOut("CAVBufferCtrl end\r\n");
//	SetSize(60,2);
}

CAVBufferCtrl::~CAVBufferCtrl()
{
	Clear();

	return;
}

void CAVBufferCtrl::SetUserID(long lUserID)
{
	m_lUserID	= lUserID;
}

void CAVBufferCtrl::StopAdd()
{
	JLOG_TRY
	m_mutexBuff.Lock();
	m_bEndAdd		= true;			// �Ƿ����д��
	m_bCanRead		= false;
	m_iRecvPos		= -1;			// ����λ��
	m_iReadPos		= -1;			// ��ȡλ��
//	m_eventRead.SetEvent();
	m_mutexBuff.Unlock();
	JLOG_CATCH("try-catch CAVBufferCtrl::StopAdd\r\n")
}

void CAVBufferCtrl::Clear()
{
	JLOG_TRY
	int i = 0;
	PAVBuffArray	pstBPEle	= NULL;
	
	m_mutexBuff.Lock();
	m_iRecvPos	= -1;				// ����λ��
	m_iReadPos	= -1;				// ��ȡλ��
	m_lHasRecv	= 0;				// ��д����
	m_lHasRead	= 0;				// �Ѷ�����
	m_bCanRead	= true;				// �Ƿ�ɶ�
//	m_bCanWrite	= false;			// �Ƿ��д
	m_bEndAdd	= true;				// �Ƿ����д��
//	m_eventRead.SetEvent();
//	m_eventWrite.SetEvent();
	m_iCanRead	= 0;				// �ɶ�������
	m_iCurStep	= 0;				// ��ǰ����
	for (i=0;i<m_iBuffSize;i++)
	{
		pstBPEle = m_arBuf[i];
		SAFE_DELETE(pstBPEle);
	}
	SAFE_DELETE_A(m_arBuf);
	m_iBuffSize = 0;
	m_mutexBuff.Unlock();
	JLOG_CATCH("try-catch CAVBufferCtrl::Clear\r\n")
}

void CAVBufferCtrl::Reset()
{
	JLOG_TRY
//	m_mutexBuff.Lock();
	m_iRecvPos	= 0;
	m_iReadPos	= -1;
	m_lHasRecv	= 0;				// ��д����
	m_lHasRead	= 0;				// �Ѷ�����
//	m_bCanWrite	= true;				// �Ƿ��д
	m_bEndAdd	= false;			// �Ƿ����д��
//	m_eventRead.ResetEvent();
	m_bCanRead	= false;			// �Ƿ�ɶ�
//	m_eventWrite.ResetEvent();
//	m_iCanRead	= 0;				// �ɶ�������
	m_iCurStep	= 0;				// ��ǰ����
//	m_mutexBuff.Unlock();
	JLOG_CATCH("try-catch CAVBufferCtrl::Reset\r\n")
}

int	CAVBufferCtrl::SetSize(int iBufSize,int iCanRead,int iEleSize)
{
	int i = 0;
	JLOG_TRY
	m_mutexBuff.Lock();
	Clear();
	m_arBuf		= new PAVBuffArray[iBufSize];
	m_iBuffSize	= iBufSize;	// �ش�С
	m_iEleSize	= iEleSize;			// Ԫ�ش�С
	m_iCanRead	= iCanRead;
	m_iCurStep	= 0;				// ��ǰ����
	Reset();
	// ��ʼ�� begin
	for (i=0;i<m_iBuffSize;i++)
	{
		m_arBuf[i]	= new CAVBuffArray(NULL,iEleSize,0,0);
	}
	// ��ʼ�� end
	m_mutexBuff.Unlock();

	return m_iBuffSize;
	JLOG_CATCH("try-catch CAVBufferCtrl::SetSize\r\n")
	return 0;
}

int CAVBufferCtrl::SetCanRead(int iCanRead)
{
	if ( m_iCanRead==iCanRead ) return 0;
	if (m_mutexBuff.Lock()==false)
	{
		return -1;
	}

	if ( m_iCanRead<iCanRead )
	{
		m_iCanRead	= iCanRead;
		// ���õĿɶ�����,��ȴ�
		m_iCurStep	= 0;
		m_bCanRead	= false;
	}
	else
	{
		// ���õĿɶ���С,������ʼ����
	//	Reset();
		m_iCanRead	= iCanRead;
		m_bCanRead	= true;
	}
	m_mutexBuff.Unlock();

	return 0;
}

PAVBuffArray CAVBufferCtrl::BeginAddBuff(const void* pBuf,int iSize,long lRealID,DWORD dwData)
{
	JLOG_TRY
	PAVBuffArray	pstBPEle	= NULL;
//	CJGetRunTime	jgrt;

//	jgrt.Start();
	if (m_mutexBuff.Lock()==false)
	{
	//	m_mutexBuff.Unlock();
		DbgStrOut("BeginAddBuff m_mutexBuff.Lock WAIT_TIMEOUT,%ld\r\n",m_lUserID);
		return NULL;
	}
	if ( m_bEndAdd )
	{
		m_mutexBuff.Unlock();
		DbgStrOut("BeginAddBuff m_bEndAdd is TRUE,%ld\r\n",m_lUserID);
		return NULL;
	}
	if ( m_iRecvPos==-1 )
	{
		m_mutexBuff.Unlock();
		DbgStrOut("BeginAddBuff m_iRecvPos=-1,%ld\r\n",m_lUserID);
		return NULL;
	}
//	if ( m_iReadPos<0 )	m_iReadPos = 0;
//	if ( m_iRecvPos==m_iBuffSize ) m_iRecvPos=0;
	// д���� begin
	pstBPEle = m_arBuf[m_iRecvPos];
	if ( pstBPEle==NULL || pstBPEle->m_iMaxSize<iSize )
	{
		if ( pstBPEle )
		{
			pstBPEle->Set(iSize);
		}
		else
		{
			pstBPEle = new CAVBuffArray(pBuf,iSize,lRealID,dwData);
			if ( pstBPEle==NULL )
			{
				m_arBuf[m_iRecvPos] = NULL;
				m_mutexBuff.Unlock();
				DbgStrOut("BeginAddBuff new CAVBuffArray error,%ld\r\n",m_lUserID);
				return NULL;
			}
			m_arBuf[m_iRecvPos] = pstBPEle;
		}
	}
	pstBPEle->m_lRSID	= lRealID;
	pstBPEle->m_dwData	= dwData;
	pstBPEle->m_iBufSize= iSize;
	jmemcpy(pstBPEle->m_pBuf,pBuf,iSize);
	pstBPEle->m_bIsNew	= true;
	// д���� end
//	jgrt.End();
//	fTemp = jgrt.GetTimeSpan();
//	JTRACE("[%ld] CAVBufferCtrl::BeginAddBuff Span [%.2f] ms\r\n",m_lUserID,fTemp);
//	if ( fTemp>30.0f) DbgStrOut("[%ld] CAVBufferCtrl::BeginAddBuff Span [%.2f] ms\r\n",m_lUserID,fTemp);
	return pstBPEle;
	JLOG_CATCH("try-catch CAVBufferCtrl::BeginAddBuff\r\n")
	return NULL;
}

void CAVBufferCtrl::EndAddBuff()
{
	JLOG_TRY
//	CJGetRunTimeTC	jgrt;

	if ( m_bEndAdd )
	{
		DbgStrOut("EndAddBuff m_bEndAdd is TRUE,%ld\r\n",m_lUserID);
		return;
	}

//	jgrt.Start();
	// ���Ƽ����� begin
	m_iRecvPos++;
	m_lHasRecv++;				// ��д����
	if ( m_iReadPos<0 )	m_iReadPos = 0;
	if ( m_iRecvPos==m_iBuffSize )
	{
		m_iRecvPos=0;
	}
	if ( GetSpan()>=m_iBuffSize )
	{
		// �������ˣ����
		Reset();
		JTRACE("Reset buf********************************************\r\n");
	}
//	else
//	{
//		if ( m_lHasRecv%60==0 )
//		{
//			DbgStrOut("CAVBufferCtrl::%ld,span=%d,m_lHasRecv=%ld,m_lHasRead=%ld.\r\n",m_lUserID,GetSpan(),m_lHasRecv,m_lHasRead);
//		}
//	}
	m_mutexBuff.Unlock();
	// ���Ƽ����� end
//	jgrt.End();
//	fTemp = jgrt.GetTimeSpan();
//	if ( fTemp>30.0f) DbgStrOut("[%ld] CAVBufferCtrl::EndAddBuff Span [%.2f] ms\r\n",m_lUserID,fTemp);
	JLOG_CATCH("try-catch CAVBufferCtrl::EndAddBuff\r\n")
	return;
}

PAVBuffArray CAVBufferCtrl::BeginGetBuff()
{
	JLOG_TRY
	PAVBuffArray	pstBPEle	= NULL;

	if (m_mutexBuff.Lock()==false)
	{
	
		DbgStrOut("BeginGetBuff m_mutexBuff.Lock WAIT_TIMEOUT,%ld\r\n",m_lUserID);
		return NULL;
	}
	if ( m_bEndAdd )
	{
		m_mutexBuff.Unlock();
		DbgStrOut("BeginGetBuff m_bEndAdd is TRUE,%ld\r\n",m_lUserID);
		return NULL;
	}

	// �Ƿ�ɶ��� 
	switch(m_iCurStep)
	{
	case 0:
		if ( m_lHasRecv-m_lHasRead<m_iCanRead )
		{
			m_iCurStep	= 1;
			m_mutexBuff.Unlock();
			return NULL;
		}
		break;
	case 1:
		if ( m_lHasRecv<=m_lHasRead )
		{
			m_iCurStep	= 0;
			m_mutexBuff.Unlock();
			return NULL;
		}
		break;
	}
	

	if ( m_iReadPos<0 )
	{
		m_mutexBuff.Unlock();
		DbgStrOut("BeginGetBuff m_iReadPos=-1,%ld\r\n",m_lUserID);
		return NULL;
	}

	pstBPEle = m_arBuf[m_iReadPos];
	if ( pstBPEle==NULL )
	{
		m_mutexBuff.Unlock();
		DbgStrOut("BeginGetBuff pstBPEle=NULL,%ld\r\n",m_lUserID);
		return NULL;
	}
	pstBPEle->m_bIsNew	= false;

	return pstBPEle;
	JLOG_CATCH("try-catch CAVBufferCtrl::BeginGetBuff\r\n")
	return NULL;
}

void CAVBufferCtrl::EndGetBuff()
{
	JLOG_TRY
//	CJGetRunTimeTC	jgrt;
//	PAVBuffArray	pstBPEle= NULL;

	if ( m_bEndAdd )
	{
		DbgStrOut("EndGetBuff m_bEndAdd is TRUE,%ld\r\n",m_lUserID);
		return;
	}

	
	m_lHasRead++;
	m_iReadPos++;
	if ( m_iReadPos==m_iBuffSize ) m_iReadPos=0;

	m_mutexBuff.Unlock();
	
	JLOG_CATCH("try-catch CAVBufferCtrl::EndGetBuff\r\n")
	return;
}
int	CAVBufferCtrl::GetHasRecv()
{
	JLOG_TRY
	return m_lHasRecv;
	JLOG_CATCH("try-catch CAVBufferCtrl::GetSpan\r\n")
	return 0;
}
int CAVBufferCtrl::GetSpan()
{
	JLOG_TRY
	return m_lHasRecv-m_lHasRead;
	JLOG_CATCH("try-catch CAVBufferCtrl::GetSpan\r\n")
	return 0;
}

int CAVBufferCtrl::GetSize()
{
	JLOG_TRY
	return m_iBuffSize;
	JLOG_CATCH("try-catch CAVBufferCtrl::GetSize\r\n")
	return 0;
}
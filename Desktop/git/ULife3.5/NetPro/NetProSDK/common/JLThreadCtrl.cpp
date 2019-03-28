// JLThreadCtrl.cpp: implementation of the CJLThreadCtrl class.
//
//////////////////////////////////////////////////////////////////////

#include "JLThreadCtrl.h"

//////////////////////////////////////////////////////////////////////
// Construction/Destruction
//////////////////////////////////////////////////////////////////////

CJLThreadCtrl::CJLThreadCtrl(void* pOwner)
{
	strcpy_s(m_szName,J_DGB_NAME_LEN,"");	// ����...������
	m_hThreadID		= 0;					// �߳�ID
	m_dwThreadState	= THREAD_STATE_STOP;	// �߳�״̬
	m_pThreadFun	= NULL;					// �̺߳���
	m_pParam		= pOwner;				// ����(�ڻص�������ʹ��)
	m_pOwner		= NULL;					// ������(�ڻص�������ʹ��)
	m_hThread		= NULL;
}

CJLThreadCtrl::~CJLThreadCtrl()
{
	StopThread(true);
	m_eventPause.CloseEvent();
	#if (defined _WIN32) || (defined _WIN64)
	if ( m_hThread )
	{
		CloseHandle(m_hThread);
		m_hThread = NULL;
	}
	#endif
}

// �����߳�״̬,ע��:ֻ��������Ӧ��״ֵ̬,�������߼�����,һ��ֻ���̺߳�����,���ý���״̬
HANDLE CJLThreadCtrl::StartThread(fcbJThread* pThreadFun)
{
	if ( pThreadFun==NULL )
	{
		// ����Ĳ�������
		return NULL;
	}
	m_pThreadFun = *pThreadFun;
	
	m_eventPause.CreateEvent();

	// ��ʼ����
	SetThreadState(THREAD_STATE_W_RUN);
	#if (defined _WIN32) || (defined _WIN64)
	m_hThread = CreateThread(NULL, 0, *m_pThreadFun, this, 0, &m_hThreadID);
	#else
	m_hThread = (HANDLE)pthread_create(&m_hThreadID, 0, *m_pThreadFun, (void*)this);
	if ( m_hThread==0 ) m_hThread = (HANDLE)m_hThreadID;
	#endif
	if ( m_hThreadID!=0 )
	{
		// �ɹ�
	//	SetThreadState(THREAD_STATE_RUN);
	//	DbgStrOut("Thread [%ld-%s] Start.\r\n",m_hThreadID,m_szName);
	//	m_eventStop.ResetEvent();
		m_eventPause.ResetEvent();
	}
	else
	{
		m_hThread = NULL;
		// ʧ��
		SetThreadState(THREAD_STATE_STOP);
	}

	return m_hThread;
}

// �����̺߳���
int	CJLThreadCtrl::StopThread(bool bWaitRet)
{
	if ( m_hThreadID==0 ) return -1;

	// �����߳�
	if ( m_dwThreadState==THREAD_STATE_RUN 
		|| m_dwThreadState==THREAD_STATE_PAUSE )
	{
		SetThreadState(THREAD_STATE_W_STOP);	// �ȴ�����
		if ( bWaitRet )
		{
			// �ȴ�����
		//	DbgStrOut("Thread [%ld-%s] wait for stop begin.\r\n",m_hThreadID,m_szName);
			m_eventPause.SetEvent();
			#if (defined _WIN32) || (defined _WIN64)
			if ( m_hThread )
			{
				WaitForSingleObject(m_hThread,INFINITE);
				CloseHandle(m_hThread);
				m_hThread = NULL;
			}
			#else
			void*	tRet	= NULL;
			pthread_join(m_hThreadID,&tRet);
			m_hThread = NULL;
			#endif
		//	DbgStrOut("Thread [%ld-%s] wait for stop end.\r\n",m_hThreadID,m_szName);
		}
	}
	m_hThreadID = 0;
	NotifyStop();
	SetThreadState(THREAD_STATE_STOP);	// �ȴ�����
	return 0;
}

// ��ͣ�̺߳���
int	CJLThreadCtrl::PauseThread()
{
	if ( m_hThreadID==0 ) return -1;
	if ( m_dwThreadState!=THREAD_STATE_RUN ) return -1;

	SetThreadState(THREAD_STATE_PAUSE);			// ��ͣ
	return 0;
}

// �����̺߳���
int CJLThreadCtrl::ContinueThread()
{
	if ( m_hThreadID==0 ) return -1;
	if ( m_dwThreadState!=THREAD_STATE_PAUSE ) return -1;

	m_eventPause.SetEvent();

	SetThreadState(THREAD_STATE_RUN);			// ����
	return 0;
}

// ��ȡ��Ӧ�ľ��
pthread_t CJLThreadCtrl::GetHandle()
{
	return m_hThreadID;
}
	
// ��ȡ�߳�״̬
DWORD CJLThreadCtrl::GetThreadState()
{
	return m_dwThreadState;
}

// ֪ͨ����
void CJLThreadCtrl::NotifyStop()
{
	m_hThreadID = 0;
	m_eventPause.SetEvent();

	if ( m_dwThreadState!=THREAD_STATE_STOP )
	{
		SetThreadState(THREAD_STATE_STOP);	// �ȴ�����
	}
	#if (defined _WIN32) || (defined _WIN64)
	if ( m_hThread )
	{
	//	WaitForSingleObject(m_hThread,INFINITE);
		CloseHandle(m_hThread);
		m_hThread = NULL;
	}
	#endif
}

// ������һ����Ĳ���
// THREAD_STATE_STOP:��ʾ�߳�Ӧ��Ҫ������;
// THREAD_STATE_RUN:��ʾ��������;
DWORD CJLThreadCtrl::GetNextAction()
{
	DWORD	dwRet	= 0;

	// ��鵱ǰ״̬ begin
	if ( m_dwThreadState==THREAD_STATE_W_STOP )
	{
	//	DbgStrOut("Thread [%ld-%s] Stop.\r\n",m_hThreadID,m_szName);
		return THREAD_STATE_STOP;
	}
	else if ( m_dwThreadState==THREAD_STATE_W_RUN )
	{
		// �ȴ�����
		SetThreadState(THREAD_STATE_RUN);
	//	DbgStrOut("Thread [%ld-%s] Start.\r\n",m_hThreadID,m_szName);
		return THREAD_STATE_RUN;
	}
	else if ( m_dwThreadState==THREAD_STATE_PAUSE )
	{
		// �ȴ���ͣ
	//	DbgStrOut("Thread [%ld-%s] wait for Pause begin.\r\n",m_hThreadID,m_szName);
		m_eventPause.WaitEvent();
	//	DbgStrOut("Thread [%ld-%s] wait for Pause end.\r\n",m_hThreadID,m_szName);

		if ( THREAD_STATE_W_STOP==m_dwThreadState )
		{
			NotifyStop();
			return THREAD_STATE_STOP;
		}
		else
		{
			SetThreadState(THREAD_STATE_RUN);
			return THREAD_STATE_RUN;
		}
	}
	// ��鵱ǰ״̬ end
	
	dwRet = dwRet;				// ���� warnning ����...
	return m_dwThreadState;
}

// ���ñ������Ĳ���,���̺߳����е���
int CJLThreadCtrl::SetParam(void* pParam)
{
	m_pParam = pParam;
	return 0;
}

// ��ȡ�������Ĳ���,���̺߳����е���
void*  CJLThreadCtrl::GetParam()
{
	return m_pParam;
}

// ���ñ�����������,���̺߳����е���
int CJLThreadCtrl::SetName(LPCTSTR lpszName)
{
	#if (defined _WIN32) || (defined _WIN64)
	#else
//	return prctl(PR_SET_NAME, lpszName); to do
	#endif
	return 0;
}

// ���ñ�������������(�ڻص�������ʹ��)
int CJLThreadCtrl::SetOwner(void* pOwner)
{
	m_pOwner = pOwner;
	return 0;
}

// ��ȡ��������������(�ڻص�������ʹ��)
void* CJLThreadCtrl::GetOwner()
{
	return m_pOwner;
}

// ��ʼ�̺߳���
void CJLThreadCtrl::SetThreadState(DWORD dwThreadState)
{
	if ( m_dwThreadState!=dwThreadState )
	{
	//	DbgStrOut("Thread [%ld-%s] State Change:0x%08X --> 0x%08X\r\n",m_hThreadID,m_szName,m_dwThreadState,dwThreadState);
		m_dwThreadState = dwThreadState;
	}
}
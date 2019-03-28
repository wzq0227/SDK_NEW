// JLThreadCtrl.cpp: implementation of the CJLThreadCtrl class.
//
//////////////////////////////////////////////////////////////////////

#include "JLThreadCtrl.h"

//////////////////////////////////////////////////////////////////////
// Construction/Destruction
//////////////////////////////////////////////////////////////////////

CJLThreadCtrl::CJLThreadCtrl(void* pOwner)
{
	strcpy_s(m_szName,J_DGB_NAME_LEN,"");	// 名称...调试用
	m_hThreadID		= 0;					// 线程ID
	m_dwThreadState	= THREAD_STATE_STOP;	// 线程状态
	m_pThreadFun	= NULL;					// 线程函数
	m_pParam		= pOwner;				// 参数(在回调函数中使用)
	m_pOwner		= NULL;					// 所有者(在回调函数中使用)
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

// 设置线程状态,注意:只是设置相应的状态值,并不做逻辑处理,一般只在线程函数中,设置结束状态
HANDLE CJLThreadCtrl::StartThread(fcbJThread* pThreadFun)
{
	if ( pThreadFun==NULL )
	{
		// 传入的参数错误
		return NULL;
	}
	m_pThreadFun = *pThreadFun;
	
	m_eventPause.CreateEvent();

	// 开始运行
	SetThreadState(THREAD_STATE_W_RUN);
	#if (defined _WIN32) || (defined _WIN64)
	m_hThread = CreateThread(NULL, 0, *m_pThreadFun, this, 0, &m_hThreadID);
	#else
	m_hThread = (HANDLE)pthread_create(&m_hThreadID, 0, *m_pThreadFun, (void*)this);
	if ( m_hThread==0 ) m_hThread = (HANDLE)m_hThreadID;
	#endif
	if ( m_hThreadID!=0 )
	{
		// 成功
	//	SetThreadState(THREAD_STATE_RUN);
	//	DbgStrOut("Thread [%ld-%s] Start.\r\n",m_hThreadID,m_szName);
	//	m_eventStop.ResetEvent();
		m_eventPause.ResetEvent();
	}
	else
	{
		m_hThread = NULL;
		// 失败
		SetThreadState(THREAD_STATE_STOP);
	}

	return m_hThread;
}

// 结束线程函数
int	CJLThreadCtrl::StopThread(bool bWaitRet)
{
	if ( m_hThreadID==0 ) return -1;

	// 结束线程
	if ( m_dwThreadState==THREAD_STATE_RUN 
		|| m_dwThreadState==THREAD_STATE_PAUSE )
	{
		SetThreadState(THREAD_STATE_W_STOP);	// 等待结束
		if ( bWaitRet )
		{
			// 等待结束
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
	SetThreadState(THREAD_STATE_STOP);	// 等待结束
	return 0;
}

// 暂停线程函数
int	CJLThreadCtrl::PauseThread()
{
	if ( m_hThreadID==0 ) return -1;
	if ( m_dwThreadState!=THREAD_STATE_RUN ) return -1;

	SetThreadState(THREAD_STATE_PAUSE);			// 暂停
	return 0;
}

// 继续线程函数
int CJLThreadCtrl::ContinueThread()
{
	if ( m_hThreadID==0 ) return -1;
	if ( m_dwThreadState!=THREAD_STATE_PAUSE ) return -1;

	m_eventPause.SetEvent();

	SetThreadState(THREAD_STATE_RUN);			// 运行
	return 0;
}

// 获取相应的句柄
pthread_t CJLThreadCtrl::GetHandle()
{
	return m_hThreadID;
}
	
// 获取线程状态
DWORD CJLThreadCtrl::GetThreadState()
{
	return m_dwThreadState;
}

// 通知结束
void CJLThreadCtrl::NotifyStop()
{
	m_hThreadID = 0;
	m_eventPause.SetEvent();

	if ( m_dwThreadState!=THREAD_STATE_STOP )
	{
		SetThreadState(THREAD_STATE_STOP);	// 等待结束
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

// 返回下一次需的操作
// THREAD_STATE_STOP:表示线程应该要结束了;
// THREAD_STATE_RUN:表示正常运行;
DWORD CJLThreadCtrl::GetNextAction()
{
	DWORD	dwRet	= 0;

	// 检查当前状态 begin
	if ( m_dwThreadState==THREAD_STATE_W_STOP )
	{
	//	DbgStrOut("Thread [%ld-%s] Stop.\r\n",m_hThreadID,m_szName);
		return THREAD_STATE_STOP;
	}
	else if ( m_dwThreadState==THREAD_STATE_W_RUN )
	{
		// 等待运行
		SetThreadState(THREAD_STATE_RUN);
	//	DbgStrOut("Thread [%ld-%s] Start.\r\n",m_hThreadID,m_szName);
		return THREAD_STATE_RUN;
	}
	else if ( m_dwThreadState==THREAD_STATE_PAUSE )
	{
		// 等待暂停
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
	// 检查当前状态 end
	
	dwRet = dwRet;				// 避免 warnning 罢了...
	return m_dwThreadState;
}

// 设置本变量的参数,供线程函数中调用
int CJLThreadCtrl::SetParam(void* pParam)
{
	m_pParam = pParam;
	return 0;
}

// 获取本变量的参数,供线程函数中调用
void*  CJLThreadCtrl::GetParam()
{
	return m_pParam;
}

// 设置本变量的名称,供线程函数中调用
int CJLThreadCtrl::SetName(LPCTSTR lpszName)
{
	#if (defined _WIN32) || (defined _WIN64)
	#else
//	return prctl(PR_SET_NAME, lpszName); to do
	#endif
	return 0;
}

// 设置本变量的所有者(在回调函数中使用)
int CJLThreadCtrl::SetOwner(void* pOwner)
{
	m_pOwner = pOwner;
	return 0;
}

// 获取本变量的所有者(在回调函数中使用)
void* CJLThreadCtrl::GetOwner()
{
	return m_pOwner;
}

// 开始线程函数
void CJLThreadCtrl::SetThreadState(DWORD dwThreadState)
{
	if ( m_dwThreadState!=dwThreadState )
	{
	//	DbgStrOut("Thread [%ld-%s] State Change:0x%08X --> 0x%08X\r\n",m_hThreadID,m_szName,m_dwThreadState,dwThreadState);
		m_dwThreadState = dwThreadState;
	}
}

// MutexLockLinux.cpp: implementation of the CMutexLock class.
//
//////////////////////////////////////////////////////////////////////

#include "MutexLock.h"
//////////////////////////////////////////////////////////////////////
// Construction/Destruction
//////////////////////////////////////////////////////////////////////

CMutexLock::CMutexLock()
{
	memset(&m_hObject,0,sizeof(JMutexHandle));
	m_bCreate	= false;
}

CMutexLock::~CMutexLock()
{
	CloseMutex();
}

bool CMutexLock::CreateMutex()
{
	#if (defined _WIN32) || (defined _WIN64)
		m_hObject	= ::CreateMutex(NULL,FALSE,NULL);
		if (m_hObject==NULL) return false;
		m_bCreate	= true;
		return true;
	#else
		// 初始化锁的属性
		pthread_mutexattr_t attr;
		pthread_mutexattr_init(&attr);
		pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_RECURSIVE);	// 设置锁的属性为可递归
		
		// 设置锁的属性
		if (pthread_mutex_init(&m_hObject, &attr)==0)
		{
			// 销毁
			pthread_mutexattr_destroy(&attr);
			m_bCreate	= true;
			return true;
		}
		else
		{
			// 销毁
			pthread_mutexattr_destroy(&attr);
			m_bCreate	= false;
			return false;
		}
	#endif
}

bool CMutexLock::Lock()
{
	if ( m_bCreate==false ) return false;
	#if (defined _WIN32) || (defined _WIN64)
		::WaitForSingleObject((HANDLE)m_hObject, INFINITE);
	#else
		pthread_mutex_lock(&m_hObject);
	#endif
	return true;
}

bool CMutexLock::Unlock()
{
	if ( m_bCreate==false ) return false;
	#if (defined _WIN32) || (defined _WIN64)
		::ReleaseMutex((HANDLE)m_hObject);
	#else
		pthread_mutex_unlock(&m_hObject); 
	#endif
	return true;
}

bool CMutexLock::IsCreate()
{
	return m_bCreate;
}

bool CMutexLock:: CloseMutex()
{
	if ( m_bCreate==false ) return true;
	#if (defined _WIN32) || (defined _WIN64)
		::CloseHandle((HANDLE)m_hObject);
	#else
		pthread_mutex_destroy(&m_hObject);
	#endif
	memset(&m_hObject,0,sizeof(JMutexHandle));
	m_bCreate		= false;
	return true;
}
JMutexHandle CMutexLock::GetObject()
{
	return m_hObject;
}

CMutexLockAuto::CMutexLockAuto(CMutexLock* lpLock)
{
	m_lpLock = lpLock;
	m_lpLock->Lock();
}
CMutexLockAuto::~CMutexLockAuto()
{
	FreeLock();
}
void CMutexLockAuto::FreeLock()
{
	if (m_lpLock)
	{
		m_lpLock->Unlock();
		m_lpLock	= NULL;
	}
}

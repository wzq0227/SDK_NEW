// EventLock.cpp: implementation of the CEventLock class.
//
//////////////////////////////////////////////////////////////////////

#include "EventLock.h"

//////////////////////////////////////////////////////////////////////
// Construction/Destruction
//////////////////////////////////////////////////////////////////////

CEventLock::CEventLock()
{
	memset(&m_hObject,0,sizeof(JEventHandle));
	m_bCreate	= false;
}

CEventLock::~CEventLock()
{
	CloseEvent();
}

bool CEventLock::CreateEvent()
{	
	#if (defined _WIN32) || (defined _WIN64)
		m_hObject	= ::CreateEvent(NULL,FALSE,FALSE,NULL);
		if (m_hObject==NULL) return NULL;
	#else
		pthread_cond_init(&(m_hObject.cond), 0);
		pthread_mutex_init(&(m_hObject.mtx),NULL);
		m_hObject.manual_reset = FALSE;
		m_hObject.signaled = FALSE;
	#endif

	m_bCreate	= true;
	return true;
}

bool CEventLock::ResetEvent()
{
	if ( m_bCreate==false ) return false;
	#if (defined _WIN32) || (defined _WIN64)
		if (::ResetEvent(m_hObject)) return true;
		else return false;
	#else
		pthread_mutex_lock(&(m_hObject.mtx));
		m_hObject.signaled = false;
		pthread_mutex_unlock(&(m_hObject.mtx));
		return true;
	#endif
}

bool CEventLock::WaitEvent()
{	
	if ( m_bCreate==false ) return false;
	#if (defined _WIN32) || (defined _WIN64)
		if ( ::WaitForSingleObject(m_hObject, INFINITE)==WAIT_OBJECT_0 ) return true;
		else return false;
	#else
		unsigned int timeout	= INFINITE;
		pthread_mutex_lock(&(m_hObject.mtx));
		int ret = 0;
		if(!m_hObject.signaled)
		{
			if(!timeout) ///no time for waiting
			{
				pthread_mutex_unlock(&(m_hObject.mtx));
				return false;
			}
			else
			{
				timespec tm;
				if (INFINITE != timeout)
				{
					/// set timeout
					timeval now;
					gettimeofday(&now, 0);
					tm.tv_sec = now.tv_sec + timeout / 1000 + (((timeout % 1000) * 1000 + now.tv_usec) / 1000000);
					tm.tv_nsec = (((timeout % 1000) * 1000 + now.tv_usec) % 1000000) * 1000;
				}
				/// wait until condition thread returns control
				do
				{
					ret = (INFINITE == timeout ? pthread_cond_wait(&(m_hObject.cond),&(m_hObject.mtx)) :
						pthread_cond_timedwait(&(m_hObject.cond), &(m_hObject.mtx), &tm));
				}
				while (!ret && !m_hObject.signaled);
			}
		}
		/// adjust signaled member
		switch(ret)
		{
			case 0: // success
				if (!m_hObject.manual_reset)
				{
					m_hObject.signaled = false;
				}
				pthread_mutex_unlock(&(m_hObject.mtx));
				return true;
			default:
				pthread_mutex_unlock(&(m_hObject.mtx));
				return false;
		}
		pthread_mutex_unlock(&(m_hObject.mtx));
	#endif
}

bool CEventLock::SetEvent()
{
	if ( m_bCreate==false ) return false;
	#if (defined _WIN32) || (defined _WIN64)
		if (::SetEvent(m_hObject)) return true;
		else return false;
	#else
		pthread_mutex_lock(&(m_hObject.mtx));
		if(m_hObject.manual_reset)
			pthread_cond_broadcast(&(m_hObject.cond));
		else
			pthread_cond_signal(&(m_hObject.cond));
		m_hObject.signaled = true;
		pthread_mutex_unlock(&(m_hObject.mtx));
		return true;
	#endif
}

bool CEventLock::IsCreate()
{
	return m_bCreate;
}

bool CEventLock::CloseEvent()
{	
	if ( m_bCreate==false ) return false;
	#if (defined _WIN32) || (defined _WIN64)
		::PulseEvent(m_hObject);
		::CloseHandle(m_hObject);
	#else
		pthread_mutex_destroy(&(m_hObject.mtx));
		pthread_cond_destroy(&(m_hObject.cond));
	#endif

	memset(&m_hObject,0,sizeof(JMutexHandle));
	m_bCreate		= false;
	return true;
}
JEventHandle CEventLock::GetObject()
{
	return m_hObject;
}

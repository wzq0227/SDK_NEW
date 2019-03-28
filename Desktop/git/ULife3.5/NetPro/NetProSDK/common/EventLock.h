// EventLock.h: interface for the CEventLock class.
//
//////////////////////////////////////////////////////////////////////

#if !defined(AFX_EVENTLOCK_H_JUI__CDEF6584_FA99_46C4_B0AA_760BB7C6F439__INCLUDED_)
#define AFX_EVENTLOCK_H_JUI__CDEF6584_FA99_46C4_B0AA_760BB7C6F439__INCLUDED_

#if _MSC_VER > 1000
#pragma once
#endif // _MSC_VER > 1000

#include "AVCommon.h"

namespace JSocketCtrl
{
#if (defined _WIN32) || (defined _WIN64)
	typedef		HANDLE			JEventHandle;
#else
	typedef struct JHANDLE JEventHandle;
/*
	typedef	struct JHANDLE
	{
		pthread_mutex_t mtx;
		pthread_cond_t cond;
		bool manual_reset;
		bool signaled;
	}JEventHandle;
*/
#endif
class CEventLock  
{
public:
	CEventLock();
	virtual ~CEventLock();

	bool CreateEvent();
	bool ResetEvent();
	bool WaitEvent();
	bool SetEvent();
	bool IsCreate();
	bool CloseEvent();
	JEventHandle GetObject();

public:
protected:
	JEventHandle	m_hObject;						// Ëø¶ÔÏó
	bool			m_bCreate;
};
}
using namespace JSocketCtrl;

#endif // !defined(AFX_EVENTLOCK_H_JUI__CDEF6584_FA99_46C4_B0AA_760BB7C6F439__INCLUDED_)

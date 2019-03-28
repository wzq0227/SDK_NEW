// MutexLockLinux.h: interface for the CMutexLock class.
//
//////////////////////////////////////////////////////////////////////

#if !defined(AFX_MUTEXLOCKLINUX_H__FDC365C0_4E88_4C5D_8846_6D22FF9655E3__INCLUDED_)
#define AFX_MUTEXLOCKLINUX_H__FDC365C0_4E88_4C5D_8846_6D22FF9655E3__INCLUDED_

#include "AVCommon.h"

namespace JSocketCtrl
{
#if (defined _WIN32) || (defined _WIN64)
	typedef		HANDLE			JMutexHandle;
#else
	typedef		pthread_mutex_t	JMutexHandle;
#endif
class CMutexLock  
{
public:
	CMutexLock();
	~CMutexLock();

	bool CreateMutex();
	bool Lock();
	bool Unlock();
	bool IsCreate();
	bool CloseMutex();
	JMutexHandle GetObject();

protected:
	JMutexHandle	m_hObject;
	bool			m_bCreate;
};
class CMutexLockAuto
{
public:
	CMutexLockAuto(CMutexLock* lpLock);
	~CMutexLockAuto();
	void FreeLock();
protected:
	CMutexLock*		m_lpLock;
};
}
using namespace JSocketCtrl;

#endif // !defined(AFX_MUTEXLOCKLINUX_H__FDC365C0_4E88_4C5D_8846_6D22FF9655E3__INCLUDED_)

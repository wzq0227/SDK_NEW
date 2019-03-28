#include "AVCommon.h"
#include "JLogWriter.h"

#if (defined _WIN32) || (defined _WIN64)
void JSleep(long lMilliseconds)
{
	Sleep(lMilliseconds);
}
bool JCreateDirectory(LPCTSTR lpPathName)
{
	if ( CreateDirectory(lpPathName,NULL) ) return true;
	else return false;
}
#else
PJHANDLE JCreateEvent(void *pSec,bool bManualReset,bool bInitialState,char *pStr)
{
	PJHANDLE handle = (PJHANDLE)malloc(sizeof(JHANDLE));
	pthread_cond_init(&handle->cond, 0);
	pthread_mutex_init(&handle->mtx,NULL);
	handle->manual_reset = bManualReset;
	handle->signaled = bInitialState;
	return handle;
}
void CloseEventHandle(PJHANDLE handle)
{
	if(NULL == handle)
		return;

	pthread_mutex_destroy(&handle->mtx);
	pthread_cond_destroy(&handle->cond);
	free(handle);
}
void SetEvent(PJHANDLE handle)
{
	if(NULL == handle)
		return;

	pthread_mutex_lock(&(handle->mtx));

	if(handle->manual_reset)
		pthread_cond_broadcast(&handle->cond);
	else
		pthread_cond_signal(&handle->cond);

	handle->signaled = true;

	pthread_mutex_unlock(&(handle->mtx));
}
void ResetEvent(PJHANDLE handle)
{
	if(NULL == handle)
		return;

	pthread_mutex_lock(&(handle->mtx));
	handle->signaled = false;
	pthread_mutex_unlock(&(handle->mtx));
}
int WaitForEvent(PJHANDLE handle,unsigned int timeout)
{
	if(NULL == handle)
		return 0;
	pthread_mutex_lock(&(handle->mtx));
	int ret = 0;
	if(!handle->signaled)
	{
		if(!timeout) ///no time for waiting
		{
			pthread_mutex_unlock(&(handle->mtx));
			return WAIT_TIMEOUT;
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
				ret = (INFINITE == timeout ? pthread_cond_wait(&handle->cond,&handle->mtx) :
					pthread_cond_timedwait(&handle->cond, &handle->mtx, &tm));
			}
			while (!ret && !handle->signaled);
		}
	}
	/// adjust signaled member
	switch(ret)
	{
	case 0: // success
		if (!handle->manual_reset)
		{
			handle->signaled = false;
		}
		pthread_mutex_unlock(&(handle->mtx));
		return WAIT_OBJECT_0;
	default:
		pthread_mutex_unlock(&(handle->mtx));
		return WAIT_TIMEOUT;
	}
	pthread_mutex_unlock(&(handle->mtx));
}

void JSleep(long lMilliseconds)
{
	usleep(lMilliseconds*1000);
}
bool JCreateDirectory(LPCTSTR lpPathName)
{
	if ( mkdir(lpPathName,S_IRWXU | S_IRWXG | S_IROTH | S_IXOTH) ) return true;
	else return false;
}
#endif
